import 'openai_service.dart';

class AiService {
  final _openAI = OpenAIService();

  Future<String> getResponse(
      String query, {
        double? totalBalance,
        double? totalSpent,
        Map<String, double>? categorySpending,
      }) async {

    String q = query.toLowerCase();

    // 🟢 1. GREETING LAYER
    if (q.contains("hi") || q.contains("hello") || q.contains("hey")) {
      return "👋 Hi! I'm your BudgetBoss AI Financial Analyst. Ask me about your spending, savings goals, or budgeting advice.";
    }

    // 🟡 2. SPENDING ANALYSIS ENGINE
    if (q.contains("spend") || q.contains("expense") || q.contains("money") || q.contains("balance")) {
      if (totalBalance != null && totalSpent != null) {
        double currentBalance = totalBalance;
        double usage = totalBalance > 0 ? (totalSpent / (totalSpent + totalBalance)) * 100 : 100;

        if (q.contains("balance")) {
           return "Your current total balance is GH₵ ${totalBalance.toStringAsFixed(2)}. Keep up the great work!";
        }

        if (usage >= 80) {
          return "⚠️ High spending alert! You've used ${usage.toStringAsFixed(1)}% of your available funds. Consider reducing non-essential expenses.";
        } else if (usage >= 50) {
          return "📊 You've spent about halfway through your available funds (${usage.toStringAsFixed(1)}%). Monitor your upcoming bills.";
        } else {
          return "✅ You're doing well! You've only used ${usage.toStringAsFixed(1)}% of your funds so far.";
        }
      }
    }

    // 🤖 3. FULL AI FALLBACK (GEMINI BRAIN)
    try {
      final response = await _openAI.analyzeFinance(
          """
You are BudgetBoss AI, a personal finance assistant. 

Context:
- Current user balance: ${totalBalance ?? 'Unknown'}
- Total spent this month: ${totalSpent ?? 'Unknown'}

User question: $query

Rules:
- Be short, helpful and professional.
- Focus on saving money, budgeting, and debt control.
- If asking about specific app features, mention sections like 'Debt Tracker' or 'Savings Goals'.
"""
      );
      return response;
    } catch (e) {
      return "I'm having a little trouble connecting right now. 🛠️ Please try again in a moment, or check your dashboard for your latest stats!";
    }
  }
}
