import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> analyzeFinance(String prompt, {bool isChat = true}) async {
    if (_apiKey.isEmpty) {
      debugPrint("OpenAI API Key is missing from .env file");
      return "BudgetBoss AI is currently offline. Please check back later.";
    }

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content": isChat 
                ? "You are BudgetBoss AI, a personal finance assistant. Be helpful, concise, and professional."
                : "You are a financial data extractor. Return JSON only."
            },
            {
              "role": "user",
              "content": prompt,
            }
          ],
          "temperature": isChat ? 0.7 : 0.1
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["choices"][0]["message"]["content"];
      } 
      
      // Friendly Error Handling
      if (response.statusCode == 429) {
        return "BudgetBoss AI is temporarily unavailable because the AI service has reached its usage limit. Please try again later.";
      } else if (response.statusCode == 401) {
        debugPrint("OpenAI Auth Error: Invalid API Key");
        return "BudgetBoss AI is experiencing configuration issues. We're working on a fix!";
      } else if (response.statusCode == 404) {
        debugPrint("OpenAI Error: Model not found");
        return "BudgetBoss AI is undergoing maintenance. Please try again shortly.";
      } else if (response.statusCode >= 500) {
        return "The AI server is a bit overwhelmed right now. 🧠 Please try your question again in a minute.";
      } else {
        debugPrint("OpenAI API Error: ${response.statusCode} - ${response.body}");
        return "I'm having trouble thinking right now. 🛠️ Please try again in a moment.";
      }
    } catch (e) {
      debugPrint("Exception during OpenAI call: $e");
      return "I encountered a connection error. 🌐 Please check your internet and try again.";
    }
  }
}
