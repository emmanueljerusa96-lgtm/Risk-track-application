import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.reportId,
    required this.kind,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String reportId;
  final String kind;
  final bool read;
  final DateTime createdAt;

  factory NotificationModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return NotificationModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Report update',
      body: data['body'] as String? ?? '',
      reportId: data['reportId'] as String? ?? '',
      kind: data['kind'] as String? ?? 'report_update',
      read: data['read'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
