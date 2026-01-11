import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Production-ready Firebase Authentication Service
/// Handles user registration, login, password reset, and email verification
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Get auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if email already exists in Firebase Auth
  /// Note: fetchSignInMethodsForEmail is deprecated but still functional
  /// It's the recommended way to check email existence before registration
  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      // Normalize email to lowercase for consistent checking
      final normalizedEmail = email.trim().toLowerCase();
      final signInMethods = await _auth.fetchSignInMethodsForEmail(normalizedEmail);
      
      return {
        'exists': signInMethods.isNotEmpty,
        'signInMethods': signInMethods,
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Error checking email: ${e.code} - ${e.message}');
      // If there's an error, assume email doesn't exist (allow registration)
      return {
        'exists': false,
        'signInMethods': [],
      };
    } catch (e) {
      debugPrint('Unexpected error checking email: $e');
      return {
        'exists': false,
        'signInMethods': [],
      };
    }
  }

  /// Register a new user with email and password
  /// After registration, email verification is sent automatically by Firebase
  Future<Map<String, dynamic>> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String companyName,
  }) async {
    try {
      debugPrint('Starting registration for: $email');

      // Create user with Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final User user = userCredential.user!;
      debugPrint('Firebase user created: ${user.uid}');

      // Update user display name
      await user.updateDisplayName(fullName);

      // Send email verification
      await user.sendEmailVerification();
      debugPrint('Email verification sent to: $email');

      // Extract country code and phone number from full phone number
      String countryCode = '+971'; // Default
      String phone = '';
      
      if (phoneNumber.isNotEmpty) {
        // Extract country code (assumes format like +971501234567)
        if (phoneNumber.startsWith('+')) {
          final parts = phoneNumber.split(' ');
          if (parts.length > 1) {
            countryCode = parts[0];
            phone = parts.sublist(1).join(' ');
          } else {
            // Try to extract country code from start
            if (phoneNumber.startsWith('+971')) {
              countryCode = '+971';
              phone = phoneNumber.substring(4);
            } else if (phoneNumber.startsWith('971')) {
              countryCode = '+971';
              phone = phoneNumber.substring(3);
            } else {
              phone = phoneNumber;
            }
          }
        } else {
          phone = phoneNumber;
        }
      }
      
      // Create user document in Firestore with production-ready structure
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email.trim().toLowerCase(),
        'fullName': fullName.trim(),
        'phoneNumber': phoneNumber.trim(), // Full phone number with country code
        'companyName': companyName.trim(),
        'emailVerified': false,
        // Profile fields - extract country code and phone separately
        'countryCode': countryCode,
        'phone': phone,
        'trn': '',
        'isVatRegistered': false,
        'vatFilingFrequency': 'quarterly',
        'taxPeriod': 'quarterly',
        'natureOfBusiness': '',
        'corporateTaxRegime': 'standard_uae_9',
        'financialYearStart': Timestamp.fromDate(DateTime(2025, 1, 1)),
        'financialYearEnd': Timestamp.fromDate(DateTime(2025, 12, 31)),
        // Account status
        'accountStatus': 'active',
        'registrationCompleted': false, // Will be set to true after profile setup
        // Timestamps
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('User document created in Firestore');

      return {
        'success': true,
        'user': user,
        'message': 'Registration successful. Please verify your email.',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
        'code': e.code,
      };
    } catch (e, stackTrace) {
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Sign in with email and password
  Future<Map<String, dynamic>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Attempting sign in for: $email');

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final User user = userCredential.user!;
      debugPrint('Sign in successful: ${user.uid}');

      // Reload user to get latest email verification status
      await user.reload();
      final updatedUser = _auth.currentUser!;

      return {
        'success': true,
        'user': updatedUser,
        'message': 'Login successful',
        'emailVerified': updatedUser.emailVerified,
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
        'code': e.code,
      };
    } catch (e, stackTrace) {
      debugPrint('Sign in error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Confirm password reset with action code (from email link)
  Future<Map<String, dynamic>> confirmPasswordReset({
    required String code,
    required String newPassword,
  }) async {
    try {
      debugPrint('Confirming password reset with code');

      await _auth.confirmPasswordReset(
        code: code,
        newPassword: newPassword,
      );

      debugPrint('Password reset confirmed successfully');

      return {
        'success': true,
        'message': 'Password reset successful. You can now log in with your new password.',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
        'code': e.code,
      };
    } catch (e, stackTrace) {
      debugPrint('Password reset confirmation error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Send password reset email
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('Sending password reset email to: $email');

      await _auth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );

      debugPrint('Password reset email sent successfully');

      return {
        'success': true,
        'message': 'Password reset email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
        'code': e.code,
      };
    } catch (e, stackTrace) {
      debugPrint('Password reset error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Resend email verification
  Future<Map<String, dynamic>> resendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user is currently signed in.',
        };
      }

      if (user.emailVerified) {
        return {
          'success': false,
          'error': 'Email is already verified.',
        };
      }

      await user.sendEmailVerification();
      debugPrint('Email verification resent');

      return {
        'success': true,
        'message': 'Verification email sent. Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
        'code': e.code,
      };
    } catch (e, stackTrace) {
      debugPrint('Resend verification error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Change password for authenticated user
  /// Requires reauthentication with current password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user is currently signed in.',
        };
      }

      if (user.email == null) {
        return {
          'success': false,
          'error': 'User email is not available.',
        };
      }

      debugPrint('Changing password for user: ${user.email}');

      // Reauthenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint('User reauthenticated successfully');

      // Update password
      await user.updatePassword(newPassword);
      debugPrint('Password updated successfully');

      return {
        'success': true,
        'message': 'Password changed successfully.',
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: ${e.code} - ${e.message}');
      return {
        'success': false,
        'error': _getAuthErrorMessage(e.code),
        'code': e.code,
      };
    } catch (e, stackTrace) {
      debugPrint('Change password error: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  /// Get user document from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  /// Update user data in Firestore
  Future<bool> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating user data: $e');
      return false;
    }
  }

  /// Update user profile (company profile) in Firestore
  Future<Map<String, dynamic>> updateUserProfile({
    String? companyName,
    String? email,
    String? countryCode,
    String? phone,
    String? trn,
    bool? isVatRegistered,
    String? vatFilingFrequency,
    String? taxPeriod,
    String? natureOfBusiness,
    String? corporateTaxRegime,
    DateTime? financialYearStart,
    DateTime? financialYearEnd,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        return {
          'success': false,
          'error': 'No user is currently signed in.',
        };
      }

      debugPrint('Updating user profile for: ${user.uid}');

      // Build update data map (only include non-null values)
      final Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (companyName != null) updateData['companyName'] = companyName;
      if (email != null) updateData['email'] = email.trim().toLowerCase();
      if (countryCode != null) updateData['countryCode'] = countryCode;
      if (phone != null) updateData['phone'] = phone;
      if (trn != null) updateData['trn'] = trn;
      if (isVatRegistered != null) updateData['isVatRegistered'] = isVatRegistered;
      if (vatFilingFrequency != null) updateData['vatFilingFrequency'] = vatFilingFrequency;
      if (taxPeriod != null) updateData['taxPeriod'] = taxPeriod;
      if (natureOfBusiness != null) updateData['natureOfBusiness'] = natureOfBusiness;
      if (corporateTaxRegime != null) updateData['corporateTaxRegime'] = corporateTaxRegime;
      if (financialYearStart != null) {
        updateData['financialYearStart'] = Timestamp.fromDate(financialYearStart);
      }
      if (financialYearEnd != null) {
        updateData['financialYearEnd'] = Timestamp.fromDate(financialYearEnd);
      }

      // Update Firestore document
      await _firestore.collection('users').doc(user.uid).set(updateData, SetOptions(merge: true));

      // Also update Firebase Auth display name if company name changed
      if (companyName != null) {
        try {
          await user.updateDisplayName(companyName);
        } catch (e) {
          debugPrint('Warning: Could not update display name: $e');
          // Continue even if display name update fails
        }
      }

      debugPrint('User profile updated successfully');

      return {
        'success': true,
        'message': 'Profile updated successfully',
      };
    } catch (e, stackTrace) {
      debugPrint('Error updating user profile: $e');
      debugPrint('Stack trace: $stackTrace');
      return {
        'success': false,
        'error': 'Failed to update profile. Please try again.',
      };
    }
  }

  /// Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        // Convert Timestamps to DateTime
        final profile = Map<String, dynamic>.from(data);
        if (data['financialYearStart'] != null) {
          profile['financialYearStart'] = (data['financialYearStart'] as Timestamp).toDate();
        }
        if (data['financialYearEnd'] != null) {
          profile['financialYearEnd'] = (data['financialYearEnd'] as Timestamp).toDate();
        }
        return profile;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred: $code';
    }
  }
}

