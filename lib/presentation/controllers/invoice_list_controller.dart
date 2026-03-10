import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fineye/core/constants/app_routes.dart';
import 'package:fineye/core/services/snackbar_service.dart';
import 'package:fineye/data/repositories/user_invoice_repository.dart';
import 'package:fineye/data/services/auth_service.dart';
import 'package:fineye/data/models/invoice_model.dart';
import 'dashboard_controller.dart';
import '../../core/services/invoice_export_service.dart';

const double vatTolerance = 0.05;

class InvoiceListController extends GetxController {
  final UserInvoiceRepository _invoiceRepository = UserInvoiceRepository();
  final AuthService _authService = AuthService();

  // Stream subscription management
  StreamSubscription<List<Invoice>>? _invoiceStreamSubscription;

  // Search & Filter
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  // Risk Filter: all / with risk / no risk
  final RxString riskFilter = 'all'.obs;

  // Advanced Filters (from InvoiceFiltersController)
  final Rx<DateTime?> filterStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> filterEndDate = Rx<DateTime?>(null);
  final RxString filterSupplier = ''.obs;
  final RxString filterCategory = ''.obs;
  final RxList<String> filterStatuses = <String>[].obs;
  final RxString filterTaxType = 'All tax types'.obs;
  final RxDouble filterMinAmount = RxDouble(0.0);
  final RxDouble filterMaxAmount = RxDouble(0.0);

  // Saved Filters
  final RxList<Map<String, dynamic>> savedFilters =
      <Map<String, dynamic>>[].obs;
  final RxString defaultFilterName = 'VAT review'.obs;

  // Data
  final RxList<Invoice> invoices = <Invoice>[].obs;
  final RxList<Invoice> filteredInvoices = <Invoice>[].obs;
  final RxBool isLoading = false.obs;

  // Get saved filters count
  int get savedFiltersCount => savedFilters.length;

  // Get default filter name
  String get defaultFilterDisplayName => defaultFilterName.value;

  int get totalFlaggedInvoices => invoices.where((inv) => inv.hasRisk).length;

  int get missingTrnCount =>
      invoices
          .expand((inv) => inv.risks)
          .where((r) => r.type == InvoiceRiskType.missingTrn)
          .length;

  int get vatMismatchCount =>
      invoices
          .expand((inv) => inv.risks)
          .where((r) => r.type == InvoiceRiskType.vatMismatch)
          .length;

  int get duplicateCount =>
      invoices
          .expand((inv) => inv.risks)
          .where((r) => r.type == InvoiceRiskType.duplicateInvoice)
          .length;

  // Helper function to get translation key for category
  static String getCategoryTranslationKey(String category) {
    final Map<String, String> categoryKeys = {
      'Office supplies': 'cat_office_supplies',
      'Office Supplies': 'cat_office_supplies',
      'Utilities': 'cat_utilities',
      'Transport': 'cat_transport',
      'Subscriptions': 'cat_subscriptions',
      'Marketing': 'cat_marketing',
      'Professional fees': 'cat_professional_fees',
      'Professional Fees': 'cat_professional_fees',
      'Rent': 'cat_rent',
      'Maintenance': 'cat_maintenance',
      'Other': 'cat_other',
      'Product Sales': 'cat_other',
      'Service Revenue': 'cat_other',
      'Food & Beverage Sales': 'cat_other',
      'Delivery Revenue': 'cat_other',
      'Other Revenue': 'cat_other',
    };
    return categoryKeys[category] ?? 'cat_other';
  }

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
    loadSavedFilters();

