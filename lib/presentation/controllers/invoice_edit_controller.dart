import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/user_invoice_repository.dart';
import '../../../core/services/snackbar_service.dart';
import 'invoice_list_controller.dart';
import 'dashboard_controller.dart';

class InvoiceEditController extends GetxController {
  final UserInvoiceRepository _invoiceRepository = UserInvoiceRepository();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // The invoice being edited
  late Invoice invoice;
  
  // Text Controllers - these are the ONLY source of truth
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController invoiceNumberController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController netAmountController = TextEditingController();
  final TextEditingController additionalChargesController = TextEditingController();
  
  // Simple state - no reactive interference
  DateTime? invoiceDate;
  String selectedCategory = '';
  bool isCtDeductible = true;
  bool isPaid = false;
  DateTime? dueDate;
  
  // Calculated values (read-only display)
  double get vatAmount {
    final net = _parseAmount(netAmountController.text);
    return (net * 0.05 * 100).roundToDouble() / 100;
  }
  
  double get grossAmount {
    final net = _parseAmount(netAmountController.text);
    return net + vatAmount;
  }
  
  double get finalTotal => grossAmount + _parseAmount(additionalChargesController.text);
  
  final List<String> categories = [
    'Office supplies',
    'Utilities',
    'Transport',
    'Subscriptions',
    'Marketing',
    'Professional fees',
    'Rent',
    'Maintenance',
    'Other',
  ];
  
  @override
  void onInit() {
    super.onInit();
    
    // Get invoice from arguments
    if (Get.arguments != null && Get.arguments is Invoice) {
      invoice = Get.arguments as Invoice;
      _loadInvoiceData();
    } else {
      throw Exception('Invoice is required to edit');
    }
  }
  
  void _loadInvoiceData() {
    // Load all data into controllers and simple variables
    supplierController.text = invoice.supplierName;
    invoiceNumberController.text = invoice.id;
    notesController.text = invoice.notes;
    invoiceDate = invoice.date;
    selectedCategory = invoice.category;
    isCtDeductible = invoice.isCtDeductible;
    isPaid = invoice.status == 'Paid';
    dueDate = invoice.dueDate;
    
    // Calculate net from gross and VAT
    final net = invoice.grossAmount - invoice.vatAmount;
    netAmountController.text = net.toStringAsFixed(2);
    additionalChargesController.text = invoice.additionalCharges.toStringAsFixed(2);
  }
  
  double _parseAmount(String text) {
    final cleaned = text.replaceAll('AED', '').replaceAll(',', '').replaceAll(' ', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
  
  Future<void> selectDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: invoiceDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      invoiceDate = picked;
      update(); // Trigger UI update
    }
  }
  
