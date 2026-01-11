import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'invoices';

  // Get all invoices
  Stream<List<Invoice>> getInvoices() {
    return _firestore
        .collection(_collection)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
    });
  }

  // Get a single invoice by ID
  Future<Invoice?> getInvoiceById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return Invoice.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting invoice: $e');
      return null;
    }
  }

  // Add a new invoice
  Future<String?> addInvoice(Invoice invoice) async {
    try {
      final docRef = await _firestore.collection(_collection).add(invoice.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding invoice: $e');
      return null;
    }
  }

  // Update an existing invoice
  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      debugPrint('Updating invoice with ID: ${invoice.id}');
      
      // Find document by invoice ID field (not document ID)
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: invoice.id)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('Invoice with ID ${invoice.id} not found. Trying document ID...');
        // If not found by ID field, try to use document ID directly (legacy support)
        try {
          await _firestore.collection(_collection).doc(invoice.id).set(
            {
              ...invoice.toMap(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
          debugPrint('✅ Invoice updated using document ID');
          return true;
        } catch (e) {
          debugPrint('❌ Failed to update invoice: $e');
          return false;
        }
      }

      // Found by ID field - update using document ID
      final docId = querySnapshot.docs.first.id;
      debugPrint('Found invoice document with ID: $docId');
      
      await _firestore.collection(_collection).doc(docId).update({
        ...invoice.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Invoice updated successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Delete an invoice
  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      // Find document by invoice ID
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('id', isEqualTo: invoiceId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // If not found by ID, try to delete by document ID
        await _firestore.collection(_collection).doc(invoiceId).delete();
        return true;
      }

      final docId = querySnapshot.docs.first.id;
      await _firestore.collection(_collection).doc(docId).delete();
      return true;
    } catch (e) {
      print('Error deleting invoice: $e');
      return false;
    }
  }

  // Add multiple invoices (for initial data seeding)
  Future<bool> addInvoices(List<Invoice> invoices) async {
    try {
      debugPrint('Creating batch write for ${invoices.length} invoices...');
      final batch = _firestore.batch();
      for (var invoice in invoices) {
        final docRef = _firestore.collection(_collection).doc();
        final invoiceMap = invoice.toMap();
        debugPrint('Adding invoice ${invoice.id} to batch...');
        batch.set(docRef, invoiceMap);
      }
      debugPrint('Committing batch to Firestore...');
      await batch.commit();
      debugPrint('✅ Successfully committed ${invoices.length} invoices to Firestore');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error adding invoices: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Get invoices by status
  Stream<List<Invoice>> getInvoicesByStatus(String status) {
    return _firestore
        .collection(_collection)
        .where('status', isEqualTo: status)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
    });
  }

  // Get invoices by date range
  Future<List<Invoice>> getInvoicesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting invoices by date range: $e');
      return [];
    }
  }
}

