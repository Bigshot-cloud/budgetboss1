import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'openai_service.dart';

/*class SmsService {
  final Telephony telephony = Telephony.instance;
  final _openAI = OpenAIService();

  final Set<String> _processedSms = {}; // 🧠 duplicate prevention

  void startListening(Function(Map<String, dynamic>) onTransaction) {
    telephony.listenIncomingSms(
      onNewMessage: (SmsMessage message) async {
        String body = message.body ?? "";
        String smsId = message.id?.toString() ?? body.hashCode.toString();

        // 🚨 1. Duplicate prevention
        if (_processedSms.contains(smsId)) return;
        _processedSms.add(smsId);

        if (!_isMoneySms(body)) return;

        // 🧠 2. Extract raw data
        double amount = _extractAmount(body);
        String type = _detectType(body);

        // 🧠 3. AI enrichment
        Map<String, dynamic> enriched =
        await _enrichWithAI(body, amount, type);

        // 🔥 4. Save to Firebase
        await _saveToFirebase(enriched);

        // 📲 5. Send to UI
        onTransaction(enriched);
      },
      listenInBackground: false,
    );
  }
*/
  // =========================
  // 🟡 BASIC DETECTION
  // =========================

  bool _isMoneySms(String sms) {
    String text = sms.toLowerCase();

    return text.contains("received") ||
        text.contains("sent") ||
        text.contains("momo") ||
        text.contains("mobile money") ||
        text.contains("transfer") ||
        text.contains("ghs") ||
        text.contains("paid") ||
        text.contains("credited") ||
        text.contains("debited");
  }

  double _extractAmount(String sms) {
    RegExp reg = RegExp(r'(\d+(\.\d{1,2})?)');
    Match? match = reg.firstMatch(sms);
    return double.tryParse(match?.group(0) ?? "0") ?? 0.0;
  }

  String _detectType(String sms) {
    String text = sms.toLowerCase();

    if (text.contains("received") ||
        text.contains("credited") ||
        text.contains("deposited")) {
      return "income";
    }
    return "expense";
  }

  /*=========================
  // 🧠 AI ENRICHMENT
  // =========================

  final aiResponse = await _openAI.analyzeFinance("""
Extract structured transaction data:

SMS:
$body

Amount: $amount
Type: $type

Return JSON ONLY:
{
  "merchant": "",
  "category": "",
  "corrected_type": "",
  "confidence": 0-100,
  "note": ""
}
""");

      // Attempt to clean JSON (Gemini sometimes adds markdown blocks)
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

  // =========================
  // 🔥 FIREBASE STORAGE
  // =========================

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
}*/
