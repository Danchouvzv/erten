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

    return Column(
      key: const ValueKey('input'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 40, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Goals',
                  style: TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 36,
                      letterSpacing: -0.5,
                      fontWeight: FontWeight.w800)),
              SizedBox(height: 10),
              Text('What do you need\nto accomplish today?',
                  style: TextStyle(
                      color: AppColors.labelGray,
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      height: 1.35)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Input field
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.cardBlack,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    autofocus: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      height: 1.55,
                    ),
                    cursorColor: AppColors.primaryOrange,
                    cursorWidth: 2,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'e.g.: Prepare 3 investor pitch slides and review Q1 financial model...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.22),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        _buildEnergyPlanner(),
        const SizedBox(height: 18),

        // Existing directive reminder
        if (existing.primaryDirective.isNotEmpty &&
            existing.primaryDirective != 'NONE')
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  color: AppColors.primaryOrange.withOpacity(0.5),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ACTIVE: ${existing.primaryDirective}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.labelGray, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // CTA button
        _buildCTA('Generate Plan', _generate),
      ],
    );
  }

  Widget _buildEnergyPlanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBlack,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Planning Context',
              style: TextStyle(
                color: AppColors.textWhite,
                fontSize: 18,
                fontWeight: FontWeight.w700,
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
              onChanged: (value) =>
                  setState(() => _energyLevel = value.round()),
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
    return Column(
      key: const ValueKey('result'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 12, 0),
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
                            fontSize: 34,
                            letterSpacing: -0.4,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      _controller.text.length > 60
                          ? '${_controller.text.substring(0, 60)}...'
                          : _controller.text,
                      style: const TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          height: 1.35),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.3), size: 20),
                onPressed: _generate,
                tooltip: 'Regenerate',
              ),
              IconButton(
                icon: Icon(Icons.close_rounded,
                    color: Colors.white.withOpacity(0.3), size: 20),
                onPressed: () => setState(() {
                  _phase = 'input';
                  _rich = [];
                }),
              ),
            ],
          ),
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          child: Row(children: [
            Text('${_rich.length} blocks scheduled',
                style: const TextStyle(
                    color: AppColors.labelGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: Colors.transparent)),
          ]),
        ),

        _buildContractPreview(),

        // Task list
        Expanded(
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
            itemCount: _rich.length,
            itemBuilder: (ctx, i) => _buildTaskCard(_rich[i], i),
          ),
        ),

        // Accept button
        _buildCTA('Accept Plan', _enforce),
      ],
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
      final s = start.split(':');
      final e = end.split(':');
      final mins = (int.parse(e[0]) * 60 + int.parse(e[1])) -
          (int.parse(s[0]) * 60 + int.parse(s[1]));
      if (mins < 60) return '${mins}m';
      final h = mins ~/ 60;
      final m = mins % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    } catch (_) {
      return '';
    }
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 120),
      child: GestureDetector(
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
      ),
    );
  }
}
