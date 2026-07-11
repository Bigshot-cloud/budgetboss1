import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/ai_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final AiService _aiService = AiService();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = context.read<AuthProvider>().user;
      setState(() {
        _messages.add({
          'role': 'ai',
          'text': "Hi ${user?.fullName.split(' ')[0] ?? 'there'}! 👋\n\nI'm here to help you build better financial habits. What would you like to do?"
        });
      });
    });
  }

  void _sendMessage([String? text]) async {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;

    final txProvider = context.read<TransactionProvider>();

    setState(() {
      if (text == null) _controller.clear();
      _messages.add({'role': 'user', 'text': messageText});
      _isTyping = true;
    });

    final response = await _aiService.getResponse(
      messageText,
      totalBalance: txProvider.totalBalance,
      totalSpent: txProvider.totalExpense,
    );

    if (mounted) {
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.gold, size: 20),
            const SizedBox(width: 10),
            Text(
              'BudgetBoss Assistant', 
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['role'] == 'ai';
                return _buildChatBubble(msg['text']!, isAi);
              },
            ),
          ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 10),
              child: Row(
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'AI is thinking...', 
                    style: TextStyle(
                      color: isDark ? AppColors.grey : Colors.grey[700], 
                      fontSize: 12
                    )
                  ),
                ],
              ),
            ),
          if (_messages.length <= 1 && !_isTyping) ...[
            _buildQuickAction(Icons.person_search_outlined, 'How can I save more?'),
            _buildQuickAction(Icons.calendar_today_outlined, 'Create a budget plan'),
            const SizedBox(height: 10),
          ],
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isAi) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isAi 
              ? (isDark ? AppColors.navy : Colors.grey[200]) 
              : AppColors.blueAccent,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isAi ? Radius.zero : const Radius.circular(20),
            bottomRight: isAi ? const Radius.circular(20) : Radius.zero,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAi 
                ? (isDark ? Colors.white : Colors.black87) 
                : Colors.white,
            height: 1.4,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: GestureDetector(
        onTap: () => _sendMessage(label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNavy : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark ? AppColors.navy : Colors.grey[300]!,
            ),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
              const SizedBox(width: 15),
              Text(
                label, 
                style: TextStyle(
                  fontWeight: FontWeight.w500, 
                  fontSize: 14, 
                  color: isDark ? Colors.white : Colors.black87
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNavy : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? AppColors.navy : Colors.grey[200]!)
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.navy : Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                onSubmitted: (_) => _sendMessage(),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Ask me anything...',
                  hintStyle: TextStyle(
                    color: isDark ? AppColors.grey : Colors.grey[600],
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 15),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.blueAccent,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
