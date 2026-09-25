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
