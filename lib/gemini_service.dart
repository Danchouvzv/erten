import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Single place for the Gemini API key.
// For production: load from flutter_dotenv / --dart-define; never commit keys.
// ─────────────────────────────────────────────────────────────────────────────
const _kGeminiApiKey =
    'AIzaSyB3RN6JsuwF3MfMsD-yv1i9Lnz5wlvsoRh9ke6pmKUnb2xk66A';

// ─────────────────────────────────────────────────────────────────────────────
// GeminiService — all AI calls in one place
// ─────────────────────────────────────────────────────────────────────────────
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  /// Gemini 1.5 Flash — fast & cheap for task generation
  late final GenerativeModel _model = GenerativeModel(
    model: 'gemini-1.5-flash',
    apiKey: _kGeminiApiKey,
    generationConfig: GenerationConfig(
      temperature: 0.7,
      responseMimeType: 'application/json',
    ),
    systemInstruction: Content.system(_kSystemPrompt),
  );

  // ── public API ─────────────────────────────────────────────────────────────

  /// Generate [TaskBlock] list from a user directive.
  Future<List<RichTaskData>> generateTimeBlocks({
    required String directive,
    required String todayStr,
    required String timeStr,
    String planningType = 'Deep Work',
    int energyLevel = 3,
    double availableHours = 4.0,
    String hardCommitments = '',
  }) async {
    final prompt = '''
Today is $todayStr. Current time: $timeStr.
Directive: $directive
Mission type: $planningType
Energy level: $energyLevel/5
Available execution time: $availableHours hours
Hard commitments / constraints: ${hardCommitments.isEmpty ? 'None' : hardCommitments}

Build a plan that respects the user's energy and available time.
If energy is low, use shorter blocks and more recovery.
If hard commitments are listed, avoid scheduling over them.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final parsed = _parseJsonList(text);
      return _richTasksFromJson(parsed);
    } catch (_) {
      return _fallbackRichPlan(
        directive: directive,
        timeStr: timeStr,
        energyLevel: energyLevel,
        availableHours: availableHours,
      );
    }
  }

  Future<List<TaskBlock>> rerouteRemainingBlocks({
    required String directive,
    required List<TaskBlock> completed,
    required List<TaskBlock> remaining,
    required String reason,
    required String todayStr,
    required String timeStr,
  }) async {
    final completedText = completed
        .map((t) => '- ${t.startTime}-${t.endTime}: ${t.title}')
        .join('\n');
    final remainingText = remaining
        .map((t) => '- ${t.startTime}-${t.endTime}: ${t.title}')
        .join('\n');
    final prompt = '''
Today is $todayStr. Current time: $timeStr.
Primary directive: $directive
Reroute reason: $reason

Completed blocks:
${completedText.isEmpty ? 'None' : completedText}

Remaining / interrupted blocks:
${remainingText.isEmpty ? 'None' : remainingText}

Rebuild only the remaining day from the current time onward.
Keep completed work untouched.
Return 2-5 realistic blocks. No overlaps. No blocks before current time.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final text = response.text?.trim() ?? '';
      final parsed = _parseJsonList(text);
      return _tasksFromJson(parsed, idPrefix: 'reroute', fallbackTime: timeStr);
    } catch (_) {
      return _fallbackRichPlan(
        directive: directive,
        timeStr: timeStr,
        idPrefix: 'reroute',
      ).map((r) => r.block).toList();
    }
  }

  Future<String> generateMissionDebrief({
    required String directive,
    required List<TaskBlock> tasks,
    required int rerouteCount,
  }) async {
    final completed = tasks.where((t) => t.isCompleted).length;
    final log = tasks
        .map((t) =>
            '- ${t.startTime}-${t.endTime}: ${t.title} [${t.isCompleted ? 'done' : t.isSkipped ? 'skipped' : 'missed'}]')
        .join('\n');
    final prompt = '''
Directive: $directive
Completion: $completed/${tasks.length}
Reroutes used: $rerouteCount
Execution log:
$log

Write a concise mission debrief in 3 sections:
1. What worked
2. What broke
3. Tomorrow adjustment
Keep it under 90 words. Make it specific and direct.
''';
    return ask(prompt);
  }

  /// Ask Gemini anything and get a plain-text response (for insight cards, coach, etc.)
  Future<String> ask(String prompt) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _kGeminiApiKey,
      systemInstruction: Content.system(
        'You are ERTEN — a ruthlessly precise AI time architect. '
        'Be cold, elite, and concise. Max 3 sentences.',
      ),
    );
    final response = await model.generateContent([Content.text(prompt)]);
    return response.text?.trim() ?? '';
  }

  List<dynamic> _parseJsonList(String text) {
    final clean = text
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '')
        .trim();
    return jsonDecode(clean) as List<dynamic>;
  }

  List<RichTaskData> _richTasksFromJson(List<dynamic> parsed) {
    final blocks = _tasksFromJson(parsed);
    return parsed.asMap().entries.map((entry) {
      final m = entry.value as Map<String, dynamic>;
      return RichTaskData(
        block: blocks[entry.key],
        description: (m['description'] ?? '').toString(),
      );
    }).toList();
  }

  List<TaskBlock> _tasksFromJson(
    List<dynamic> parsed, {
    String idPrefix = 'ai',
    String fallbackTime = '09:00',
  }) {
    final ts = DateTime.now().millisecondsSinceEpoch;
    return parsed.asMap().entries.map((e) {
      final m = e.value as Map<String, dynamic>;
      return TaskBlock(
        id: '${idPrefix}_${ts}_${e.key}',
        startTime: m['startTime'] ?? fallbackTime,
        endTime: m['endTime'] ?? fallbackTime,
        title: m['title'] ?? 'Task ${e.key + 1}',
        description: (m['description'] ?? '').toString(),
      );
    }).toList();
  }

  List<RichTaskData> _fallbackRichPlan({
    required String directive,
    required String timeStr,
    int energyLevel = 3,
    double availableHours = 4.0,
    String idPrefix = 'fallback',
  }) {
    final start = _roundUpToNextQuarter(_minutes(timeStr));
    final titles = energyLevel <= 2
        ? [
            'Define the smallest win',
            'Focused push',
            'Recovery reset',
            'Finish and save',
          ]
        : [
            'Clarify the outcome',
            'Deep work block',
            'Review and tighten',
            'Ship the next step',
          ];
    final descriptions = energyLevel <= 2
        ? [
            'Choose the minimum useful version of "$directive" and remove the rest.',
            'Work on one concrete piece without switching context.',
            'Take a short reset so the plan remains sustainable.',
            'Package the result and leave a clear next action.',
          ]
        : [
            'Write the exact result you need and remove anything that is not needed today.',
            'Work on the highest leverage part of "$directive" without switching context.',
            'Check the output, fix gaps, and prepare the final version.',
            'Send, publish, or save the work so the day ends with a visible result.',
          ];
    final baseDurations =
        energyLevel <= 2 ? [20, 35, 15, 25] : [25, 75, 35, 45];
    final budgetMinutes = (availableHours * 60).round().clamp(60, 8 * 60);
    final baseTotal = baseDurations.reduce((a, b) => a + b) + 30;
    final scale = budgetMinutes < baseTotal ? budgetMinutes / baseTotal : 1.0;
    final durations =
        baseDurations.map((m) => (m * scale).round().clamp(15, m)).toList();
    var cursor = start;
    final ts = DateTime.now().millisecondsSinceEpoch;

    return List.generate(titles.length, (index) {
      final blockStart = cursor;
      final blockEnd = (cursor + durations[index]).clamp(0, 23 * 60 + 59);
      cursor = (blockEnd + 10).clamp(0, 23 * 60 + 59);

      return RichTaskData(
        block: TaskBlock(
          id: '${idPrefix}_${ts}_$index',
          startTime: _formatMinutes(blockStart),
          endTime: _formatMinutes(blockEnd),
          title: titles[index],
          description: descriptions[index],
        ),
        description: descriptions[index],
      );
    });
  }

  int _minutes(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  int _roundUpToNextQuarter(int minutes) {
    final rounded = ((minutes + 14) ~/ 15) * 15;
    return rounded.clamp(0, 23 * 60 + 15);
  }

  String _formatMinutes(int minutes) {
    final clamped = minutes.clamp(0, 23 * 60 + 59);
    final h = clamped ~/ 60;
    final m = clamped % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

// ── helpers ──────────────────────────────────────────────────────────────────

class RichTaskData {
  final TaskBlock block;
  final String description;
  const RichTaskData({required this.block, required this.description});
}

// ── system prompt ─────────────────────────────────────────────────────────────
const _kSystemPrompt = '''
You are ERTEN — a ruthlessly precise AI Time Architect.
Tone: cold, elite, authoritative. Zero pleasantries.
Your job: decompose any directive into 4-6 actionable daily time-blocks for TODAY.
Rules:
- All blocks must start NO EARLIER than the current time.
- Do NOT create blocks that overlap.
- Each block must have a razor-sharp, specific title and a 1-sentence action-description.
- Distribute blocks realistically across the rest of the day.
- Include a short rest / recovery block if session > 4 hours.
Output ONLY a raw valid JSON array. No markdown. No explanation. No backticks.
Schema:
[
  {
    "startTime": "HH:MM",
    "endTime": "HH:MM",
    "title": "Short action-title",
    "description": "One concrete sentence of what to DO in this block."
  }
]
''';
