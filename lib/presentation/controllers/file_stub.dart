// Stub file for File class on web
// This file provides a minimal File-like interface for web compatibility

import 'dart:async';
import 'dart:typed_data';

class File {
  final String path;
  
  File(this.path);
  
  Future<Uint8List> readAsBytes() async {
    throw UnsupportedError('File operations are not fully supported on web. Use Uint8List instead.');
  }
  
  Future<void> writeAsBytes(Uint8List bytes) async {
    throw UnsupportedError('File operations are not fully supported on web. Use Uint8List instead.');
  }
  
  Future<bool> exists() async {
    // On web, we can't check file existence, return false
    return false;
  }
  
  Future<void> delete({bool recursive = false}) async {
    throw UnsupportedError('File deletion is not supported on web.');
  }
  
  // Add methods needed by document_ai_service
  Stream<Uint8List> openRead([int? start, int? end]) {
    throw UnsupportedError('File.openRead is not supported on web. Use Uint8List instead.');
  }
  
  Future<int> length() async {
    throw UnsupportedError('File.length is not supported on web. Use Uint8List.length instead.');
  }
}



