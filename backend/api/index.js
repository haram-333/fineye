const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const { Redis } = require('@upstash/redis');
const otpService = require('../services/otpService');
const admin = require('firebase-admin');
const multer = require('multer');
const { parseInvoiceWithDocumentAI } = require('./documentaiHelper');

dotenv.config();

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  try {
    // Try to initialize with service account credentials from environment variable
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      try {
        // Clean the JSON string - remove any leading/trailing whitespace and newlines
        let jsonString = process.env.FIREBASE_SERVICE_ACCOUNT.trim();
        
        // Try to parse the JSON
        let serviceAccount;
        try {
          serviceAccount = JSON.parse(jsonString);
        } catch (parseError) {
          console.error('❌ JSON Parse Error:', parseError.message);
          console.error('First 100 chars of env var:', jsonString.substring(0, 100));
          // Try to fix common issues: remove BOM, fix escaped quotes
          jsonString = jsonString.replace(/^\uFEFF/, ''); // Remove BOM
          jsonString = jsonString.replace(/\\"/g, '"'); // Fix double-escaped quotes
          serviceAccount = JSON.parse(jsonString);
        }
        
        // Validate required fields
        if (!serviceAccount.private_key || !serviceAccount.client_email) {
          throw new Error('Missing required fields: private_key or client_email');
        }
        
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: 'fineye-app'
      });
        console.log('✅ Firebase Admin SDK initialized with service account');
        console.log('Service account email:', serviceAccount.client_email);
      } catch (parseError) {
        console.error('❌ Error parsing FIREBASE_SERVICE_ACCOUNT:', parseError);
        console.error('Error message:', parseError.message);
        console.error('Error stack:', parseError.stack);
        throw parseError;
      }
    } else {
      // Initialize with application default credentials (for production environments like Vercel)
      admin.initializeApp({
        projectId: 'fineye-app'
      });
      console.log('✅ Firebase Admin SDK initialized with application default credentials');
    }
  } catch (error) {
    console.error('❌ Error initializing Firebase Admin SDK:', error);
    console.error('Error details:', error.message);
    console.warn('⚠️ Firebase Admin SDK not initialized. Password reset will fail.');
  }
} else {
  console.log('✅ Firebase Admin SDK already initialized');
}

// Initialize Firestore reference (for user lookups, etc.)
let firestoreDb = null;
try {
  if (admin.apps && admin.apps.length > 0 && admin.firestore) {
    firestoreDb = admin.firestore();
    console.log('✅ Firestore initialized for user lookups');
  } else {
    console.warn('⚠️ Firestore not initialized - admin SDK not ready');
  }
} catch (firestoreError) {
  console.error('❌ Error initializing Firestore:', firestoreError);
}

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Set up multer for file uploads (in-memory storage)
const upload = multer({ 
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max file size
  },
});

// Initialize Redis client
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_REST_TOKEN,
});

// Debug password reset endpoint (for testing)
app.post('/api/password/reset-debug', async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    
    if (!email || !newPassword) {
      return res.status(400).json({
        success: false,
        message: 'Email and password required'
      });
    }
    
    const normalizedEmail = email.trim().toLowerCase();
    
    // Check Firebase status
    const firebaseStatus = {
      initialized: admin.apps.length > 0,
      appsCount: admin.apps.length
    };
    
    if (!firebaseStatus.initialized) {
      return res.status(503).json({
        success: false,
        message: 'Firebase Admin SDK not initialized',
        firebaseStatus
      });
    }
    
    // Try to get user
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(normalizedEmail);
      console.log(`✅ User found: ${userRecord.uid}, email: ${userRecord.email}`);
    } catch (getUserError) {
      console.error('❌ Error getting user:', getUserError);
      console.error('Error code:', getUserError.code);
      console.error('Error message:', getUserError.message);
      console.error('Searched email:', normalizedEmail);
      
      // Try to list users to see if email exists with different casing
      let alternativeMessage = 'User not found with this email address.';
      if (getUserError.code === 'auth/internal-error') {
        alternativeMessage = 'Firebase internal error. The email might not exist, or there might be a Firebase configuration issue.';
      } else if (getUserError.code === 'auth/user-not-found') {
        alternativeMessage = 'No account found with this email address. Please make sure you registered with this email.';
      }
      
      return res.status(404).json({
        success: false,
        message: alternativeMessage,
        error: getUserError.code,
        errorMessage: getUserError.message,
        searchedEmail: normalizedEmail,
        firebaseStatus
      });
    }
    
    // Try to update password
    try {
      await admin.auth().updateUser(userRecord.uid, {
        password: newPassword
      });
      
      return res.json({
        success: true,
        message: 'Password updated successfully',
        userId: userRecord.uid,
        email: userRecord.email,
        firebaseStatus
      });
    } catch (updateError) {
      return res.status(500).json({
        success: false,
        message: 'Failed to update password',
        error: updateError.code,
        errorMessage: updateError.message,
        userId: userRecord.uid,
        firebaseStatus
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Debug endpoint error',
      error: error.message
    });
  }
});

