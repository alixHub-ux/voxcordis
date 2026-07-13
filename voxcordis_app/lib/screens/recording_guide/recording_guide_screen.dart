import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../widgets/bottom_nav.dart';

class _Page { final String title, tip; const _Page(this.title, this.tip); }

class RecordingGuideScreen extends StatefulWidget {
  const RecordingGuideScreen({super.key});
  @override State<RecordingGuideScreen> createState() => _RecordingGuideScreenState();
}

class _RecordingGuideScreenState extends State<RecordingGuideScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    _Page('Trouvez un endroit calme',
        'Éloignez-vous du bruit, de la télévision ou de la circulation.'),
    _Page('Gardez votre téléphone\nprès de vous.',
        'Gardez le micro à environ 10 cm de votre bouche.'),
    _Page('Maintenez une voyelle\npendant 03 secondes.',
        "Pour commencer l'enregistrement, maintenez la voyelle 'a' (ou 'i', 'u') "
        "pendant au moins 3 secondes, en prononçant un son long et soutenu comme 'aaaaaaaaaa'..."),
  ];

  // Images assets (à placer dans assets/images/)
  static const _images = [
    'assets/images/guide_calm.png',   // homme dans pièce calme
    'assets/images/guide_phone.png',  // homme tenant téléphone
    'assets/images/guide_voice.png',  // homme qui parle "aaaaaa"
  ];

  void _next() {
    if (_page < 2) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _goToRecording();
    }
  }

  void _prev() {
    if (_page > 0) {
      _ctrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _goToRecording() => Navigator.pushReplacementNamed(context, AppRoutes.recording);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.dashboard),
                  child: Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                    child: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                const Text("Étape de l'Analyse vocale",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ]),
            ),
            const SizedBox(height: 20),

            // Indicateurs (3 pills)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: i == _page ? 40 : 24,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: i <= _page
                      // ignore: deprecated_member_use
                      ? (i == _page ? AppColors.primary : AppColors.primary.withOpacity(0.4))
                      : const Color(0xFFE8D5D5),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
            const SizedBox(height: 24),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: 3,
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title,
                            style: const TextStyle(fontSize: 24,
                                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        const SizedBox(height: 20),
                        // Image avec coins arrondis
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            _images[i],
                            height: 200, width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 200, width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEE5E0),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                [Icons.volume_off_outlined,
                                 Icons.phone_in_talk_outlined,
                                 Icons.record_voice_over_outlined][i],
                                // ignore: deprecated_member_use
                                size: 60, color: AppColors.primary.withOpacity(0.4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(p.tip,
                            style: const TextStyle(fontSize: 14,
                                color: AppColors.textSecondary, height: 1.6)),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Navigation boutons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_page > 0) ...[
                    _CircleBtn(icon: Icons.arrow_back, onTap: _prev),
                    const SizedBox(width: 20),
                  ],
                  if (_page < 2)
                    _CircleBtn(icon: Icons.arrow_forward, onTap: _next)
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),

            // Bouton "Passez directement" - pill bordeaux sur la dernière page
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: _page == 2
                  ? SizedBox(
                      width: double.infinity, height: 52,
                      child: ElevatedButton(
                        onPressed: _goToRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32)),
                        ),
                        child: const Text("Passez directement à l'enregistrement",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    )
                  : TextButton(
                      onPressed: _goToRecording,
                      child: const Text("Passez directement à l'enregistrement",
                          style: TextStyle(color: AppColors.primary,
                              fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const VoxcordisBottomNav(currentIndex: 1),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
      child: Icon(icon, color: Colors.white, size: 24),
    ),
  );
}
