import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/constants.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override State<AdminLoginScreen> createState() => _State();
}

class _State extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'arjun.admin@msmelending.com');
  final _passCtrl  = TextEditingController(text: 'Admin@1234');
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AdminAuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Login failed'), backgroundColor: kError),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    return Scaffold(
      backgroundColor: kSidebar,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 40, offset: const Offset(0, 12))],
          ),
          child: Form(
            key: _formKey,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Logo / Header
              Center(child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: kPrimary, borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 36),
              )),
              const SizedBox(height: 20),
              Center(child: Text('MSME Admin Portal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: kTextDark))),
              Center(child: Text('Loan Origination Dashboard',
                  style: TextStyle(fontSize: 13, color: kTextMuted))),
              const SizedBox(height: 32),

              // Email
              Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.email_outlined), hintText: 'admin@msmelending.com'),
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 18),

              // Password
              Text('Password', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 28),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.loading ? null : _login,
                  child: auth.loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign In to Dashboard'),
                ),
              ),
              const SizedBox(height: 16),

              Center(child: Text('Admin access only — Borrowers use the mobile app',
                  style: TextStyle(fontSize: 11, color: kTextMuted), textAlign: TextAlign.center)),
            ]),
          ),
        ),
      ),
    );
  }
}
