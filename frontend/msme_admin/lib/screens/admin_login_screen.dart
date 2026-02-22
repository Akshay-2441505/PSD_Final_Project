import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/constants.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override State<AdminLoginScreen> createState() => _State();
}

class _State extends State<AdminLoginScreen> with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController(text: 'arjun.admin@msmelending.com');
  final _passCtrl  = TextEditingController(text: 'Admin@1234');
  bool _obscure    = true;

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    Future.delayed(const Duration(milliseconds: 100), _fadeCtrl.forward);
  }

  @override
  void dispose() { _fadeCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AdminAuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: kError,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AdminAuthProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 800;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnim,
        child: isWide ? _WideLayout(
          obscure: _obscure,
          formKey: _formKey,
          emailCtrl: _emailCtrl,
          passCtrl: _passCtrl,
          loading: auth.loading,
          onLogin: _login,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
        ) : _NarrowLayout(
          obscure: _obscure,
          formKey: _formKey,
          emailCtrl: _emailCtrl,
          passCtrl: _passCtrl,
          loading: auth.loading,
          onLogin: _login,
          onToggleObscure: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

// ── Wide layout: split screen ────────────────────────────────────────────────
class _WideLayout extends StatelessWidget {
  final bool obscure, loading;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final VoidCallback onLogin, onToggleObscure;
  const _WideLayout({
    required this.obscure, required this.loading, required this.formKey,
    required this.emailCtrl, required this.passCtrl,
    required this.onLogin, required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    // ── Left brand panel ──────────────────────────────────────────────
    Expanded(
      flex: 5,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1730), Color(0xFF2D2450), Color(0xFF3D2F72)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(children: [
          // Background decoration
          Positioned(top: -80, left: -80,
              child: _Blob(size: 280, color: Colors.white.withOpacity(0.04))),
          Positioned(bottom: 40, right: -60,
              child: _Blob(size: 220, color: kPrimary.withOpacity(0.15))),
          // Content
          Padding(
            padding: const EdgeInsets.all(52),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: kPrimary.withOpacity(0.4), blurRadius: 20)],
                ),
                child: const Icon(Icons.account_balance, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 32),
              const Text('MSME Admin', 
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1)),
              const SizedBox(height: 8),
              const Text('Lending intelligence\nat scale.',
                  style: TextStyle(color: Colors.white60, fontSize: 18, height: 1.4)),
              const SizedBox(height: 48),
              _FeaturePill(icon: Icons.speed_rounded, label: 'Real-time risk scoring'),
              const SizedBox(height: 12),
              _FeaturePill(icon: Icons.verified_user_rounded, label: 'Account Aggregator insights'),
              const SizedBox(height: 12),
              _FeaturePill(icon: Icons.analytics_rounded, label: 'Business analytics'),
            ]),
          ),
        ]),
      ),
    ),

    // ── Right form panel ─────────────────────────────────────────────
    Expanded(
      flex: 4,
      child: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(52),
            child: _LoginForm(
              obscure: obscure,
              formKey: formKey,
              emailCtrl: emailCtrl,
              passCtrl: passCtrl,
              loading: loading,
              onLogin: onLogin,
              onToggleObscure: onToggleObscure,
            ),
          ),
        ),
      ),
    ),
  ]);
}

// ── Narrow (mobile) layout ────────────────────────────────────────────────────
class _NarrowLayout extends StatelessWidget {
  final bool obscure, loading;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final VoidCallback onLogin, onToggleObscure;
  const _NarrowLayout({
    required this.obscure, required this.loading, required this.formKey,
    required this.emailCtrl, required this.passCtrl,
    required this.onLogin, required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF1A1730), Color(0xFF3D2F72)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40)],
          ),
          child: _LoginForm(
            obscure: obscure,
            formKey: formKey,
            emailCtrl: emailCtrl,
            passCtrl: passCtrl,
            loading: loading,
            onLogin: onLogin,
            onToggleObscure: onToggleObscure,
          ),
        ),
      ),
    ),
  );
}

// ── Shared form widget ────────────────────────────────────────────────────────
class _LoginForm extends StatelessWidget {
  final bool obscure, loading;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final VoidCallback onLogin, onToggleObscure;
  const _LoginForm({
    required this.obscure, required this.loading, required this.formKey,
    required this.emailCtrl, required this.passCtrl,
    required this.onLogin, required this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, children: [
      const Text('Welcome back,', style: TextStyle(fontSize: 13, color: kTextMuted)),
      const Text('Admin 👋', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: kTextDark)),
      const SizedBox(height: 32),

      // Email
      _FieldLabel('Email address'),
      const SizedBox(height: 6),
      TextFormField(
        controller: emailCtrl,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'admin@msmelending.com',
          prefixIcon: Icon(Icons.email_outlined, size: 20),
        ),
        validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
      ),
      const SizedBox(height: 18),

      // Password
      _FieldLabel('Password'),
      const SizedBox(height: 6),
      TextFormField(
        controller: passCtrl,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
            onPressed: onToggleObscure,
          ),
        ),
        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
      ),
      const SizedBox(height: 28),

      // Login Button — Stripe-style: full-width, dark
      SizedBox(
        width: double.infinity, height: 50,
        child: ElevatedButton(
          onPressed: loading ? null : onLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A1730),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: loading
              ? const SizedBox(height: 20, width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Sign in to Dashboard',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      const SizedBox(height: 16),
      Center(child: Text('Admin access only • Borrowers use the mobile app',
          style: const TextStyle(fontSize: 11, color: kTextMuted),
          textAlign: TextAlign.center)),
    ]),
  );
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);
  @override Widget build(BuildContext context) => Text(label,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark));
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeaturePill({required this.icon, required this.label});
  @override Widget build(BuildContext context) => Row(children: [
    Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: Colors.white, size: 16),
    ),
    const SizedBox(width: 12),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
  ]);
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});
  @override Widget build(BuildContext context) => Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}
