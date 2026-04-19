import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/widgets/empty_state_widget.dart';

class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addWeight() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final weight = double.tryParse(text);
    if (weight != null && weight > 0) {
      ref.read(weightProvider.notifier).addWeight(weight);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final weights = ref.watch(weightProvider);
    final sorted  = [...weights]..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(title: const Text('تتبع الوزن')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: 'أدخل وزنك اليوم (كجم)...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    ),
                    onSubmitted: (_) => _addWeight(),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _addWeight,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.black
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('سجّل', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('سجل الوزن',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: sorted.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.monitor_weight_outlined,
                      title: 'لسه ماسجلتش وزنك',
                      subtitle: 'ابدأ دلوقتي وتابع تقدمك\nكل يوم بيفرق!',
                      color: Colors.purpleAccent,
                    )
                  : ListView.separated(
                      itemCount: sorted.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final log = sorted[i];
                        final isFirst = i == 0;
                        double? diff;
                        if (i < sorted.length - 1) {
                          diff = log.weight - sorted[i + 1].weight;
                        }
                        return ListTile(
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.purpleAccent.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.monitor_weight,
                                color: Colors.purpleAccent, size: 22),
                          ),
                          title: Row(
                            children: [
                              Text('${log.weight} كجم',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isFirst
                                          ? Colors.purpleAccent
                                          : null)),
                              if (diff != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: diff < 0
                                        ? Colors.green.withValues(alpha: 0.15)
                                        : Colors.red.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${diff > 0 ? '+' : ''}${diff.toStringAsFixed(1)}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: diff < 0
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${log.date.day}/${log.date.month}/${log.date.year}  '
                            '${log.date.hour}:${log.date.minute.toString().padLeft(2, '0')}',
                          ),
                          trailing: isFirst
                              ? const Chip(
                                  label: Text('آخر تسجيل',
                                      style: TextStyle(fontSize: 11)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                )
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
