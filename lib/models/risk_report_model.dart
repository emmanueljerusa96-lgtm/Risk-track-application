import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/constants.dart';

class RiskReportModel {
  const RiskReportModel({
    required this.reportId,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.imageUrl,
    required this.status,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.reporterName,
  });

  final String reportId;
  final String userId;
  final String title;
  final String description;
  final RiskCategory category;
  final double latitude;
  final double longitude;
  final String address;
  final String imageUrl;
  final ReportStatus status;
  final VerificationStatus verificationStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String reporterName;

  bool get hasImage => imageUrl.isNotEmpty;
  bool get isVerified => verificationStatus == VerificationStatus.verified;

  RiskReportModel copyWith({
    ReportStatus? status,
    VerificationStatus? verificationStatus,
    DateTime? updatedAt,
    String? imageUrl,
    String? reporterName,
  }) => RiskReportModel(
        reportId: reportId,
        userId: userId,
        title: title,
        description: description,
        category: category,
        latitude: latitude,
        longitude: longitude,
        address: address,
        imageUrl: imageUrl ?? this.imageUrl,
        status: status ?? this.status,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        reporterName: reporterName ?? this.reporterName,
      );

  factory RiskReportModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return RiskReportModel(
      reportId: doc.id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? 'Community report',
      description: data['description'] as String? ?? '',
      category: RiskCategory.fromLabel(data['category'] as String?),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      address: data['address'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      status: ReportStatus.fromValue(data['status'] as String?),
      verificationStatus: VerificationStatus.fromValue(
        data['verificationStatus'] as String?,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      reporterName: data['reporterName'] as String? ?? 'Community member',
    );
  }
}
