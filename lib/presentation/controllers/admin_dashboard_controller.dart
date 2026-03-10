import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

class AdminUserMetric {
  const AdminUserMetric({
    required this.uid,
    required this.companyName,
    required this.email,
    required this.invoiceCount,
    required this.lastActiveAt,
    required this.appOpenCount,
    required this.screenViewCount,
  });

  final String uid;
  final String companyName;
  final String email;
  final int invoiceCount;
  final DateTime? lastActiveAt;
  final int appOpenCount;
  final int screenViewCount;
}

class AdminDashboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final isLoading = false.obs;
  final isAuthorized = false.obs;
  final errorMessage = ''.obs;

  final registeredUsers = 0.obs;
  final activeUsersToday = 0.obs;
  final activeUsers7Days = 0.obs;
  final totalInvoices = 0.obs;
  final totalAppOpens = 0.obs;
  final totalScreenViews = 0.obs;

  final userMetrics = <AdminUserMetric>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final user = _auth.currentUser;
      if (user == null) {
        isAuthorized.value = false;
        errorMessage.value = 'Please sign in first.';
        return;
      }

      final tokenResult = await user.getIdTokenResult(true);
      final email = (user.email ?? '').trim().toLowerCase();
      const allowList = {
        'haramnawaz77@gmail.com',
        'akrammustafa170@gmail.com',
        'haramnawaz74@gmail.com',
      };
      final isAdmin =
          tokenResult.claims?['admin'] == true || allowList.contains(email);
      isAuthorized.value = isAdmin;

      if (!isAdmin) {
        errorMessage.value = 'Access denied. Admin role is required.';
        return;
      }

      await _loadMetrics();
    } catch (e) {
      errorMessage.value = 'Failed to load admin dashboard: $e';
      debugPrint('AdminDashboardController.loadDashboard error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadMetrics() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    final usersSnapshot = await _firestore.collection('users').get();
    final activitySnapshot = await _firestore.collection('user_activity').get();
    final totalInvoicesAgg =
        await _firestore.collection('user_invoices').count().get();

    registeredUsers.value = usersSnapshot.size;
    totalInvoices.value = totalInvoicesAgg.count ?? 0;

    int todayCount = 0;
    int weeklyCount = 0;
    int appOpenSum = 0;
    int screenViewSum = 0;

    final activityByUid = <String, Map<String, dynamic>>{};
    for (final doc in activitySnapshot.docs) {
      final data = doc.data();
      activityByUid[doc.id] = data;

      final ts = data['lastActiveAt'];
      final lastActive = ts is Timestamp ? ts.toDate() : null;
      if (lastActive != null) {
        if (!lastActive.isBefore(todayStart)) todayCount++;
        if (!lastActive.isBefore(sevenDaysAgo)) weeklyCount++;
      }

      appOpenSum += (data['appOpenCount'] as num?)?.toInt() ?? 0;
      screenViewSum += (data['screenViewCount'] as num?)?.toInt() ?? 0;
    }

    activeUsersToday.value = todayCount;
    activeUsers7Days.value = weeklyCount;
    totalAppOpens.value = appOpenSum;
    totalScreenViews.value = screenViewSum;

    final metricsFutures =
        usersSnapshot.docs.map((doc) async {
          final data = doc.data();
          final uid = doc.id;
          final companyName = (data['companyName'] as String?)?.trim() ?? '';
          final email = (data['email'] as String?)?.trim() ?? '';

          final invoiceCountAgg =
              await _firestore
                  .collection('user_invoices')
                  .where('userId', isEqualTo: uid)
                  .count()
                  .get();

          final activity = activityByUid[uid];
          final lastActiveTs = activity?['lastActiveAt'];
          final lastActiveAt =
              lastActiveTs is Timestamp ? lastActiveTs.toDate() : null;

          return AdminUserMetric(
            uid: uid,
            companyName: companyName.isEmpty ? 'Unnamed Company' : companyName,
            email: email,
            invoiceCount: invoiceCountAgg.count ?? 0,
            lastActiveAt: lastActiveAt,
            appOpenCount: (activity?['appOpenCount'] as num?)?.toInt() ?? 0,
            screenViewCount:
                (activity?['screenViewCount'] as num?)?.toInt() ?? 0,
          );
        }).toList();

    final rows = await Future.wait(metricsFutures);
    rows.sort((a, b) => b.invoiceCount.compareTo(a.invoiceCount));
    userMetrics.assignAll(rows);
  }
}
