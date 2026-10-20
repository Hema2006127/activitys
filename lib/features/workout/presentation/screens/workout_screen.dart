import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymapp/core/providers/rest_timer_provider.dart';
import 'package:gymapp/core/providers/workout_provider.dart';
import 'package:gymapp/features/tools/fitness_tools_screen.dart';
import 'package:gymapp/features/workout/presentation/widgets/rest_timer_bar.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final DateTime date;
  const WorkoutScreen({super.key, required this.date});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  final _weightController = TextEditingController();
  String _selectedGroup = 'Chest';
  String _selectedPart = '';

  final Map<String, List<String>> _muscleParts = {
    'Chest': ['Upper', 'Middle', 'Lower', 'Inner'],
    'Back': ['Lats', 'Upper Back', 'Lower Back', 'Traps'],
    'Shoulders': ['Front Delt', 'Side Delt', 'Rear Delt'],
    'Legs': ['Quads', 'Hamstrings', 'Glutes', 'Calves'],
    'Arms': ['Biceps', 'Triceps', 'Forearms'],
    'Core': ['Abs', 'Obliques'],
  };

  @override
  void initState() {
    super.initState();
    _selectedPart = _muscleParts[_selectedGroup]!.first;
  }

  @override
  Widget build(BuildContext context) {
    // using watch to rebuild when the state changes
    final allSets = ref.watch(workoutProvider);
    final sets = allSets
        .where(
          (s) =>
              s.date.year == widget.date.year &&
              s.date.month == widget.date.month &&
              s.date.day == widget.date.day,
        )
        .toList();

    return Scaffold(
      bottomNavigationBar: const RestTimerBar(),
      appBar: AppBar(
        title: Text(
          'تمرين: ${widget.date.day}/${widget.date.month}/${widget.date.year}',
        ),
        actions: [
          IconButton(
            tooltip: 'مؤقت الراحة بين المجموعات',
            icon: const Icon(Icons.timer_outlined, color: Color(0xFF00E5FF)),
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const FitnessToolsScreen(initialTab: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () => ref
                        .read(workoutProvider.notifier)
                        .addTemplate(widget.date, 'Push'),
                    child: const Text('Push Day'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(workoutProvider.notifier)
                        .addTemplate(widget.date, 'Pull'),
                    child: const Text('Pull Day'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(workoutProvider.notifier)
                        .addTemplate(widget.date, 'Legs'),
                    child: const Text('Legs Day'),
                  ),
                ],
              ),
            ),
            const Divider(height: 30),

            // Add Set Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedGroup,
                            decoration: const InputDecoration(
                              labelText: 'Muscle Group',
                            ),
                            items: _muscleParts.keys
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedGroup = val;
                                  _selectedPart = _muscleParts[val]!.first;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPart,
                            decoration: const InputDecoration(
                              labelText: 'Specific Part',
                            ),
                            items: _muscleParts[_selectedGroup]!
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(() => _selectedPart = val);
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
                            controller: _weightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Weight (kg)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            final w =
                                double.tryParse(_weightController.text) ?? 0.0;
                            HapticFeedback.mediumImpact();
                            ref
                                .read(workoutProvider.notifier)
                                .addSet(
                                  widget.date,
                                  _selectedGroup,
                                  _selectedPart,
                                  w,
                                );
                            _weightController.clear();
                            // ابدأ عداد الراحة تلقائياً بعد كل set
                            final setNo = sets
                                    .where((s) =>
                                        s.muscleGroup == _selectedGroup &&
                                        s.musclePart == _selectedPart)
                                    .length +
                                1;
                            ref.read(restTimerProvider.notifier).start(
                                  label: '$_selectedGroup • $_selectedPart • Set $setNo',
                                );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Set'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Logged Sets',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: sets.isEmpty
                  ? const Center(child: Text('No sets logged yet.'))
                  : ListView.builder(
                      itemCount: sets.length,
                      itemBuilder: (context, index) {
                        final s = sets[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.fitness_center),
                            title: Text('${s.muscleGroup} - ${s.musclePart}'),
                            subtitle: Text('Weight: ${s.weight} kg'),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => ref
                                  .read(workoutProvider.notifier)
                                  .removeSet(s.id),
                            ),
                          ),
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
