// Helper for Google Document AI Invoice Parsing
const {DocumentProcessorServiceClient} = require('@google-cloud/documentai').v1;

/**
 * Initialize Google Document AI client with explicit service account credentials.
 *
 * We MUST pass credentials explicitly because Vercel doesn't provide GCP default
 * credentials. We try, in order:
 *   1) DOCUMENT_AI_SERVICE_ACCOUNT (JSON string)
 *   2) FIREBASE_SERVICE_ACCOUNT (JSON string)
 *
 * If neither can be parsed, we throw a clear error instead of silently falling
 * back to Application Default Credentials (which leads to
 * \"Could not load the default credentials\" errors).
 */
const getGoogleClient = () => {
  let rawJson = process.env.DOCUMENT_AI_SERVICE_ACCOUNT || process.env.FIREBASE_SERVICE_ACCOUNT;

  if (!rawJson) {
    throw new Error(
      'No service account JSON found for Document AI. ' +
      'Set DOCUMENT_AI_SERVICE_ACCOUNT or reuse FIREBASE_SERVICE_ACCOUNT in your environment.'
    );
  }

  try {
    // Clean common formatting issues (BOM, double-escaped quotes)
    let jsonString = rawJson.trim();
    jsonString = jsonString.replace(/^\uFEFF/, ''); // remove BOM if present
    jsonString = jsonString.replace(/\\"/g, '"');   // unescape quotes if needed

    const serviceAccount = JSON.parse(jsonString);

    if (!serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error('Service account JSON is missing client_email or private_key');
    }

    console.log('✅ Using service account for Document AI:', serviceAccount.client_email);

    return new DocumentProcessorServiceClient({
      credentials: {
        client_email: serviceAccount.client_email,
        private_key: serviceAccount.private_key,
      },
    });
  } catch (e) {
    console.error('❌ Failed to initialize Document AI service account credentials:', e);
    throw new Error('Invalid service account JSON for Document AI. Check DOCUMENT_AI_SERVICE_ACCOUNT / FIREBASE_SERVICE_ACCOUNT env var.');
  }
};

/**
 * Calls Google Document AI API with given file buffer and returns parsed result
 */
async function parseInvoiceWithDocumentAI({fileBuffer, fileMimeType, filename}) {
  const projectId = process.env.DOCUMENT_AI_PROJECT_ID;
  const location = process.env.DOCUMENT_AI_LOCATION;
  const processorId = process.env.DOCUMENT_AI_PROCESSOR_ID;
  
  if (!projectId || !location || !processorId) {
    throw new Error('Missing Document AI environment variables. Required: DOCUMENT_AI_PROJECT_ID, DOCUMENT_AI_LOCATION, DOCUMENT_AI_PROCESSOR_ID');
  }
  
  // Detect MIME type from filename if not provided or if it's application/octet-stream
  function detectMimeType(mimeType, filename) {
    // If we have a valid MIME type, use it
    if (mimeType && mimeType !== 'application/octet-stream') {
      return mimeType;
    }
    
    // Otherwise, detect from filename extension
    if (filename) {
      const ext = filename.toLowerCase().split('.').pop();
      switch (ext) {
        case 'jpg':
        case 'jpeg':
          return 'image/jpeg';
        case 'png':
          return 'image/png';
        case 'pdf':
          return 'application/pdf';
        default:
          return 'image/jpeg'; // Default to JPEG
      }
    }
    
    // Fallback to JPEG
    return 'image/jpeg';
  }
  
  // Supported types: image/jpeg, image/png, application/pdf
  const mimeType = detectMimeType(fileMimeType, filename || 'invoice.jpg');
  
  const name = `projects/${projectId}/locations/${location}/processors/${processorId}`;
  const client = getGoogleClient();

  // Validate inputs
  if (!fileBuffer || fileBuffer.length === 0) {
    throw new Error('File buffer is empty or invalid');
  }
  
  if (fileBuffer.length > 20 * 1024 * 1024) { // 20MB limit
    throw new Error(`File too large: ${fileBuffer.length} bytes (max 20MB)`);
  }
  
  // Validate mimeType
  const validMimeTypes = ['image/jpeg', 'image/png', 'image/jpg', 'application/pdf'];
  if (!validMimeTypes.includes(mimeType)) {
    throw new Error(`Invalid mime type: ${mimeType}. Supported: ${validMimeTypes.join(', ')}`);
  }

  // Convert the file buffer to base64 string (as per official Google samples)
  const encodedImage = fileBuffer.toString('base64');
  
  const request = {
    name,
    rawDocument: {
      content: encodedImage, // Base64 encoded string (as per official samples)
      mimeType,
    },
  };
  
  console.log(`🔍 Document AI: Processing invoice`);
  console.log(`   Processor: ${name}`);
  console.log(`   File size: ${fileBuffer.length} bytes`);
  console.log(`   MIME type: ${mimeType}`);
  console.log(`   Project ID: ${projectId}`);
  console.log(`   Location: ${location}`);
  console.log(`   Processor ID: ${processorId}`);
  
  try {
    const [result] = await client.processDocument(request);
    console.log(`✅ Document AI: Processing completed successfully`);
    return result;
  } catch (error) {
    console.error(`❌ Document AI API error:`);
    console.error(`   Error code: ${error.code}`);
    console.error(`   Error message: ${error.message}`);
    console.error(`   Error details:`, error.details);
    
    // Provide more helpful error messages
    if (error.message && error.message.includes('INVALID_ARGUMENT')) {
      console.error(`❌ INVALID_ARGUMENT - Common causes:`);
      console.error(`   1. Processor ID doesn't exist: ${processorId}`);
      console.error(`   2. Wrong location (processor is in different region): ${location}`);
      console.error(`   3. Processor is in different project: ${projectId}`);
      console.error(`   4. Invalid image format or corrupted file`);
      console.error(`   5. File too large or empty`);
    }
    
    throw error;
  }
}

module.exports = {
  parseInvoiceWithDocumentAI,
};

