import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'debug_service.dart';

class OpenAIService {
  final DebugService _debugService = DebugService();
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> analyzeFinance(String prompt, {bool isChat = true}) async {
    final feature = isChat ? "AI Assistant" : "SMS Parser";

    if (_apiKey.isEmpty) {
      const errorMsg = "OpenAI API Key is missing from .env file";
      _debugService.log(
        feature: feature,
        status: "Error",
        message: "Missing API Key",
      );
      _debugService.updateAiStatus("Configuration Error");
      return "BudgetBoss AI is currently offline. Please check back later.";
    }

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    try {
      _debugService.log(
        feature: feature,
        status: "Pending",
        message: "Sending request to OpenAI",
        details: isChat ? "Chat Query" : "SMS Content Extraction",
      );

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

      _debugService.updateAiStatus("Response Received", responseCode: response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = data["choices"][0]["message"]["content"];
        
        _debugService.log(
          feature: feature,
          status: "Success",
          message: "Data received successfully",
          details: !isChat ? "Extracted: $result" : null,
        );

        return result;
      } 
      
      String friendlyError;
      String errorType;

      if (response.statusCode == 429) {
        errorType = "Quota Exceeded";
        friendlyError = "BudgetBoss AI is temporarily unavailable because the AI service has reached its usage limit. Please try again later.";
      } else if (response.statusCode == 401) {
        errorType = "Auth Error";
        friendlyError = "AI service connection error (Invalid API Key).";
      } else if (response.statusCode == 404) {
        errorType = "Model Error";
        friendlyError = "The AI model is currently being updated. Please try again shortly.";
      } else if (response.statusCode >= 500) {
        errorType = "Server Error";
        friendlyError = "The AI server is overwhelmed. 🧠 Please try again in a minute.";
      } else {
        errorType = "API Error ${response.statusCode}";
        friendlyError = "I'm having trouble thinking right now. 🛠️ Error: ${response.statusCode}";
      }

      _debugService.log(
        feature: feature,
        status: "Failed",
        message: errorType,
        details: "Body: ${response.body}",
      );

      return friendlyError;

    } catch (e) {
      _debugService.updateAiStatus("Network Exception");
      _debugService.log(
        feature: feature,
        status: "Exception",
        message: "Connection Error",
        details: e.toString(),
      );
      return "I encountered a connection error. 🌐 Please check your internet and try again.";
    }
  }
}
