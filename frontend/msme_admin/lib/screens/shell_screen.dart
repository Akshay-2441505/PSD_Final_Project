import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/constants.dart';
import 'applications_list_screen.dart';
import 'charts_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.assignment_outlined, label: 'Applications'),
    _NavItem(icon: Icons.bar_chart_outlined,  label: 'Analytics'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        // ── Sidebar ──────────────────────────────────────────────────────
        _Sidebar(
          items: _navItems,
          selectedIndex: _selectedIndex,
          onSelect: (i) => setState(() => _selectedIndex = i),
        ),

        // ── Main Content ─────────────────────────────────────────────────
        Expanded(
          child: _selectedIndex == 0
              ? const ApplicationsListScreen()
              : const ChartsScreen(),
        ),
      ]),
    );
  }
}

// ── Sidebar Widget ────────────────────────────────────────────────────────
class _Sidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.items, required this.selectedIndex, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AdminAuthProvider>();
    return Container(
      width: 220,
      color: kSidebar,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Logo
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 30),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.account_balance, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            const Text('MSME Admin', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const Text('Lending Portal', style: TextStyle(color: kSidebarText, fontSize: 11)),
          ]),
        ),

        const Divider(color: Color(0xFF2D2850), thickness: 1, height: 1),
        const SizedBox(height: 12),

        // Nav Items
        ...items.asMap().entries.map((e) {
          final isSelected = e.key == selectedIndex;
          return GestureDetector(
            onTap: () => onSelect(e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? kPrimary.withOpacity(0.25) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isSelected ? Border.all(color: kPrimary.withOpacity(0.5)) : null,
              ),
              child: Row(children: [
                Icon(e.value.icon, color: isSelected ? Colors.white : kSidebarText, size: 20),
                const SizedBox(width: 12),
                Text(e.value.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : kSidebarText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 14,
                    )),
              ]),
            ),
          );
        }),

        const Spacer(),

        // Logout
        const Divider(color: Color(0xFF2D2850), thickness: 1, height: 1),
        GestureDetector(
          onTap: () => auth.logout(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              const Icon(Icons.logout, color: kSidebarText, size: 18),
              const SizedBox(width: 10),
              const Text('Logout', style: TextStyle(color: kSidebarText, fontSize: 14)),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}
