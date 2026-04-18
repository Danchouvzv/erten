import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TaskBlock {
  final String id;
  String startTime;
  String endTime;
  String title;
  String description;
  bool isCompleted;
  bool isSkipped;

  TaskBlock({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    this.isSkipped = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime,
        'endTime': endTime,
        'title': title,
        'description': description,
        'isCompleted': isCompleted,
        'isSkipped': isSkipped,
      };

  factory TaskBlock.fromJson(Map<String, dynamic> json) => TaskBlock(
        id: json['id'],
        startTime: json['startTime'],
        endTime: json['endTime'],
        title: json['title'],
        description: json['description'] ?? '',
        isCompleted: json['isCompleted'] ?? false,
        isSkipped: json['isSkipped'] ?? false,
      );

  bool get isClosed => isCompleted || isSkipped;
}

class AppState extends ChangeNotifier {
  String primaryDirective = 'NONE';
  double progressPercent = 0.0;
  String lastMissionDebrief = '';
  int rerouteCount = 0;
  String planningType = 'Deep Work';
  int energyLevel = 3;
  double availableHours = 4.0;
  String hardCommitments = '';
  String executionContract = '';
  String contractStatus = 'none';
  int currentStreak = 0;
  int bestStreak = 0;
  String lastCompletedDay = '';
  Map<String, int> failureReasons = {};

  double disciplineScore = 0.50;
  double executionScore = 0.50;
  double focusScore = 0.50;

  int totalTasksCompleted = 0;
  int level = 1;

  List<TaskBlock> dailyTasks = [];

  AppState() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    primaryDirective = prefs.getString('primaryDirective') ?? 'NONE';
    progressPercent = prefs.getDouble('progressPercent') ?? 0.0;
    lastMissionDebrief = prefs.getString('lastMissionDebrief') ?? '';
    rerouteCount = prefs.getInt('rerouteCount') ?? 0;
    planningType = prefs.getString('planningType') ?? 'Deep Work';
    energyLevel = prefs.getInt('energyLevel') ?? 3;
    availableHours = prefs.getDouble('availableHours') ?? 4.0;
    hardCommitments = prefs.getString('hardCommitments') ?? '';
    executionContract = prefs.getString('executionContract') ?? '';
    contractStatus = prefs.getString('contractStatus') ?? 'none';
    currentStreak = prefs.getInt('currentStreak') ?? 0;
    bestStreak = prefs.getInt('bestStreak') ?? 0;
    lastCompletedDay = prefs.getString('lastCompletedDay') ?? '';
    final reasonsJson = prefs.getString('failureReasons');
    if (reasonsJson != null) {
      failureReasons = Map<String, int>.from(jsonDecode(reasonsJson));
    }
    disciplineScore = prefs.getDouble('disciplineScore') ?? 0.50;
    executionScore = prefs.getDouble('executionScore') ?? 0.50;
    focusScore = prefs.getDouble('focusScore') ?? 0.50;
    totalTasksCompleted = prefs.getInt('totalTasksCompleted') ?? 0;
    level = prefs.getInt('level') ?? 1;

    final tasksJson = prefs.getString('dailyTasks');
    if (tasksJson != null) {
      final List<dynamic> decoded = jsonDecode(tasksJson);
      dailyTasks = decoded.map((e) => TaskBlock.fromJson(e)).toList();
    }
    notifyListeners();
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('primaryDirective', primaryDirective);
    await prefs.setDouble('progressPercent', progressPercent);
    await prefs.setString('lastMissionDebrief', lastMissionDebrief);
    await prefs.setInt('rerouteCount', rerouteCount);
    await prefs.setString('planningType', planningType);
    await prefs.setInt('energyLevel', energyLevel);
    await prefs.setDouble('availableHours', availableHours);
    await prefs.setString('hardCommitments', hardCommitments);
    await prefs.setString('executionContract', executionContract);
    await prefs.setString('contractStatus', contractStatus);
    await prefs.setInt('currentStreak', currentStreak);
    await prefs.setInt('bestStreak', bestStreak);
    await prefs.setString('lastCompletedDay', lastCompletedDay);
    await prefs.setString('failureReasons', jsonEncode(failureReasons));
    await prefs.setDouble('disciplineScore', disciplineScore);
    await prefs.setDouble('executionScore', executionScore);
    await prefs.setDouble('focusScore', focusScore);
    await prefs.setInt('totalTasksCompleted', totalTasksCompleted);
    await prefs.setInt('level', level);

    final tasksJson = jsonEncode(dailyTasks.map((e) => e.toJson()).toList());
    await prefs.setString('dailyTasks', tasksJson);
  }

  void setNewDirective(
    String directive,
    List<TaskBlock> newTasks, {
    String type = 'Deep Work',
    int energy = 3,
    double hours = 4.0,
    String commitments = '',
  }) {
    primaryDirective = directive;
    dailyTasks = _sorted(newTasks);
    planningType = type;
    energyLevel = energy;
    availableHours = hours;
    hardCommitments = commitments;
    executionContract = _buildExecutionContract(directive, dailyTasks);
    contractStatus = 'active';
    progressPercent = 0.0;
    lastMissionDebrief = '';
    rerouteCount = 0;
    _saveState();
    notifyListeners();
  }

  void replaceRemainingTasks(List<TaskBlock> newTasks) {
    final completed = dailyTasks.where((t) => t.isClosed).toList();
    dailyTasks = _sorted([...completed, ...newTasks]);
    rerouteCount++;
    progressPercent = completionRate;
    focusScore = (focusScore + 0.02).clamp(0.0, 1.0);
    _saveState();
    notifyListeners();
  }

  void saveMissionDebrief(String debrief) {
    lastMissionDebrief = debrief;
    _saveState();
    notifyListeners();
  }

  void completeTask(String taskId) {
    final taskIndex = dailyTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1 && !dailyTasks[taskIndex].isClosed) {
      dailyTasks[taskIndex].isCompleted = true;
      dailyTasks[taskIndex].isSkipped = false;
      totalTasksCompleted++;

      progressPercent = completionRate;

      disciplineScore = (disciplineScore + 0.02).clamp(0.0, 1.0);
      executionScore = (executionScore + 0.03).clamp(0.0, 1.0);
      focusScore = (focusScore + 0.01).clamp(0.0, 1.0);

      if (totalTasksCompleted % 5 == 0) {
        level++;
      }

      _refreshContractStatus();

      _saveState();
      notifyListeners();
    }
  }

  void skipTask(String taskId, {String reason = 'Skipped'}) {
    final taskIndex = dailyTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1 && !dailyTasks[taskIndex].isClosed) {
      dailyTasks[taskIndex].isSkipped = true;
      recordFailureReason(reason);
      progressPercent = completionRate;
      disciplineScore = (disciplineScore - 0.01).clamp(0.0, 1.0);
      focusScore = (focusScore - 0.01).clamp(0.0, 1.0);
      _refreshContractStatus();
      _saveState();
      notifyListeners();
    }
  }

  void reopenTask(String taskId) {
    final taskIndex = dailyTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      dailyTasks[taskIndex].isCompleted = false;
      dailyTasks[taskIndex].isSkipped = false;
      progressPercent = completionRate;
      _refreshContractStatus();
      _saveState();
      notifyListeners();
    }
  }

  void postponeTask(String taskId, int minutes) {
    final taskIndex = dailyTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1 || dailyTasks[taskIndex].isClosed) return;

    final task = dailyTasks[taskIndex];
    task.startTime = _shiftTime(task.startTime, minutes);
    task.endTime = _shiftTime(task.endTime, minutes);
    dailyTasks = _sorted(dailyTasks);
    focusScore = (focusScore + 0.005).clamp(0.0, 1.0);
    _saveState();
    notifyListeners();
  }

  void addTask({
    required String title,
    required String startTime,
    required String endTime,
    String description = '',
  }) {
    final task = TaskBlock(
      id: 'manual_${DateTime.now().millisecondsSinceEpoch}',
      startTime: startTime,
      endTime: endTime,
      title: title,
      description: description,
    );
    dailyTasks = _sorted([...dailyTasks, task]);
    progressPercent = completionRate;
    _saveState();
    notifyListeners();
  }

  void updateTask(TaskBlock updated) {
    final taskIndex = dailyTasks.indexWhere((t) => t.id == updated.id);
    if (taskIndex == -1) return;
    dailyTasks[taskIndex] = updated;
    dailyTasks = _sorted(dailyTasks);
    progressPercent = completionRate;
    _saveState();
    notifyListeners();
  }

  void deleteTask(String taskId) {
    dailyTasks = dailyTasks.where((t) => t.id != taskId).toList();
    progressPercent = completionRate;
    _saveState();
    notifyListeners();
  }

  void clearToday() {
    primaryDirective = 'NONE';
    dailyTasks = [];
    progressPercent = 0.0;
    lastMissionDebrief = '';
    rerouteCount = 0;
    executionContract = '';
    contractStatus = 'none';
    _saveState();
    notifyListeners();
  }

  void recordFailureReason(String reason) {
    failureReasons[reason] = (failureReasons[reason] ?? 0) + 1;
  }

  String get topFailureReason {
    if (failureReasons.isEmpty) return 'No pattern yet';
    final entries = failureReasons.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  List<String> get earnedBadges {
    final badges = <String>[];
    if (totalTasksCompleted >= 1) badges.add('First Block');
    if (currentStreak >= 3) badges.add('3-Day Streak');
    if (currentStreak >= 7) badges.add('7-Day Streak');
    if (totalTasksCompleted >= 25) badges.add('Executor');
    if (bestStreak >= 14) badges.add('Consistent');
    if (failureReasons.length >= 3) badges.add('Self-Aware');
    return badges;
  }

  double get completionRate {
    if (dailyTasks.isEmpty) return 0;
    final completed = dailyTasks.where((t) => t.isClosed).length;
    return completed / dailyTasks.length;
  }

  void _refreshContractStatus() {
    if (dailyTasks.isEmpty || executionContract.isEmpty) return;
    if (dailyTasks.any((t) => !t.isClosed)) {
      contractStatus = 'active';
      return;
    }
    final completed = dailyTasks.where((t) => t.isCompleted).length;
    final rate = completed / dailyTasks.length;
    if (rate >= 1.0) {
      contractStatus = 'fulfilled';
      _updateStreak();
    } else if (rate >= 0.6) {
      contractStatus = 'partial';
    } else {
      contractStatus = 'broken';
    }
  }

  void _updateStreak() {
    final now = DateTime.now();
    final today = _dateKey(now);
    if (lastCompletedDay == today) return;

    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    if (lastCompletedDay == yesterday) {
      currentStreak++;
    } else {
      currentStreak = 1;
    }
    bestStreak = currentStreak > bestStreak ? currentStreak : bestStreak;
    lastCompletedDay = today;
  }

  String _buildExecutionContract(String directive, List<TaskBlock> tasks) {
    if (tasks.isEmpty) return '';
    final last = tasks.last.endTime;
    return 'Complete ${tasks.length} blocks for "$directive" by $last.';
  }

  String _dateKey(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  List<TaskBlock> _sorted(List<TaskBlock> tasks) {
    return List<TaskBlock>.from(tasks)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  String _shiftTime(String value, int minutes) {
    final parts = value.split(':');
    final current = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final shifted = (current + minutes).clamp(0, 23 * 60 + 59);
    final h = shifted ~/ 60;
    final m = shifted % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
