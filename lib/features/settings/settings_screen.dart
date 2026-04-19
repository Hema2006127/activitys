import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/theme_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/services/auth_service.dart';
import 'package:gymapp/features/auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late int _waterGoal;
  late int _gymDaysGoal;

  @override
  void initState() {
    super.initState();
    final name = HiveSetup.getSetting('user_name') ?? '';
    final waterStr = HiveSetup.getSetting('water_goal');
    final gymStr = HiveSetup.getSetting('gym_days_goal');
    _nameCtrl = TextEditingController(text: name);
    _waterGoal = int.tryParse(waterStr ?? '') ?? 2000;
    _gymDaysGoal = int.tryParse(gymStr ?? '') ?? 4;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isNotEmpty) HiveSetup.setSetting('user_name', name);
    HiveSetup.setSetting('water_goal', _waterGoal.toString());
    HiveSetup.setSetting('gym_days_goal', _gymDaysGoal.toString());
    ref.read(waterProvider.notifier).setGoal(_waterGoal);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم حفظ الإعدادات', textAlign: TextAlign.center),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج من حسابك؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('خروج', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, _, _) => const LoginScreen(),
          transitionsBuilder: (_, anim, _, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = ref.watch(themeProvider.notifier).isLight;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('حفظ', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── الحساب ─────────────────────────────────────────────────────────
          _SectionHeader(label: 'الحساب'),
          if (user != null) ...[
            _InfoTile(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: user.email ?? '-',
            ),
            const SizedBox(height: 8),
          ],
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'الاسم',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'اكتب اسمك...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── الأهداف ────────────────────────────────────────────────────────
          _SectionHeader(label: 'الأهداف اليومية'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Water goal
                  Row(
                    children: [
                      const Icon(
                        Icons.water_drop,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'هدف المياه اليومي',
                        style: TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        '$_waterGoal مل',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _waterGoal.toDouble(),
                    min: 1000,
                    max: 4000,
                    divisions: 12,
                    activeColor: Colors.blue,
                    onChanged: (v) => setState(() => _waterGoal = v.round()),
                  ),

                  const Divider(height: 24),

                  // Gym days goal
                  Row(
                    children: [
                      const Icon(
                        Icons.fitness_center,
                        color: Color(0xFF00E5FF),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'أيام الجيم في الأسبوع',
                        style: TextStyle(fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        '$_gymDaysGoal أيام',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _gymDaysGoal.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    activeColor: const Color(0xFF00E5FF),
                    onChanged: (v) => setState(() => _gymDaysGoal = v.round()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── المظهر ────────────────────────────────────────────────────────
          _SectionHeader(label: 'المظهر'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: SwitchListTile(
              secondary: Icon(isLight ? Icons.light_mode : Icons.dark_mode),
              title: Text(isLight ? 'الوضع المضيء' : 'الوضع المظلم'),
              value: isLight,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── تسجيل الخروج ─────────────────────────────────────────────────
          _SectionHeader(label: 'الحساب'),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'تسجيل الخروج',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text('الخروج من حسابك الحالي'),
              onTap: _logout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white54
              : Colors.black45,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
