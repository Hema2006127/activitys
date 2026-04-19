import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:gymapp/core/database/hive_setup.dart';
import 'package:gymapp/core/providers/gym_provider.dart';
import 'package:gymapp/core/providers/tasks_provider.dart';
import 'package:gymapp/core/providers/water_provider.dart';
import 'package:gymapp/core/providers/weight_provider.dart';
import 'package:gymapp/core/providers/meals_provider.dart';
import 'package:gymapp/core/providers/sleep_provider.dart';
import 'package:gymapp/core/providers/workout_provider.dart';

const String _groqApiKey = 'YOUR_API_KEY';
const String _groqModel = 'llama-3.3-70b-versatile';
const int _maxHistoryMessages = 20;

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _ChatMsg {
  final String text;
  final bool isUser;
  _ChatMsg({required this.text, required this.isUser});

  Map<String, dynamic> toJson() => {'text': text, 'isUser': isUser};
  factory _ChatMsg.fromJson(Map<String, dynamic> j) =>
      _ChatMsg(text: j['text'], isUser: j['isUser']);
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final List<_ChatMsg> _messages = [];
  final List<Map<String, String>> _apiHistory = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late Box<String> _chatBox;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _chatBox = Hive.box<String>(HiveSetup.chatBox);
    _loadHistory();
  }

  void _loadHistory() {
    if (_chatBox.isEmpty) {
      // First time — add welcome message
      _messages.add(_ChatMsg(
        text: "مرحباً! أنا مدربك الشخصي الذكي 🏋️\nأتذكر محادثاتنا السابقة وأستطيع تحليل بياناتك اليومية لإرشادك بشكل مخصص. ما الذي تريد معرفته اليوم؟",
        isUser: false,
      ));
    } else {
      // Load saved messages
      for (final raw in _chatBox.values) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          final msg = _ChatMsg.fromJson(map);
          _messages.add(msg);
          // Rebuild API history (skip welcome message from history)
          if (msg.isUser) {
            _apiHistory.add({'role': 'user', 'content': msg.text});
          } else if (_chatBox.values.first != raw) {
            _apiHistory.add({'role': 'assistant', 'content': msg.text});
          }
        } catch (_) {}
      }
      // Keep only last N for API
      if (_apiHistory.length > _maxHistoryMessages) {
        _apiHistory.removeRange(0, _apiHistory.length - _maxHistoryMessages);
      }
    }
  }

  void _saveMessage(_ChatMsg msg) {
    _chatBox.add(jsonEncode(msg.toJson()));
    // Trim if too many stored
    if (_chatBox.length > 100) {
      _chatBox.deleteAt(0);
    }
  }

  void _clearHistory() {
    _chatBox.clear();
    setState(() {
      _messages.clear();
      _apiHistory.clear();
      _messages.add(_ChatMsg(
        text: "تم مسح المحادثة السابقة 🗑️ كيف يمكنني مساعدتك اليوم؟",
        isUser: false,
      ));
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _buildSystemPrompt() {
    final gymStreak = ref.read(gymProvider.notifier).currentStreak;
    final waterLog = ref.read(waterProvider);
    final tasksRate = (ref.read(tasksProvider.notifier).completionRate * 100).toStringAsFixed(0);
    final weightList = ref.read(weightProvider);
    final weight = weightList.isNotEmpty ? weightList.last.weight : 0.0;
    final meals = ref.read(mealsProvider).mealsCount;
    final sleep = ref.read(sleepProvider).hours;
    final today = DateTime.now();
    final workouts = ref.read(workoutProvider.notifier).getSetsForDate(today);
    final workoutSummary = workouts.isEmpty
        ? "لا يوجد تمارين مسجلة اليوم"
        : workouts.map((s) => "${s.muscleGroup} (${s.musclePart}): ${s.weight}kg").join(', ');

    final userName = HiveSetup.getSetting('user_name') ?? 'صديقي';
    final gymGoal = int.tryParse(HiveSetup.getSetting('gym_days_goal') ?? '4') ?? 4;

    return '''أنت "كوتش جيم" — مدرب لياقة بدنية وتغذية شخصي خبير داخل تطبيق GymApp.

## هويتك وأسلوبك:
- اسمك "كوتش جيم"، وأنت متخصص في اللياقة البدنية والتغذية وبناء العادات الصحية.
- تحدث دائماً بنفس لغة المستخدم: إذا كتب عربي رد عربي، إذا كتب إنجليزي رد إنجليزي.
- أسلوبك: واضح، عملي، مشجع — مثل صديق خبير وليس كتاب طبي.
- لا تقل "كمدرب ذكاء اصطناعي..." أو "لا أستطيع..." — أنت مدرب حقيقي.

## قواعد الردود:
- استخدم بيانات المستخدم الحية دائماً في إجاباتك.
- اعطِ نصائح محددة وقابلة للتطبيق، مش كلام عام.
- الرد المثالي: 3-6 جمل واضحة، أو قائمة مرتبة إذا طلب خطة.
- إذا سأل عن تمرين: اشرح الحركة، العضلات المستهدفة، والتكرارات المناسبة.
- إذا سأل عن تغذية: اعطِ أمثلة واقعية ملائمة لنمط حياته.
- إذا سأل عن وزنه أو تقدمه: حلّل البيانات الحية وقارنها بأهدافه.

## بيانات المستخدم الحية الآن:
- الاسم: $userName
- سلسلة الجيم (streak): $gymStreak يوم متتالي (هدفه $gymGoal أيام/أسبوع)
- شرب الماء اليوم: ${waterLog.amount} مل من أصل ${waterLog.goal} مل (${(waterLog.goal > 0 ? waterLog.amount / waterLog.goal * 100 : 0).toStringAsFixed(0)}%)
- إنجاز المهام اليوم: $tasksRate%
- آخر وزن مسجل: ${weight > 0 ? '$weight كجم' : 'لم يُسجَّل بعد'}
- عدد الوجبات اليوم: $meals
- ساعات النوم الأخيرة: ${sleep > 0 ? '${sleep.toStringAsFixed(1)} ساعة' : 'لم تُسجَّل بعد'}
- تمارين اليوم: $workoutSummary

## تعليمات مهمة:
- إذا كان الماء أقل من 50% من الهدف → نبّهه بلطف.
- إذا كان الـ streak كبير → اثنِ عليه وشجعه يكمل.
- إذا كان النوم أقل من 7 ساعات → أشر لأثره على الأداء الرياضي.
- تذكر سياق المحادثة السابقة وربط الردود ببعضها.''';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = _ChatMsg(text: text, isUser: true);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _saveMessage(userMsg);
    _controller.clear();
    _apiHistory.add({'role': 'user', 'content': text});
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _groqModel,
          'messages': [
            {'role': 'system', 'content': _buildSystemPrompt()},
            ..._apiHistory.takeLast(_maxHistoryMessages),
          ],
          'max_tokens': 900,
          'temperature': 0.55,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'] as String;
        _apiHistory.add({'role': 'assistant', 'content': reply});

        final aiMsg = _ChatMsg(text: reply, isUser: false);
        _saveMessage(aiMsg);
        setState(() {
          _messages.add(aiMsg);
          _isLoading = false;
        });
      } else {
        final error = jsonDecode(response.body);
        _apiHistory.removeLast();
        setState(() {
          _messages.add(_ChatMsg(
            text: "⚠️ خطأ: ${error['error']['message'] ?? response.statusCode}",
            isUser: false,
          ));
          _isLoading = false;
        });
      }
    } catch (e) {
      _apiHistory.removeLast();
      setState(() {
        _messages.add(_ChatMsg(
          text: "⚠️ تعذّر الاتصال. تأكد من اتصالك بالإنترنت.",
          isUser: false,
        ));
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Coach 🧠'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'مسح المحادثة',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('مسح المحادثة؟'),
                content: const Text('سيتم حذف تاريخ المحادثة نهائياً.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearHistory();
                    },
                    child: const Text('مسح', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final msg = _messages[i];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? theme.primaryColor : theme.colorScheme.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: msg.isUser ? const Radius.circular(20) : Radius.zero,
                        bottomRight: msg.isUser ? Radius.zero : const Radius.circular(20),
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 6, offset: const Offset(2, 2))],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(color: msg.isUser ? Colors.black : Colors.white, fontSize: 15, height: 1.5),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 10),
                  Text("المدرب يفكر...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textAlign: TextAlign.right,
                      decoration: InputDecoration(
                        hintText: 'اسأل مدربك الذكي...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: Colors.black12,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: theme.primaryColor,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded),
                      color: Colors.black,
                      onPressed: _isLoading ? null : _sendMessage,
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

extension _ListExtension<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}
