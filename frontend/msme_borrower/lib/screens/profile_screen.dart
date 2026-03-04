import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/constants.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: kAccent,
              child: Icon(Icons.business_center, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              'Acme Manufacturing Co.',
              style: kHeading1(context).copyWith(fontSize: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'MSME Priority Business',
              style: kCaption(context).copyWith(color: kAccent, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            _buildInfoCard(
              context,
              icon: Icons.confirmation_number_outlined,
              title: 'GSTIN',
              value: '22AAAAA0000A1Z5',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.email_outlined,
              title: 'Registered Email',
              value: 'contact@acmemfg.in',
            ),
            const SizedBox(height: 16),
            _buildInfoCard(
              context,
              icon: Icons.phone_outlined,
              title: 'Phone Number',
              value: '+91 98765 43210',
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  context.read<AuthProvider>().logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, {required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kPrimary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: kCaption(context)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kTextDark)),
            ],
          )
        ],
      ),
    );
  }
}
