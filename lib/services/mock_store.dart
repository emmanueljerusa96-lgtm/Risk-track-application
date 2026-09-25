import 'dart:async';

import '../models/admin_stats.dart';
import '../models/notification_model.dart';
import '../models/risk_report_model.dart';
import '../models/session_user.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

abstract final class SampleAccounts {
  static const memberEmail = 'ada@risktrack.app';
  static const memberPassword = 'demo1234';
  static const adminEmail = 'admin@risktrack.app';
  static const adminPassword = 'admin1234';
}

/// Process-local community data. Restarting the app restores the sample set.
class MockStore {
  MockStore._() {
    _seed();
  }
  static final MockStore instance = MockStore._();

  final _changes = StreamController<void>.broadcast();
  final _users = <String, UserModel>{};
  final _passwords = <String, String>{};
  final _reports = <String, RiskReportModel>{};
  final _notifications = <String, List<NotificationModel>>{};
  final _flags = <String, Map<String, dynamic>>{};
  SessionUser? currentUser;
  int _sequence = 0;

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Stream<T> _watch<T>(T Function() read) => Stream<T>.multi((listener) {
        listener.add(read());
        final subscription = _changes.stream.listen((_) {
          if (!listener.isClosed) listener.add(read());
        });
        listener.onCancel = subscription.cancel;
      });

  Stream<SessionUser?> get authChanges => _watch(() => currentUser);

  void signInSampleMember() => _signInEmail(
        SampleAccounts.memberEmail, SampleAccounts.memberPassword,
      );

  void signIn({required String email, required String password}) =>
      _signInEmail(email, password);

  void _signInEmail(String email, String password) {
    final normalized = email.trim().toLowerCase();
    UserModel? user;
    for (final item in _users.values) {
      if (item.email == normalized) {
        user = item;
        break;
      }
    }
    if (user == null || _passwords[normalized] != password) {
      throw const AuthFailure('Email or password is incorrect.');
    }
    currentUser = SessionUser(
      uid: user.uid, email: user.email, displayName: user.fullName,
    );
    _notify();
  }

  void signOut() {
    currentUser = null;
    _notify();
  }

  void register({
    required String fullName,
    required String email,
    required String password,
  }) {
    final normalized = email.trim().toLowerCase();
    if (_passwords.containsKey(normalized)) {
      throw const AuthFailure('This email is already registered. Try signing in.');
    }
    final uid = 'user-${++_sequence}';
    _users[uid] = UserModel(
      uid: uid,
      fullName: fullName.trim(),
      email: normalized,
      photoUrl: '',
      role: 'user',
      createdAt: DateTime.now(),
    );
    _passwords[normalized] = password;
    _notifications[uid] = [];
    currentUser = SessionUser(
      uid: uid, email: normalized, displayName: fullName.trim(),
    );
    _notify();
  }

  void updateFullName(String uid, String name) {
    final existing = _users[uid];
    if (existing == null) return;
    _users[uid] = UserModel(
      uid: existing.uid,
      fullName: name.trim(),
      email: existing.email,
      photoUrl: existing.photoUrl,
      role: existing.role,
      createdAt: existing.createdAt,
    );
    if (currentUser?.uid == uid) {
      currentUser = SessionUser(
        uid: uid, email: existing.email, displayName: name.trim(),
      );
    }
    _notify();
  }

  Stream<UserModel?> watchProfile(String uid) => _watch(() => _users[uid]);

  Stream<List<UserModel>> watchUsers() => _watch(() {
        final people = _users.values.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return people;
      });

  void setUserRole(String uid, {required bool admin}) {
    final existing = _users[uid];
    if (existing == null) return;
    _users[uid] = UserModel(
      uid: existing.uid,
      fullName: existing.fullName,
      email: existing.email,
      photoUrl: existing.photoUrl,
      role: admin ? 'admin' : 'user',
      createdAt: existing.createdAt,
    );
    _notify();
  }

  String newReportId() => 'report-${++_sequence}';

  Stream<List<RiskReportModel>> watchReports({
    RiskCategory? category,
    ReportStatus? status,
    VerificationStatus? verification,
    DateTime? since,
    String? userId,
    int limit = AppConstants.resultsLimit,
  }) => _watch(() => _query(
        category: category, status: status, verification: verification,
        since: since, userId: userId, limit: limit,
      ));

