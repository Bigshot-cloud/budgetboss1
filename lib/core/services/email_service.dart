import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter/material.dart';

/// NOTE: Custom SMTP Email Integration is TEMPORARILY DISABLED.
/// To re-enable, uncomment usages in auth_service.dart and auth_provider.dart.
class EmailService {
  static final EmailService _instance = EmailService._internal();
  factory EmailService() => _instance;
  EmailService._internal();

  // String get _server => dotenv.env['SMTP_SERVER'] ?? 'smtp.gmail.com';
  // int get _port => int.tryParse(dotenv.env['SMTP_PORT'] ?? '587') ?? 587;
  String get _username => dotenv.env['SMTP_USERNAME'] ?? '';
  String get _password => dotenv.env['SMTP_PASSWORD'] ?? '';
  String get _senderName => dotenv.env['SMTP_SENDER_NAME'] ?? 'BudgetBoss';

  Future<bool> sendEmail({
    required String recipient,
    required String subject,
    required String body,
    bool isHtml = false,
  }) async {
    if (_username.isEmpty || _password.isEmpty) {
      debugPrint('SMTP Configuration is incomplete. Email not sent.');
      return false;
    }

    final smtpServer = gmail(_username, _password);

    final message = Message()
      ..from = Address(_username, _senderName)
      ..recipients.add(recipient)
      ..subject = subject;

    if (isHtml) {
      message.html = body;
    } else {
      message.text = body;
    }

    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: $sendReport');
      return true;
    } on MailerException catch (e) {
      debugPrint('Message not sent. Error: $e');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      debugPrint('Generic error sending email: $e');
      return false;
    }
  }

  // Convenience methods
  Future<void> sendWelcomeEmail(String email, String name) async {
    await sendEmail(
      recipient: email,
      subject: 'Welcome to BudgetBoss, $name! 👑',
      body: '''
        <h1>Welcome to BudgetBoss!</h1>
        <p>Hi $name,</p>
        <p>Thank you for joining BudgetBoss. We're excited to help you take control of your finances.</p>
        <p>Start tracking your spending, setting goals, and managing your debts today!</p>
        <br>
        <p>Best regards,</p>
        <p>The BudgetBoss Team</p>
      ''',
      isHtml: true,
    );
  }

  Future<void> sendSecurityAlert(String email, String message) async {
    await sendEmail(
      recipient: email,
      subject: 'BudgetBoss Security Alert 🛡️',
      body: 'Security Alert: $message',
    );
  }
}