  Future<void> selectDueDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      dueDate = picked;
      update(); // Trigger UI update
    }
  }
  
  void setCategory(String category) {
    selectedCategory = category;
    update();
  }
  
  void toggleCtDeductible() {
    isCtDeductible = !isCtDeductible;
    update();
  }
  
  void setPaymentStatus(bool paid) {
    isPaid = paid;
    if (paid) {
      dueDate = null; // Clear due date if paid
    }
    update();
  }
  
  String getLocalizedCategory(String cat) {
    switch (cat) {
      case 'Office supplies': return 'cat_office_supplies'.tr;
      case 'Utilities': return 'cat_utilities'.tr;
      case 'Transport': return 'cat_transport'.tr;
      case 'Subscriptions': return 'cat_subscriptions'.tr;
      case 'Marketing': return 'cat_marketing'.tr;
      case 'Professional fees': return 'cat_professional_fees'.tr;
      case 'Rent': return 'cat_rent'.tr;
      case 'Maintenance': return 'cat_maintenance'.tr;
      case 'Other': return 'cat_other'.tr;
      default: return cat;
    }
  }
  
  Future<void> saveInvoice() async {
    // Validate required fields
    if (supplierController.text.trim().isEmpty) {
      SnackbarService.to.showError('error'.tr, 'supplier_required'.tr);
      return;
    }
    
    if (invoiceNumberController.text.trim().isEmpty) {
      SnackbarService.to.showError('error'.tr, 'invoice_number_required'.tr);
      return;
    }
    
    if (invoiceDate == null) {
      SnackbarService.to.showError('error'.tr, 'invoice_date_required'.tr);
      return;
    }
    
    final net = _parseAmount(netAmountController.text);
    if (net <= 0) {
      SnackbarService.to.showError('error'.tr, 'net_amount_gt_zero'.tr);
      return;
    }
    
    // Validate due date if unpaid
    if (!isPaid && dueDate == null) {
      SnackbarService.to.showError('error'.tr, 'due_date_required'.tr);
      return;
    }
    
    try {
      // Get current user
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        SnackbarService.to.showError('error'.tr, 'must_login'.tr);
        return;
      }
      
      // Calculate amounts
      final vat = vatAmount;
      final gross = grossAmount;
      final additional = _parseAmount(additionalChargesController.text);
      
      // Determine status
      final status = isPaid ? 'Paid' : 'Pending';
      
      // Get all invoices for risk assessment
      List<Invoice> allInvoices = [];
      if (Get.isRegistered<InvoiceListController>()) {
        allInvoices = Get.find<InvoiceListController>().invoices.toList();
      }
      
      // Assess risks
      List<InvoiceRisk> updatedRisks = [];
      if (Get.isRegistered<InvoiceListController>()) {
        final listController = Get.find<InvoiceListController>();
        final tempInvoice = Invoice(
          id: invoiceNumberController.text.trim(),
          supplierName: supplierController.text.trim(),
          category: selectedCategory,
          date: invoiceDate!,
          grossAmount: gross,
          vatAmount: vat,
          additionalCharges: additional,
          status: status,
          taxBadge: invoice.taxBadge,
          notes: notesController.text.trim(),
          isCtDeductible: isCtDeductible,
          vatActivity: invoice.vatActivity,
          dueDate: isPaid ? null : dueDate,
        );
        updatedRisks = listController.assessInvoiceRisks(tempInvoice, allInvoices);
      }
      
      // Create updated invoice
      final updatedInvoice = Invoice(
        id: invoiceNumberController.text.trim(),
        supplierName: supplierController.text.trim(),
        category: selectedCategory,
        date: invoiceDate!,
        grossAmount: gross,
        vatAmount: vat,
        additionalCharges: additional,
        status: status,
        taxBadge: invoice.taxBadge,
        notes: notesController.text.trim(),
        isCtDeductible: isCtDeductible,
        vatActivity: invoice.vatActivity,
        dueDate: isPaid ? null : dueDate,
        userId: invoice.userId.isNotEmpty ? invoice.userId : currentUser.uid,
        imageUrl: invoice.imageUrl,
        firestoreDocId: invoice.firestoreDocId,
        risks: updatedRisks,
        isFlagged: invoice.isFlagged.value,
      );
      
      // Update in Firestore - MUST use firestoreDocId to update existing invoice
      String? docId = invoice.firestoreDocId;
      
      // If no firestoreDocId, try to find the document by invoice ID
      if (docId == null || docId.isEmpty) {
        debugPrint('⚠️ No firestoreDocId found, trying to find by invoice ID: ${invoice.id}');
        // Try to get the document ID by querying
        try {
          final query = await _firestore
              .collection('user_invoices')
              .where('id', isEqualTo: invoice.id)
              .where('userId', isEqualTo: currentUser.uid)
              .limit(1)
              .get();
          
          if (query.docs.isNotEmpty) {
            docId = query.docs.first.id;
            debugPrint('✅ Found document ID: $docId');
          } else {
            debugPrint('❌ No document found with invoice ID: ${invoice.id}');
            SnackbarService.to.showError('error'.tr, 'invoice_not_found'.tr);
            return;
          }
        } catch (e) {
          debugPrint('❌ Error finding document: $e');
          SnackbarService.to.showError('error'.tr, 'failed_to_find_invoice'.trParams({'error': e.toString()}));
          return;
        }
      }
      
      debugPrint('💾 Updating invoice with docId: $docId');
      debugPrint('   Invoice ID: ${updatedInvoice.id}');
      debugPrint('   Supplier: ${updatedInvoice.supplierName}');
      debugPrint('   Amount: ${updatedInvoice.grossAmount}');
      
      final success = await _invoiceRepository.updateInvoiceByDocId(docId!, updatedInvoice);
      
      if (success) {
        debugPrint('✅ Invoice updated successfully!');
        SnackbarService.to.showSuccess('success'.tr, 'invoice_updated_success'.tr);
        
        // Refresh invoice list and dashboard
        if (Get.isRegistered<InvoiceListController>()) {
          await Get.find<InvoiceListController>().refreshInvoices();
        }
        if (Get.isRegistered<DashboardController>()) {
          Get.find<DashboardController>().loadDashboardData();
        }
        
        // Navigate back after a short delay
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back();
      } else {
        debugPrint('❌ Failed to update invoice');
        SnackbarService.to.showError('error'.tr, 'failed_to_update_invoice'.tr);
      }
    } catch (e) {
      SnackbarService.to.showError('error'.tr, 'failed_to_save'.trParams({'error': e.toString()}));
    }
  }
  
  @override
  void onClose() {
    supplierController.dispose();
    invoiceNumberController.dispose();
    notesController.dispose();
    netAmountController.dispose();
    additionalChargesController.dispose();
    super.onClose();
  }
}