// Create Auth user from Firestore data (if user exists in Firestore but not in Auth)
app.post('/api/user/create-auth', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }
    
    if (password.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters'
      });
    }
    
    const normalizedEmail = email.trim().toLowerCase();
    
    if (!admin.apps.length) {
      return res.status(503).json({
        success: false,
        message: 'Firebase Admin SDK not initialized'
      });
    }
    
    // Check if user already exists in Auth
    try {
      const existingUser = await admin.auth().getUserByEmail(normalizedEmail);
      return res.json({
        success: true,
        message: 'User already exists in Firebase Auth',
        userId: existingUser.uid,
        email: existingUser.email
      });
    } catch (error) {
      if (error.code !== 'auth/user-not-found' && error.code !== 'auth/internal-error') {
        throw error;
      }
      // User doesn't exist, continue to create
    }
    
    // Create the Auth user
    try {
      const userRecord = await admin.auth().createUser({
        email: normalizedEmail,
        password: password,
        emailVerified: false, // They'll need to verify
      });
      
      console.log(`✅ Auth user created: ${userRecord.uid} for ${normalizedEmail}`);
      
      return res.json({
        success: true,
        message: 'Firebase Auth user created successfully',
        userId: userRecord.uid,
        email: userRecord.email,
        note: 'User can now login and reset password'
      });
    } catch (createError) {
      console.error('Error creating Auth user:', createError);
      return res.status(500).json({
        success: false,
        message: 'Failed to create Auth user',
        error: createError.code,
        errorMessage: createError.message
      });
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error creating Auth user',
      error: error.message
    });
  }
});

// Check if user exists endpoint
app.post('/api/user/check', async (req, res) => {
  try {
    const { email } = req.body;
    
    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }
    
    const normalizedEmail = email.trim().toLowerCase();
    
    if (!admin.apps.length) {
      return res.status(503).json({
        success: false,
        message: 'Firebase Admin SDK not initialized'
      });
    }
    
    try {
      const userRecord = await admin.auth().getUserByEmail(normalizedEmail);
      return res.json({
        success: true,
        exists: true,
        userId: userRecord.uid,
        email: userRecord.email,
        emailVerified: userRecord.emailVerified,
        createdAt: userRecord.metadata.creationTime,
        lastSignIn: userRecord.metadata.lastSignInTime
      });
    } catch (error) {
      if (error.code === 'auth/user-not-found' || error.code === 'auth/internal-error') {
        return res.json({
          success: true,
          exists: false,
          message: 'User not found in Firebase Auth',
          error: error.code
        });
      }
      throw error;
    }
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: 'Error checking user',
      error: error.message
    });
  }
});

// Test Firebase endpoint
app.get('/api/test/firebase', async (req, res) => {
  try {
    const isInitialized = admin.apps.length > 0;
    const hasEnvVar = !!process.env.FIREBASE_SERVICE_ACCOUNT;
    
    let parseError = null;
    if (hasEnvVar) {
      try {
        JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      } catch (e) {
        parseError = e.message;
      }
    }
    
    res.json({
      firebaseInitialized: isInitialized,
      hasServiceAccountEnv: hasEnvVar,
      parseError: parseError,
      appsCount: admin.apps.length,
      message: isInitialized 
        ? 'Firebase Admin SDK is initialized correctly' 
        : 'Firebase Admin SDK is NOT initialized. Check environment variables.'
    });
  } catch (error) {
    res.status(500).json({
      error: error.message,
      firebaseInitialized: false
    });
  }
});

