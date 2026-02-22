import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import 'applications_list_screen.dart';
import 'charts_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;
  int _pendingCount  = 0;
  int _totalCount    = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final token = context.read<AdminAuthProvider>().token!;
      final apps  = await AdminApiService().getApplications(token);
      if (mounted) {
        setState(() {
          _totalCount   = apps.length;
          _pendingCount = apps.where((a) => a['status'] == 'PENDING').length;
        });
      }
    } catch (_) {}
  }

  static const _pages = [
    ApplicationsListScreen(),
    ChartsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth      = context.read<AdminAuthProvider>();
    final adminName = auth.adminName ?? 'Admin';
    final initials  = adminName.split(' ').take(2).map((s) => s[0].toUpperCase()).join();

    return Scaffold(
      backgroundColor: kBackground,
      body: Row(children: [
        // ── Sidebar ──────────────────────────────────────────────────────
        _Sidebar(
          selectedIndex: _selectedIndex,
          pendingCount:  _pendingCount,
          totalCount:    _totalCount,
          adminName:     adminName,
          initials:      initials,
          onSelect: (i) => setState(() => _selectedIndex = i),
          onLogout: () async {
            await auth.logout();
          },
        ),

        // ── Main content ─────────────────────────────────────────────────
        Expanded(
          child: Column(children: [
            // Top header bar
            _TopBar(
              title: _selectedIndex == 0 ? 'Applications' : 'Analytics',
              adminName: adminName,
              initials: initials,
            ),
            // Page content
            Expanded(child: _pages[_selectedIndex]),
          ]),
        ),
      ]),
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final int pendingCount;
  final int totalCount;
  final String adminName;
  final String initials;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.selectedIndex,
    required this.pendingCount,
    required this.totalCount,
    required this.adminName,
    required this.initials,
    required this.onSelect,
    required this.onLogout,
  });

  static final _navItems = [
    (icon: Icons.assignment_outlined, label: 'Applications'),
    (icon: Icons.bar_chart_outlined,  label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 228,
      decoration: const BoxDecoration(
        color: kSidebar,
        border: Border(right: BorderSide(color: Color(0xFF2D2850), width: 1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Logo ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 10)],
              ),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MSME Admin',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
              Text('Lending Portal',
                  style: TextStyle(color: Color(0xFF8A7FAA), fontSize: 10)),
            ]),
          ]),
        ),

        const SizedBox(height: 24),

        // ── Admin Avatar ──────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [kPrimary, Color(0xFF5B4A99)]),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text(initials,
                  style: const TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(adminName, style: const TextStyle(color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              const Text('Loan Officer', style: TextStyle(color: Color(0xFF8A7FAA), fontSize: 10)),
            ])),
          ]),
        ),
        const SizedBox(height: 8),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Text('NAVIGATE', style: TextStyle(color: Color(0xFF5A4F7A), fontSize: 10,
              fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
        const SizedBox(height: 4),

        // ── Nav Items ─────────────────────────────────────────────────
        ..._navItems.asMap().entries.map((e) {
          final isSelected = e.key == selectedIndex;
          final badge      = e.key == 0 && pendingCount > 0 ? pendingCount : null;
          return GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary.withOpacity(0.18) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected
                    ? Border(left: BorderSide(color: kPrimary, width: 3))
                    : Border(left: const BorderSide(color: Colors.transparent, width: 3)),
              ),
              child: Row(children: [
                Icon(e.value.icon,
                    color: isSelected ? Colors.white : const Color(0xFF8A7FAA),
                    size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(e.value.label,
                    style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF8A7FAA),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13))),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: kWarning,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$badge',
                        style: const TextStyle(color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          );
        }),

        const Spacer(),

        const Divider(color: Color(0xFF2D2850), thickness: 1, height: 1),
        // ── Logout ────────────────────────────────────────────────────
        GestureDetector(
          onTap: onLogout,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(children: [
              const Icon(Icons.logout_rounded, color: Color(0xFF8A7FAA), size: 18),
              const SizedBox(width: 10),
              const Text('Sign out',
                  style: TextStyle(color: Color(0xFF8A7FAA), fontSize: 13)),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Top Header Bar ────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final String adminName;
  final String initials;
  const _TopBar({required this.title, required this.adminName, required this.initials});

  @override
  Widget build(BuildContext context) => Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 28),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: Color(0xFFEEECF5), width: 1)),
    ),
    child: Row(children: [
      // Breadcrumb
      const Text('MSME Admin',
          style: TextStyle(color: kTextMuted, fontSize: 13)),
      const Icon(Icons.chevron_right_rounded, color: kTextMuted, size: 18),
      Text(title, style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),

      const Spacer(),

      // Admin badge
      Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kPrimary, Color(0xFF5B4A99)]),
            shape: BoxShape.circle,
          ),
          child: Center(child: Text(initials,
              style: const TextStyle(color: Colors.white, fontSize: 11,
                  fontWeight: FontWeight.w700))),
        ),
        const SizedBox(width: 8),
        Text(adminName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
      ]),
    ]),
  );
}
