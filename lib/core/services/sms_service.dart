import 'dart:convert';
import 'package:telephony/telephony.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'openai_service.dart';
import 'debug_service.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;
  final _openAI = OpenAIService();
  final _debugService = DebugService();

  final Set<String> _processedSms = {}; // Duplicate prevention

  void startListening(Function(Map<String, dynamic>) onTransaction) {
    _debugService.log(
      feature: "SMS Listener",
      status: "Active",
      message: "Listening for incoming SMS messages",
    );

    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        String body = message.body ?? "";
        String sender = message.address ?? "Unknown";
        String smsId = message.id?.toString() ?? body.hashCode.toString();

        _debugService.log(
          feature: "SMS Listener",
          status: "Received",
          message: "Incoming SMS from $sender",
          details: body,
        );

        if (_processedSms.contains(smsId)) {
           _debugService.log(feature: "SMS Listener", status: "Ignored", message: "Duplicate SMS ID: $smsId");
           return;
        }
        _processedSms.add(smsId);

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
          message: "Financial transaction detected. Processing with AI...",
        );

        try {
          Map<String, dynamic> enriched = await _parseWithAI(body);
          
          if (enriched['amount'] > 0) {
            await _saveToFirebase(enriched);
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

  bool _isFinancialSms(String sms) {
    String text = sms.toLowerCase();
    
    // Core financial keywords (must contain at least one)
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

Return JSON ONLY:
{
  "title": "Merchant/Sender Name",
  "amount": 0.0,
  "type": "income | expense",
  "category": "Food & Dining | Transportation | Shopping | Utilities | Entertainment | Healthcare | Education | Salary | Savings | Investment | Bills | Transfers | Mobile Money | Bank Deposit | ATM Withdrawal | Others",
  "date": "ISO format",
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

    String type = sms.toLowerCase().contains("received") || sms.toLowerCase().contains("credited") 
      ? "income" : "expense";

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

  Future<void> _saveToFirebase(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("transactions")
          .add({
        "title": data["title"],
        "type": "TransactionType.${data["type"]}",
        "amount": data["amount"],
        "category": data["category"],
        "date": FieldValue.serverTimestamp(),
        "iconCode": data["iconCode"],
        "source": "sms",
        "rawSms": data["rawSms"],
        "note": data["note"],
      });
      _debugService.log(feature: "Firebase", status: "Success", message: "Transaction saved to cloud");
    } catch (e) {
       _debugService.log(feature: "Firebase", status: "Failed", message: "Error saving to cloud", details: e.toString());
       throw e;
    }
  }

  void _sendSystemNotification(String title, String body) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
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
  }
}
