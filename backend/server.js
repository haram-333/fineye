const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { Redis } = require('@upstash/redis');
const otpService = require('./services/otpService');
const admin = require('firebase-admin');

dotenv.config();

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  try {
    // Try to initialize with service account credentials from environment variable
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: 'fineye-app'
      });
      console.log('Firebase Admin SDK initialized with service account');
    } else {
      // Initialize with application default credentials (for production environments)
      admin.initializeApp({
        projectId: 'fineye-app'
      });
      console.log('Firebase Admin SDK initialized with application default credentials');
    }
  } catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error);
    console.warn('Firebase Admin SDK not initialized. Password reset will use email link method.');
  }
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Initialize Redis client
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Test Redis connection
    await redis.ping();
    res.json({ status: 'OK', message: 'Server is running', redis: 'connected' });
  } catch (error) {
    res.status(500).json({ status: 'ERROR', message: 'Redis connection failed', error: error.message });
  }
});

// Send OTP endpoint
app.post('/api/otp/send', async (req, res) => {
  try {
    const { email, purpose } = req.body;

    if (!email) {
      return res.status(400).json({ 
        success: false, 
        message: 'Email is required' 
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    
    // Log incoming request details
    console.log(`[OTP] Request received - Email: ${normalizedEmail}, Purpose: ${purpose || 'none'}`);

    // If this is for forgot password, check if user exists first
    if (purpose === 'forgot_password') {
      console.log(`[OTP] Forgot password flow - Checking if user exists: ${normalizedEmail}`);
      
      // Check if Firebase Admin SDK is available
      if (!admin.apps || admin.apps.length === 0) {
        console.error('[OTP] ❌ Firebase Admin SDK NOT initialized - Cannot verify user');
        return res.status(503).json({
          success: false,
          message: 'Firebase Admin SDK not initialized. Cannot verify user existence.'
        });
      }

      try {
        // Check if user exists in Firebase Auth
        console.log(`[OTP] Checking Firebase Auth for user: ${normalizedEmail}`);
        const userRecord = await admin.auth().getUserByEmail(normalizedEmail);
        console.log(`[OTP] ✅ User found: ${userRecord.uid} - Email: ${userRecord.email} - Proceeding with OTP`);
        // User exists, proceed with OTP generation below
      } catch (authError) {
        console.error(`[OTP] Firebase Auth error:`, authError.code, authError.message);
        
        if (authError.code === 'auth/user-not-found') {
          // User doesn't exist - return error and don't send OTP
          console.log(`[OTP] ❌ User NOT found for: ${normalizedEmail} - Returning error, NOT sending OTP`);
          return res.status(404).json({
            success: false,
            message: 'No account found with this email address. Please check your email or register a new account.'
          });
        } else {
          // Other Firebase errors - don't send OTP on error
          console.error('[OTP] ❌ Firebase Auth error checking user:', authError);
          return res.status(500).json({
            success: false,
            message: 'Error verifying user. Please try again.'
          });
        }
      }
    } else {
      console.log(`[OTP] Regular OTP request (purpose: ${purpose || 'none'}) - No user verification required for: ${normalizedEmail}`);
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = Date.now() + 10 * 60 * 1000; // 10 minutes

    // Store OTP in Redis with expiration (10 minutes = 600 seconds)
    const otpKey = `otp:${normalizedEmail}`;
    await redis.set(otpKey, JSON.stringify({ otp, expiresAt }), { ex: 600 });

    // Send email
    const emailSent = await otpService.sendOtpEmail(normalizedEmail, otp);

    if (emailSent) {
      res.json({
        success: true,
        message: 'OTP sent successfully',
        expiresIn: 600 // 10 minutes in seconds
      });
    } else {
      res.status(500).json({
        success: false,
        message: 'Failed to send OTP email'
      });
    }
  } catch (error) {
    console.error('Error sending OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Verify OTP endpoint
app.post('/api/otp/verify', async (req, res) => {
  try {
    const { email, otp } = req.body;

    if (!email || !otp) {
      return res.status(400).json({
        success: false,
        message: 'Email and OTP are required'
      });
    }

    const otpKey = `otp:${email}`;
    let storedDataStr;
    
    try {
      storedDataStr = await redis.get(otpKey);
    } catch (redisError) {
      console.error('Redis get error:', redisError);
      return res.status(500).json({
        success: false,
        message: 'Failed to retrieve OTP from storage'
      });
    }

    // Check if OTP exists
    if (!storedDataStr || storedDataStr === 'null' || storedDataStr === null || storedDataStr === '') {
      return res.status(404).json({
        success: false,
        message: 'OTP not found or expired'
      });
    }

    let storedData;
    try {
      // Upstash Redis returns string, need to parse it
      if (typeof storedDataStr === 'string') {
        storedData = JSON.parse(storedDataStr);
      } else {
        // Already an object (shouldn't happen with Upstash, but handle it)
        storedData = storedDataStr;
      }
      
      // Validate storedData structure
      if (!storedData || !storedData.otp || !storedData.expiresAt) {
        console.error('Invalid storedData structure:', storedData);
        return res.status(500).json({
          success: false,
          message: 'Invalid OTP data structure'
        });
      }
    } catch (parseError) {
      console.error('Error parsing OTP data:', parseError);
      console.error('Raw value type:', typeof storedDataStr);
      console.error('Raw value:', storedDataStr);
      return res.status(500).json({
        success: false,
        message: 'Invalid OTP data format'
      });
    }

    if (Date.now() > storedData.expiresAt) {
      await redis.del(otpKey);
      return res.status(400).json({
        success: false,
        message: 'OTP has expired'
      });
    }

    // Compare as strings to handle any type mismatches
    if (String(storedData.otp) !== String(otp)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid OTP'
      });
    }

    // OTP verified successfully - mark as verified in Redis for password reset
    // Store verification token that expires in 15 minutes (900 seconds)
    const verificationKey = `otp_verified:${email}`;
    await redis.set(verificationKey, 'verified', { ex: 900 });
    
    // Delete OTP after verification
    await redis.del(otpKey);

    res.json({
      success: true,
      message: 'OTP verified successfully'
    });
  } catch (error) {
    console.error('Error verifying OTP:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
});

// Reset password endpoint (requires OTP verification first)
app.post('/api/password/reset', async (req, res) => {
  try {
    const { email, newPassword } = req.body;

    if (!email || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Email and new password are required'
      });
    }

    // Validate password strength (basic validation)
    if (newPassword.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters long'
      });
    }

    // Check if OTP was verified recently (within last 15 minutes)
    const verificationKey = `otp_verified:${email}`;
    const isVerified = await redis.get(verificationKey);

    if (!isVerified || isVerified !== 'verified') {
      return res.status(403).json({
        success: false,
        message: 'OTP verification required. Please verify OTP first.'
      });
    }

    // Check if Firebase Admin SDK is available
    if (!admin.apps.length) {
      // Fallback: Store password temporarily and use Firebase email flow
      // Store the new password in Redis temporarily (5 minutes) as a fallback
      const tempPasswordKey = `temp_password:${email}`;
      await redis.set(tempPasswordKey, newPassword, { ex: 300 });
      
      return res.status(503).json({
        success: false,
        message: 'Password reset service requires Firebase Admin SDK setup. Please use the email link method for now. See backend/FIREBASE_ADMIN_SETUP.md for setup instructions.'
      });
    }

    try {
      // Get user by email
      const userRecord = await admin.auth().getUserByEmail(email.trim().toLowerCase());
      
      // Update password using Admin SDK
      await admin.auth().updateUser(userRecord.uid, {
        password: newPassword
      });

      // Remove verification token after successful reset
      await redis.del(verificationKey);

      console.log(`Password reset successful for user: ${email}`);

      res.json({
        success: true,
        message: 'Password reset successful. You can now log in with your new password.'
      });
    } catch (authError) {
      console.error('Firebase Admin Auth Error:', authError);
      
      if (authError.code === 'auth/user-not-found') {
        return res.status(404).json({
          success: false,
          message: 'User not found with this email address.'
        });
      }

      return res.status(500).json({
        success: false,
        message: 'Failed to reset password. Please try again.'
      });
    }
  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Start server - listen on all network interfaces for physical device access
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://localhost:${PORT}`);
  console.log(`Server accessible at http://192.168.1.5:${PORT} (for physical devices)`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});



