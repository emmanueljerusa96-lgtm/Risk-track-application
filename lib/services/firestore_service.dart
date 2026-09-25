import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_stats.dart';
import '../models/notification_model.dart';
import '../models/risk_report_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'demo_mode.dart';
import 'mock_store.dart';

export '../models/admin_stats.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore;
  final FirebaseFirestore? _db;

  bool get _demo => DemoMode.enabled && _db == null;
  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('risk_reports');

  String newReportId() => _demo ? MockStore.instance.newReportId() : _reports.doc().id;

  Stream<List<RiskReportModel>> watchReports({
    RiskCategory? category,
    ReportStatus? status,
    VerificationStatus? verification,
    DateTime? since,
    int limit = AppConstants.resultsLimit,
  }) {
    if (_demo) {
      return MockStore.instance.watchReports(
        category: category, status: status, verification: verification,
        since: since, limit: limit,
      );
    }
    Query<Map<String, dynamic>> query = _reports;
    if (category != null) query = query.where('category', isEqualTo: category.label);
    if (status != null) query = query.where('status', isEqualTo: status.value);
    if (verification != null) {
      query = query.where('verificationStatus', isEqualTo: verification.value);
    }
    if (since != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since));
    }
    return query.orderBy('createdAt', descending: true).limit(limit)
        .snapshots().map((snapshot) => snapshot.docs
            .map(RiskReportModel.fromDocument).toList());
  }

  Stream<List<RiskReportModel>> watchMyReports(String uid) => _demo
      ? MockStore.instance.watchReports(userId: uid)
      : _reports
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(AppConstants.resultsLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(RiskReportModel.fromDocument).toList());

  Stream<RiskReportModel?> watchReport(String id) => _demo
      ? MockStore.instance.watchReport(id)
      : _reports.doc(id).snapshots()
      .map((snapshot) => snapshot.exists ? RiskReportModel.fromDocument(snapshot) : null);

  Future<String> createReport({
    required String reportId,
    required String userId,
    required String title,
    required String description,
    required RiskCategory category,
    required double latitude,
    required double longitude,
    required String address,
    required String imageUrl,
  }) async {
    if (_demo) {
      return MockStore.instance.createReport(
        reportId: reportId, userId: userId, title: title,
        description: description, category: category, latitude: latitude,
        longitude: longitude, address: address, imageUrl: imageUrl,
      );
    }
    // Server read prevents a stale displayed name from impersonating another user.
    final profile = await _firestore.collection('users').doc(userId)
        .get(const GetOptions(source: Source.server));
    final reporterName = profile.data()?['fullName'] as String?;
    if (reporterName == null || reporterName.trim().isEmpty) {
      throw StateError('A user profile is required to publish a report.');
    }
    await _reports.doc(reportId).set({
      'reportId': reportId,
      'userId': userId,
      'reporterName': reporterName,
      'title': title.trim(),
      'description': description.trim(),
      'category': category.label,
      'latitude': latitude,
      'longitude': longitude,
      'address': address.trim(),
      'imageUrl': imageUrl,
      'status': ReportStatus.active.value,
      'verificationStatus': VerificationStatus.pending.value,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return reportId;
  }

  Future<bool> reportIncorrectInformation({
    required String reportId,
    required String uid,
    required String reason,
  }) async {
    if (_demo) {
      return MockStore.instance.flagReport(
        reportId: reportId, uid: uid, reason: reason,
      );
    }
    final ref = _firestore.collection('report_flags').doc('${reportId}_$uid');
    // Do not get a nonexistent flag first: rules deliberately deny reading
    // arbitrary nonexistent documents. Creation is one-per-user-and-report.
    try {
      await ref.set({
        'reportId': reportId,
        'userId': uid,
        'reason': reason.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (_) {
      try {
        if ((await ref.get()).exists) return false;
      } catch (_) {
        // The original write error (e.g. offline) is more useful to the user.
      }
      rethrow;
    }
  }

  Stream<List<NotificationModel>> watchNotifications(String uid) => _demo
      ? MockStore.instance.watchNotifications(uid)
      : _firestore
      .collection('users').doc(uid).collection('notifications')
      .orderBy('createdAt', descending: true).limit(50)
      .snapshots().map((snap) => snap.docs.map(NotificationModel.fromDocument).toList());

  Future<void> markNotificationRead(String uid, String id) {
    if (_demo) {
      MockStore.instance.markNotificationRead(uid, id);
      return Future<void>.value();
    }
    return _firestore
      .collection('users').doc(uid).collection('notifications').doc(id)
      .update({'read': true});
  }

  Future<void> reviewReport(
    String id, {ReportStatus? status, VerificationStatus? verification,
  }) async {
    if (_demo) {
      MockStore.instance.reviewReport(id, status: status, verification: verification);
      return;
    }
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (status != null) updates['status'] = status.value;
    if (verification != null) updates['verificationStatus'] = verification.value;
    if (updates.length == 1) return;
    await _reports.doc(id).update(updates);
  }

  Stream<List<UserModel>> watchUsers() => _demo
      ? MockStore.instance.watchUsers()
      : _firestore.collection('users')
      .orderBy('createdAt', descending: true).limit(100)
      .snapshots().map((snap) => snap.docs.map(UserModel.fromDocument).toList());

  Future<void> setUserRole(String uid, {required bool admin}) {
    if (_demo) {
      MockStore.instance.setUserRole(uid, admin: admin);
      return Future<void>.value();
    }
    return _firestore.collection('users').doc(uid)
        .update({'role': admin ? 'admin' : 'user'});
  }

  Future<AdminStats> adminStats() async {
    if (_demo) return MockStore.instance.adminStats();
    Future<int> count(Query<Map<String, dynamic>> query) async =>
        (await query.count().get()).count ?? 0;
    final results = await Future.wait([
      count(_firestore.collection('users')),
      count(_reports),
      count(_reports.where('verificationStatus', isEqualTo: 'pending')),
      count(_reports.where('verificationStatus', isEqualTo: 'verified')),
      count(_reports.where('verificationStatus', isEqualTo: 'rejected')),
      count(_reports.where('status', isEqualTo: 'resolved')),
      count(_firestore.collection('report_flags')),
    ]);
    return AdminStats(
      users: results[0], reports: results[1], pending: results[2],
      verified: results[3], rejected: results[4], resolved: results[5],
      flags: results[6],
    );
  }

  Stream<List<Map<String, dynamic>>> watchFlags(String reportId) => _demo
      ? MockStore.instance.watchFlags(reportId)
      : _firestore.collection('report_flags').where('reportId', isEqualTo: reportId)
      .limit(20).snapshots().map((snap) => snap.docs.map((doc) => doc.data()).toList());

  Stream<List<Map<String, dynamic>>> watchAllFlags() => _demo
      ? MockStore.instance.watchAllFlags()
      : _firestore.collection('report_flags').orderBy('createdAt', descending: true)
      .limit(100).snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()).toList());
}
