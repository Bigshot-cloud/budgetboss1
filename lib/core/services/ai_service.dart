import 'gemini_services.dart';

class AiService {
  final GeminiService _gemini = GeminiService();

  Future<String> getResponse(
      String query, {
        double? totalBalance,
        double? totalSpent,
        Map<String, double>? categorySpending,
      }) async {

    String q = query.toLowerCase();

    // 🟢 1. GREETING LAYER
    if (q.contains("hi") || q.contains("hello")) {
      return "👋 Hi! I'm your BudgetBoss AI Financial Analyst. Ask me about spending, savings, or budgeting.";
    }

    // 🟡 2. SPENDING ANALYSIS ENGINE
    if (q.contains("spend") || q.contains("expense") || q.contains("money")) {
      if (totalBalance != null && totalSpent != null) {

        double usage = (totalSpent / totalBalance) * 100;

        if (usage >= 80) {
          return "⚠️ High spending alert! You've used ${usage.toStringAsFixed(1)}% of your budget. Reduce non-essential expenses immediately.";
        } else if (usage >= 50) {
          return "📊 You're halfway through your budget (${usage.toStringAsFixed(1)}%). Monitor your spending carefully.";
        } else {
          return "✅ You're doing well! Only ${usage.toStringAsFixed(1)}% of your budget used.";
        }
      }
    }

    // 🔵 3. CATEGORY ANALYSIS ENGINE
    if (q.contains("food") || q.contains("transport") || q.contains("shopping")) {
      if (categorySpending != null) {
        String insight = "";

        categorySpending.forEach((key, value) {
          if (value > 500) {
            insight += "⚠️ $key spending is high at GHS $value. ";
          }
        });

        if (insight.isNotEmpty) {
          return insight;
        }
      }
    }

    // 🟣 4. BUDGET + SAVINGS STRATEGY (AI POWERED)
    if (q.contains("save") || q.contains("budget")) {
      return await _gemini.askGemini(
        "Act as a professional financial advisor. Give short, practical budgeting advice for this query: $query",
      );
    }

    // 🔴 5. DEBT STRATEGY ENGINE
    if (q.contains("debt") || q.contains("loan")) {
      return await _gemini.askGemini(
        "Explain a simple debt repayment strategy (like avalanche or snowball) in a beginner-friendly way: $query",
      );
    }

    // 🤖 6. FULL AI FALLBACK (GEMINI BRAIN)
    return await _gemini.askGemini(
        """
You are BudgetBoss AI, a personal finance assistant.

Rules:
- Be short and practical
- Focus on saving money, budgeting, and spending control
- Give real-life financial advice

User question: $query
"""
    );
  }
}