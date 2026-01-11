import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

enum InvoiceRiskType {
  missingTrn,
  supplierNotRegistered,
  duplicateInvoice,
  vatMismatch,
  missingSupplier,
  missingDate,
  missingAmount,
  vatCalculationError,
}

enum InvoiceRiskSeverity {
  warning, // Medium Risk (Amber)
  high,    // High Risk (Red)
  low,     // Low Risk (Blue)
}

class InvoiceRisk {
  final InvoiceRiskType type;
  final InvoiceRiskSeverity severity;

  const InvoiceRisk({
    required this.type,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'severity': severity.name,
    };
  }

  factory InvoiceRisk.fromMap(Map<String, dynamic> map) {
    return InvoiceRisk(
      type: InvoiceRiskType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InvoiceRiskType.missingAmount,
      ),
      severity: InvoiceRiskSeverity.values.firstWhere(
        (e) => e.name == map['severity'],
        orElse: () => InvoiceRiskSeverity.low,
      ),
    );
  }
}

class Invoice {
  /// Human-readable invoice identifier (e.g. "INV-123").
  /// This is what is currently shown in the UI as invoice number.
  final String id;

  final String supplierName;
  final String category;
  final DateTime date;
  final double grossAmount;
  final double vatAmount;
  final double additionalCharges; // Delivery, service charges, etc.
  final String status; // Paid, Pending, Review
  final String taxBadge; // VAT 5%, Zero-rate, Exempt
  final String notes;
  final bool isCtDeductible;
  final String vatActivity; // High, Medium, Low

  /// Optional Firestore user id (uid) of the owner of this invoice.
  /// Used for the `user_invoices` collection to scope invoices per user.
  final String userId;

  /// Optional URL of the stored invoice image (e.g. in Firebase Storage).
  /// This allows the invoice detail screen to show the original image.
  final String? imageUrl;

  /// Firestore document ID for this invoice in the `user_invoices` collection.
  /// This is different from the human-readable `id` field (invoice number).
  /// Used to update/delete the correct document even if invoice number changes.
  final String? firestoreDocId;

  List<InvoiceRisk> risks;
  RxBool isFlagged;

  // Helper for safe supplier access
  bool get isVatRegistered => taxBadge.contains('VAT') || vatAmount > 0;

  Invoice({
    required this.id,
    required this.supplierName,
    required this.category,
    required this.date,
    required this.grossAmount,
    required this.vatAmount,
    this.additionalCharges = 0.0,
    required this.status,
    required this.taxBadge,
    required this.notes,
    required this.isCtDeductible,
    required this.vatActivity,
    this.userId = '',
    this.imageUrl,
    this.firestoreDocId,
    this.risks = const [],
    bool isFlagged = false,
  }) : isFlagged = isFlagged.obs;

  bool get hasRisk => risks.isNotEmpty;

  bool get hasHighRisk => risks.any((r) => r.severity == InvoiceRiskSeverity.high);

  // Convert Invoice to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierName': supplierName,
      'category': category,
      'date': Timestamp.fromDate(date),
      'grossAmount': grossAmount,
      'vatAmount': vatAmount,
      'additionalCharges': additionalCharges,
      'status': status,
      'taxBadge': taxBadge,
      'notes': notes,
      'isCtDeductible': isCtDeductible,
      'vatActivity': vatActivity,
      'userId': userId,
      'imageUrl': imageUrl,
      'risks': risks.map((r) => r.toMap()).toList(),
      'isFlagged': isFlagged.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create Invoice from Firestore Document
  factory Invoice.fromMap(Map<String, dynamic> map, String documentId) {
    return Invoice(
      id: map['id'] ?? documentId,
      supplierName: map['supplierName'] ?? '',
      category: map['category'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grossAmount: (map['grossAmount'] as num?)?.toDouble() ?? 0.0,
      vatAmount: (map['vatAmount'] as num?)?.toDouble() ?? 0.0,
      additionalCharges: (map['additionalCharges'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      taxBadge: map['taxBadge'] ?? 'VAT 5%',
      notes: map['notes'] ?? '',
      isCtDeductible: map['isCtDeductible'] ?? true,
      vatActivity: map['vatActivity'] ?? 'Low',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] as String?,
      firestoreDocId: documentId, // Store the Firestore document ID
      risks: (map['risks'] as List<dynamic>?)
              ?.map((r) => InvoiceRisk.fromMap(r as Map<String, dynamic>))
              .toList() ??
          [],
      isFlagged: map['isFlagged'] ?? false,
    );
  }

  // Create Invoice from Firestore DocumentSnapshot
  factory Invoice.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Invoice.fromMap(data, doc.id);
  }

  // Create a copy of Invoice with updated fields
  Invoice copyWith({
    String? id,
    String? supplierName,
    String? category,
    DateTime? date,
    double? grossAmount,
    double? vatAmount,
    double? additionalCharges,
    String? status,
    String? taxBadge,
    String? notes,
    bool? isCtDeductible,
    String? vatActivity,
    List<InvoiceRisk>? risks,
    String? userId,
    String? imageUrl,
    String? firestoreDocId,
    bool? isFlagged,
  }) {
    return Invoice(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      category: category ?? this.category,
      date: date ?? this.date,
      grossAmount: grossAmount ?? this.grossAmount,
      vatAmount: vatAmount ?? this.vatAmount,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      status: status ?? this.status,
      taxBadge: taxBadge ?? this.taxBadge,
      notes: notes ?? this.notes,
      isCtDeductible: isCtDeductible ?? this.isCtDeductible,
      vatActivity: vatActivity ?? this.vatActivity,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      risks: risks ?? this.risks,
      isFlagged: isFlagged ?? this.isFlagged.value,
    );
  }
}

