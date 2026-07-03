import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/security_provider.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  final List<String> _pin = [];
  String _error = '';

  void _onNumberPress(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin.add(number);
        _error = '';
      });
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin.removeLast());
    }
  }

  void _verifyPin() async {
    final success = await context.read<SecurityProvider>().verifyPin(_pin.join());
    if (success) {
      context.read<SecurityProvider>().unlock();
    } else {
      setState(() {
        _pin.clear();
        _error = 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.lock, size: 50, color: AppColors.gold),
            const SizedBox(height: 20),
            const Text(
              'App Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Enter your PIN to continue', style: TextStyle(color: AppColors.grey)),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? AppColors.gold : AppColors.navy,
                    border: Border.all(color: AppColors.gold),
                  ),
                );
              }),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(_error, style: const TextStyle(color: AppColors.expense)),
            ],
            const Spacer(),
            _buildKeyboard(),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () {
                context.read<SecurityProvider>().authenticateBiometrics();
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fingerprint, color: AppColors.gold),
                  SizedBox(width: 10),
                  Text('Unlock with Biometrics', style: TextStyle(color: AppColors.gold)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', 'backspace']
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key == '') return const SizedBox(width: 60);
              return IconButton(
                onPressed: key == 'backspace' ? _backspace : () => _onNumberPress(key),
                icon: key == 'backspace'
                    ? const Icon(Icons.backspace_outlined, color: AppColors.white)
                    : Text(
                        key,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.white),
                      ),
                iconSize: 40,
                padding: const EdgeInsets.all(20),
              );
            }).toList(),
          ),
      ],
    );
  }
}
