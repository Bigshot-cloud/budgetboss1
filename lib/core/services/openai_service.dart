import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class OpenAIService {
  String get _apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> analyzeFinance(String prompt) async {
    if (_apiKey.isEmpty) {
      return "Missing OpenAI API key";
    }

    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

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
            "content":
            "You are BudgetBoss AI, a strict financial analyst. Return structured JSON only."
          },
          {
            "role": "user",
            "content": prompt,
          }
        ],
        "temperature": 0.2
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data["choices"][0]["message"]["content"];
    } else {
      return "OpenAI Error: ${response.statusCode} - ${response.body}";
    }
  }
}