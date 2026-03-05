import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/constants.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  final VoidCallback onApplyRequested;
  const HomeScreen({super.key, required this.onApplyRequested});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _loanAmount = 500000;
  double _tenureMonths = 12;
  final double _annualInterestRate = 18.0; // Fixed 18% for demo

  int get _emi {
    double p = _loanAmount;
    double r = (_annualInterestRate / 12) / 100;
    double n = _tenureMonths;
    if (r == 0) return (p / n).round();
    double emi = p * r * (pow(1 + r, n)) / (pow(1 + r, n) - 1);
    return emi.round();
  }

  @override
  Widget build(BuildContext context) {
    // Derive a short display name: prefer owner_name, fall back to first word of company name
    final profile = context.watch<AuthProvider>().profile;
    final ownerName   = profile?['owner_name']  as String? ?? '';
    final legalName   = profile?['legal_name']  as String? ?? '';
    final displayName = ownerName.isNotEmpty
        ? ownerName.split(' ').first
        : legalName.isNotEmpty
            ? legalName.split(' ').first
            : 'there';

    return Scaffold(
      appBar: AppBar(
        title: const Text('LendingKart MSME'),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Text('Hello, $displayName!',
                style: kHeading1(context).copyWith(fontSize: 28, color: kPrimary)),
            const SizedBox(height: 8),
            Text('Calculate your EMI and apply instantly.',
                style: TextStyle(fontSize: 16, color: kTextDark)),
            const SizedBox(height: 24),
            
            // EMI Calculator Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('EMI Calculator', style: kHeading1(context).copyWith(fontSize: 18)),
                      const Icon(Icons.calculate_outlined, color: kAccent),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Loan Amount Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Loan Amount', style: kCaption(context)),
                      Text('₹${_loanAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimary)),
                    ],
                  ),
                  Slider(
                    value: _loanAmount,
                    min: 50000,
                    max: 5000000,
                    divisions: 100,
                    activeColor: kPrimary,
                    onChanged: (val) => setState(() => _loanAmount = val),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tenure Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tenure (Months)', style: kCaption(context)),
                      Text('${_tenureMonths.toInt()} Months', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimary)),
                    ],
                  ),
                  Slider(
                    value: _tenureMonths,
                    min: 3,
                    max: 36,
                    divisions: 33,
                    activeColor: kPrimary,
                    onChanged: (val) => setState(() => _tenureMonths = val),
                  ),
                  const SizedBox(height: 24),
                  // Result Area
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimary.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Estimated EMI', style: kCaption(context)),
                            const SizedBox(height: 4),
                            Text('₹$_emi', style: kHeading1(context).copyWith(fontSize: 24, color: kAccent)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Interest Rate', style: kCaption(context)),
                            const SizedBox(height: 4),
                            Text('$_annualInterestRate% p.a.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kTextDark)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, duration: 400.ms),

            const SizedBox(height: 24),

            // ── Apply Now — separate from the EMI Calculator ───────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [kPrimary, kPrimary.withOpacity(0.8)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: kPrimary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ready to Apply?',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get funds in your account within 48 hours.',
                          style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: widget.onApplyRequested,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: const Text('Apply Now',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.08, duration: 400.ms),
            
            const SizedBox(height: 32),
            
            // Benefits Section
            Text('Why LendingKart?', style: kHeading1(context).copyWith(fontSize: 18)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBenefitItem('100% Online', Icons.laptop_mac),
                _buildBenefitItem('No Collateral', Icons.security),
                _buildBenefitItem('Fast Disbursal', Icons.bolt),
              ],
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: kPrimary, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: kTextDark)),
      ],
    );
  }
}
