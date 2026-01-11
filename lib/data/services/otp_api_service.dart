import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

// Web-compatible OTP API Service
// No dart:io imports needed - uses kIsWeb for platform detection

class OtpApiService {
  // Production URL - Always use this in production
  // This is set to your Vercel deployment URL
  static const String productionUrl = 'https://fineye-one.vercel.app';
  
  // Your computer's local IP address (for physical device testing)
  // Update this if your IP changes (check with: ipconfig on Windows)
  // Only used in development mode on mobile platforms
  static const String localIp = '192.168.1.3';
  
  // Get base URL based on environment and platform
  static String get baseUrl {
    // Always use production URL - works for all platforms including web
    // Production URL is already set, so this ensures web works correctly
    if (productionUrl.isNotEmpty && productionUrl != 'YOUR_PRODUCTION_URL_HERE') {
      return productionUrl;
    }
    
    // Development mode URLs (fallback if production URL not set)
    if (kIsWeb) {
      // For web development: use localhost
      return 'http://localhost:3000';
    }
    
    // For mobile platforms in development
    // Use local IP for physical device testing
    return 'http://$localIp:3000';
  }
  
  /// Send OTP to email
  /// [purpose] can be 'forgot_password' to check if user exists before sending OTP
  static Future<Map<String, dynamic>> sendOtp(String email, {String? purpose}) async {
    try {
      // Normalize email to lowercase for consistent storage/retrieval
      final normalizedEmail = email.trim().toLowerCase();
      
      final requestBody = <String, dynamic>{
        'email': normalizedEmail,
      };
      
      // Add purpose if provided (e.g., 'forgot_password' to validate user exists)
      if (purpose != null && purpose.isNotEmpty) {
        requestBody['purpose'] = purpose;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/otp/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
          'expiresIn': data['expiresIn'] ?? 600,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Verify OTP code
  static Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    try {
      // Normalize email to lowercase for consistent storage/retrieval
      final normalizedEmail = email.trim().toLowerCase();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/otp/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);
      
      // Check if response is successful
      if (response.statusCode == 200) {
        // Only return success if data['success'] is explicitly true
        if (data['success'] == true) {
          return {
            'success': true,
            'message': data['message'] ?? 'OTP verified successfully',
          };
        } else {
          // Response was 200 but success is false
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid OTP',
          };
        }
      } else {
        // Non-200 status code
        return {
          'success': false,
          'message': data['message'] ?? 'OTP verification failed',
        };
      }
    } catch (e) {
      debugPrint('OTP verification error: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Reset password after OTP verification
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      // Normalize email to lowercase
      final normalizedEmail = email.trim().toLowerCase();
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': normalizedEmail,
          'newPassword': newPassword,
        }),
      );

      // Check if response is HTML (means endpoint not found)
      final responseBody = response.body;
      if (responseBody.trim().startsWith('<!DOCTYPE') || responseBody.trim().startsWith('<html')) {
        return {
          'success': false,
          'message': 'Password reset endpoint not found. Please ensure the backend is deployed and the endpoint is available.',
          'statusCode': response.statusCode,
        };
      }

      final data = jsonDecode(responseBody);
      
      // Log response for debugging
      debugPrint('Password reset API response:');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Response body: $data');
      
      // Only return success if status code is 200 AND success is explicitly true
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password reset successful',
        };
      } else {
        // Include status code and error details in response for better error handling
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reset password',
          'statusCode': response.statusCode,
          'error': data['error'] ?? data,
        };
      }
    } catch (e) {
      debugPrint('Password reset error: $e');
      // Check if it's a JSON decode error (likely HTML response)
      if (e.toString().contains('FormatException') || e.toString().contains('SyntaxError')) {
        return {
          'success': false,
          'message': 'Backend endpoint not accessible. Please ensure the backend server is running and the /api/password/reset endpoint is available. See backend/FIREBASE_ADMIN_SETUP.md for setup instructions.',
        };
      }
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}

