import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';
import 'settings_storage_service.dart';

/// Service to handle automatic app locking after period of inactivity
class AutoLockService {
  static AutoLockService? _instance;
  static AutoLockService get instance => _instance ??= AutoLockService._();
  
  AutoLockService._();
  
  Timer? _inactivityTimer;
  DateTime _lastInteraction = DateTime.now();
  bool _isEnabled = true;
  int _lockTimeoutMinutes = 3;
  bool _isLocked = false;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SettingsStorageService _storageService = SettingsStorageService();
  
  /// Initialize the auto-lock service
  Future<void> initialize() async {
    await _loadSettings();
    _startMonitoring();
  }
  
  Future<void> _loadSettings() async {
    final settings = await _storageService.loadSecuritySettings();
    _isEnabled = settings['autoLockEnabled'] as bool? ?? true;
    final timeString = settings['autoLockTime'] as String? ?? '3m';
    
    if (timeString == 'off') {
      _isEnabled = false;
      return;
    }
    
    // Parse time string (e.g., "3m" -> 3 minutes)
    final timeValue = int.tryParse(timeString.replaceAll('m', '')) ?? 3;
    _lockTimeoutMinutes = timeValue;
  }
  
  /// Update auto-lock settings
  void updateSettings({bool? enabled, int? timeoutMinutes}) {
    if (enabled != null) {
      _isEnabled = enabled;
    }
    if (timeoutMinutes != null) {
      _lockTimeoutMinutes = timeoutMinutes;
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
    
    // Check every 30 seconds if app should be locked
    _inactivityTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkInactivity();
    });
    
    debugPrint('🔒 Auto-lock monitoring started (${_lockTimeoutMinutes}m timeout)');
  }
  
  /// Stop monitoring
  void _stopMonitoring() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }
  
  /// Check if app should be locked due to inactivity
  void _checkInactivity() {
    if (!_isEnabled || _isLocked) return;
    
    final now = DateTime.now();
    final inactiveDuration = now.difference(_lastInteraction);
    
    if (inactiveDuration.inMinutes >= _lockTimeoutMinutes) {
      debugPrint('🔒 Auto-locking app after ${inactiveDuration.inMinutes} minutes of inactivity');
      _lockApp();
    }
  }
  
  /// Record user interaction (reset inactivity timer)
  void recordInteraction() {
    _lastInteraction = DateTime.now();
  }
  
  /// Lock the app
  void _lockApp() {
    if (_isLocked) return;
    
    _isLocked = true;
    _showUnlockScreen();
  }
  
  /// Show unlock screen
  void _showUnlockScreen() {
    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // Prevent dismissing with back button
        child: Material(
          color: Colors.black87,
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Color(0xFF002060),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'App Locked',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF002060),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Authenticate to unlock',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _authenticate(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF002060),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Unlock',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
  
  /// Authenticate user to unlock
  Future<void> _authenticate() async {
    try {
      // Check if biometric is available
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (canCheckBiometrics && isDeviceSupported) {
        final authenticated = await _localAuth.authenticate(
          localizedReason: 'Authenticate to unlock FinEye',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: false,
          ),
        );
        
        if (authenticated) {
          _unlockApp();
        }
      } else {
        // No biometric available, just unlock
        _unlockApp();
      }
    } catch (e) {
      debugPrint('❌ Authentication error: $e');
      // On error, unlock anyway (don't lock user out)
      _unlockApp();
    }
  }
  
  /// Unlock the app
  void _unlockApp() {
    _isLocked = false;
    _lastInteraction = DateTime.now();
    Get.back(); // Close unlock dialog
    debugPrint('✅ App unlocked');
  }
  
  /// Dispose resources
  void dispose() {
    _stopMonitoring();
  }
}

