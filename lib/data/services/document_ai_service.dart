import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io' if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart';

/// Service for calling Google Document AI via backend API
class DocumentAIService {
  // Production URL - Always use this in production
  static const String productionUrl = 'https://fineye-one.vercel.app';
  
  // Your computer's local IP address (for physical device testing)
  static const String localIp = '192.168.100.6';
  
  // Get base URL based on environment and platform
  static String get baseUrl {
    // Always use production URL - works for all platforms including web
    if (productionUrl.isNotEmpty && productionUrl != 'YOUR_PRODUCTION_URL_HERE') {
      return productionUrl;
    }
    
    // Development mode URLs (fallback if production URL not set)
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    
    // For mobile platforms in development
    return 'http://$localIp:3000';
  }

  /// Process invoice image with Document AI
  /// Returns extracted invoice data from Document AI
  static Future<Map<String, dynamic>> processInvoice({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      print('🔍🔍🔍 DOCUMENT AI SERVICE: Starting processInvoice 🔍🔍🔍');
      print('🔍 Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      print('🔍 Image File: ${imageFile?.path ?? "null"}');
      print('🔍 Image Bytes: ${imageBytes?.length ?? 0} bytes');
      print('🔍 Base URL: $baseUrl');
      
      if (imageFile == null && imageBytes == null) {
        final error = 'No image file or bytes provided';
        print('❌❌❌ DOCUMENT AI SERVICE ERROR ❌❌❌');
        print('❌ Error: $error');
        debugPrint('❌❌❌ DOCUMENT AI SERVICE ERROR ❌❌❌');
        debugPrint('❌ Error: $error');
        throw Exception(error);
      }

      print('🔍 Document AI: Preparing to send invoice to backend...');

      // Prepare multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/ocr/document-ai'),
      );

      // Determine MIME type from file extension or default to image/jpeg
      String determineMimeType(String? filePath, Uint8List? bytes) {
        if (filePath != null) {
          final extension = filePath.toLowerCase().split('.').last;
          switch (extension) {
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
        return 'image/jpeg'; // Default for bytes
      }

      // Add file to request
      if (imageFile != null && !kIsWeb) {
        // Mobile: use file directly
        // TypeScript knows this is dart:io File because of !kIsWeb check
        if (await imageFile.exists()) {
          // Use dynamic to access dart:io File methods (only on mobile)
          final ioFile = imageFile as dynamic;
          final fileStream = ioFile.openRead() as Stream<List<int>>;
          final length = await ioFile.length() as int;
          final mimeType = determineMimeType(imageFile.path, null);
          final multipartFile = http.MultipartFile(
            'invoice',
            fileStream,
            length,
            filename: imageFile.path.split('/').last,
            contentType: http.MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);
          print('📤 Document AI: Sending file: ${imageFile.path}');
          print('📤 Document AI: MIME type: $mimeType');
        } else {
          throw Exception('File does not exist: ${imageFile.path}');
        }
      } else if (imageBytes != null) {
        // Web or bytes: use bytes
        final mimeType = determineMimeType(null, imageBytes);
        final multipartFile = http.MultipartFile.fromBytes(
          'invoice',
          imageBytes,
          filename: 'invoice.jpg',
          contentType: http.MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);
        print('📤 Document AI: Sending ${imageBytes.length} bytes');
        print('📤 Document AI: MIME type: $mimeType');
      } else {
        throw Exception('No valid image data provided');
      }

      // Send request
      print('🚀 Document AI: Sending request to $baseUrl/api/ocr/document-ai');
      print('🚀 Document AI: Request has ${request.files.length} file(s)');
      if (request.files.isNotEmpty) {
        print('🚀 Document AI: File name: ${request.files.first.filename}');
        print('🚀 Document AI: File length: ${request.files.first.length} bytes');
      }
      
      final streamedResponse = await request.send();
      print('📡 Document AI: Request sent, waiting for response...');
      final response = await http.Response.fromStream(streamedResponse);
      print('📡 Document AI: Response received!');

      print('📥 Document AI: Response status: ${response.statusCode}');
      print('📥 Document AI: Response headers: ${response.headers}');
      
      // Log response body (truncate if too long)
      final responseBody = response.body;
      if (responseBody.length > 1000) {
        print('📥 Document AI: Response body (first 1000 chars): ${responseBody.substring(0, 1000)}...');
      } else {
        print('📥 Document AI: Response body: $responseBody');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('📊 Document AI: Parsed data keys: ${data.keys}');
        print('📊 Document AI: data.success: ${data['success']}');
        print('📊 Document AI: data.data exists: ${data['data'] != null}');
        
        if (data['success'] == true) {
          final fullText = data['data']?['fullText'] ?? '';
          final entities = data['data']?['entities'] ?? [];
          
          print('✅ Document AI: Successfully processed invoice');
          print('📊 Document AI: Full text length: ${fullText.length}');
          print('📊 Document AI: Entities count: ${entities.length}');
          
          // Check for Arabic in the response
          if (fullText.isNotEmpty) {
            final containsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(fullText);
            print('📊 Document AI: Contains Arabic: $containsArabic');
            if (containsArabic) {
              print('✅ Document AI: Arabic text detected in response!');
            }
          }
          
          return {
            'success': true,
            'data': data['data'],
            'rawDocumentAI': data['rawDocumentAI'],
          };
        } else {
          final errorMsg = data['message'] ?? data['error'] ?? 'Document AI processing failed';
          print('❌ Document AI: Backend returned success=false');
          print('❌ Error message: $errorMsg');
          print('❌ Full error data: $data');
          throw Exception(errorMsg);
        }
      } else {
        // Try to parse error response
        String errorMessage;
        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorData['error'] ?? 'Unknown error';
        } catch (e) {
          errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}\nResponse: ${response.body}';
        }
        print('❌ Document AI: Backend error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('❌❌❌ DOCUMENT AI SERVICE ERROR ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      print('❌ Image File: ${imageFile?.path ?? "null"}');
      print('❌ Image Bytes: ${imageBytes?.length ?? 0} bytes');
      print('❌ Base URL: $baseUrl');
      debugPrint('❌❌❌ DOCUMENT AI SERVICE ERROR ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}

