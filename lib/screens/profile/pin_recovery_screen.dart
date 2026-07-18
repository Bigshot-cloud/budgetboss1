import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/security_provider.dart';
import '../../widgets/custom_text_field.dart';

class PinRecoveryScreen extends StatefulWidget {
  const PinRecoveryScreen({super.key});

  @override
  State<PinRecoveryScreen> createState() => _PinRecoveryScreenState();
}

class _PinRecoveryScreenState extends State<PinRecoveryScreen> {
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  int _currentStep = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _verifyPassword() async {
    final authProvider = context.read<AuthProvider>();
    final email = authProvider.user?.email;
    if (email == null) return;

    setState(() => _isLoading = true);
    try {
      await authProvider.login(email, _passwordController.text.trim());
      if (mounted) {
        setState(() {
          _currentStep = 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid password: $e')),
        );
      }
    }
  }

  void _resetPin() async {
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN must be 4 digits')));
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PINs do not match')));
      return;
    }

    setState(() => _isLoading = true);
    await context.read<SecurityProvider>().updatePin(_pinController.text);
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN reset successfully')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset PIN')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_currentStep == 0) ...[
              Text('Verify Identity', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text('Please enter your account password to reset your PIN.', 
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 30),
              CustomTextField(
                controller: _passwordController,
                hintText: 'Account Password',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPassword,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Verify'),
                ),
              ),
            ] else ...[
              Text('Create New PIN', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Text('Set a new 4-digit PIN for app access.', 
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
              const SizedBox(height: 30),
              CustomTextField(
                controller: _pinController,
                hintText: 'New PIN',
                prefixIcon: Icons.password,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              CustomTextField(
                controller: _confirmPinController,
                hintText: 'Confirm New PIN',
                prefixIcon: Icons.password,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPin,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Reset PIN'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