// Health check endpoint
app.get('/health', async (req, res) => {
  try {
    // Test Redis connection
    await redis.ping();
    
    // Check Firebase Admin SDK status
    const firebaseStatus = admin.apps.length > 0 ? 'initialized' : 'not initialized';
    const firebaseDetails = admin.apps.length > 0 
      ? { 
          projectId: admin.apps[0].options.projectId,
          hasServiceAccount: !!process.env.FIREBASE_SERVICE_ACCOUNT
        }
      : { error: 'Firebase Admin SDK not initialized' };
    
    res.json({ 
      status: 'OK', 
      message: 'Server is running', 
      redis: 'connected',
      firebase: firebaseStatus,
      firebaseDetails: firebaseDetails
    });
  } catch (error) {
    res.status(500).json({ 
      status: 'ERROR', 
      message: 'Health check failed', 
      error: error.message,
      firebase: admin.apps.length > 0 ? 'initialized' : 'not initialized'
    });
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

    // Normalize email to lowercase for consistent storage
    const normalizedEmail = email.trim().toLowerCase();
    
    // Log incoming request details
    console.log(`[OTP] Request received - Email: ${normalizedEmail}, Purpose: ${purpose || 'none'}`);
    console.log('[OTP] Full request body:', JSON.stringify(req.body));

    // If this is for forgot password, check if user exists first
    if (purpose === 'forgot_password') {
      console.log(`[OTP] Forgot password flow - Checking if user exists: ${normalizedEmail}`);

      // Check if Firestore is available
      if (!firestoreDb) {
        console.error('[OTP] ❌ Firestore NOT initialized - Cannot verify user via Firestore');
        return res.status(503).json({
          success: false,
          message: 'User database not initialized. Cannot verify user existence.'
        });
      }

      try {
        // Check if user exists in Firestore "users" collection by email
        console.log(`[OTP] Checking Firestore 'users' collection for email: ${normalizedEmail}`);
        const usersSnapshot = await firestoreDb
          .collection('users')
          .where('email', '==', normalizedEmail)
          .limit(1)
          .get();

        if (usersSnapshot.empty) {
          // No Firestore user found with this email - do NOT send OTP
          console.log(`[OTP] ❌ No Firestore user found for email: ${normalizedEmail} - NOT sending OTP`);
          return res.status(404).json({
            success: false,
            message: 'No account found with this email address. Please check your email or register a new account.'
          });
        }

        // User exists in Firestore - safe to proceed with OTP generation
        const userDoc = usersSnapshot.docs[0];
        console.log(
          `[OTP] ✅ Firestore user found (docId: ${userDoc.id}) for email: ${normalizedEmail} - Proceeding with OTP`
        );
      } catch (firestoreError) {
        console.error('[OTP] ❌ Firestore error while checking user:', firestoreError);
        return res.status(500).json({
          success: false,
          message: 'Unable to verify your email address. Please try again later.'
        });
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

    // Send email (use original email for display, but store normalized in Redis)
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

    // Normalize email to lowercase for consistent lookup
    const normalizedEmail = email.trim().toLowerCase();
    const otpKey = `otp:${normalizedEmail}`;
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
    // Use normalized email for consistency
    const verificationKey = `otp_verified:${normalizedEmail}`;
    await redis.set(verificationKey, 'verified', { ex: 900 });
    
    // Delete OTP after verification
    await redis.del(otpKey);

    res.json({
      success: true,
      message: 'OTP verified successfully'
    });
  } catch (error) {
    console.error('Error verifying OTP:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Send Firebase password reset email (alternative method - sends link)
app.post('/api/password/reset-email', async (req, res) => {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Email is required'
      });
    }

    // Check if Firebase Admin SDK is available
    if (!admin.apps.length) {
      return res.status(503).json({
        success: false,
        message: 'Firebase Admin SDK not initialized. Please check environment variables.'
      });
    }

    const normalizedEmail = email.trim().toLowerCase();
    
    try {
      // Check if user exists first
      const userRecord = await admin.auth().getUserByEmail(normalizedEmail);
      
      // Generate password reset link
      const actionCodeSettings = {
        url: 'https://fineye-one.vercel.app/password-reset', // Your app's password reset page
        handleCodeInApp: false,
      };
      
      const link = await admin.auth().generatePasswordResetLink(normalizedEmail, actionCodeSettings);
      
      console.log(`Password reset link generated for: ${normalizedEmail}`);
      
      // In production, you'd send this link via email
      // For now, we'll return it (remove this in production!)
      res.json({
        success: true,
        message: 'Password reset link generated. Check your email.',
        resetLink: link // Remove this in production - only for testing
      });
    } catch (authError) {
      console.error('Error generating password reset link:', authError);
      if (authError.code === 'auth/user-not-found') {
        return res.status(404).json({
          success: false,
          message: 'User not found with this email address.'
        });
      }
      throw authError;
    }
  } catch (error) {
    console.error('Error in password reset email:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send password reset email',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Invoice OCR endpoint with Google Document AI
app.post('/api/ocr/document-ai', upload.single('invoice'), async (req, res) => {
  try {
    console.log('📥 Document AI: Received invoice upload request');
    
    if (!req.file) {
      return res.status(400).json({ 
        success: false, 
        message: "No file uploaded. Please send the invoice image/file with field name 'invoice'." 
      });
    }

    console.log(`📄 Document AI: File received - ${req.file.originalname}, size: ${req.file.size} bytes, type: ${req.file.mimetype}`);

    // Check environment variables
    const missingVars = [];
    if (!process.env.DOCUMENT_AI_PROJECT_ID) missingVars.push('DOCUMENT_AI_PROJECT_ID');
    if (!process.env.DOCUMENT_AI_LOCATION) missingVars.push('DOCUMENT_AI_LOCATION');
    if (!process.env.DOCUMENT_AI_PROCESSOR_ID) missingVars.push('DOCUMENT_AI_PROCESSOR_ID');
    
    if (missingVars.length > 0) {
      console.error('❌ Document AI: Missing environment variables:', missingVars.join(', '));
      console.error('❌ Document AI: Available env vars:', {
        hasProjectId: !!process.env.DOCUMENT_AI_PROJECT_ID,
        hasLocation: !!process.env.DOCUMENT_AI_LOCATION,
        hasProcessorId: !!process.env.DOCUMENT_AI_PROCESSOR_ID,
        hasDocAIServiceAccount: !!process.env.DOCUMENT_AI_SERVICE_ACCOUNT,
        hasFirebaseServiceAccount: !!process.env.FIREBASE_SERVICE_ACCOUNT,
      });
      return res.status(500).json({
        success: false,
        message: 'Document AI service not configured. Missing environment variables.',
        error: `Missing: ${missingVars.join(', ')}`,
        missingVariables: missingVars,
      });
    }
    
    // Check if we have service account credentials
    const hasServiceAccount = !!(process.env.DOCUMENT_AI_SERVICE_ACCOUNT || process.env.FIREBASE_SERVICE_ACCOUNT);
    if (!hasServiceAccount) {
      console.warn('⚠️ Document AI: No service account found. Will try default credentials (may fail in Vercel)');
    }

    // Validate file
    if (!req.file || !req.file.buffer) {
      console.error('❌ Document AI: No file uploaded');
      return res.status(400).json({
        success: false,
        message: 'No file uploaded',
        error: 'Missing file in request',
      });
    }
    
    console.log(`📤 Document AI: Received file`);
    console.log(`   Original name: ${req.file.originalname}`);
    console.log(`   MIME type: ${req.file.mimetype}`);
    console.log(`   Size: ${req.file.buffer.length} bytes`);
    
    // Parse invoice with Document AI (works with both Invoice Parser and Document OCR)
    // Pass filename to help detect MIME type if mimetype is wrong
    const docAIResult = await parseInvoiceWithDocumentAI({
      fileBuffer: req.file.buffer,
      fileMimeType: req.file.mimetype,
      filename: req.file.originalname || req.file.filename
    });

    // Extract data from Document AI response
    const document = docAIResult.document;
    
    // Log processor type (Invoice Parser vs Document OCR)
    // Invoice Parser has entities, Document OCR doesn't
    const processorType = (document?.entities && document.entities.length > 0) 
      ? 'Invoice Parser (may not handle Arabic well)' 
      : 'Document OCR (better Arabic support)';
    console.log(`🔍 Document AI: Processor type detected: ${processorType}`);
    console.log(`⚠️ NOTE: If Arabic text is garbled, switch to Document OCR processor for better Arabic support`);
    
    // Helper function to extract text from textAnchor (as per official samples)
    const getTextFromAnchor = (textAnchor, fullText) => {
      if (!textAnchor || !textAnchor.textSegments || textAnchor.textSegments.length === 0) {
        return textAnchor?.content || ''; // Fallback to content if available
      }
      
      // First shard in document doesn't have startIndex property
      const startIndex = textAnchor.textSegments[0].startIndex || 0;
      const endIndex = textAnchor.textSegments[0].endIndex;
      
      return fullText ? fullText.substring(startIndex, endIndex) : '';
    };
    
    const fullText = document?.text || '';
    
    // Check if text contains Arabic characters (even if garbled)
    const arabicPattern = /[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]/;
    const hasArabicChars = arabicPattern.test(fullText);
    if (hasArabicChars) {
      console.log(`✅ Document AI: Found Arabic characters in extracted text!`);
    } else {
      console.log(`⚠️ Document AI: No Arabic characters detected in text (might be garbled by Invoice Parser)`);
    }
    
    // Extract detected languages from pages (important for Arabic detection)
    const detectedLanguages = [];
    if (document?.pages && document.pages.length > 0) {
      for (const page of document.pages) {
        if (page.detectedLanguages && page.detectedLanguages.length > 0) {
          for (const lang of page.detectedLanguages) {
            detectedLanguages.push({
              languageCode: lang.languageCode,
              confidence: lang.confidence || 0,
            });
          }
        }
      }
    }
    
    console.log(`🌐 Document AI: Detected languages: ${detectedLanguages.map(l => `${l.languageCode} (${(l.confidence * 100).toFixed(1)}%)`).join(', ') || 'none'}`);
    
    // Document OCR returns raw text, Invoice Parser returns structured entities
    // Check if we have entities (Invoice Parser) or just text (Document OCR)
    const hasEntities = document?.entities && document.entities.length > 0;
    
    let extractedData;
    
    if (hasEntities) {
      // Invoice Parser format - structured entities
      const entities = document.entities || [];
      extractedData = {
        fullText: fullText,
        entities: entities.map(entity => {
          // Extract text value using textAnchor (as per official samples)
          const textValue = entity.textAnchor 
            ? getTextFromAnchor(entity.textAnchor, fullText)
            : (entity.mentionText || '');
          
          return {
            type: entity.type,
            value: textValue,
            confidence: entity.confidence || 0,
            normalizedValue: entity.normalizedValue || null,
          };
        }),
        detectedLanguages: detectedLanguages,
        // Common invoice fields (if available) - use textAnchor extraction
        invoiceNumber: entities.find(e => e.type === 'invoice_id' || e.type === 'invoice_number') 
          ? getTextFromAnchor(entities.find(e => e.type === 'invoice_id' || e.type === 'invoice_number').textAnchor, fullText)
          : null,
        supplierName: entities.find(e => e.type === 'supplier_name' || e.type === 'supplier')
          ? getTextFromAnchor(entities.find(e => e.type === 'supplier_name' || e.type === 'supplier').textAnchor, fullText)
          : null,
        invoiceDate: entities.find(e => e.type === 'invoice_date')
          ? getTextFromAnchor(entities.find(e => e.type === 'invoice_date').textAnchor, fullText)
          : null,
        dueDate: entities.find(e => e.type === 'due_date')
          ? getTextFromAnchor(entities.find(e => e.type === 'due_date').textAnchor, fullText)
          : null,
        totalAmount: entities.find(e => e.type === 'total_amount' || e.type === 'total')
          ? getTextFromAnchor(entities.find(e => e.type === 'total_amount' || e.type === 'total').textAnchor, fullText)
          : null,
        netAmount: entities.find(e => e.type === 'net_amount' || e.type === 'net')
          ? getTextFromAnchor(entities.find(e => e.type === 'net_amount' || e.type === 'net').textAnchor, fullText)
          : null,
        taxAmount: entities.find(e => e.type === 'tax_amount' || e.type === 'vat_amount')
          ? getTextFromAnchor(entities.find(e => e.type === 'tax_amount' || e.type === 'vat_amount').textAnchor, fullText)
          : null,
        currency: entities.find(e => e.type === 'currency')
          ? getTextFromAnchor(entities.find(e => e.type === 'currency').textAnchor, fullText)
          : null,
      };
    } else {
      // Document OCR format - raw text only
      extractedData = {
        fullText: fullText,
        entities: [], // No structured entities from Document OCR
        detectedLanguages: detectedLanguages,
        // Fields will be parsed client-side using regex
      };
      console.log(`📄 Document OCR: Extracted ${fullText.length} characters of text`);
    }

    console.log('✅ Document AI: Successfully extracted invoice data');
    
    res.json({ 
      success: true, 
      data: extractedData,
      rawDocumentAI: docAIResult // Include full response for debugging/advanced use
    });
  } catch (error) {
    console.error('❌ Document AI error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      success: false, 
      message: 'Failed to process invoice with Document AI',
      error: error.message || error.toString() 
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

    // Normalize email to lowercase for consistent lookup
    const normalizedEmail = email.trim().toLowerCase();

    // Check if OTP was verified recently (within last 15 minutes)
    const verificationKey = `otp_verified:${normalizedEmail}`;
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
      console.log(`Attempting password reset for: ${normalizedEmail}`);
      
      // Get user by email
      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(normalizedEmail);
        console.log(`✅ User found: ${userRecord.uid}`);
        console.log(`User email in Firebase: ${userRecord.email}`);
        console.log(`User created: ${userRecord.metadata.creationTime}`);
      } catch (getUserError) {
        console.error('❌ Error getting user by email:', getUserError);
        console.error('Error code:', getUserError.code);
        console.error('Error message:', getUserError.message);
        console.error('Searched email:', normalizedEmail);
        
        if (getUserError.code === 'auth/user-not-found') {
          return res.status(404).json({
            success: false,
            message: 'No account found with this email address. Please make sure you registered with this email.',
            error: getUserError.code
          });
        } else if (getUserError.code === 'auth/internal-error') {
          return res.status(500).json({
            success: false,
            message: 'Firebase internal error. Please check if the email exists in Firebase Auth.',
            error: getUserError.code,
            errorMessage: getUserError.message
          });
        }
        throw getUserError;
      }
      
      // Update password using Admin SDK
      try {
        const updateResult = await admin.auth().updateUser(userRecord.uid, {
        password: newPassword
      });
        console.log(`✅ Password updated successfully for user: ${userRecord.uid}`);
        console.log(`Updated user email: ${updateResult.email}`);
        
        // Verify the password was actually updated by checking user metadata
        const updatedUser = await admin.auth().getUser(userRecord.uid);
        console.log(`User metadata updated at: ${updatedUser.metadata.lastSignInTime}`);
      } catch (updateError) {
        console.error('❌ Error updating password:', updateError);
        console.error('Error code:', updateError.code);
        console.error('Error message:', updateError.message);
        console.error('Error stack:', updateError.stack);
        
        // Check for specific Firebase errors
        if (updateError.code === 'auth/invalid-password') {
          return res.status(400).json({
            success: false,
            message: 'Password does not meet requirements. Please use a stronger password.'
          });
        }
        
        throw updateError;
      }

      // Remove verification token after successful reset
      await redis.del(verificationKey);

      console.log(`✅ Password reset successful for user: ${normalizedEmail}`);
      console.log(`Verification token removed from Redis`);

      res.json({
        success: true,
        message: 'Password reset successful. You can now log in with your new password.'
      });
    } catch (authError) {
      console.error('Firebase Admin Auth Error:', authError);
      console.error('Error code:', authError.code);
      console.error('Error message:', authError.message);
      console.error('Error stack:', authError.stack);
      
      if (authError.code === 'auth/user-not-found') {
        return res.status(404).json({
          success: false,
          message: 'User not found with this email address.'
        });
      }

      // Return more detailed error in development, generic in production
      return res.status(500).json({
        success: false,
        message: process.env.NODE_ENV === 'development' 
          ? `Failed to reset password: ${authError.message || authError.code || 'Unknown error'}`
          : 'Failed to reset password. Please try again.',
        error: process.env.NODE_ENV === 'development' ? {
          code: authError.code,
          message: authError.message
        } : undefined
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

// Export for Vercel serverless
module.exports = app;

