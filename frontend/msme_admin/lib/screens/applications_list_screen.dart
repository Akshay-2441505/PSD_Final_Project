import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import 'application_detail_screen.dart';

class ApplicationsListScreen extends StatefulWidget {
  const ApplicationsListScreen({super.key});
  @override State<ApplicationsListScreen> createState() => _State();
}

class _State extends State<ApplicationsListScreen> {
  final _api = AdminApiService();
  List<dynamic> _apps = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String _selectedStatus = 'ALL';

  final List<String> _statuses = ['ALL', 'PENDING', 'UNDER_REVIEW', 'APPROVED', 'REJECTED'];

  @override
  void initState() { super.initState(); _loadApps(); }

  Future<void> _loadApps() async {
    setState(() => _loading = true);
    try {
      final token = context.read<AdminAuthProvider>().token!;
      _apps = await _api.getApplications(token);
      _applyFilter();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: kError));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _selectedStatus == 'ALL'
          ? _apps
          : _apps.where((a) => a['status'] == _selectedStatus).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
          color: kSurface,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('Loan Applications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh), onPressed: _loadApps, tooltip: 'Refresh'),
            ]),
            const SizedBox(height: 4),
            Text('${_filtered.length} of ${_apps.length} applications', style: const TextStyle(color: kTextMuted, fontSize: 13)),
            const SizedBox(height: 16),

            // Status Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statuses.map((s) {
                  final isSelected = s == _selectedStatus;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s),
                      selected: isSelected,
                      selectedColor: statusColor(s).withOpacity(0.2),
                      checkmarkColor: statusColor(s),
                      labelStyle: TextStyle(
                        color: isSelected ? statusColor(s) : kTextMuted,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12,
                      ),
                      onSelected: (_) {
                        _selectedStatus = s;
                        _applyFilter();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),

        // ── Summary Cards ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
          child: Row(children: [
            _StatCard('Total', _apps.length.toString(), Icons.assignment, kPrimary),
            const SizedBox(width: 14),
            _StatCard('Pending', _apps.where((a) => a['status'] == 'PENDING').length.toString(), Icons.hourglass_empty, kWarning),
            const SizedBox(width: 14),
            _StatCard('Approved', _apps.where((a) => a['status'] == 'APPROVED').length.toString(), Icons.check_circle, kSuccess),
            const SizedBox(width: 14),
            _StatCard('Rejected', _apps.where((a) => a['status'] == 'REJECTED').length.toString(), Icons.cancel, kError),
          ]),
        ),

        const SizedBox(height: 20),

        // ── Table ────────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.inbox, size: 48, color: kTextMuted),
                      const SizedBox(height: 8),
                      Text('No applications found', style: TextStyle(color: kTextMuted)),
                    ]))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(kBackground),
                              dividerThickness: 0.5,
                              columns: const [
                                DataColumn(label: Text('Business', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Tenure', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Purpose', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Risk', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                                DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.w600))),
                              ],
                              rows: _filtered.map((app) {
                                final score = app['risk_score'] ?? 0;
                                final status = app['status'] ?? '';
                                final flags = (app['risk_flags'] as List?)?.cast<String>() ?? [];
                                return DataRow(cells: [
                                  DataCell(Text(app['business_id']?.toString().substring(0, 8) ?? '',
                                      style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                                  DataCell(Text('₹ ${_fmt(app['requested_amount'])}',
                                      style: const TextStyle(fontWeight: FontWeight.w600))),
                                  DataCell(Text('${app['tenure_months']}m')),
                                  DataCell(Text((app['purpose'] ?? '').toString().replaceAll('_', ' '),
                                      style: const TextStyle(fontSize: 12))),
                                  DataCell(Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: score >= 80 ? kSuccess.withOpacity(0.12)
                                            : score >= 60 ? kWarning.withOpacity(0.12)
                                            : kError.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('$score',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700, fontSize: 12,
                                            color: score >= 80 ? kSuccess : score >= 60 ? kWarning : kError,
                                          )),
                                    ),
                                    if (flags.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Tooltip(
                                        message: flags.join('\n'),
                                        child: const Icon(Icons.warning_amber, size: 14, color: kWarning),
                                      ),
                                    ]
                                  ])),
                                  DataCell(_StatusBadge(status)),
                                  DataCell(TextButton(
                                    onPressed: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) =>
                                            ApplicationDetailScreen(app: app))).then((_) => _loadApps()),
                                    child: const Text('Review →'),
                                  )),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '0';
    final n = (v as num).toDouble();
    if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
    return '${(n / 1000).toStringAsFixed(0)}K';
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.2)),
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: kTextMuted)),
      ]),
    ]),
  ));
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status.replaceAll('_', ' '),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
