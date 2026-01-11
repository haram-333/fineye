import 'package:flutter/foundation.dart';
import 'package:fineye/data/repositories/invoice_repository.dart';
import 'package:fineye/data/models/invoice_model.dart';

/// Helper script to manually add sample invoice data to Firestore
/// 
/// Usage:
/// 1. Import this file in your app (e.g., in a debug menu or initialization)
/// 2. Call seedSampleInvoices() to add sample data
/// 
/// Example:
/// ```dart
/// import 'package:fineye/data/helpers/seed_invoice_data.dart';
/// 
/// // In your code:
/// await seedSampleInvoices();
/// ```
Future<bool> seedSampleInvoices() async {
  final repository = InvoiceRepository();
  final now = DateTime.now();
  
  final sampleInvoices = [
    Invoice(
      id: 'INV-${now.year}-${now.month.toString().padLeft(2, '0')}-001',
      supplierName: 'ABC Trading LLC',
      category: 'Office supplies',
      date: now.subtract(const Duration(days: 2)),
      grossAmount: 1250.00,
      vatAmount: 59.52,
      status: 'Paid',
      taxBadge: 'VAT 5%',
      notes: 'Monthly stationery',
      isCtDeductible: true,
      vatActivity: 'High',
      isFlagged: false,
    ),
    Invoice(
      id: 'INV-847392',
      supplierName: 'Unknown Supplier',
      category: 'Utilities',
      date: now.subtract(const Duration(days: 5)),
      grossAmount: 3480.00,
      vatAmount: 165.71,
      status: 'Pending',
      taxBadge: 'Zero-rate',
      notes: 'Water & Electricity',
      isCtDeductible: false,
      vatActivity: 'Medium',
      isFlagged: true,
    ),
    Invoice(
      id: 'INV-102948',
      supplierName: 'Gulf Logistics',
      category: 'Transport',
      date: now.subtract(const Duration(days: 8)),
      grossAmount: 12980.00,
      vatAmount: 618.10,
      status: 'Paid',
      taxBadge: 'VAT 5%',
      notes: 'Q2 Shipping',
      isCtDeductible: true,
      vatActivity: 'High',
      isFlagged: false,
    ),
    Invoice(
      id: 'INV-102948-DUP',
      supplierName: 'Gulf Logistics',
      category: 'Transport',
      date: now.subtract(const Duration(days: 8)),
      grossAmount: 12980.00,
      vatAmount: 618.10,
      status: 'Pending',
      taxBadge: 'VAT 5%',
      notes: 'Duplicate Entry',
      isCtDeductible: true,
      vatActivity: 'High',
      isFlagged: false,
    ),
    Invoice(
      id: 'INV-553210',
      supplierName: 'Cloud Services ME',
      category: 'Subscriptions',
      date: now.subtract(const Duration(days: 12)),
      grossAmount: 1000.00,
      vatAmount: 100.00, // Error: Should be ~47.62 for 5% VAT
      status: 'Review',
      taxBadge: 'Exempt', // Error: Exempt but has VAT
      notes: 'Software license',
      isCtDeductible: false,
      vatActivity: 'Low',
      isFlagged: false,
    ),
    Invoice(
      id: 'INV-789456',
      supplierName: 'Tech Solutions UAE',
      category: 'Professional fees',
      date: now.subtract(const Duration(days: 15)),
      grossAmount: 5000.00,
      vatAmount: 238.10,
      status: 'Paid',
      taxBadge: 'VAT 5%',
      notes: 'Consulting services',
      isCtDeductible: true,
      vatActivity: 'High',
      isFlagged: false,
    ),
    Invoice(
      id: 'INV-321654',
      supplierName: 'Office Rentals LLC',
      category: 'Rent',
      date: now.subtract(const Duration(days: 20)),
      grossAmount: 15000.00,
      vatAmount: 714.29,
      status: 'Paid',
      taxBadge: 'VAT 5%',
      notes: 'Monthly office rent',
      isCtDeductible: true,
      vatActivity: 'High',
      isFlagged: false,
    ),
    Invoice(
      id: 'INV-987123',
      supplierName: 'Marketing Pro',
      category: 'Marketing',
      date: now.subtract(const Duration(days: 25)),
      grossAmount: 8500.00,
      vatAmount: 404.76,
      status: 'Review',
      taxBadge: 'VAT 5%',
      notes: 'Digital marketing campaign',
      isCtDeductible: true,
      vatActivity: 'Medium',
      isFlagged: false,
    ),
  ];

  try {
    debugPrint('Attempting to add ${sampleInvoices.length} sample invoices to Firestore...');
    final success = await repository.addInvoices(sampleInvoices);
    if (success) {
      debugPrint('✅ Successfully added ${sampleInvoices.length} sample invoices to Firestore');
    } else {
      debugPrint('❌ Failed to add sample invoices to Firestore - repository returned false');
    }
    return success;
  } catch (e, stackTrace) {
    debugPrint('❌ Error adding sample invoices: $e');
    debugPrint('Stack trace: $stackTrace');
    return false;
  }
}

