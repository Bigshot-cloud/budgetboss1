import 'dart:convert';
import 'package:telephony/telephony.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'openai_service.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;
  final _openAI = OpenAIService();

  final Set<String> _processedSms = {}; // duplicate prevention

  void startListening(Function(Map<String, dynamic>) onTransaction) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        String body = message.body ?? "";
        String smsId = message.id?.toString() ?? body.hashCode.toString();

        if (_processedSms.contains(smsId)) return;
        _processedSms.add(smsId);

        if (!_isMoneySms(body)) return;

        double amount = _extractAmount(body);
        if (amount <= 0) return; // Ignore if no valid amount found

        String type = _detectType(body);

        Map<String, dynamic> enriched = await _enrichWithAI(body, amount, type);

        await _saveToFirebase(enriched);

        onTransaction(enriched);
      },
      listenInBackground: false,
    );
  }

  bool _isMoneySms(String sms) {
    String text = sms.toLowerCase();
    return text.contains("received") ||
        text.contains("sent") ||
        text.contains("momo") ||
        text.contains("mobile money") ||
        text.contains("transfer") ||
        text.contains("ghs") ||
        text.contains("ghc") ||
        text.contains("paid") ||
        text.contains("credited") ||
        text.contains("debited");
  }

  double _extractAmount(String sms) {
    // Look for GHS/Ghc followed by a number
    RegExp reg = RegExp(r'(?:GHS|Ghc|Amt:?)\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
    Match? match = reg.firstMatch(sms);
    if (match != null) {
      return double.tryParse(match.group(1) ?? "0") ?? 0.0;
    }
    
    // Fallback to first number found if GHS is not present
    RegExp fallbackReg = RegExp(r'(\d+(?:\.\d{1,2})?)');
    Match? fallbackMatch = fallbackReg.firstMatch(sms);
    return double.tryParse(fallbackMatch?.group(0) ?? "0") ?? 0.0;
  }

  String _detectType(String sms) {
    String text = sms.toLowerCase();
    if (text.contains("received") || text.contains("credited") || text.contains("deposited") || text.contains("from")) {
       // Often "Payment received from..." or "Cash in received..."
       if (text.contains("sent to") || text.contains("paid to")) return "expense";
       return "income";
    }
    return "expense";
  }

  Future<Map<String, dynamic>> _enrichWithAI(String sms, double amount, String type) async {
    try {
      final response = await _openAI.analyzeFinance("""
Extract structured transaction data from this SMS:
SMS: $sms
Amount detected: $amount
Type detected: $type

Return JSON ONLY:
{
  "merchant": "Extracted merchant or person name",
  "category": "food | transport | shopping | bills | income | other",
  "confidence": 0,
  "corrected_type": "income or expense",
  "note": "brief summary"
}
""", isChat: false);

      String cleaned = response.replaceAll("```json", "").replaceAll("```", "").trim();
      Map<String, dynamic> aiData = jsonDecode(cleaned);

      return {
        "title": aiData["merchant"] ?? (type == "income" ? "Income" : "Expense"),
        "amount": amount,
        "type": aiData["corrected_type"] ?? type,
        "category": aiData["category"] ?? "other",
        "rawSms": sms,
        "note": aiData["note"] ?? "",
        "iconCode": _getIconCode(aiData["category"]),
      };
    } catch (e) {
      return {
        "title": type == "income" ? "Income Received" : "Payment Sent",
        "amount": amount,
        "type": type,
        "category": "other",
        "rawSms": sms,
        "note": "AI processing failed",
        "iconCode": Icons.message.codePoint,
      };
    }
  }

  int _getIconCode(String? category) {
    switch (category?.toLowerCase()) {
      case 'food': return Icons.restaurant.codePoint;
      case 'transport': return Icons.directions_car.codePoint;
      case 'shopping': return Icons.shopping_bag.codePoint;
      case 'bills': return Icons.receipt_long.codePoint;
      case 'income': return Icons.payments.codePoint;
      default: return Icons.account_balance_wallet.codePoint;
    }
  }

  Future<void> _saveToFirebase(Map<String, dynamic> data) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
  }
}
