import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Service to handle screen privacy (blur/hide app content in app switcher)
class ScreenPrivacyService {
  static const MethodChannel _channel = MethodChannel('com.example.fineye/security');
  static bool _isEnabled = false;

  /// Enable screen privacy (hides content in app switcher)
  /// On Android, this uses FLAG_SECURE to prevent screenshots and hide content
  static Future<void> enable() async {
    if (kIsWeb) return; // Not applicable on web
    
    try {
      await _channel.invokeMethod('enableScreenPrivacy');
    _isEnabled = true;
      debugPrint('✅ Screen privacy enabled');
    } catch (e) {
      debugPrint('❌ Failed to enable screen privacy: $e');
    }
  }

  /// Disable screen privacy
  static Future<void> disable() async {
    if (kIsWeb) return;
    
    try {
      await _channel.invokeMethod('disableScreenPrivacy');
    _isEnabled = false;
      debugPrint('✅ Screen privacy disabled');
    } catch (e) {
      debugPrint('❌ Failed to disable screen privacy: $e');
    }
  }

  /// Check if screen privacy is enabled
  static bool get isEnabled => _isEnabled;
}



