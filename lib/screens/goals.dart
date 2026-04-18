import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../app_state.dart';
import '../gemini_service.dart';

// Extended TaskBlock with a description field (kept locally for display only)
typedef _RichTask = RichTaskData;

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  // 'input' | 'loading' | 'result' | 'error'
  String _phase = 'input';
  List<_RichTask> _rich = [];
  String _errorMsg = '';
  String _planningType = 'Deep Work';
  int _energyLevel = 3;
  double _availableHours = 4.0;
  final TextEditingController _commitmentsController = TextEditingController();

  static const _planningTypes = [
    'Deep Work',
    'Study',
    'Startup',
    'Creative',
    'Admin',
    'Recovery',
  ];

  late AnimationController _scanCtrl;
  late Animation<double> _scanAnim;

  @override
  void initState() {
    super.initState();
    _scanCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat();
    _scanAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _scanCtrl, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    _commitmentsController.dispose();
    _focus.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  String _pad(int v) => v.toString().padLeft(2, '0');

  Future<void> _generate() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      _focus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _phase = 'loading');

    final now = DateTime.now();
    final todayStr = '${now.year}-${_pad(now.month)}-${_pad(now.day)}';
    final timeStr = '${_pad(now.hour)}:${_pad(now.minute)}';

    try {
      _rich = await GeminiService.instance.generateTimeBlocks(
        directive: raw,
        todayStr: todayStr,
        timeStr: timeStr,
        planningType: _planningType,
        energyLevel: _energyLevel,
        availableHours: _availableHours,
        hardCommitments: _commitmentsController.text.trim(),
      );
      setState(() => _phase = 'result');
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _phase = 'error';
      });
    }
  }

  void _enforce() {
    final directive = _controller.text.trim();
    Provider.of<AppState>(context, listen: false).setNewDirective(
      directive,
      _rich.map((r) => r.block).toList(),
      type: _planningType,
      energy: _energyLevel,
      hours: _availableHours,
      commitments: _commitmentsController.text.trim(),
    );
    setState(() {
      _phase = 'input';
      _controller.clear();
      _commitmentsController.clear();
      _rich = [];
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(24, 0, 24, 32),
        backgroundColor: Color(0xFF0F1B21),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        duration: Duration(seconds: 3),
        content: Row(
          children: [
            Icon(Icons.bolt, color: AppColors.primaryOrange, size: 16),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Plan accepted. Flow is ready.',
                style: TextStyle(
                  color: AppColors.primaryOrange,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _buildPhase(),
        ),
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case 'loading':
        return _buildLoading();
      case 'result':
        return _buildResult();
      case 'error':
        return _buildError();
      default:
        return _buildInput();
    }
  }

  // ─── INPUT ────────────────────────────────────────────────────────────────

  Widget _buildInput() {
    final existing = Provider.of<AppState>(context, listen: false);

    return Stack(
      key: const ValueKey('input'),
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 148),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputHeader(),
              const SizedBox(height: 24),
              _buildDirectiveCard(),
              const SizedBox(height: 18),
              _buildEnergyPlanner(),
              if (existing.primaryDirective.isNotEmpty &&
                  existing.primaryDirective != 'NONE') ...[
                const SizedBox(height: 18),
                _buildActiveDirective(existing.primaryDirective),
              ],
            ],
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 28,
          child: _buildCTA('Generate Plan', _generate),
        ),
      ],
    );
  }

  Widget _buildInputHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goals',
                  style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 38,
                      letterSpacing: -0.6,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('Design a realistic day around your energy.',
                  style: TextStyle(
                      color: AppColors.labelGray,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.35)),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.elevatedBlack,
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: const Icon(
            Icons.flag_rounded,
            color: AppColors.primaryOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildDirectiveCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primaryOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Primary Goal',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autofocus: true,
            minLines: 4,
            maxLines: 7,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
            cursorColor: AppColors.primaryOrange,
            cursorWidth: 2,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'What should be true by the end of today?',
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.25),
                fontSize: 19,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDirective(String directive) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.elevatedBlack,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded,
              color: AppColors.primaryOrange, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              directive,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.labelGray,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyPlanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Planning Context',
            style: TextStyle(
              color: AppColors.textWhite,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _planningTypes.map((type) {
                final selected = type == _planningType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    onSelected: (_) => setState(() => _planningType = type),
                    selectedColor: AppColors.primaryOrange,
                    backgroundColor: AppColors.elevatedBlack,
                    labelStyle: TextStyle(
                      color: selected
                          ? AppColors.backgroundBlack
                          : AppColors.textWhite,
                      fontWeight: FontWeight.w700,
                    ),
                    side: BorderSide(color: Colors.white.withOpacity(0.06)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: 'Energy',
            valueLabel: '$_energyLevel/5',
            value: _energyLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (value) => setState(() => _energyLevel = value.round()),
          ),
          _buildSliderRow(
            label: 'Available time',
            valueLabel: '${_availableHours.toStringAsFixed(1)}h',
            value: _availableHours,
            min: 1,
            max: 8,
            divisions: 14,
            onChanged: (value) => setState(() => _availableHours = value),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commitmentsController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textWhite),
            cursorColor: AppColors.primaryOrange,
            decoration: InputDecoration(
              hintText: 'Hard commitments, meetings, blocked hours...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.28)),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              valueLabel,
              style: const TextStyle(
                color: AppColors.primaryOrange,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryOrange,
            inactiveTrackColor: Colors.white.withOpacity(0.10),
            thumbColor: AppColors.primaryOrange,
            overlayColor: AppColors.primaryOrange.withOpacity(0.12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ─── LOADING ──────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Center(
      key: const ValueKey('loading'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cardBlack,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryOrange.withOpacity(0.08),
                blurRadius: 34,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 7,
                      valueColor: AlwaysStoppedAnimation(
                        Colors.white.withOpacity(0.08),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _scanAnim,
                      builder: (_, __) => CircularProgressIndicator(
                        value: (_scanAnim.value * 0.74).clamp(0.12, 0.74),
                        strokeWidth: 7,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation(
                          AppColors.primaryOrange,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primaryOrange,
                      size: 24,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Designing your day',
                style: TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Balancing your energy, time, and commitments.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.56),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: AnimatedBuilder(
                  animation: _scanAnim,
                  builder: (_, __) => LinearProgressIndicator(
                    minHeight: 8,
                    value: _scanAnim.value,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    valueColor: const AlwaysStoppedAnimation(
                      AppColors.primaryOrange,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── RESULT ───────────────────────────────────────────────────────────────

  Widget _buildResult() {
    return Stack(
      key: const ValueKey('result'),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 18, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Preview',
                            style: TextStyle(
                                color: AppColors.textWhite,
                                fontSize: 38,
                                letterSpacing: -0.6,
                                fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text(
                          _controller.text.length > 74
                              ? '${_controller.text.substring(0, 74)}...'
                              : _controller.text,
                          style: const TextStyle(
                              color: AppColors.labelGray,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded,
                        color: Colors.white.withOpacity(0.44), size: 22),
                    onPressed: _generate,
                    tooltip: 'Regenerate',
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: Colors.white.withOpacity(0.44), size: 22),
                    onPressed: () => setState(() {
                      _phase = 'input';
                      _rich = [];
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildPlanSummary(),
            ),
            _buildContractPreview(),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 150),
                itemCount: _rich.length,
                itemBuilder: (ctx, i) => _buildTaskCard(_rich[i], i),
              ),
            ),
          ],
        ),
        Positioned(
          left: 24,
          right: 24,
          bottom: 28,
          child: _buildCTA('Accept Plan', _enforce),
        ),
      ],
    );
  }

  Widget _buildPlanSummary() {
    final totalMinutes = _rich.fold<int>(
      0,
      (sum, r) => sum + _durationMinutes(r.block.startTime, r.block.endTime),
    );
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final duration = hours == 0
        ? '${minutes}m'
        : minutes == 0
            ? '${hours}h'
            : '${hours}h ${minutes}m';

    return Row(
      children: [
        Expanded(
          child: _buildPlanStat(
            Icons.view_timeline_rounded,
            '${_rich.length}',
            'blocks',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPlanStat(
            Icons.hourglass_bottom_rounded,
            duration,
            'planned',
          ),
        ),
      ],
    );
  }

  Widget _buildPlanStat(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.055)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryOrange, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.labelGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractPreview() {
    if (_rich.isEmpty) return const SizedBox.shrink();
    final last = _rich.last.block.endTime;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.primaryOrange.withOpacity(0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.primaryOrange),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Contract: complete ${_rich.length} blocks by $last.',
                style: const TextStyle(
                  color: AppColors.textWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(_RichTask r, int idx) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Index accent
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: idx == 0
                    ? AppColors.primaryOrange
                    : AppColors.primaryOrange.withOpacity(
                        0.2 + ((_rich.length - idx) / _rich.length) * 0.4),
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(24)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time range
                    Row(
                      children: [
                        Text(
                          '${r.block.startTime} - ${r.block.endTime}',
                          style: const TextStyle(
                              color: AppColors.primaryOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        Text(
                          _durationLabel(r.block.startTime, r.block.endTime),
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(r.block.title,
                        style: const TextStyle(
                            color: AppColors.textWhite,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            height: 1.25)),
                    // Description
                    if (r.description.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.description,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.32),
                              fontSize: 13,
                              height: 1.45)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _durationLabel(String start, String end) {
    try {
      final mins = _durationMinutes(start, end);
      if (mins < 60) return '${mins}m';
      final h = mins ~/ 60;
      final m = mins % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    } catch (_) {
      return '';
    }
  }

  int _durationMinutes(String start, String end) {
    final s = start.split(':');
    final e = end.split(':');
    return (int.parse(e[0]) * 60 + int.parse(e[1])) -
        (int.parse(s[0]) * 60 + int.parse(s[1]));
  }

  // ─── ERROR ────────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      key: const ValueKey('error'),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                color: Colors.redAccent.withOpacity(0.6), size: 40),
            const SizedBox(height: 24),
            const Text('Couldn’t build the plan',
                style: TextStyle(
                    color: AppColors.textWhite,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Text(
              _errorMsg.length > 160
                  ? '${_errorMsg.substring(0, 160)}...'
                  : _errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25),
                  fontSize: 10,
                  height: 1.5),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: _generate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: AppColors.primaryOrange.withOpacity(0.5)),
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        color: AppColors.primaryOrange,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => setState(() => _phase = 'input'),
              child: Text('Back to input',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.2), fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SHARED CTA BUTTON ────────────────────────────────────────────────────

  Widget _buildCTA(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: BoxDecoration(
          color: AppColors.primaryOrange,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
                color: AppColors.primaryOrange.withOpacity(0.18),
                blurRadius: 32,
                offset: const Offset(0, -8)),
          ],
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded,
                color: AppColors.backgroundBlack, size: 16),
            const SizedBox(width: 10),
            Text(label,
                style: const TextStyle(
                    color: AppColors.backgroundBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
