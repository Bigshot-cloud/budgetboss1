import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/security_provider.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChange;
  const PinSetupScreen({super.key, this.isChange = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final List<String> _pin = [];
  final List<String> _confirmPin = [];
  bool _isConfirming = false;
  String _error = '';

  void _onNumberPress(String number) {
    setState(() {
      _error = '';
      if (!_isConfirming) {
        if (_pin.length < 4) _pin.add(number);
        if (_pin.length == 4) {
          _isConfirming = true;
        }
      } else {
        if (_confirmPin.length < 4) _confirmPin.add(number);
        if (_confirmPin.length == 4) {
          _verifyAndSave();
        }
      }
    });
  }

  void _backspace() {
    setState(() {
      if (!_isConfirming) {
        if (_pin.isNotEmpty) _pin.removeLast();
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin.removeLast();
        } else {
          _isConfirming = false;
          _pin.removeLast();
        }
      }
    });
  }

  void _verifyAndSave() async {
    final pinStr = _pin.join();
    final confirmStr = _confirmPin.join();

    if (pinStr == confirmStr) {
      await context.read<SecurityProvider>().updatePin(pinStr);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isChange ? 'PIN changed successfully' : 'PIN created successfully')),
        );
        Navigator.pop(context);
      }
    } else {
      setState(() {
        _confirmPin.clear();
        _error = 'PINs do not match. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isChange ? 'Change PIN' : 'Create PIN')),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Text(
            _isConfirming ? 'Confirm your PIN' : 'Enter a 4-digit PIN',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final dots = _isConfirming ? _confirmPin : _pin;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index < dots.length ? AppColors.gold : AppColors.navy,
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
          const SizedBox(height: 40),
        ],
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
