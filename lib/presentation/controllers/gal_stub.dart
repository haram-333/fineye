// Stub file for gal package on web
// This file is used when building for web platform where gal is not supported

import 'dart:typed_data';

class Gal {
  static Future<void> requestAccess() async {
    throw UnsupportedError('Gal is not supported on web platform');
  }
  
  static Future<void> putImageBytes(Uint8List bytes) async {
    throw UnsupportedError('Gal is not supported on web platform');
  }
}