  List<RiskReportModel> _query({
    RiskCategory? category,
    ReportStatus? status,
    VerificationStatus? verification,
    DateTime? since,
    String? userId,
    int limit = AppConstants.resultsLimit,
  }) {
    final items = _reports.values.where((report) {
      if (category != null && report.category != category) return false;
      if (status != null && report.status != status) return false;
      if (verification != null && report.verificationStatus != verification) {
        return false;
      }
      if (since != null && report.createdAt.isBefore(since)) return false;
      if (userId != null && report.userId != userId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.take(limit).toList();
  }

  Stream<RiskReportModel?> watchReport(String id) =>
      _watch(() => _reports[id]);

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
    final profile = _users[userId];
    if (profile == null || profile.fullName.trim().isEmpty) {
      throw StateError('A user profile is required to publish a report.');
    }
    final now = DateTime.now();
    _reports[reportId] = RiskReportModel(
      reportId: reportId,
      userId: userId,
      reporterName: profile.fullName,
      title: title.trim(),
      description: description.trim(),
      category: category,
      latitude: latitude,
      longitude: longitude,
      address: address.trim(),
      imageUrl: imageUrl,
      status: ReportStatus.active,
      verificationStatus: VerificationStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    _addNotification(userId,
      title: 'Report received',
      body: 'Your community report is pending verification.',
      reportId: reportId,
      kind: 'report_received',
    );
    _notify();
    return reportId;
  }

  bool flagReport({
    required String reportId,
    required String uid,
    required String reason,
  }) {
    final key = '${reportId}_$uid';
    if (_flags.containsKey(key)) return false;
    _flags[key] = {
      'reportId': reportId,
      'userId': uid,
      'reason': reason.trim(),
      'createdAt': DateTime.now(),
    };
    _notify();
    return true;
  }

  Stream<List<Map<String, dynamic>>> watchFlags(String reportId) => _watch(() =>
      _flags.values.where((flag) => flag['reportId'] == reportId).toList());

  Stream<List<Map<String, dynamic>>> watchAllFlags() => _watch(() {
        final flags = _flags.values.toList()
          ..sort((a, b) => (b['createdAt'] as DateTime)
              .compareTo(a['createdAt'] as DateTime));
        return flags;
      });

  void reviewReport(String id, {ReportStatus? status, VerificationStatus? verification}) {
    final existing = _reports[id];
    if (existing == null) return;
    if (status == null && verification == null) return;
    final updated = existing.copyWith(
      status: status,
      verificationStatus: verification,
      updatedAt: DateTime.now(),
    );
    _reports[id] = updated;
    final label = verification?.label ?? status?.label ?? 'updated';
    _addNotification(existing.userId,
      title: 'Report $label',
      body: '"${existing.title}" is now ${label.toLowerCase()}.',
      reportId: id,
      kind: 'report_update',
    );
    _notify();
  }

  Stream<List<NotificationModel>> watchNotifications(String uid) => _watch(() {
        final items = List<NotificationModel>.from(_notifications[uid] ?? [])
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items;
      });

  void markNotificationRead(String uid, String id) {
    final items = _notifications[uid];
    if (items == null) return;
    final index = items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final current = items[index];
    items[index] = NotificationModel(
      id: current.id,
      title: current.title,
      body: current.body,
      reportId: current.reportId,
      kind: current.kind,
      read: true,
      createdAt: current.createdAt,
    );
    _notify();
  }

  AdminStats adminStats() {
    final reports = _reports.values.toList();
    return AdminStats(
      users: _users.length,
      reports: reports.length,
      pending: reports.where((r) => r.verificationStatus == VerificationStatus.pending).length,
      verified: reports.where((r) => r.verificationStatus == VerificationStatus.verified).length,
      rejected: reports.where((r) => r.verificationStatus == VerificationStatus.rejected).length,
      resolved: reports.where((r) => r.status == ReportStatus.resolved).length,
      flags: _flags.length,
    );
  }

  void _addNotification(String uid, {
    required String title,
    required String body,
    required String reportId,
    required String kind,
  }) {
    final items = _notifications.putIfAbsent(uid, () => []);
    items.insert(0, NotificationModel(
      id: 'note-${++_sequence}',
      title: title,
      body: body,
      reportId: reportId,
      kind: kind,
      read: false,
      createdAt: DateTime.now(),
    ));
  }

  void _seed() {
    final now = DateTime.now();
    void user(String uid, String name, String email, String password, String role, int daysAgo) {
      _users[uid] = UserModel(
        uid: uid,
        fullName: name,
        email: email,
        photoUrl: '',
        role: role,
        createdAt: now.subtract(Duration(days: daysAgo)),
      );
      _passwords[email] = password;
      _notifications[uid] = [];
    }

    user('user-ada', 'Ada Okonkwo', SampleAccounts.memberEmail,
      SampleAccounts.memberPassword, 'user', 12);
    user('user-admin', 'Chinedu Adeyemi', SampleAccounts.adminEmail,
      SampleAccounts.adminPassword, 'admin', 40);
    user('user-tunde', 'Tunde Bakare', 'tunde@risktrack.app', 'unused', 'user', 20);

    RiskReportModel report({
      required String id,
      required String userId,
      required String name,
      required String title,
      required String description,
      required RiskCategory category,
      required double latitude,
      required double longitude,
      required String address,
      required ReportStatus status,
      required VerificationStatus verification,
      required Duration age,
    }) => RiskReportModel(
          reportId: id,
          userId: userId,
          reporterName: name,
          title: title,
          description: description,
          category: category,
          latitude: latitude,
          longitude: longitude,
          address: address,
          imageUrl: '',
          status: status,
          verificationStatus: verification,
          createdAt: now.subtract(age),
          updatedAt: now.subtract(age),
        );

    final samples = [
      report(
        id: 'sample-lighting', userId: 'user-ada', name: 'Ada Okonkwo',
        title: 'Dark stretch beside CMS bus stop',
        description: 'Several street lights on the walk to the jetty have been out for days. The pavement is hard to see after 7pm.',
        category: RiskCategory.poorLighting, latitude: 6.4541, longitude: 3.3891,
        address: 'CMS Bus Stop, Lagos Island',
        status: ReportStatus.active, verification: VerificationStatus.pending,
        age: const Duration(hours: 5),
      ),
      report(
        id: 'sample-flood', userId: 'user-tunde', name: 'Tunde Bakare',
        title: 'Water across the Third Mainland approach',
        description: 'Standing water covers one lane after rain. Vehicles are moving slowly and some riders are using the shoulder.',
        category: RiskCategory.flood, latitude: 6.5028, longitude: 3.3964,
        address: 'Third Mainland Bridge approach, Lagos',
        status: ReportStatus.active, verification: VerificationStatus.verified,
        age: const Duration(hours: 18),
      ),
      report(
        id: 'sample-manhole', userId: 'user-tunde', name: 'Tunde Bakare',
        title: 'Open manhole on Allen Avenue',
        description: 'A cover is missing near the junction. It is easy to miss in traffic, especially for motorcycles.',
        category: RiskCategory.roadHazard, latitude: 6.6018, longitude: 3.3515,
        address: 'Allen Avenue, Ikeja',
        status: ReportStatus.active, verification: VerificationStatus.pending,
        age: const Duration(days: 1, hours: 3),
      ),
      report(
        id: 'sample-refuse', userId: 'user-ada', name: 'Ada Okonkwo',
        title: 'Refuse blocking a roadside drain',
        description: 'A heap of waste is sitting over the drain. The last rain already started pooling beside the shops.',
        category: RiskCategory.environmental, latitude: 6.4965, longitude: 3.3582,
        address: 'Adeniran Ogunsanya, Surulere',
        status: ReportStatus.active, verification: VerificationStatus.pending,
        age: const Duration(days: 2),
      ),
      report(
        id: 'sample-accident', userId: 'user-tunde', name: 'Tunde Bakare',
        title: 'Cleared collision near Lekki',
        description: 'Two vehicles collided earlier. The road is open again, with glass still near the shoulder.',
        category: RiskCategory.accident, latitude: 6.4474, longitude: 3.4723,
        address: 'Lekki-Epe Expressway',
        status: ReportStatus.resolved, verification: VerificationStatus.verified,
        age: const Duration(days: 3),
      ),
      report(
        id: 'sample-smoke', userId: 'user-tunde', name: 'Tunde Bakare',
        title: 'Smoke from a generator shop',
        description: 'A shop generator was smoking heavily. Neighbours said it was shut off before any fire spread.',
        category: RiskCategory.fire, latitude: 6.5095, longitude: 3.3711,
        address: 'Herbert Macaulay Way, Yaba',
        status: ReportStatus.active, verification: VerificationStatus.rejected,
        age: const Duration(days: 4),
      ),
      report(
        id: 'sample-security', userId: 'user-ada', name: 'Ada Okonkwo',
        title: 'Unlit alley behind the market',
        description: 'The path behind the evening market has no working light. People are avoiding it and using the main road instead.',
        category: RiskCategory.security, latitude: 6.5281, longitude: 3.3496,
        address: 'Mushin Market side street',
        status: ReportStatus.active, verification: VerificationStatus.pending,
        age: const Duration(days: 6),
      ),
    ];
    for (final item in samples) {
      _reports[item.reportId] = item;
    }
    _flags['sample-manhole_user-admin'] = {
      'reportId': 'sample-manhole',
      'userId': 'user-admin',
      'reason': 'A cover may have been replaced this morning. Please confirm before verifying.',
      'createdAt': now.subtract(const Duration(hours: 2)),
    };
    _notifications['user-ada'] = [
      NotificationModel(
        id: 'note-seed-1',
        title: 'Report received',
        body: 'Your community report is pending verification.',
        reportId: 'sample-lighting',
        kind: 'report_received',
        read: false,
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      NotificationModel(
        id: 'note-seed-2',
        title: 'Nearby report verified',
        body: 'A flood report on the Third Mainland approach was marked verified.',
        reportId: 'sample-flood',
        kind: 'nearby_update',
        read: true,
        createdAt: now.subtract(const Duration(hours: 16)),
      ),
    ];
  }
}