    // Listen to search & filters
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _applyFilters();
    });
    ever(riskFilter, (_) => _applyFilters());
    ever(filterStartDate, (_) => _applyFilters());
    ever(filterEndDate, (_) => _applyFilters());
    ever(filterSupplier, (_) => _applyFilters());
    ever(filterCategory, (_) => _applyFilters());
    ever(filterStatuses, (_) => _applyFilters());
    ever(filterTaxType, (_) => _applyFilters());
    ever(filterMinAmount, (_) => _applyFilters());
    ever(filterMaxAmount, (_) => _applyFilters());
  }

  @override
  void onClose() {
    // Cancel stream subscription to prevent memory leaks and race conditions
    _invoiceStreamSubscription?.cancel();
    _invoiceStreamSubscription = null;
    searchController.dispose();
    super.onClose();
  }

  List<InvoiceRisk> assessInvoiceRisks(
    Invoice invoice,
    List<Invoice> allInvoices,
  ) {
    List<InvoiceRisk> identifiedRisks = [];

    // 1. Missing TRN Check (High Risk)
    if (invoice.isVatRegistered &&
        invoice.supplierName.toLowerCase().contains('unknown')) {
      identifiedRisks.add(
        const InvoiceRisk(
          type: InvoiceRiskType.missingTrn,
          severity: InvoiceRiskSeverity.high,
        ),
      );
    }

    // 2. VAT Mismatch Check (High Risk)
    // Check if VAT is approx 5% of Net Amount
    // Net = Gross - VAT
    // Expected VAT = Net * 0.05
    if (invoice.vatAmount > 0) {
      final double netAmount = invoice.grossAmount - invoice.vatAmount;
      final double expectedVat = netAmount * 0.05;
      final double difference = (invoice.vatAmount - expectedVat).abs();

      if (difference > vatTolerance) {
        identifiedRisks.add(
          const InvoiceRisk(
            type: InvoiceRiskType.vatMismatch,
            severity: InvoiceRiskSeverity.high,
          ),
        );
      }
    }

    // 3. Duplicate Invoice (Medium Risk)
    // Same Supplier + Same Date + Same Amount
    final bool isDuplicate = allInvoices.any(
      (other) =>
          other.id != invoice.id &&
          other.supplierName == invoice.supplierName &&
          other.date.isAtSameMomentAs(invoice.date) &&
          (other.grossAmount - invoice.grossAmount).abs() < 0.01,
    );

    if (isDuplicate) {
      identifiedRisks.add(
        const InvoiceRisk(
          type: InvoiceRiskType.duplicateInvoice,
          severity: InvoiceRiskSeverity.warning, // Medium
        ),
      );
    }

    // 4. Missing Critical Fields (Medium Risk)
    if (invoice.supplierName.isEmpty) {
      identifiedRisks.add(
        const InvoiceRisk(
          type: InvoiceRiskType.missingSupplier,
          severity: InvoiceRiskSeverity.warning,
        ),
      );
    }

    if (invoice.grossAmount <= 0) {
      identifiedRisks.add(
        const InvoiceRisk(
          type: InvoiceRiskType.missingAmount,
          severity: InvoiceRiskSeverity.warning,
        ),
      );
    }

    // 5. VAT Charged but Supplier Not Registered (High Risk)
    if (invoice.vatAmount > 0 && invoice.taxBadge == 'Exempt') {
      identifiedRisks.add(
        const InvoiceRisk(
          type: InvoiceRiskType.supplierNotRegistered,
          severity: InvoiceRiskSeverity.high,
        ),
      );
    }

    return identifiedRisks;
  }

  void loadInvoices() {
    final user = _authService.currentUser;
    if (user == null) {
      // No authenticated user; clear list and stop.
      _invoiceStreamSubscription?.cancel();
      _invoiceStreamSubscription = null;
      invoices.clear();
      filteredInvoices.clear();
      isLoading.value = false;
      SnackbarService.to.showError(
        'Error',
        'You must be logged in to view invoices.',
      );
      return;
    }

    // CRITICAL: Cancel previous subscription to prevent multiple active streams
    _invoiceStreamSubscription?.cancel();
    _invoiceStreamSubscription = null;

    isLoading.value = true;

    // Try to load with index first, fallback to without index if needed
    Stream<List<Invoice>> invoiceStream;
    try {
      invoiceStream = _invoiceRepository.getInvoicesForUser(user.uid);
    } catch (e) {
      // If initial setup fails, use fallback
      debugPrint('Using fallback query (no index): $e');
      invoiceStream = _invoiceRepository.getInvoicesForUserWithoutIndex(
        user.uid,
      );
    }

    // Listen to Firestore stream for this user's invoices in `user_invoices`.
    _invoiceStreamSubscription = invoiceStream.listen(
      (firestoreInvoices) {
        debugPrint(
          '📥 Invoice stream update: ${firestoreInvoices.length} invoices received',
        );

        // Assess risks for all invoices
        final updatedInvoices =
            firestoreInvoices.map((invoice) {
              final risks = assessInvoiceRisks(invoice, firestoreInvoices);
              return invoice.copyWith(risks: risks);
            }).toList();

        // Update invoices list
        invoices.assignAll(updatedInvoices);
        debugPrint(
          '✅ Updated invoices list: ${invoices.length} total invoices',
        );

        // Apply filters after updating invoices
        _applyFilters();
        isLoading.value = false;
      },
      onError: (error) {
        debugPrint('❌ Error loading invoices: $error');

        // Check if it's an index error - try fallback
        final errorStr = error.toString();
        if (errorStr.contains('index') ||
            errorStr.contains('failed-precondition')) {
          // Extract the index creation URL if present
          final urlMatch = RegExp(r'https://[^\s]+').firstMatch(errorStr);
          final indexUrl = urlMatch?.group(0);

          debugPrint('⚠️ Index error detected. Trying fallback query...');
          if (indexUrl != null) {
            debugPrint('🔗 Create index at: $indexUrl');
          }

          // Cancel current subscription before creating new one
          _invoiceStreamSubscription?.cancel();

          // Try fallback query without index
          try {
            _invoiceStreamSubscription = _invoiceRepository
                .getInvoicesForUserWithoutIndex(user.uid)
                .listen(
                  (firestoreInvoices) {
                    debugPrint(
                      '📥 Fallback stream update: ${firestoreInvoices.length} invoices received',
                    );

                    final updatedInvoices =
                        firestoreInvoices.map((invoice) {
                          final risks = assessInvoiceRisks(
                            invoice,
                            firestoreInvoices,
                          );
                          return invoice.copyWith(risks: risks);
                        }).toList();

                    invoices.assignAll(updatedInvoices);
                    debugPrint(
                      '✅ Updated invoices list (fallback): ${invoices.length} total invoices',
                    );

                    _applyFilters();
                    isLoading.value = false;

                    // Log that we're using fallback (don't show annoying banner)
                    debugPrint(
                      '⚠️ Using fallback query (no index). Create index for better performance.',
                    );
                  },
                  onError: (fallbackError) {
                    debugPrint('❌ Fallback query also failed: $fallbackError');
                    SnackbarService.to.showError(
                      'Error',
                      'Failed to load invoices. Please check your connection.',
                    );
                    invoices.clear();
                    filteredInvoices.clear();
                    isLoading.value = false;
                  },
                );
          } catch (e) {
            debugPrint('❌ Exception in fallback setup: $e');
            SnackbarService.to.showError(
              'Error',
              'Failed to load invoices: ${error.toString()}',
            );
            invoices.clear();
            filteredInvoices.clear();
            isLoading.value = false;
          }
        } else {
          SnackbarService.to.showError(
            'Error',
            'Failed to load invoices: ${error.toString()}',
          );
          invoices.clear();
          filteredInvoices.clear();
          isLoading.value = false;
        }
      },
    );
  }

  void _applyFilters() {
    // Start with all invoices
    var result = List<Invoice>.from(invoices);

    debugPrint('🔍🔍🔍 APPLYING FILTERS TO ${result.length} INVOICES 🔍🔍🔍');
    debugPrint('  Filter state:');
    debugPrint(
      '    Supplier: "${filterSupplier.value}" (isEmpty: ${filterSupplier.value.isEmpty})',
    );
    debugPrint(
      '    Category: "${filterCategory.value}" (isEmpty: ${filterCategory.value.isEmpty})',
    );
    debugPrint(
      '    Statuses: ${filterStatuses.toList()} (count: ${filterStatuses.length})',
    );
    debugPrint('    Tax Type: "${filterTaxType.value}"');
    debugPrint('    Min Amount: ${filterMinAmount.value}');
    debugPrint('    Max Amount: ${filterMaxAmount.value}');
    debugPrint('    Start Date: ${filterStartDate.value}');
    debugPrint('    End Date: ${filterEndDate.value}');

    // Debug: Show sample invoice data
    if (invoices.isNotEmpty) {
      debugPrint('  Sample invoice data:');
      invoices.take(3).forEach((inv) {
        debugPrint(
          '    - Supplier: "${inv.supplierName}", Category: "${inv.category}", Status: "${inv.status}", Tax: "${inv.taxBadge}"',
        );
      });
    }

    // Apply search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result =
          result
              .where(
                (inv) =>
                    inv.supplierName.toLowerCase().contains(query) ||
                    inv.id.toLowerCase().contains(query) ||
                    inv.grossAmount.toString().contains(query),
              )
              .toList();
      debugPrint('  ✅ After search: ${result.length} invoices');
    }

    // Apply risk filter
    if (riskFilter.value == 'with_risk') {
      result = result.where((inv) => inv.hasRisk).toList();
      debugPrint(
        '  ✅ After risk filter (with_risk): ${result.length} invoices',
      );
    } else if (riskFilter.value == 'no_risk') {
      result = result.where((inv) => !inv.hasRisk).toList();
      debugPrint('  ✅ After risk filter (no_risk): ${result.length} invoices');
    }

    // Date filters
    if (filterStartDate.value != null) {
      final startDate = filterStartDate.value!;
      final beforeCount = result.length;
      result =
          result.where((inv) {
            // Include invoices on or after start date
            return inv.date.isAfter(
                  startDate.subtract(const Duration(days: 1)),
                ) ||
                inv.date.isAtSameMomentAs(startDate);
          }).toList();
      debugPrint(
        '  ✅ After start date: ${result.length} invoices (was $beforeCount)',
      );
    }
    if (filterEndDate.value != null) {
      final endDate = filterEndDate.value!;
      final beforeCount = result.length;
      result =
          result.where((inv) {
            // Include invoices on or before end date
            return inv.date.isBefore(endDate.add(const Duration(days: 1))) ||
                inv.date.isAtSameMomentAs(endDate);
          }).toList();
      debugPrint(
        '  ✅ After end date: ${result.length} invoices (was $beforeCount)',
      );
    }

    // Supplier filter - COMPLETELY REBUILT
    final supplierFilter = filterSupplier.value.trim();
    if (supplierFilter.isNotEmpty && supplierFilter != 'All suppliers') {
      final beforeCount = result.length;
      debugPrint('  🔍 SUPPLIER FILTER: "$supplierFilter"');

      result =
          result.where((inv) {
            final invSupplier = inv.supplierName.trim();
            final invLower = invSupplier.toLowerCase();
            final filterLower = supplierFilter.toLowerCase();

            // Try exact match first
            if (invLower == filterLower) {
              debugPrint(
                '    ✅ Exact match: "$invSupplier" == "$supplierFilter"',
              );
              return true;
            }

            // Try contains match
            if (invLower.contains(filterLower) ||
                filterLower.contains(invLower)) {
              debugPrint(
                '    ✅ Contains match: "$invSupplier" contains "$supplierFilter"',
              );
              return true;
            }

            return false;
          }).toList();

      debugPrint(
        '  ✅ After supplier filter: ${result.length} invoices (was $beforeCount)',
      );
      if (result.isEmpty && beforeCount > 0) {
        debugPrint('    ❌ NO MATCHES! Available suppliers:');
        invoices.map((inv) => inv.supplierName.trim()).toSet().take(10).forEach(
          (s) {
            debugPrint('      - "$s"');
          },
        );
      }
    }

    // Category filter - COMPLETELY REBUILT
    final categoryFilter = filterCategory.value.trim();
    if (categoryFilter.isNotEmpty && categoryFilter != 'All categories') {
      final beforeCount = result.length;
      debugPrint('  🔍 CATEGORY FILTER: "$categoryFilter"');

      result =
          result.where((inv) {
            final invCategory = inv.category.trim();
            final invLower = invCategory.toLowerCase();
            final filterLower = categoryFilter.toLowerCase();

            final matches = invLower == filterLower;
            if (matches) {
              debugPrint('    ✅ Match: "$invCategory" == "$categoryFilter"');
            }
            return matches;
          }).toList();

      debugPrint(
        '  ✅ After category filter: ${result.length} invoices (was $beforeCount)',
      );
      if (result.isEmpty && beforeCount > 0) {
        debugPrint('    ❌ NO MATCHES! Available categories:');
        invoices.map((inv) => inv.category.trim()).toSet().take(10).forEach((
          c,
        ) {
          debugPrint('      - "$c"');
        });
        debugPrint('    Looking for: "$categoryFilter"');
      }
    }

    // Status filter - COMPLETELY REBUILT
    if (filterStatuses.isNotEmpty) {
      final beforeCount = result.length;
      final statusFilters =
          filterStatuses.map((s) => s.trim().toLowerCase()).toList();
      debugPrint('  🔍 STATUS FILTER: $statusFilters');

      result =
          result.where((inv) {
            final invStatus = inv.status.trim().toLowerCase();
            final matches = statusFilters.contains(invStatus);
            if (matches) {
              debugPrint('    ✅ Match: "$invStatus" in $statusFilters');
            }
            return matches;
          }).toList();

      debugPrint(
        '  ✅ After status filter: ${result.length} invoices (was $beforeCount)',
      );
      if (result.isEmpty && beforeCount > 0) {
        debugPrint('    ❌ NO MATCHES! Available statuses:');
        invoices.map((inv) => inv.status.trim()).toSet().forEach((s) {
          debugPrint('      - "$s"');
        });
        debugPrint('    Looking for: $statusFilters');
      }
    }

    // Tax type filter - COMPLETELY REBUILT
    final taxTypeFilter = filterTaxType.value.trim();
    if (taxTypeFilter.isNotEmpty && taxTypeFilter != 'All tax types') {
      final beforeCount = result.length;
      debugPrint('  🔍 TAX TYPE FILTER: "$taxTypeFilter"');

      result =
          result.where((inv) {
            final invTaxBadge = inv.taxBadge.trim();
            final invLower = invTaxBadge.toLowerCase();
            final filterLower = taxTypeFilter.toLowerCase();

            final matches = invLower == filterLower;
            if (!matches) {
              debugPrint('    ❌ Mismatch: "$invTaxBadge" != "$taxTypeFilter"');
            } else {
              debugPrint('    ✅ Match: "$invTaxBadge" == "$taxTypeFilter"');
            }
            return matches;
          }).toList();

      debugPrint(
        '  ✅ After tax type filter: ${result.length} invoices (was $beforeCount)',
      );
      if (result.isEmpty && beforeCount > 0) {
        debugPrint('    ❌ NO MATCHES! Available tax badges:');
        invoices.map((inv) => inv.taxBadge.trim()).toSet().forEach((t) {
          debugPrint('      - "$t"');
        });
        debugPrint('    Looking for: "$taxTypeFilter"');
      }
    }

    // Amount filters
    if (filterMinAmount.value > 0) {
      final beforeCount = result.length;
      result =
          result
              .where((inv) => inv.grossAmount >= filterMinAmount.value)
              .toList();
      debugPrint(
        '  ✅ After min amount (${filterMinAmount.value}): ${result.length} invoices (was $beforeCount)',
      );
    }
    if (filterMaxAmount.value > 0) {
      final beforeCount = result.length;
      result =
          result
              .where((inv) => inv.grossAmount <= filterMaxAmount.value)
              .toList();
      debugPrint(
        '  ✅ After max amount (${filterMaxAmount.value}): ${result.length} invoices (was $beforeCount)',
      );
    }

    // Always update filteredInvoices, even if empty
    filteredInvoices.assignAll(result);
    debugPrint(
      '🎯 FINAL RESULT: ${result.length} invoices shown out of ${invoices.length} total',
    );
  }

  Future<void> toggleFlag(Invoice invoice) async {
    invoice.isFlagged.value = !invoice.isFlagged.value;

    // Update in Firestore
    final updatedInvoice = invoice.copyWith(isFlagged: invoice.isFlagged.value);
    final success = await _invoiceRepository.updateInvoice(updatedInvoice);

    if (!success) {
      // Revert if update failed
      invoice.isFlagged.value = !invoice.isFlagged.value;
      SnackbarService.to.showError(
        'title_error'.tr,
        'msg_flag_update_failed'.tr,
      );
    }
  }

  void setRiskFilter(String value) {
    riskFilter.value = value;
  }

  void showFilterOptions() async {
    final result = await Get.toNamed(AppRoutes.invoiceFilters);
    if (result != null && result is Map) {
      debugPrint('🔍 Received filter result: $result');

      // Apply filters from result
      filterStartDate.value = result['startDate'] as DateTime?;
      filterEndDate.value = result['endDate'] as DateTime?;

      // Handle supplier - convert null or "All suppliers" to empty string
      final supplierValue = result['supplier'] as String?;
      if (supplierValue == null ||
          supplierValue.isEmpty ||
          supplierValue == 'All suppliers') {
        filterSupplier.value = '';
      } else {
        filterSupplier.value = supplierValue.trim(); // Trim whitespace
      }
      debugPrint(
        '  - Supplier filter set to: "${filterSupplier.value}" (original: "$supplierValue")',
      );

      // Handle category - convert null or "All categories" to empty string
      final categoryValue = result['category'] as String?;
      if (categoryValue == null ||
          categoryValue.isEmpty ||
          categoryValue == 'All categories') {
        filterCategory.value = '';
      } else {
        filterCategory.value = categoryValue.trim(); // Trim whitespace
      }
      debugPrint(
        '  - Category filter set to: "${filterCategory.value}" (original: "$categoryValue")',
      );

      final statusList =
          (result['statuses'] as List<dynamic>?)?.cast<String>() ?? [];
      filterStatuses.assignAll(statusList.map((s) => s.trim()).toList());
      debugPrint('  - Status filters: ${filterStatuses.toList()}');

      // Handle tax type - convert null to "All tax types"
      final taxTypeValue = result['taxType'] as String?;
      if (taxTypeValue == null ||
          taxTypeValue.trim().isEmpty ||
          taxTypeValue == 'All tax types') {
        filterTaxType.value = 'All tax types';
      } else {
        filterTaxType.value = taxTypeValue.trim(); // Trim whitespace
      }
      debugPrint(
        '  - Tax type filter set to: "${filterTaxType.value}" (original: "$taxTypeValue")',
      );

      // Parse amount filters - handle "AED 1000" format
      final minAmountStr = result['minAmount'] as String? ?? '';
      final maxAmountStr = result['maxAmount'] as String? ?? '';

      // Extract numbers from strings (handles "AED 1000", "1000", "1,000", etc.)
      double? parseAmount(String? str) {
        if (str == null || str.isEmpty) return 0.0;
        // Remove currency symbols, commas, and whitespace
        final cleaned = str.replaceAll(RegExp(r'[AED\s,]+'), '').trim();
        return double.tryParse(cleaned) ?? 0.0;
      }

      filterMinAmount.value = parseAmount(minAmountStr) ?? 0.0;
      filterMaxAmount.value = parseAmount(maxAmountStr) ?? 0.0;
      debugPrint(
        '  - Amount range: ${filterMinAmount.value} - ${filterMaxAmount.value} (from "$minAmountStr" / "$maxAmountStr")',
      );

      // Reapply filters
      _applyFilters();

      SnackbarService.to.showInfo(
        'title_filters_applied'.tr,
        'msg_filters_applied_success'.tr,
      );
    }
  }

  void loadSavedFilters() {
    // Load saved filters from SharedPreferences or Firestore
    // For now, initialize with default filter
    if (savedFilters.isEmpty) {
      savedFilters.add({
        'name': 'VAT review',
        'isDefault': true,
        'filters': {
          'statuses': ['Pending', 'Review'],
          'taxType': 'VAT 5%',
        },
      });
      defaultFilterName.value = 'VAT review';
    }
  }

  void saveCurrentFilter(String name) {
    final filter = {
      'name': name,
      'isDefault': savedFilters.isEmpty,
      'filters': {
        'startDate': filterStartDate.value?.millisecondsSinceEpoch,
        'endDate': filterEndDate.value?.millisecondsSinceEpoch,
        'supplier': filterSupplier.value,
        'category': filterCategory.value,
        'statuses': filterStatuses.toList(),
        'taxType': filterTaxType.value,
        'minAmount': filterMinAmount.value,
        'maxAmount': filterMaxAmount.value,
      },
    };
    savedFilters.add(filter);
    if (filter['isDefault'] == true) {
      defaultFilterName.value = name;
    }
    // TODO: Persist to SharedPreferences or Firestore
  }

  Future<void> exportInvoices() async {
    // Show a dialog to choose between VAT Summary (Compliance) and Quick Export (Current List)
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Get.back();
                performQuickExport();
              },
              icon: const Icon(Icons.table_view, color: Colors.white),
              label: const Text(
                'Quick Export (Current List)',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF002060),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Get.back();
                if (Get.isRegistered<DashboardController>()) {
                  Get.find<DashboardController>().showReadinessChecklist();
                } else {
                  SnackbarService.to.showError(
                    'title_error'.tr,
                    'msg_dashboard_not_available'.tr,
                  );
                }
              },
              icon: const Icon(Icons.verified_user),
              label: Text('btn_full_vat_summary'.tr),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> performQuickExport() async {
    if (filteredInvoices.isEmpty) {
      SnackbarService.to.showInfo(
        'title_empty_list'.tr,
        'msg_no_invoices_to_export'.tr,
      );
      return;
    }

    SnackbarService.to.showInfo('title_exporting'.tr, 'msg_preparing_excel'.tr);

    try {
      final path = await InvoiceExportService.exportToExcel(filteredInvoices);
      if (path != null) {
        // Share is handled inside the service now
        debugPrint('✅ Export handled via share sheet');
      }
    } catch (e) {
      debugPrint('❌ Export error: $e');
      SnackbarService.to.showError(
        'title_export_failed'.tr,
        'msg_export_error'.tr,
      );
    }
  }

  // Refresh invoices manually
  Future<void> refreshInvoices() async {
    debugPrint('🔄 Manual refresh triggered');
    // Cancel existing subscription and reload
    _invoiceStreamSubscription?.cancel();
    _invoiceStreamSubscription = null;
    loadInvoices();
  }

  // Delete an invoice
  Future<void> deleteInvoice(Invoice invoice) async {
    try {
      // Use firestoreDocId if available, otherwise fallback to invoice.id
      final docId = invoice.firestoreDocId ?? invoice.id;
      debugPrint('🗑️ Deleting invoice with docId: $docId');

      final success = await _invoiceRepository.deleteInvoice(docId);
      if (success) {
        SnackbarService.to.showSuccess(
          'title_success'.tr,
          'msg_invoice_deleted_success'.tr,
        );
        // The invoice list will automatically update via the Firestore stream
      } else {
        SnackbarService.to.showError(
          'title_error'.tr,
          'msg_delete_invoice_failed'.tr,
        );
      }
    } catch (e) {
      debugPrint('❌ Error deleting invoice: $e');
      SnackbarService.to.showError(
        'title_error'.tr,
        'msg_delete_invoice_failed'.tr,
      );
    }
  }
}
