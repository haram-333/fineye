import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';

/// Repository for user-specific invoices stored in `user_invoices` collection.
/// Each document should include a `userId` field so we can query per user.
class UserInvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'user_invoices';

  /// Stream all invoices for a specific user, ordered by date desc.
  /// Note: This requires a Firestore composite index on userId and date.
  /// If index doesn't exist, use getInvoicesForUserWithoutIndex() as fallback.
  Stream<List<Invoice>> getInvoicesForUser(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      final invoiceList = snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
      // Sort by date descending (already sorted by Firestore, but ensure it)
      invoiceList.sort((a, b) => b.date.compareTo(a.date));
      return invoiceList;
    });
  }

  /// Fallback method: Get invoices without using orderBy (sorts in memory).
  /// Use this if the composite index hasn't been created yet.
  Stream<List<Invoice>> getInvoicesForUserWithoutIndex(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final invoiceList = snapshot.docs
          .map((doc) => Invoice.fromFirestore(doc))
          .toList();
      // Sort by date descending in memory
      invoiceList.sort((a, b) => b.date.compareTo(a.date));
      return invoiceList;
    });
  }

  /// Get a single invoice by Firestore document ID.
  Future<Invoice?> getInvoiceByDocId(String docId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(docId).get();
      if (doc.exists) {
        return Invoice.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user invoice by docId: $e');
      return null;
    }
  }

  /// Add a new invoice for a user.
  /// If [documentId] is provided, it will be used as Firestore doc id
  /// (useful when you want to align it with a storage object key).
  Future<String?> addInvoice(Invoice invoice, {String? documentId}) async {
    try {
      final collectionRef = _firestore.collection(_collection);
      final docRef = documentId != null
          ? collectionRef.doc(documentId)
          : collectionRef.doc();

      await docRef.set(invoice.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error adding user invoice: $e');
      return null;
    }
  }

  /// Update an existing invoice by Firestore document ID.
  Future<bool> updateInvoiceByDocId(String docId, Invoice invoice) async {
    try {
      await _firestore.collection(_collection).doc(docId).update({
        ...invoice.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating user invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete an invoice by Firestore document ID.
  Future<bool> deleteInvoiceByDocId(String docId) async {
    try {
      await _firestore.collection(_collection).doc(docId).delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting user invoice: $e');
      return false;
    }
  }

  /// Update invoice using firestoreDocId (preferred) or fallback to id field
  Future<bool> updateInvoice(Invoice invoice) async {
    try {
      // ALWAYS use firestoreDocId if available (it's the actual Firestore document ID)
      if (invoice.firestoreDocId != null && invoice.firestoreDocId!.isNotEmpty) {
        debugPrint('✅ Updating user invoice by firestoreDocId: ${invoice.firestoreDocId}');
        return await updateInvoiceByDocId(invoice.firestoreDocId!, invoice);
      }
      
      // Fallback: use invoice.id as document ID (legacy behavior)
      debugPrint('⚠️ No firestoreDocId, using invoice.id as docId: ${invoice.id}');
      return await updateInvoiceByDocId(invoice.id, invoice);
    } catch (e, stackTrace) {
      debugPrint('❌ Error updating user invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete invoice by Firestore document ID
  Future<bool> deleteInvoice(String firestoreDocId) async {
    try {
      debugPrint('🗑️ Deleting user invoice by firestoreDocId: $firestoreDocId');
      await _firestore.collection(_collection).doc(firestoreDocId).delete();
      debugPrint('✅ Invoice deleted successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ Error deleting user invoice: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}


