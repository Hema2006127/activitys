import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/theme/app_theme.dart';

class FitnessToolsScreen extends StatefulWidget {
  final int initialTab;
  const FitnessToolsScreen({super.key, this.initialTab = 0});

  @override
  State<FitnessToolsScreen> createState() => _FitnessToolsScreenState();
}

class _FitnessToolsScreenState extends State<FitnessToolsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('أدوات وحاسبات اللياقة ⚡'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentColor,
          labelColor: AppTheme.accentColor,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'BMI والوزن'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'السعرات TDEE'),
            Tab(icon: Icon(Icons.timer_outlined), text: 'مؤقت الراحة'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _BmiCalculatorTab(),
          _TdeeCalculatorTab(),
          _RestTimerTab(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 1. BMI & Ideal Weight Tab
// ═══════════════════════════════════════════════════════════════════════════════
class _BmiCalculatorTab extends ConsumerStatefulWidget {
  const _BmiCalculatorTab();

  @override
  ConsumerState<_BmiCalculatorTab> createState() => _BmiCalculatorTabState();
}

class _BmiCalculatorTabState extends ConsumerState<_BmiCalculatorTab> {
  final _heightCtrl = TextEditingController(text: '175');
  final _weightCtrl = TextEditingController(text: '75');
  bool _isMale = true;
  double? _bmi;
  String _category = '';
  Color _catColor = Colors.green;
  double? _minIdealWeight;
  double? _maxIdealWeight;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final h = double.tryParse(_heightCtrl.text) ?? 0.0;
    final w = double.tryParse(_weightCtrl.text) ?? 0.0;
    if (h > 50 && w > 20) {
      final hMeter = h / 100.0;
      final bmiVal = w / (hMeter * hMeter);
      setState(() {
        _bmi = bmiVal;
        _minIdealWeight = 18.5 * (hMeter * hMeter);
        _maxIdealWeight = 24.9 * (hMeter * hMeter);

        if (bmiVal < 18.5) {
          _category = 'نقص في الوزن (Underweight)';
          _catColor = Colors.blue;
        } else if (bmiVal < 25.0) {
          _category = 'وزن مثالي وصحي (Normal)';
          _catColor = Colors.greenAccent;
        } else if (bmiVal < 30.0) {
          _category = 'زيادة في الوزن (Overweight)';
          _catColor = Colors.orangeAccent;
        } else {
          _category = 'سمنة (Obese)';
          _catColor = Colors.redAccent;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.male, size: 20),
                      SizedBox(width: 6),
                      Text('ذكر'),
                    ],
                  ),
                  selected: _isMale,
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _isMale = true);
                    _calculate();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.female, size: 20),
                      SizedBox(width: 6),
                      Text('أنثى'),
                    ],
                  ),
                  selected: !_isMale,
                  onSelected: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _isMale = false);
                    _calculate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الطول (سم)',
                    prefixIcon: const Icon(Icons.height),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الوزن (كجم)',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_bmi != null) ...[
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    _catColor.withValues(alpha: 0.2),
                    Theme.of(context).cardColor,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                border: Border.all(color: _catColor.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Column(
                children: [
                  const Text('مؤشر كتلة جسمك (BMI)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    _bmi!.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _catColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _category,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _catColor,
                    ),
                  ),
                  const Divider(height: 32),
                  if (_minIdealWeight != null && _maxIdealWeight != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('الوزن المثالي المقترح',
                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${_minIdealWeight!.toStringAsFixed(1)} - ${_maxIdealWeight!.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('احتياج الماء اليومي',
                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${((double.tryParse(_weightCtrl.text) ?? 70) * 35 / 1000).toStringAsFixed(1)} لتر',
                              style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                final w = double.tryParse(_weightCtrl.text);
                if (w != null && w > 0) {
                  HapticFeedback.mediumImpact();
                  ref.read(weightProvider.notifier).addWeight(w);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تسجيل وزن $w كجم بنجاح في سجلك! 🎯'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('حفظ هذا الوزن في سجلي الشخصي'),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 2. TDEE & Calories Tab
// ═══════════════════════════════════════════════════════════════════════════════
class _TdeeCalculatorTab extends ConsumerStatefulWidget {
  const _TdeeCalculatorTab();

  @override
  ConsumerState<_TdeeCalculatorTab> createState() => _TdeeCalculatorTabState();
}

class _TdeeCalculatorTabState extends ConsumerState<_TdeeCalculatorTab> {
  final _ageCtrl = TextEditingController(text: '24');
  final _heightCtrl = TextEditingController(text: '175');
  final _weightCtrl = TextEditingController(text: '75');
  bool _isMale = true;
  double _activityMultiplier = 1.375; // light activity (1-3 days)

  double? _bmr;
  double? _tdee;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final age = double.tryParse(_ageCtrl.text) ?? 24;
    final h = double.tryParse(_heightCtrl.text) ?? 175;
    final w = double.tryParse(_weightCtrl.text) ?? 75;

    // Mifflin-St Jeor
    double baseBmr = (10 * w) + (6.25 * h) - (5 * age);
    baseBmr += _isMale ? 5 : -161;

    setState(() {
      _bmr = baseBmr;
      _tdee = baseBmr * _activityMultiplier;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.male, size: 18), SizedBox(width: 4), Text('ذكر')],
                  ),
                  selected: _isMale,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _isMale = true);
                    _calculate();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.female, size: 18), SizedBox(width: 4), Text('أنثى')],
                  ),
                  selected: !_isMale,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _isMale = false);
                    _calculate();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'العمر',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _heightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الطول (سم)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الوزن (كجم)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => _calculate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text('مستوى النشاط الأسبوعي:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<double>(
            initialValue: _activityMultiplier,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
            items: const [
              DropdownMenuItem(value: 1.2, child: Text('خامل (عمل مكتبي وقليل الحركة)')),
              DropdownMenuItem(value: 1.375, child: Text('نشاط خفيف (تمرين 1-3 أيام/أسبوع)')),
              DropdownMenuItem(value: 1.55, child: Text('نشاط متوسط (تمرين 3-5 أيام/أسبوع)')),
              DropdownMenuItem(value: 1.725, child: Text('نشاط عالي (تمرين 6-7 أيام شاق)')),
            ],
            onChanged: (val) {
              if (val != null) {
                HapticFeedback.selectionClick();
                setState(() => _activityMultiplier = val);
                _calculate();
              }
            },
          ),
          const SizedBox(height: 24),
          if (_tdee != null && _bmr != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Theme.of(context).cardColor,
                border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('معدل الحرق الأساسي (BMR)',
                              style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${_bmr!.toInt()} kcal',
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          const Text('سعرات الثبات (TDEE)',
                              style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            '${_tdee!.toInt()} kcal',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('أهدافك المقترحة:',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CalorieGoalCard(
                          title: 'تنشيف / خسارة',
                          cals: (_tdee! - 500).toInt(),
                          color: Colors.blueAccent,
                          icon: Icons.trending_down,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CalorieGoalCard(
                          title: 'تثبيت الوزن',
                          cals: _tdee!.toInt(),
                          color: Colors.greenAccent,
                          icon: Icons.trending_flat,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CalorieGoalCard(
                          title: 'ضخامة / عضلات',
                          cals: (_tdee! + 400).toInt(),
                          color: Colors.purpleAccent,
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CalorieGoalCard extends StatelessWidget {
  final String title;
  final int cals;
  final Color color;
  final IconData icon;

  const _CalorieGoalCard({
    required this.title,
    required this.cals,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text('$cals',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Text('kcal', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// 3. Rest Stopwatch & Timer Tab
// ═══════════════════════════════════════════════════════════════════════════════
class _RestTimerTab extends StatefulWidget {
  const _RestTimerTab();

  @override
  State<_RestTimerTab> createState() => _RestTimerTabState();
}

class _RestTimerTabState extends State<_RestTimerTab> {
  int _selectedDuration = 60; // seconds
  int _remaining = 60;
  bool _isRunning = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    setState(() => _isRunning = true);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remaining > 1) {
        setState(() => _remaining--);
      } else {
        t.cancel();
        setState(() {
          _remaining = 0;
          _isRunning = false;
        });
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 300), () {
          HapticFeedback.heavyImpact();
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.amber, size: 28),
                  SizedBox(width: 10),
                  Text('انتهى وقت الراحة! 🏋️'),
                ],
              ),
              content: const Text('يلا للمجموعة التالية بكل حماس! 💪'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _resetTimer();
                  },
                  child: const Text('تم'),
                ),
              ],
            ),
          );
        }
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _remaining = _selectedDuration;
    });
  }

  void _setDuration(int seconds) {
    HapticFeedback.selectionClick();
    _timer?.cancel();
    setState(() {
      _selectedDuration = seconds;
      _remaining = seconds;
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = _selectedDuration > 0
        ? (_remaining / _selectedDuration).clamp(0.0, 1.0)
        : 0.0;
    final mins = _remaining ~/ 60;
    final secs = _remaining % 60;
    final timeStr =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('مؤقت الراحة بين المجموعات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Preset duration chips
          Wrap(
            spacing: 8,
            children: [30, 45, 60, 90, 120, 180].map((s) {
              final isSel = _selectedDuration == s;
              return ChoiceChip(
                label: Text(s >= 60 ? '${s ~/ 60} د' : '$s ث'),
                selected: isSel,
                onSelected: (_) => _setDuration(s),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),

          // Big circular countdown
          SizedBox(
            width: 220,
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remaining <= 5 ? Colors.redAccent : AppTheme.accentColor,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: _remaining <= 5 ? Colors.redAccent : null,
                      ),
                    ),
                    Text(
                      _isRunning ? 'استرح وتنفس 💨' : 'جاهز للمجموعة',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                iconSize: 32,
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh),
              ),
              const SizedBox(width: 24),
              FloatingActionButton.large(
                onPressed: _isRunning ? _pauseTimer : _startTimer,
                backgroundColor: _isRunning ? Colors.amber : AppTheme.primaryColor,
                child: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  size: 42,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 24),
              IconButton.filledTonal(
                iconSize: 32,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _setDuration(_selectedDuration + 15);
                },
                icon: const Icon(Icons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
