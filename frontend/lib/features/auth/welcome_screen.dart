import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'login_screen.dart';

/// Boshlang'ich ekran - foydalanuvchi rolini tanlash.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor,
              AppTheme.accentColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Sarlavha
                Text(
                  'Kichkintoy Connect',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.2),
                            offset: const Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Maktabgacha ta\'lim platformasi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 60),

                // Rol tanlash
                Text(
                  'Kim sifatida kirasiz?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 24),

                _RoleButton(
                  icon: Icons.child_care,
                  label: 'Bola',
                  color: AppTheme.secondaryColor,
                  onTap: () => _navigateToLogin(context, 'child'),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  icon: Icons.family_restroom,
                  label: 'Ota-ona',
                  color: AppTheme.primaryColor,
                  onTap: () => _navigateToLogin(context, 'parent'),
                ),
                const SizedBox(height: 16),
                _RoleButton(
                  icon: Icons.school,
                  label: 'Pedagog',
                  color: const Color(0xFF6C5CE7),
                  onTap: () => _navigateToLogin(context, 'teacher'),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => _navigateToLogin(context, 'admin'),
                  child: const Text(
                    'Admin panel',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToLogin(BuildContext context, String role) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(role: role)),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 32, color: color),
                ),
                const SizedBox(width: 20),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_ios, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
