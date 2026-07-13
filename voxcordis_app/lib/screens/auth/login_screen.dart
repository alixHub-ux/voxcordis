import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passwordCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text);
    if (ok && mounted) Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.primary,
      // ── AppBar avec titre en haut à gauche ─────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        titleSpacing: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.splash),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.25),
            ),
            child: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
          ),
        ),
        title: const Text(
          'Content de te revoir',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Photo médicale ────────────────────────────────────────
          SizedBox(
            height: h * 0.33,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/login_doctor.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(color: const Color(0xFFB07070)),
                ),
                // Dégradé bordeaux en haut
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary,
                        // ignore: deprecated_member_use
                        AppColors.primary.withOpacity(0.3),
                        // ignore: deprecated_member_use
                        AppColors.primary.withOpacity(0.0),
                      ],
                      stops: const [0.0, 0.3, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Formulaire ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Email',
                      style: TextStyle(color: Colors.white70, fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _PillField(
                    controller: _emailCtrl,
                    hint: 'utilisateur@gmail.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  const Text('Mot de passe',
                      style: TextStyle(color: Colors.white70, fontSize: 14,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _PillField(
                    controller: _passwordCtrl,
                    hint: '••••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscure: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                          color: Colors.grey, size: 20),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Message d'erreur ────────────────────────────
                  if (auth.error != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: Colors.red.shade900.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        auth.error!,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

                  // ── Bouton Se connecter ─────────────────────────
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32)),
                      ),
                      child: auth.isLoading
                          ? const SizedBox(height: 22, width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Se connecter',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Column(
                      children: [
                        const Text("Vous n'avez pas de compte!?",
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, AppRoutes.register),
                          child: const Text("S'inscrire",
                              style: TextStyle(color: Color(0xFFB8960C),
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _PillField({
    required this.controller, required this.hint, required this.prefixIcon,
    this.obscure = false, this.keyboardType, this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, obscureText: obscure, keyboardType: keyboardType,
    style: const TextStyle(color: Colors.black87, fontSize: 15),
    decoration: InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(prefixIcon, color: Colors.grey, size: 20),
      suffixIcon: suffixIcon,
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(32),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(32),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
  );
}