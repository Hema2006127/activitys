import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/database/models.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'اختر يوم',
      cancelText: 'إلغاء',
      confirmText: 'موافق',
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    int selectedPriority = 1;
    DateTime taskDate = _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 24,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('مهمة جديدة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                textAlign: TextAlign.right,
                decoration: InputDecoration(
                  hintText: 'اسم المهمة...',
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.task_alt),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                textAlign: TextAlign.right,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'ملاحظة (اختياري)...',
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              // Priority selector
              Row(
                children: [
                  const Text('الأولوية:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  ...[0, 1, 2].map((p) {
                    final labels = ['منخفضة', 'متوسطة', 'عالية'];
                    final colors = [Colors.green, Colors.orange, Colors.red];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(labels[p]),
                        selected: selectedPriority == p,
                        selectedColor: colors[p],
                        onSelected: (_) => setModalState(() => selectedPriority = p),
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              // Date selector
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: taskDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setModalState(() => taskDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormat('EEEE، d MMMM yyyy', 'ar').format(taskDate)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    ref.read(tasksProvider.notifier).addTask(
                      titleCtrl.text.trim(),
                      date: taskDate,
                      priority: selectedPriority,
                      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
                    );
                    setState(() => _selectedDate = taskDate);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة المهمة'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(tasksProvider);
    final notifier = ref.read(tasksProvider.notifier);
    final tasks = notifier.getTasksForDate(_selectedDate);
    final completed = tasks.where((t) => t.isCompleted).length;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المهام 📋'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 28),
            tooltip: 'مهمة جديدة',
            onPressed: _showAddTaskDialog,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'مهام اليوم'),
            Tab(icon: Icon(Icons.history), text: 'السجل'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // --- TAB 1: Day View ---
          Column(
            children: [
              // Date navigation bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: theme.colorScheme.surface,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => setState(() => _selectedDate = _selectedDate.subtract(const Duration(days: 1))),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: Column(
                          children: [
                            Text(
                              _isToday ? 'اليوم' : DateFormat('EEEE', 'ar').format(_selectedDate),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.primaryColor),
                            ),
                            Text(
                              DateFormat('d MMMM yyyy', 'ar').format(_selectedDate),
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => setState(() => _selectedDate = _selectedDate.add(const Duration(days: 1))),
                    ),
                  ],
                ),
              ),

              // Progress bar
              if (tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$completed / ${tasks.length} مكتملة', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${(completed / tasks.length * 100).toStringAsFixed(0)}%', style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: tasks.isEmpty ? 0 : completed / tasks.length,
                          minHeight: 8,
                          backgroundColor: Colors.white12,
                          valueColor: AlwaysStoppedAnimation(completed == tasks.length ? Colors.green : theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),

              // Task list
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, size: 70, color: Colors.white24),
                            const SizedBox(height: 16),
                            const Text('لا توجد مهام لهذا اليوم', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            const SizedBox(height: 8),
                            const Text('اضغط + لإضافة مهمة جديدة', style: TextStyle(color: Colors.white38)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return _TaskCard(
                            task: task,
                            onToggle: () => ref.read(tasksProvider.notifier).toggleTask(task.id),
                            onDelete: () => ref.read(tasksProvider.notifier).deleteTask(task.id),
                          );
                        },
                      ),
              ),
            ],
          ),

          // --- TAB 2: History ---
          Builder(builder: (context) {
            final dates = notifier.datesWithTasks;
            if (dates.isEmpty) {
              return const Center(child: Text('لا يوجد سجل بعد', style: TextStyle(color: Colors.grey)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: dates.length,
              itemBuilder: (context, i) {
                final date = dates[i];
                final dayTasks = notifier.getTasksForDate(date);
                final doneCount = dayTasks.where((t) => t.isCompleted).length;
                final isToday = date.year == DateTime.now().year &&
                    date.month == DateTime.now().month &&
                    date.day == DateTime.now().day;

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: doneCount == dayTasks.length ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                      child: Text('$doneCount/${dayTasks.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(
                      isToday ? 'اليوم' : DateFormat('EEEE، d MMM', 'ar').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${dayTasks.length} مهمة • $doneCount مكتملة', style: const TextStyle(color: Colors.grey)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.open_in_new, size: 18),
                          onPressed: () {
                            setState(() {
                              _selectedDate = date;
                              _tabController.animateTo(0);
                            });
                          },
                        ),
                      ],
                    ),
                    children: dayTasks.map((task) => ListTile(
                      dense: true,
                      leading: Icon(
                        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: task.isCompleted ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? Colors.grey : Colors.white,
                        ),
                      ),
                      subtitle: task.note != null ? Text(task.note!, style: const TextStyle(color: Colors.white54, fontSize: 12)) : null,
                      trailing: _PriorityBadge(priority: task.priority),
                    )).toList(),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ---- Task Card Widget ----
class _TaskCard extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskCard({required this.task, required this.onToggle, required this.onDelete});

  Color get _priorityColor {
    if (task.priority == 2) return Colors.red;
    if (task.priority == 1) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('حذف المهمة؟'),
            content: Text('هل تريد حذف "${task.title}"؟'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف', style: TextStyle(color: Colors.red))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _priorityColor.withValues(alpha: 0.3), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Priority line
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(color: _priorityColor, borderRadius: BorderRadius.circular(4)),
                ),
                const SizedBox(width: 12),
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: task.isCompleted ? Colors.green : Colors.transparent,
                      border: Border.all(
                        color: task.isCompleted ? Colors.green : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Title & note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          color: task.isCompleted ? Colors.grey : Colors.white,
                        ),
                      ),
                      if (task.note != null) ...[
                        const SizedBox(height: 2),
                        Text(task.note!, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ],
                  ),
                ),
                // Delete button
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('حذف المهمة؟'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                        TextButton(
                          onPressed: () { Navigator.pop(context); onDelete(); },
                          child: const Text('حذف', style: TextStyle(color: Colors.red)),
                        ),
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
}

class _PriorityBadge extends StatelessWidget {
  final int priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final labels = ['منخفضة', 'متوسطة', 'عالية'];
    final colors = [Colors.green, Colors.orange, Colors.red];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colors[priority].withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors[priority].withValues(alpha: 0.4)),
      ),
      child: Text(labels[priority], style: TextStyle(fontSize: 11, color: colors[priority])),
    );
  }
}
