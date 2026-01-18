import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'settings_storage_service.dart';
import '../../data/services/auth_service.dart';

/// Service to handle automatic session termination after period of inactivity (Banking Level Security)
class AutoLockService {
  static AutoLockService? _instance;
  static AutoLockService get instance => _instance ??= AutoLockService._();
  
  AutoLockService._();
  
  Timer? _inactivityTimer;
  DateTime _lastInteraction = DateTime.now();
  bool _isEnabled = true;
  int _lockTimeoutSeconds = 15; // Set to 15s for testing as requested
  bool _isLoggedOut = false;
  final SettingsStorageService _storageService = SettingsStorageService();
  
  /// Initialize the auto-lock service
  Future<void> initialize() async {
    await _loadSettings();
    _startMonitoring();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _storageService.loadSecuritySettings();
    _isEnabled = settings['autoLockEnabled'] as bool? ?? true;
    
    // For testing, we are hardcoding 15s. 
    // In production, this would be parsed from settings.
    _lockTimeoutSeconds = 15; 
  }
  
  /// Update auto-lock settings
  void updateSettings({bool? enabled, int? timeoutSeconds}) {
    if (enabled != null) {
      _isEnabled = enabled;
    }
    if (timeoutSeconds != null) {
      _lockTimeoutSeconds = timeoutSeconds;
    }
    
    if (_isEnabled) {
      _startMonitoring();
    } else {
      _stopMonitoring();
    }
  }
  
  /// Start monitoring user activity
  void _startMonitoring() {
    if (!_isEnabled) return;
    
    _stopMonitoring(); // Stop any existing timer
    _lastInteraction = DateTime.now();
    _isLoggedOut = false;
    
    // Check every 5 seconds for banking-level precision
    _inactivityTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkInactivity();
    });
    
    debugPrint('🔒 Session monitoring started (${_lockTimeoutSeconds}s timeout)');
  }
  
  /// Stop monitoring
  void _stopMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
  
  /// Check if session should be terminated due to inactivity
  void _checkInactivity() {
    if (!_isEnabled || _isLoggedOut) return;
    
    final now = DateTime.now();
    final inactiveDuration = now.difference(_lastInteraction);
    
    if (inactiveDuration.inSeconds >= _lockTimeoutSeconds) {
      debugPrint('🚨 Session expired: Logging out after ${inactiveDuration.inSeconds} seconds of inactivity');
      _performHardLogout();
    }
  }
  
  /// Record user interaction (reset inactivity timer)
  void recordInteraction() {
    _lastInteraction = DateTime.now();
  }
  
  /// Perform a hard logout (Banking level security)
  void _performHardLogout() async {
    if (_isLoggedOut) return;
    _isLoggedOut = true;
    _stopMonitoring();

    try {
      // 1. Clear session in Auth Service
      // Ensure AuthService is registered in GetX or use a new instance
      if (Get.isRegistered<AuthService>()) {
        await Get.find<AuthService>().signOut();
      } else {
        await AuthService().signOut();
      }
      
      // 2. Force redirect to login screen and clear history
      Get.offAllNamed('/auth'); 

      // 3. Show "Professional Bullshit" Security Dialog after redirect
      Get.dialog(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.security, color: Color(0xFF002060)),
              SizedBox(width: 10),
              Text('Security Notice'),
            ],
          ),
          content: const Text(
            'Your session has expired due to 15 seconds of inactivity. You have been logged out to protect your financial data.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF002060))),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      debugPrint('❌ Logout error: $e');
      // Fallback redirect if anything fails
      Get.offAllNamed('/auth');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _stopMonitoring();
  }
}

