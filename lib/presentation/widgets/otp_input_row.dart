import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class OtpInputRow extends StatefulWidget {
  final ValueChanged<String> onCodeChanged;

  const OtpInputRow({super.key, required this.onCodeChanged});

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      // Move to next field if available
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last field, unfocus
        _focusNodes[index].unfocus();
      }
    } else {
      // Move to previous field if backspace
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    
    // Collect code
    String code = _controllers.map((c) => c.text).join();
    widget.onCodeChanged(code);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Responsive sizing: Use 6% of screen width with min/max constraints
    final fieldWidth = (screenWidth * 0.12).clamp(40.0, 55.0);
    final fieldHeight = (screenHeight * 0.06).clamp(45.0, 60.0);
    final fontSize = (screenWidth * 0.055).clamp(18.0, 24.0);
    final borderRadius = (screenWidth * 0.03).clamp(10.0, 14.0);
    
    // Force LTR direction for OTP input regardless of app language
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (index) {
          return Container(
            width: fieldWidth,
            height: fieldHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: const Color(0xFFE0E0E0), // Light grey border
                width: 1,
              ),
            ),
            child: Center(
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr, // Force LTR for text input
                maxLength: 1,
                style: TextStyle(
                  fontSize: fontSize, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => _onChanged(value, index),
              ),
            ),
          );
        }),
      ),
    );
  }
}
