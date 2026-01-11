import 'package:flutter/material.dart';

class PressableText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final VoidCallback onTap;
  final String? secondText;
  final TextStyle? secondStyle;

  const PressableText({
    super.key,
    required this.text,
    required this.style,
    required this.onTap,
    this.secondText,
    this.secondStyle,
  });

  @override
  State<PressableText> createState() => _PressableTextState();
}

class _PressableTextState extends State<PressableText> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  Color _getDarkerColor(Color color) {
    final HSLColor hsl = HSLColor.fromColor(color);
    final HSLColor darker = hsl.withLightness((hsl.lightness - 0.2).clamp(0.0, 1.0));
    return darker.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final Color baseColor = widget.style.color ?? Colors.black;
    final Color activeColor = _isPressed ? _getDarkerColor(baseColor) : baseColor;

    if (widget.secondText != null && widget.secondStyle != null) {
        final Color secondBaseColor = widget.secondStyle!.color ?? Colors.black;
        final Color secondActiveColor = _isPressed ? _getDarkerColor(secondBaseColor) : secondBaseColor;
        
        return GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          behavior: HitTestBehavior.opaque, 
          child: RichText(
            text: TextSpan(
              text: widget.text,
              style: widget.style.copyWith(color: activeColor),
              children: [
                TextSpan(
                  text: widget.secondText,
                  style: widget.secondStyle!.copyWith(color: secondActiveColor),
                ),
              ],
            ),
          ),
        );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: Text(
        widget.text,
        style: widget.style.copyWith(color: activeColor),
      ),
    );
  }
}
