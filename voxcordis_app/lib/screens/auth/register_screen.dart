import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen> {
  final _firstCtrl   = TextEditingController();
  final _lastCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true, _obscure2 = true;
 
  @override
  void dispose() {
    for (final c in [_firstCtrl,_lastCtrl,_emailCtrl,_passCtrl,_confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }
 
  Future<void> _submit() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Les mots de passe ne correspondent pas.')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      firstName: _firstCtrl.text.trim(), lastName: _lastCtrl.text.trim(),
      email: _emailCtrl.text.trim(), password: _passCtrl.text,
    );
    if (ok && mounted) Navigator.pushReplacementNamed(context, AppRoutes.login);
  }
 
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFFE8C4C4),
                Color(0xFFFAF6F0),
                Color(0xFFE8C4C4),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Contenu scrollable ──────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(children: [
                          GestureDetector(
                            onTap: () => Navigator.pushReplacementNamed(
                                context, AppRoutes.login),
                            child: Container(
                              width: 34, height: 34,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                              child: const Icon(Icons.chevron_left,
                                  color: AppColors.primary, size: 22),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Créer un compte',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ]),
                        const SizedBox(height: 32),
 
                        // Prénom + Nom (2 colonnes)
                        Row(children: [
                          Expanded(child: _field('Prénom', _firstCtrl, hint: 'Amadou')),
                          const SizedBox(width: 12),
                          Expanded(child: _field('Nom', _lastCtrl, hint: 'Traoré')),
                        ]),
                        const SizedBox(height: 16),
 
                        _field('Email', _emailCtrl,
                            hint: 'utilisateur@gmail.com',
                            prefix: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 16),
 
                        _field('Mot de passe', _passCtrl,
                            hint: '••••••••••', prefix: Icons.lock_outline,
                            obscure: _obscure1,
                            onToggle: () => setState(() => _obscure1 = !_obscure1)),
                        const SizedBox(height: 16),
 
                        _field('Confirmer mot de passe', _confirmCtrl,
                            hint: '••••••••••', prefix: Icons.lock_outline,
                            obscure: _obscure2,
                            onToggle: () => setState(() => _obscure2 = !_obscure2)),
                        const SizedBox(height: 32),
                        // Affichage de l'erreur
                         if (auth.error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade300),
                            ),
                            child: Text(
                              auth.error!,
                              style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        // Bouton S'inscrire
                        SizedBox(
                          width: double.infinity, height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white, elevation: 0,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32)),
                            ),
                            child: auth.isLoading
                                ? const SizedBox(height: 22, width: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text("S'inscrire",
                                    style: TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 16),
 
                        // Lien Se connecter
                        Center(
                          child: Column(children: [
                            const Text("Vous avez déjà un compte!?",
                                style: TextStyle(color: Colors.grey, fontSize: 13)),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacementNamed(
                                  context, AppRoutes.login),
                              child: const Text('Se connecter',
                                  style: TextStyle(color: AppColors.primary,
                                      fontWeight: FontWeight.w700, fontSize: 15)),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
 
                // ── Mention légale collée en bas ────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                      children: [
                        TextSpan(text: 'Inscription vaut acceptation de nos '),
                        TextSpan(text: 'Conditions',
                            style: TextStyle(fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        TextSpan(text: '. Vos données de santé sont sécurisées.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  Widget _field(String label, TextEditingController ctrl, {
    String hint = '', IconData? prefix, bool obscure = false,
    VoidCallback? onToggle, TextInputType? keyboard,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 13,
          fontWeight: FontWeight.w500, color: Colors.black87)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, obscureText: obscure, keyboardType: keyboard,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: prefix != null
              ? Icon(prefix, color: Colors.grey, size: 18) : null,
          suffixIcon: onToggle != null
              ? IconButton(
                  icon: Icon(obscure ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                      color: Colors.grey, size: 18),
                  onPressed: onToggle)
              : null,
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.primary, width: 1)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              // ignore: deprecated_member_use
              borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    ],
  );
}