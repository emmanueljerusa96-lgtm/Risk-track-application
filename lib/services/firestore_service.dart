import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification_model.dart';
import '../models/risk_report_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class AdminStats {
  const AdminStats({
    required this.users,
    required this.reports,
    required this.pending,
    required this.verified,
    required this.rejected,
    required this.resolved,
    required this.flags,
  });
  final int users;
  final int reports;
  final int pending;
  final int verified;
  final int rejected;
  final int resolved;
  final int flags;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('risk_reports');

  String newReportId() => _reports.doc().id;

  Stream<List<RiskReportModel>> watchReports({
    RiskCategory? category,
    ReportStatus? status,
    VerificationStatus? verification,
    DateTime? since,
    int limit = AppConstants.resultsLimit,
  }) {
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

  Stream<List<RiskReportModel>> watchMyReports(String uid) => _reports
      .where('userId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(AppConstants.resultsLimit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(RiskReportModel.fromDocument).toList());

  Stream<RiskReportModel?> watchReport(String id) => _reports.doc(id).snapshots()
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
    // Server read prevents a stale displayed name from impersonating another user.
    final profile = await _db.collection('users').doc(userId)
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
    final ref = _db.collection('report_flags').doc('${reportId}_$uid');
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

  Stream<List<NotificationModel>> watchNotifications(String uid) => _db
      .collection('users').doc(uid).collection('notifications')
      .orderBy('createdAt', descending: true).limit(50)
      .snapshots().map((snap) => snap.docs.map(NotificationModel.fromDocument).toList());

  Future<void> markNotificationRead(String uid, String id) => _db
      .collection('users').doc(uid).collection('notifications').doc(id)
      .update({'read': true});

  Future<void> reviewReport(
    String id, {ReportStatus? status, VerificationStatus? verification,
  }) async {
    final updates = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (status != null) updates['status'] = status.value;
    if (verification != null) updates['verificationStatus'] = verification.value;
    if (updates.length == 1) return;
    await _reports.doc(id).update(updates);
  }

  Stream<List<UserModel>> watchUsers() => _db.collection('users')
      .orderBy('createdAt', descending: true).limit(100)
      .snapshots().map((snap) => snap.docs.map(UserModel.fromDocument).toList());

  Future<void> setUserRole(String uid, {required bool admin}) => _db
      .collection('users').doc(uid).update({'role': admin ? 'admin' : 'user'});

  Future<AdminStats> adminStats() async {
    Future<int> count(Query<Map<String, dynamic>> query) async =>
        (await query.count().get()).count ?? 0;
    final results = await Future.wait([
      count(_db.collection('users')),
      count(_reports),
      count(_reports.where('verificationStatus', isEqualTo: 'pending')),
      count(_reports.where('verificationStatus', isEqualTo: 'verified')),
      count(_reports.where('verificationStatus', isEqualTo: 'rejected')),
      count(_reports.where('status', isEqualTo: 'resolved')),
      count(_db.collection('report_flags')),
    ]);
    return AdminStats(
      users: results[0], reports: results[1], pending: results[2],
      verified: results[3], rejected: results[4], resolved: results[5],
      flags: results[6],
    );
  }

  Stream<List<Map<String, dynamic>>> watchFlags(String reportId) => _db
      .collection('report_flags').where('reportId', isEqualTo: reportId)
      .limit(20).snapshots().map((snap) => snap.docs.map((doc) => doc.data()).toList());

  Stream<List<Map<String, dynamic>>> watchAllFlags() => _db
      .collection('report_flags').orderBy('createdAt', descending: true)
      .limit(100).snapshots()
      .map((snap) => snap.docs.map((doc) => doc.data()).toList());
}
