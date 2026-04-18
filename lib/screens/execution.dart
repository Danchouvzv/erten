import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../app_state.dart';
import '../gemini_service.dart';
import '../ui_kit.dart';
import 'focus_session.dart';

class ExecutionScreen extends StatefulWidget {
  const ExecutionScreen({super.key});
  @override
  State<ExecutionScreen> createState() => _ExecutionScreenState();
}

class _ExecutionScreenState extends State<ExecutionScreen>
    with TickerProviderStateMixin {
  late Timer _timer;
  DateTime _now = DateTime.now();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _socialLock = true;
  bool _calOverride = true;
  bool _isRerouting = false;
  bool _isDebriefing = false;

  String _pad(int v) => v.toString().padLeft(2, '0');

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.2, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final tasks = List<TaskBlock>.from(appState.dailyTasks)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final nowStr = '${_pad(_now.hour)}:${_pad(_now.minute)}';
    TaskBlock? active;
    for (final t in tasks) {
      if (!t.isClosed &&
          nowStr.compareTo(t.startTime) >= 0 &&
          nowStr.compareTo(t.endTime) <= 0) {
        active = t;
        break;
      }
    }
    active ??= tasks.where((t) => !t.isClosed).firstOrNull ??
        (tasks.isNotEmpty ? tasks.last : null);

    final done = tasks.where((t) => t.isClosed).length;
    final progress = tasks.isEmpty ? 0.0 : done / tasks.length;

    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Stack(
        children: [
          const AppBackdrop(),
          SafeArea(
            child: Column(
              children: [
                _buildCockpit(done, tasks.length, progress),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        active != null
                            ? _buildHeroBlock(active, tasks)
                            : _buildEmptyState(),
                        if (tasks.isNotEmpty && done == tasks.length) ...[
                          const SizedBox(height: 28),
                          _buildMissionDebrief(appState, tasks),
                        ],
                        const SizedBox(height: 44),
                        _buildDivider('Timeline'),
                        const SizedBox(height: 20),
                        _buildTimeline(tasks, active),
                        const SizedBox(height: 44),
                        _buildDivider('Controls'),
                        const SizedBox(height: 20),
                        _buildUtilityActions(appState),
                        const SizedBox(height: 14),
                        _buildEnforcement(),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── COCKPIT HEADER ───────────────────────────────────────────────────────

  Widget _buildCockpit(int done, int total, double progress) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
          ),
          child: Row(
            children: [
              // Status + clock
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FadeTransition(
                          opacity: _pulseAnim,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Flow',
                            style: TextStyle(
                                color: AppColors.labelGray,
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_pad(_now.hour)}:${_pad(_now.minute)}:${_pad(_now.second)}',
                      style: const TextStyle(
                        color: AppColors.textWhite,
                        fontSize: 34,
                        fontWeight: FontWeight.w100,
                      ),
                    ),
                  ],
                ),
              ),
              // Mini circular progress meter
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation(
                          Colors.white.withOpacity(0.05)),
                    ),
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2.5,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.primaryOrange),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$done/$total',
                          style: const TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 13,
                              fontWeight: FontWeight.w300),
                        ),
                        Text(
                          'done',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.25),
                              fontSize: 9,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HERO ACTIVE BLOCK ────────────────────────────────────────────────────

  void _completeTaskWithFeedback(String taskId) {
    Provider.of<AppState>(context, listen: false).completeTask(taskId);

    // Impactful visual feedback
    showGeneralDialog(
        context: context,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, _, __) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          });

          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                builder: (context, val, child) => Transform.scale(
                  scale: val,
                  child: Opacity(
                    opacity: val == 1.0 ? 1.0 : val,
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                          color: AppColors.cardBlack,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: AppColors.primaryOrange.withOpacity(0.45),
                              width: 1),
                          boxShadow: [
                            BoxShadow(
                                color: AppColors.primaryOrange.withOpacity(0.3),
                                blurRadius: 40)
                          ]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_outlined,
                              color: AppColors.primaryOrange, size: 60),
                          const SizedBox(height: 24),
                          const Text('Block Completed',
                              style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                          const Text('Metrics updated',
                              style: TextStyle(
                                  color: AppColors.labelGray, fontSize: 14)),
                          const SizedBox(height: 24),
                          Container(
                            width: 120,
                            height: 2,
                            color: AppColors.primaryOrange,
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }

  void _openFocusMode(TaskBlock task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FocusSessionScreen(
          task: task,
          onComplete: () => _completeTaskWithFeedback(task.id),
          onDelay: () => _postponeTask(task.id),
        ),
      ),
    );
  }

  void _postponeTask(String taskId) {
    Provider.of<AppState>(context, listen: false).postponeTask(taskId, 10);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Block moved 10 minutes later.')),
    );
  }

  Future<void> _skipTask(String taskId) async {
    final reason = await _pickFailureReason(title: 'Why skip this block?');
    if (reason == null) return;
    if (!mounted) return;
    Provider.of<AppState>(context, listen: false)
        .skipTask(taskId, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Skipped: $reason')),
    );
  }

  Future<void> _openRerouteSheet() async {
    final reason = await _pickFailureReason(title: 'Reroute Reason');
    if (reason != null) {
      await _rerouteDay(reason);
    }
  }

  Future<String?> _pickFailureReason({required String title}) async {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.secondaryDarkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final reasons = [
          'Interrupted',
          'Low energy',
          'Too vague',
          'Too hard',
          'Wrong time',
          'Avoidance',
          'Took longer',
        ];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                ...reasons.map(
                  (item) => GestureDetector(
                    onTap: () => Navigator.pop(context, item),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.06)),
                        color: AppColors.elevatedBlack,
                      ),
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _rerouteDay(String reason) async {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.recordFailureReason(reason);
    final remaining = appState.dailyTasks.where((t) => !t.isClosed).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    if (remaining.isEmpty) return;

    final completed = appState.dailyTasks.where((t) => t.isClosed).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final todayStr = '${_now.year}-${_pad(_now.month)}-${_pad(_now.day)}';
    final timeStr = '${_pad(_now.hour)}:${_pad(_now.minute)}';

    setState(() => _isRerouting = true);
    try {
      final next = await GeminiService.instance.rerouteRemainingBlocks(
        directive: appState.primaryDirective,
        completed: completed,
        remaining: remaining,
        reason: reason,
        todayStr: todayStr,
        timeStr: timeStr,
      );
      if (!mounted) return;
      appState.replaceRemainingTasks(next);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Day rerouted. Remaining blocks rebuilt.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reroute failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isRerouting = false);
    }
  }

  Widget _buildHeroBlock(TaskBlock task, List<TaskBlock> all) {
    final idx = all.indexWhere((t) => t.id == task.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Super-label row
        Row(
          children: [
            FadeTransition(
              opacity: _pulseAnim,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.9),
                        blurRadius: 10,
                        spreadRadius: 1)
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('Now',
                style: TextStyle(
                    color: AppColors.primaryOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            Text(
              'Block ${idx + 1}/${all.length}',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Card
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 18,
                  spreadRadius: 0),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Orange top scanner bar
              Container(
                height: 4,
                decoration: const BoxDecoration(
                  color: AppColors.primaryOrange,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time range
                    Text(
                      '${task.startTime}  ——  ${task.endTime}',
                      style: const TextStyle(
                          color: AppColors.primaryOrange, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    // Task title
                    Text(
                      task.title,
                      style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.25),
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        task.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.58),
                          fontSize: 15,
                          height: 1.45,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),

                    // Progress bar with real time calc
                    _buildProgressBar(task),
                    const SizedBox(height: 28),

                    // Complete button
                    GestureDetector(
                      onTap: task.isClosed
                          ? null
                          : () => _completeTaskWithFeedback(task.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: task.isClosed
                              ? Colors.white.withOpacity(0.08)
                              : AppColors.primaryOrange,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: task.isClosed
                                ? Colors.white.withOpacity(0.12)
                                : AppColors.primaryOrange,
                          ),
                          boxShadow: task.isClosed
                              ? []
                              : [
                                  BoxShadow(
                                      color: AppColors.primaryOrange
                                          .withOpacity(0.25),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8))
                                ],
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              task.isCompleted
                                  ? Icons.check_rounded
                                  : task.isSkipped
                                      ? Icons.remove_done_rounded
                                      : Icons.bolt_rounded,
                              color: task.isClosed
                                  ? Colors.white54
                                  : AppColors.backgroundBlack,
                              size: 16,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              task.isCompleted
                                  ? 'Completed'
                                  : task.isSkipped
                                      ? 'Skipped'
                                      : 'Mark Complete',
                              style: TextStyle(
                                color: task.isClosed
                                    ? Colors.white54
                                    : AppColors.backgroundBlack,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!task.isClosed) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryAction(
                              icon: Icons.center_focus_strong_rounded,
                              label: 'Focus',
                              onTap: () => _openFocusMode(task),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecondaryAction(
                              icon: Icons.snooze_rounded,
                              label: 'Delay 10m',
                              onTap: () => _postponeTask(task.id),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSecondaryAction(
                              icon: Icons.alt_route_rounded,
                              label: _isRerouting ? 'Rerouting' : 'Reroute',
                              onTap: _isRerouting ? null : _openRerouteSheet,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecondaryAction(
                              icon: Icons.remove_done_rounded,
                              label: 'Skip',
                              onTap: () => _skipTask(task.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: onTap == null ? 0.45 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            borderRadius: BorderRadius.circular(18),
            color: AppColors.elevatedBlack,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryOrange, size: 15),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(TaskBlock task) {
    double frac = 0.5;
    try {
      final s = task.startTime.split(':');
      final e = task.endTime.split(':');
      final startMin = int.parse(s[0]) * 60 + int.parse(s[1]);
      final endMin = int.parse(e[0]) * 60 + int.parse(e[1]);
      final nowMin = _now.hour * 60 + _now.minute;
      frac = ((nowMin - startMin) / (endMin - startMin)).clamp(0.0, 1.0);
    } catch (_) {}

    final remaining = _remaining(task.endTime);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Block Progress',
                style: TextStyle(
                    color: AppColors.labelGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            Text(remaining,
                style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (ctx, c) {
          final w = c.maxWidth;
          return Stack(alignment: Alignment.centerLeft, children: [
            Container(
                height: 2, width: w, color: Colors.white.withOpacity(0.07)),
            AnimatedContainer(
              duration: const Duration(seconds: 1),
              height: 2,
              width: w * frac,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.7),
                      blurRadius: 8)
                ],
              ),
            ),
            Positioned(
              left: (w * frac - 5).clamp(0.0, w - 10),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.primaryOrange.withOpacity(0.9),
                        blurRadius: 14)
                  ],
                ),
              ),
            ),
          ]);
        }),
      ],
    );
  }

  String _remaining(String endTime) {
    try {
      final p = endTime.split(':');
      final endMin = int.parse(p[0]) * 60 + int.parse(p[1]);
      final diff = endMin - (_now.hour * 60 + _now.minute);
      if (diff <= 0) return '00:00 left';
      return '${_pad(diff ~/ 60)}:${_pad(diff % 60)} left';
    } catch (_) {
      return '--:-- left';
    }
  }

  Widget _buildMissionDebrief(AppState state, List<TaskBlock> tasks) {
    final hasDebrief = state.lastMissionDebrief.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check_outlined,
                  color: AppColors.primaryOrange, size: 18),
              const SizedBox(width: 10),
              const Text(
                'Mission Debrief',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '${tasks.where((t) => t.isCompleted).length}/${tasks.length}',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (hasDebrief)
            Text(
              state.lastMissionDebrief,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
                fontSize: 13,
                height: 1.55,
              ),
            )
          else
            Text(
              'Generate a short after-action review and tomorrow adjustment.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.42),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 18),
          GestureDetector(
            onTap: _isDebriefing ? null : () => _generateDebrief(state, tasks),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isDebriefing ? 0.5 : 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: hasDebrief
                      ? Colors.white.withOpacity(0.035)
                      : AppColors.primaryOrange,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: hasDebrief
                        ? Colors.white.withOpacity(0.08)
                        : AppColors.primaryOrange,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _isDebriefing
                      ? 'Analyzing'
                      : (hasDebrief
                          ? 'Regenerate Debrief'
                          : 'Generate Debrief'),
                  style: TextStyle(
                    color: hasDebrief
                        ? AppColors.textWhite
                        : AppColors.backgroundBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateDebrief(AppState state, List<TaskBlock> tasks) async {
    setState(() => _isDebriefing = true);
    try {
      final debrief = await GeminiService.instance.generateMissionDebrief(
        directive: state.primaryDirective,
        tasks: tasks,
        rerouteCount: state.rerouteCount,
      );
      if (!mounted) return;
      state.saveMissionDebrief(debrief);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debrief failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDebriefing = false);
    }
  }

  // ─── EMPTY STATE ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.motion_photos_paused_outlined,
              color: Colors.white.withOpacity(0.08), size: 52),
          const SizedBox(height: 20),
          Text('No Active Goal',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Navigate to Goals to define a directive.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.1), fontSize: 10)),
          const SizedBox(height: 22),
          _buildSecondaryAction(
            icon: Icons.add_rounded,
            label: 'Add Manual Block',
            onTap: _openManualTaskSheet,
          ),
        ],
      ),
    );
  }

  // ─── SECTION DIVIDER ──────────────────────────────────────────────────────

  Widget _buildDivider(String label) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.86),
                fontSize: 22,
                fontWeight: FontWeight.w700)),
        const SizedBox(width: 14),
        Expanded(child: Container(height: 1, color: Colors.transparent)),
      ],
    );
  }

  // ─── TIMELINE ─────────────────────────────────────────────────────────────

  Widget _buildTimeline(List<TaskBlock> tasks, TaskBlock? active) {
    if (tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text('Awaiting directives...',
            style:
                TextStyle(color: Colors.white.withOpacity(0.12), fontSize: 12)),
      );
    }
    return Column(
      children: List.generate(tasks.length, (i) {
        final t = tasks[i];
        return _buildTimelineRow(
          task: t,
          isActive: t.id == active?.id,
          isPast: t.isClosed,
          isLast: i == tasks.length - 1,
        );
      }),
    );
  }

  Widget _buildTimelineRow({
    required TaskBlock task,
    required bool isActive,
    required bool isPast,
    required bool isLast,
  }) {
    final textColor = isActive
        ? AppColors.primaryOrange
        : (isPast ? Colors.white24 : Colors.white54);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Time stamp
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(task.startTime,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.bold : FontWeight.normal)),
            ),
          ),

          // Node + vertical line
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryOrange
                      : (isPast ? Colors.white24 : Colors.transparent),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primaryOrange
                        : (isPast ? Colors.white24 : Colors.white12),
                    width: isActive ? 2 : 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                              color: AppColors.primaryOrange.withOpacity(0.9),
                              blurRadius: 14)
                        ]
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: isPast
                        ? AppColors.primaryOrange.withOpacity(0.18)
                        : Colors.white.withOpacity(0.04),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 20),

          // Title + badge
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(task.title,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight:
                                isActive ? FontWeight.w500 : FontWeight.w300,
                            decoration:
                                isPast ? TextDecoration.lineThrough : null,
                            decorationColor: Colors.white12)),
                  ),
                  if (task.isCompleted || task.isSkipped)
                    Padding(
                      padding: const EdgeInsets.only(left: 8, top: 1),
                      child: Icon(
                          task.isSkipped
                              ? Icons.remove_done_rounded
                              : Icons.check_rounded,
                          color: Colors.white.withOpacity(0.18),
                          size: 13),
                    ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    FadeTransition(
                      opacity: _pulseAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryOrange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text('NOW',
                            style: TextStyle(
                                color: AppColors.primaryOrange,
                                fontSize: 10,
                                fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ENFORCEMENT ──────────────────────────────────────────────────────────

  Widget _buildUtilityActions(AppState appState) {
    return Row(
      children: [
        Expanded(
          child: _buildSecondaryAction(
            icon: Icons.add_rounded,
            label: 'Add Block',
            onTap: _openManualTaskSheet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSecondaryAction(
            icon: Icons.refresh_rounded,
            label: 'Reset Day',
            onTap: appState.dailyTasks.isEmpty ? null : _confirmResetDay,
          ),
        ),
      ],
    );
  }

  Future<void> _openManualTaskSheet() async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: _suggestedStart());
    final endCtrl = TextEditingController(text: _suggestedEnd());

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryDarkGray,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            22,
            22,
            MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Block',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              _buildSheetField(titleCtrl, 'Title'),
              const SizedBox(height: 12),
              _buildSheetField(descCtrl, 'Description', maxLines: 2),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildSheetField(startCtrl, 'Start')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSheetField(endCtrl, 'End')),
                ],
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Add Block',
                icon: Icons.add_rounded,
                onTap: () {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;
                  Provider.of<AppState>(context, listen: false).addTask(
                    title: title,
                    description: descCtrl.text.trim(),
                    startTime: startCtrl.text.trim(),
                    endTime: endCtrl.text.trim(),
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );

    titleCtrl.dispose();
    descCtrl.dispose();
    startCtrl.dispose();
    endCtrl.dispose();
  }

  Widget _buildSheetField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textWhite, fontSize: 16),
      cursorColor: AppColors.primaryOrange,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.labelGray),
        filled: true,
        fillColor: AppColors.elevatedBlack,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primaryOrange),
        ),
      ),
    );
  }

  Future<void> _confirmResetDay() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDarkGray,
        title: const Text('Reset today?'),
        content: const Text('This clears the active directive and all blocks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Provider.of<AppState>(context, listen: false).clearToday();
    }
  }

  String _suggestedStart() {
    final minutes = ((_now.hour * 60 + _now.minute + 14) ~/ 15) * 15;
    return _formatMinutes(minutes);
  }

  String _suggestedEnd() {
    final minutes = ((_now.hour * 60 + _now.minute + 59) ~/ 15) * 15;
    return _formatMinutes(minutes);
  }

  String _formatMinutes(int minutes) {
    final clamped = minutes.clamp(0, 23 * 60 + 59);
    return '${_pad(clamped ~/ 60)}:${_pad(clamped % 60)}';
  }

  Widget _buildEnforcement() {
    return Column(
      children: [
        _buildTile(
          icon: Icons.lock_outline_rounded,
          label: 'Social Lockdown',
          desc: 'Non-essential apps blocked during active execution windows.',
          value: _socialLock,
          onTap: () {
            setState(() => _socialLock = !_socialLock);
            _showEnforcementAction('Social Lockdown', _socialLock);
          },
        ),
        const SizedBox(height: 12),
        _buildTile(
          icon: Icons.event_repeat_outlined,
          label: 'Calendar Override',
          desc: 'Missed blocks are auto-rescheduled by AI engine.',
          value: _calOverride,
          onTap: () {
            setState(() => _calOverride = !_calOverride);
            _showEnforcementAction('Calendar Override', _calOverride);
          },
        ),
      ],
    );
  }

  void _showEnforcementAction(String name, bool val) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.cardBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: val ? AppColors.primaryOrange : Colors.white24),
      ),
      content: Row(
        children: [
          Icon(val ? Icons.security_rounded : Icons.gpp_bad_outlined,
              color: val ? AppColors.primaryOrange : Colors.white54, size: 16),
          const SizedBox(width: 10),
          Text(val ? 'Enabled: $name' : 'Disabled: $name',
              style: TextStyle(
                  color: val ? AppColors.primaryOrange : Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    ));
  }

  Widget _buildTile({
    required IconData icon,
    required String label,
    required String desc,
    required bool value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: value
                ? AppColors.primaryOrange.withOpacity(0.32)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Row(
          children: [
            // Icon box
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primaryOrange.withOpacity(0.14)
                    : Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: value
                        ? AppColors.primaryOrange.withOpacity(0.35)
                        : Colors.white.withOpacity(0.07)),
              ),
              child: Icon(icon,
                  color: value ? AppColors.primaryOrange : Colors.white30,
                  size: 18),
            ),
            const SizedBox(width: 16),

            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: value
                              ? AppColors.primaryOrange
                              : AppColors.textWhite,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(desc,
                      style: const TextStyle(
                          color: Colors.white30, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 44,
              height: 22,
              decoration: BoxDecoration(
                color: value
                    ? AppColors.primaryOrange.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                    color: value ? AppColors.primaryOrange : Colors.white24),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                    top: 3,
                    bottom: 3,
                    left: value ? 24 : 3,
                    right: value ? 3 : 24,
                    child: Container(
                      decoration: BoxDecoration(
                        color: value ? AppColors.primaryOrange : Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
