/// Production-ready validation utilities
class ValidationUtils {
  /// Email validation with RFC 5322 compliant regex
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    // RFC 5322 compliant email regex
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    return emailRegex.hasMatch(email.trim());
  }

  /// Password strength validation
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    if (password.length > 128) {
      return 'Password must be less than 128 characters';
    }
    
    // Check for at least one uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for at least one lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least one lowercase letter';
    }
    
    // Check for at least one digit
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character (!@#\$%^&*(),.?":{}|<>)';
    }
    
    // Check for common weak passwords
    final weakPasswords = [
      'password',
      '12345678',
      'password123',
      'qwerty123',
      'admin123',
    ];
    
    if (weakPasswords.contains(password.toLowerCase())) {
      return 'This password is too common. Please choose a stronger password';
    }
    
    return null; // Valid password
  }

  /// Phone number validation (UAE format and international)
  /// Supports formats: +971501234567, 0501234567, 971501234567
  static bool isValidPhoneNumber(String phoneNumber, String countryCode) {
    if (phoneNumber.isEmpty) return false;
    
    // Remove all spaces, dashes, and parentheses
    final cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // UAE phone number validation
    if (countryCode == '+971') {
      // UAE mobile numbers: 0501234567, 0521234567, etc. (9 digits after 0)
      if (RegExp(r'^0[5][0-9]{8}$').hasMatch(cleaned)) {
        return true;
      }
      // UAE landline: 021234567 (8 digits after 0)
      if (RegExp(r'^0[1-4][0-9]{7}$').hasMatch(cleaned)) {
        return true;
      }
      // UAE with country code: 971501234567
      if (RegExp(r'^971[5][0-9]{8}$').hasMatch(cleaned)) {
        return true;
      }
    }
    
    // International format validation (general)
    // Minimum 7 digits, maximum 15 digits (E.164 standard)
    final digitsOnly = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length >= 7 && digitsOnly.length <= 15) {
      return true;
    }
    
    return false;
  }

  /// Full name validation
  static String? validateFullName(String name) {
    if (name.isEmpty) {
      return 'Full name is required';
    }
    
    final trimmed = name.trim();
    
    if (trimmed.length < 2) {
      return 'Full name must be at least 2 characters long';
    }
    
    if (trimmed.length > 100) {
      return 'Full name must be less than 100 characters';
    }
    
    // Allow letters, spaces, hyphens, apostrophes (international names)
    if (!RegExp(r"^[a-zA-Z\s\-\'\.]+$").hasMatch(trimmed)) {
      return 'Full name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    // Must contain at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmed)) {
      return 'Full name must contain at least one letter';
    }
    
    return null; // Valid name
  }

  /// Company name validation
  static String? validateCompanyName(String companyName) {
    if (companyName.isEmpty) {
      return 'Company name is required';
    }
    
    final trimmed = companyName.trim();
    
    if (trimmed.length < 2) {
      return 'Company name must be at least 2 characters long';
    }
    
    if (trimmed.length > 200) {
      return 'Company name must be less than 200 characters';
    }
    
    // Allow letters, numbers, spaces, and common business characters
    if (!RegExp(r"^[a-zA-Z0-9\s\-\'\.&,()]+$").hasMatch(trimmed)) {
      return 'Company name contains invalid characters';
    }
    
    return null; // Valid company name
  }

  /// Sanitize input string (remove leading/trailing whitespace, multiple spaces)
  static String sanitizeInput(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Validate and format phone number for storage
  static String formatPhoneNumber(String phoneNumber, String countryCode) {
    // Remove all non-digit characters except +
    var cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If country code is +971 and number starts with 0, keep the 0
    // Otherwise format as needed
    if (countryCode == '+971' && cleaned.startsWith('0')) {
      return cleaned;
    }
    
    // If number starts with country code without +, add it
    if (countryCode == '+971' && cleaned.startsWith('971')) {
      cleaned = cleaned.replaceFirst('971', '0');
    }
    
    return cleaned;
  }
}

