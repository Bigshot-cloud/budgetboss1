import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:telephony/telephony.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'openai_service.dart';
import 'debug_service.dart';

class SmsService {
  // Singleton pattern to ensure only one instance exists
  static final SmsService _instance = SmsService._internal();
  factory SmsService() => _instance;
  SmsService._internal();

  final Telephony telephony = Telephony.instance;
  final _openAI = OpenAIService();
  final _debugService = DebugService();

  bool _isListening = false;
  final Set<String> _processedSmsHashes = {}; // In-memory cache for session duplicates

  void startListening(Function(Map<String, dynamic>) onTransaction) {
    if (_isListening) {
      _debugService.log(
        feature: "SMS Listener",
        status: "Warning",
        message: "Listener already active. Ignoring start request.",
      );
      return;
    }

    _isListening = true;
    _debugService.log(
      feature: "SMS Listener",
      status: "Active",
      message: "Listening for incoming SMS messages",
    );

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        String body = message.body ?? "";
        String sender = message.address ?? "Unknown";
        int? timestamp = message.date;
        
        // 🚨 1. Robust Duplicate Prevention (Local)
        // Generate a unique hash for this SMS based on sender, body and timestamp
        String smsHash = _generateSmsHash(sender, body, timestamp);
        
        if (_processedSmsHashes.contains(smsHash)) {
           _debugService.log(feature: "SMS Listener", status: "Ignored", message: "Duplicate SMS detected locally: $smsHash");
           return;
        }
        _processedSmsHashes.add(smsHash);

        _debugService.log(
          feature: "SMS Listener",
          status: "Received",
          message: "Incoming SMS from $sender",
          details: body,
        );

        // 🚨 2. Financial Filter
        if (!_isFinancialSms(body)) {
          _debugService.log(
            feature: "SMS Listener",
            status: "Filtered",
            message: "SMS is not a financial transaction",
          );
          return;
        }

        _debugService.log(
          feature: "SMS Listener",
          status: "Match",
          message: "Financial transaction detected. Processing...",
        );

        try {
          // 🚨 3. AI Extraction with strict constraints
          Map<String, dynamic> enriched = await _parseWithAI(body);
          
          if (enriched['amount'] > 0) {
            // 🚨 4. IDEMPOTENT Database Write
            // Use the SMS hash as the Firestore Document ID to prevent duplicates at the database level
            bool saved = await _saveToFirebaseIdempotent(enriched, smsHash);
            
            if (saved) {
              onTransaction(enriched);
              
              _debugService.log(
                feature: "SMS Parser",
                status: "Success",
                message: "Transaction logged: ${enriched['title']} (GH₵ ${enriched['amount']})",
              );

              _sendSystemNotification(
                "Transaction Recorded 💰",
                "Logged ${enriched['title']} for GH₵ ${enriched['amount']}",
              );
            } else {
              _debugService.log(
                feature: "SMS Parser",
                status: "Ignored",
                message: "Transaction already exists in database.",
              );
            }
          } else {
             _debugService.log(
              feature: "SMS Parser",
              status: "Rejected",
              message: "Amount was 0 or invalid after parsing",
            );
          }
        } catch (e) {
          _debugService.log(
            feature: "SMS Parser",
            status: "Error",
            message: "Failed to process transaction",
            details: e.toString(),
          );
          _sendSystemNotification("SMS Processing Failed", "Unable to analyze this transaction message.");
        }
      },
      listenInBackground: false, 
    );
  }

  String _generateSmsHash(String sender, String body, int? timestamp) {
    String input = "$sender|$body|$timestamp";
    return sha256.convert(utf8.encode(input)).toString();
  }

  bool _isFinancialSms(String sms) {
    String text = sms.toLowerCase();
    
    // Explicit exclusions to reduce noise
    if (text.contains("otp is") || text.contains("verification code")) return false;

    // Core financial keywords
    final financialKeywords = [
      "received", "sent", "momo", "mobile money", "transfer", "ghs", "ghc", 
      "paid", "credited", "debited", "alert", "balance", "transaction", "cash",
      "withdrawal", "deposit", "payment", "bank", "amt", "fee", "reference"
    ];

    return financialKeywords.any((key) => text.contains(key));
  }

  Future<Map<String, dynamic>> _parseWithAI(String sms) async {
    final response = await _openAI.analyzeFinance("""
You are a financial data extractor for BudgetBoss. 
Extract structured transaction data from this SMS.

SMS: $sms

Rules:
1. Classification: 
   - If the message says "received", "credited", "deposit", "cash in", it is an "income".
   - If the message says "sent", "paid", "withdrawal", "transfer", "cash out", "fee", it is an "expense".
   - NEVER return both. Choose the primary action.
2. Return JSON ONLY.

Return format:
{
  "title": "Merchant/Sender Name",
  "amount": 0.0,
  "type": "income | expense",
  "category": "Food & Dining | Transportation | Shopping | Utilities | Entertainment | Healthcare | Education | Salary | Savings | Investment | Bills | Transfers | Mobile Money | Bank Deposit | ATM Withdrawal | Others",
  "note": "summary"
}
""", isChat: false);

    if (response.startsWith("BudgetBoss AI is temporarily unavailable") || 
        response.startsWith("BudgetBoss AI is currently offline") ||
        response.startsWith("AI service connection error")) {
      
      _debugService.log(
        feature: "SMS Parser",
        status: "Fallback",
        message: "AI unavailable, using basic regex extraction",
      );
      return _localRegexFallback(sms);
    }

    try {
      String cleaned = response.replaceAll("```json", "").replaceAll("```", "").trim();
      Map<String, dynamic> aiData = jsonDecode(cleaned);

      return {
        "title": aiData["title"] ?? "Transaction",
        "amount": (aiData["amount"] as num?)?.toDouble() ?? 0.0,
        "type": aiData["type"] == "income" ? "income" : "expense",
        "category": aiData["category"] ?? "Others",
        "rawSms": sms,
        "note": aiData["note"] ?? "",
        "iconCode": _getIconCode(aiData["category"]),
      };
    } catch (e) {
      _debugService.log(
        feature: "SMS Parser",
        status: "Parsing Failed",
        message: "Failed to decode JSON from AI",
        details: response,
      );
      throw Exception("AI output formatting error");
    }
  }

  Map<String, dynamic> _localRegexFallback(String sms) {
    // Basic local parsing logic if OpenAI fails
    double amount = 0.0;
    RegExp amountReg = RegExp(r'(?:GHS|Ghc|Amt:?)\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    Match? match = amountReg.firstMatch(sms);
    if (match != null) {
      amount = double.tryParse(match.group(1) ?? "0") ?? 0.0;
    }

    String lowerSms = sms.toLowerCase();
    String type = "expense";
    if (lowerSms.contains("received") || lowerSms.contains("credited") || lowerSms.contains("deposit") || lowerSms.contains("cash in")) {
       type = "income";
    }

    return {
      "title": "SMS Transaction (Local)",
      "amount": amount,
      "type": type,
      "category": "Others",
      "rawSms": sms,
      "note": "AI offline - local extraction used",
      "iconCode": Icons.message.codePoint,
    };
  }

  int _getIconCode(String? category) {
    switch (category?.toLowerCase()) {
      case 'food & dining': return Icons.restaurant.codePoint;
      case 'transportation': return Icons.directions_car.codePoint;
      case 'shopping': return Icons.shopping_bag.codePoint;
      case 'utilities': return Icons.electrical_services.codePoint;
      case 'entertainment': return Icons.movie.codePoint;
      case 'healthcare': return Icons.local_hospital.codePoint;
      case 'education': return Icons.school.codePoint;
      case 'salary':
      case 'income': return Icons.payments.codePoint;
      case 'savings': return Icons.savings.codePoint;
      case 'investment': return Icons.trending_up.codePoint;
      case 'bills': return Icons.receipt_long.codePoint;
      case 'transfers': return Icons.compare_arrows.codePoint;
      case 'mobile money': return Icons.phone_android.codePoint;
      case 'bank deposit': return Icons.account_balance.codePoint;
      case 'atm withdrawal': return Icons.atm.codePoint;
      default: return Icons.account_balance_wallet.codePoint;
    }
  }

  Future<bool> _saveToFirebaseIdempotent(Map<String, dynamic> data, String smsHash) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("transactions")
          .doc("sms_$smsHash"); // 🚨 Use hash as ID to ensure only one document exists per SMS

      final doc = await docRef.get();
      if (doc.exists) return false; // Already processed

      await docRef.set({
        "title": data["title"],
        "type": "TransactionType.${data["type"]}",
        "amount": data["amount"],
        "category": data["category"],
        "date": FieldValue.serverTimestamp(),
        "iconCode": data["iconCode"],
        "source": "sms",
        "rawSms": data["rawSms"],
        "note": data["note"],
        "smsHash": smsHash, // Store for reference
      });
      
      _debugService.log(feature: "Firebase", status: "Success", message: "Transaction saved with ID: sms_$smsHash");
      return true;
    } catch (e) {
       _debugService.log(feature: "Firebase", status: "Failed", message: "Error saving to cloud", details: e.toString());
       rethrow;
    }
  }

  void _sendSystemNotification(String title, String body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .add({
        'title': title,
        'body': body,
        'date': Timestamp.now(),
        'isRead': false,
      });
    } catch (e) {
      debugPrint("Error sending system notification: $e");
    }
  }
}
