import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database before scheduling notifications.
  tzdata.initializeTimeZones();
  tz.setLocalLocation(
  tz.getLocation('Asia/Kolkata'),
);

  const androidSettings = AndroidInitializationSettings(
    '@mipmap/ic_launcher',
  );

  const initializationSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
    onDidReceiveNotificationResponse: _onNotificationTapped,
  );

  final androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.requestNotificationsPermission();
  

  runApp(const LifeCountdownApp());
}
Future<void> scheduleDailyGoalNotification(
  CountdownItem item,
) async {
  // Cancel any previously scheduled notification for this goal.
  await flutterLocalNotificationsPlugin.cancel(
    id: item.id.hashCode,
  );

  final indiaLocation =
      tz.getLocation('Asia/Kolkata');

  final now =
      tz.TZDateTime.now(indiaLocation);

  // Schedule the next notification for exactly 12:00 AM IST.
  final nextMidnight =
      tz.TZDateTime(
        indiaLocation,
        now.year,
        now.month,
        now.day + 1,
        0,
        0,
        0,
      );

  await flutterLocalNotificationsPlugin.zonedSchedule(
    id: item.id.hashCode,
    title: '${item.emoji} ${item.title}',
    body:
        'One more day closer to your goal. Keep going! 💪',
    scheduledDate: nextMidnight,
    notificationDetails:
        const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_goal_milestones',
        'Daily Goal Milestones',
        channelDescription:
            'Daily motivational notifications '
            'for countdown goals.',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle,
    matchDateTimeComponents:
        DateTimeComponents.time,
    payload: item.id,
  );
}



void _onNotificationTapped(NotificationResponse response) {
  // The app can handle the goal id from response.payload here later.
  debugPrint('Goal notification tapped: ${response.payload}');
}

// ============================================================
// APP
// ============================================================

class LifeCountdownApp extends StatelessWidget {
  const LifeCountdownApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Life Countdown',
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F1017),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B7CFF),
          brightness: Brightness.dark,
        ),
      ),
      home: const CountdownHomePage(),
    );
  }
}

// ============================================================
// HOME WIDGET SERVICE
// ============================================================

class HomeWidgetService {
  static const String androidWidgetName =
      'com.aashigupta.countdown.CountdownWidgetProvider';

  static Future<void> updateForGoal(
    CountdownItem? item,
  ) async {
    try {
      if (item == null) {
        await HomeWidget.saveWidgetData<String>(
          'widget_title',
          'Life Countdown',
        );

        await HomeWidget.saveWidgetData<String>(
          'widget_countdown',
          'Set a primary goal',
        );

        await HomeWidget.saveWidgetData<String>(
          'widget_tagline',
          '',
        );

        await HomeWidget.saveWidgetData<String>(
          'widget_emoji',
          '🎯',
        );

        await HomeWidget.saveWidgetData<int>(
          'widget_target_millis',
          0,
        );

        await HomeWidget.saveWidgetData<String>(
          'widget_display_mode',
          'days',
        );
      } else {
        await HomeWidget.saveWidgetData<String>(
          'widget_title',
          item.title,
        );

        await HomeWidget.saveWidgetData<String>(
          'widget_tagline',
          item.tagline,
        );

        await HomeWidget.saveWidgetData<String>(
          'widget_emoji',
          item.emoji,
        );

        await HomeWidget.saveWidgetData<int>(
          'widget_target_millis',
          item.target.millisecondsSinceEpoch,
        );

        await HomeWidget.saveWidgetData<String>(
          'widget_display_mode',
          item.displayMode,
        );

        final remaining =
            item.target.difference(DateTime.now());

        final totalSeconds =
            remaining.inSeconds < 0
                ? 0
                : remaining.inSeconds;

        final days = totalSeconds ~/ 86400;

        final hours =
            totalSeconds ~/ 3600;

        final minutes =
            (totalSeconds % 3600) ~/ 60;

        final seconds =
            totalSeconds % 60;

        final countdownText =
            item.displayMode == 'hours'
                ? '${hours}h '
                    '${minutes.toString().padLeft(2, '0')}m '
                    '${seconds.toString().padLeft(2, '0')}s'
                : '${days}d '
                    '${((totalSeconds % 86400) ~/ 3600).toString().padLeft(2, '0')}h '
                    '${minutes.toString().padLeft(2, '0')}m '
                    '${seconds.toString().padLeft(2, '0')}s';

        await HomeWidget.saveWidgetData<String>(
          'widget_countdown',
          countdownText,
        );
      }

      await HomeWidget.updateWidget(
        qualifiedAndroidName: androidWidgetName,
      );
    } catch (e) {
      debugPrint(
        'Home Widget update error: $e',
      );
    }
  }

// ⬇️ ADD DEADLINE METHOD HERE

static Future<void> updateDeadlineForGoal(
  CountdownItem? item,
) async {
  try {
    if (item == null) {
      await HomeWidget.saveWidgetData<String>(
        'deadline_widget_title',
        'Deadline',
      );

      await HomeWidget.saveWidgetData<String>(
        'deadline_widget_emoji',
        '⏳',
      );

      await HomeWidget.saveWidgetData<int>(
        'deadline_widget_target_millis',
        0,
      );

      await HomeWidget.saveWidgetData<String>(
        'deadline_widget_display_mode',
        'days',
      );
    } else {
      // Always write the CURRENT selected deadline goal.
      await HomeWidget.saveWidgetData<String>(
        'deadline_widget_title',
        item.title,
      );

      await HomeWidget.saveWidgetData<String>(
        'deadline_widget_emoji',
        item.emoji,
      );

      await HomeWidget.saveWidgetData<int>(
        'deadline_widget_target_millis',
        item.target.millisecondsSinceEpoch,
      );

      await HomeWidget.saveWidgetData<String>(
        'deadline_widget_display_mode',
        item.displayMode,
      );
    }

    // Tell Android to refresh the Deadline widget(s).
    await HomeWidget.updateWidget(
      qualifiedAndroidName:
          '"com.aashigupta_countdown".DeadlineWidgetProvider',
    );
  } catch (e) {
    debugPrint(
      'Deadline widget update error: $e',
    );
  }

}
  // 👇 ADD refreshDeadlineWidget HERE

static Future<void> refreshDeadlineWidget() async {
  final deadlineId =
      await AppStorage.loadDeadlineGoal();

  if (deadlineId == null || deadlineId.isEmpty) {
    await updateDeadlineForGoal(null);
    return;
  }

  final goals =
      await AppStorage.loadCountdowns();

  CountdownItem? deadlineGoal;

  for (final goal in goals) {
    if (goal.id == deadlineId) {
      deadlineGoal = goal;
      break;
    }
  }

  await updateDeadlineForGoal(
    deadlineGoal,
  );
 }
}


// ============================================================
// COUNTDOWN MODEL
// ============================================================

class CountdownItem {
  final String id;
  final String title;
  final String tagline;
  final String emoji;
  final DateTime target;
  final DateTime startTime;
  final bool showInApp;

  // days = 115d 18h 38m 31s
  // hours = 2766h 38m 31s
  final String displayMode;

  const CountdownItem({
    required this.id,
    required this.title,
    required this.tagline,
    required this.emoji,
    required this.target,
    required this.startTime,
    this.showInApp = true,
    this.displayMode = 'days',
  });
  int get completedDays {
    final startDate = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
    );

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    final difference = today.difference(startDate).inDays;

    return difference < 0 ? 0 : difference;
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'tagline': tagline,
      'emoji': emoji,
      'target': target.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'showInApp': showInApp,
      'displayMode': displayMode,
    };
  }

  factory CountdownItem.fromJson(
    Map<String, dynamic> json,
  ) {
    DateTime target;
    DateTime startTime;

    try {
      target = DateTime.parse(
        json['target']?.toString() ??
            DateTime.now()
                .add(
                  const Duration(days: 1),
                )
                .toIso8601String(),
      );
    } catch (_) {
      target = DateTime.now().add(
        const Duration(days: 1),
      );
    }
    try {
      startTime = DateTime.parse(
        json['startTime']?.toString() ??
            DateTime.now().toIso8601String(),
      );
    } catch (_) {
      startTime = DateTime.now();
    }

    final savedDisplayMode =
        json['displayMode']?.toString();

    return CountdownItem(
      id: json['id']?.toString() ??
          DateTime.now()
              .millisecondsSinceEpoch
              .toString(),

      title: json['title']?.toString() ??
          'My Goal',

      tagline: json['tagline']?.toString() ??
          json['Tagline']?.toString() ??
          'Keep going. You can do this.',

      emoji: json['emoji']?.toString() ??
          '🎯',

      target: target,

      startTime: startTime,

      showInApp:
          json['showInApp'] is bool
              ? json['showInApp'] as bool
              : true,

      displayMode:
          savedDisplayMode == 'hours'
              ? 'hours'
              : 'days',
    );
  }
}

// ============================================================
// STORAGE
// ============================================================

class AppStorage {
  static const String countdownKey =
      'countdowns';

  static const String primaryGoalKey =
      'primary_goal_id';
  static const String deadlineGoalKey =
    'deadline_goal_id';

  static Future<List<CountdownItem>>
      loadCountdowns() async {
    final prefs =
        await SharedPreferences.getInstance();

    final saved =
        prefs.getString(countdownKey);

    if (saved == null || saved.isEmpty) {
      return [];
    }

    try {
      final decoded =
          jsonDecode(saved);

      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) =>
                CountdownItem.fromJson(
              Map<String, dynamic>.from(
                item,
              ),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint(
        'Load error: $e',
      );

      return [];
    }
  }

  static Future<void> saveCountdowns(
    List<CountdownItem> items,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      countdownKey,
      jsonEncode(
        items
            .map(
              (item) => item.toJson(),
            )
            .toList(),
      ),
    );
  }

  static Future<String?>
      loadPrimaryGoal() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      primaryGoalKey,
    );
  }

  static Future<void> savePrimaryGoal(
    String id,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      primaryGoalKey,
      id,
    );
  }

  static Future<void>
      clearPrimaryGoal() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      primaryGoalKey,
    );
  }

  static Future<String?>
      loadDeadlineGoal() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(
      deadlineGoalKey,
    );
  }

  static Future<void>
      saveDeadlineGoal(String id) async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
      deadlineGoalKey,
      id,
    );
  }

  static Future<void>
      clearDeadlineGoal() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      deadlineGoalKey,
    );
  }
}


// ============================================================
// HOME PAGE
// ============================================================

class CountdownHomePage
    extends StatefulWidget {
  const CountdownHomePage({
    super.key,
  });

  @override
  State<CountdownHomePage> createState() =>
      _CountdownHomePageState();
}

class _CountdownHomePageState
    extends State<CountdownHomePage> {
  List<CountdownItem> countdowns = [];

  String? primaryGoalId;

  Timer? timer;

  @override
  void initState() {
    super.initState();

    loadApp();

    timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {});

          final goal = primaryGoal;

          if (goal != null) {
            HomeWidgetService
                .updateForGoal(goal);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  // ==========================================================
  // LOAD APP
  // ==========================================================

  Future<void> loadApp() async {
    final items =
        await AppStorage.loadCountdowns();

    final savedPrimary =
        await AppStorage.loadPrimaryGoal();

    if (!mounted) return;

    setState(() {
      countdowns = items;
      primaryGoalId = savedPrimary;
    });

    // Make sure saved primary goal still exists.
    if (primaryGoalId != null &&
        !countdowns.any(
          (item) =>
              item.id == primaryGoalId,
        )) {
      primaryGoalId = null;

      await AppStorage.clearPrimaryGoal();

      if (mounted) {
        setState(() {});
      }
    }

    // IMPORTANT:
    // We DO NOT create example goals anymore.
    //
    // A new user starts with zero goals.

    await HomeWidgetService.updateForGoal(
      primaryGoal,
    );
  }

  // ==========================================================
  // PRIMARY GOAL
  // ==========================================================

  CountdownItem? get primaryGoal {
    if (primaryGoalId == null) {
      return null;
    }

    try {
      return countdowns.firstWhere(
        (item) =>
            item.id == primaryGoalId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> selectPrimaryGoal(
    CountdownItem item,
  ) async {
    setState(() {
      primaryGoalId = item.id;
    });

    await AppStorage.savePrimaryGoal(
      item.id,
    );

    await HomeWidgetService
        .updateForGoal(item);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          '${item.emoji} ${item.title} '
          'selected as your primary goal.',
        ),
      ),
    );
  }

  // ==========================================================
  // ADD GOAL
  // ==========================================================

  Future<void> addCountdown() async {
     debugPrint('>>> ADD GOAL PRESSED');
    try {
    final result =
        await Navigator.push<CountdownItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const CountdownEditorPage(),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      countdowns.add(result);

      // First goal automatically becomes primary.
    primaryGoalId ??= result.id;  
    });

    await AppStorage.saveCountdowns(
      countdowns,
    );

    if (primaryGoalId != null) {
      await AppStorage.savePrimaryGoal(
        primaryGoalId!,
      );
    }

    await HomeWidgetService
        .updateForGoal(primaryGoal);
  } catch (e, stackTrace) {
    debugPrint('>>> ADD GOAL ERROR: $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}

  // ==========================================================
  // EDIT GOAL
  // ==========================================================

  Future<void> editCountdown(
    CountdownItem item,
  ) async {
    final result =
        await Navigator.push<CountdownItem>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CountdownEditorPage(
          existingItem: item,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    final index =
        countdowns.indexWhere(
      (element) =>
          element.id == item.id,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      countdowns[index] = result;
    });

    await AppStorage.saveCountdowns(
      countdowns,
    );

    if (primaryGoalId == result.id) {
      await HomeWidgetService
          .updateForGoal(result);
    }
    final deadlineId =
    await AppStorage.loadDeadlineGoal();

    if (deadlineId == result.id) {
      await HomeWidgetService
          .updateDeadlineForGoal(result);
}
  }

  // ==========================================================
  // DELETE GOAL
  // ==========================================================

  Future<void> deleteCountdown(
    CountdownItem item,
  ) async {
    final confirmed =
        await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            'Delete countdown?',
          ),
          content: Text(
            'Delete "${item.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                false,
              ),
              child:
                  const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(
                context,
                true,
              ),
              child:
                  const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }
    final deadlineId =
    await AppStorage.loadDeadlineGoal();

    setState(() {
      countdowns.removeWhere(
        (element) =>
            element.id == item.id,
      );

      if (primaryGoalId == item.id) {
        primaryGoalId =
            countdowns.isEmpty
                ? null
                : countdowns.first.id;
      }
    });

    await AppStorage.saveCountdowns(
      countdowns,
    );

    if (primaryGoalId != null) {
      await AppStorage.savePrimaryGoal(
        primaryGoalId!,
      );
    } else {
      await AppStorage.clearPrimaryGoal();
    }
    if (deadlineId == item.id) {
  await AppStorage.clearDeadlineGoal();

  await HomeWidgetService
      .updateDeadlineForGoal(null);
    }

      await HomeWidgetService
          .updateForGoal(primaryGoal);
    
  }  


    

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Countdown',
          style: TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(16),

        children: [

          // ====================================================
          // PRIMARY GOAL
          // ====================================================

          if (primaryGoal != null) ...[
            PrimaryGoalCard(
              item: primaryGoal!,
            ),

            const SizedBox(
              height: 24,
            ),

            const Text(
              'All Goals',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 12,
            ),
          ],

          // ====================================================
          // EMPTY STATE
          // ====================================================

          if (countdowns.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.only(
                top: 100,
                left: 20,
                right: 20,
              ),
              child: Column(
                children: [
                  const Text(
                    '🎯',
                    style: TextStyle(
                      fontSize: 64,
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  const Text(
                    'Create your first goal',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    'Set a goal and watch '
                    'the countdown begin.',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color:
                          Colors.white60,
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  FilledButton.icon(
                    onPressed:
                        addCountdown,
                    icon: const Icon(
                      Icons.add,
                    ),
                    label: const Text(
                      'Create Goal',
                    ),
                  ),
                ],
              ),
            ),

          // ====================================================
          // ALL GOALS
          // ====================================================

          ...countdowns.map(
            (item) =>
                CountdownCard(
              item: item,
              isPrimary:
                  primaryGoalId ==
                      item.id,
              onSelect: () =>
                  selectPrimaryGoal(
                item,
              ),
              onEdit: () =>
                  editCountdown(
                item,
              ),
              onDelete: () =>
                  deleteCountdown(
                item,
              ),
              onSetDeadline: () async {
                await AppStorage
                    .saveDeadlineGoal(
                  item.id,
                );

                await HomeWidgetService
                    .updateDeadlineForGoal(
                  item,
                );

                if (!mounted) return;
                final currentContext = context;

                ScaffoldMessenger.of(
                  // ignore: use_build_context_synchronously
                  currentContext 
                        )
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      '${item.emoji} ${item.title} '
                      'set as your deadline goal.',
                    ),
                  ),
                );
              },
            )
          ),
        ],
      ),
              

      floatingActionButton:
          FloatingActionButton.extended(
        onPressed:
            addCountdown,
        icon: const Icon(
          Icons.add,
        ),
        label: const Text(
          'Add Goal',
        ),
      ),
    );
  }
}

// ============================================================
// PRIMARY GOAL CARD
// ============================================================

class PrimaryGoalCard
    extends StatelessWidget {
  final CountdownItem item;

  const PrimaryGoalCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final remaining =
        item.target.difference(
      DateTime.now(),
    );

    final totalSeconds =
        remaining.inSeconds < 0
            ? 0
            : remaining.inSeconds;

    final days =
        totalSeconds ~/ 86400;

    final hours =
        totalSeconds ~/ 3600;

    final hoursPart =
        (totalSeconds % 86400) ~/ 3600;

    final minutes =
        (totalSeconds % 3600) ~/ 60;

    final seconds =
        totalSeconds % 60;

    final completed =
        totalSeconds == 0;

    return Card(
      elevation: 0,
      color:
          const Color(0xFF1D1A30),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(
          28,
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                Text(
                  item.emoji,
                  style:
                      const TextStyle(
                    fontSize: 32,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                const Expanded(
                  child: Text(
                    'PRIMARY GOAL',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const Icon(
                  Icons.push_pin,
                  size: 20,
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            Text(
              item.tagline,
              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color:
                    Colors.white60,
                fontStyle:
                    FontStyle.italic,
              ),
            ),

            const SizedBox(
              height: 28,
            ),

            if (completed)
              const Text(
                '🎉 GOAL DAY!',
                style:
                    TextStyle(
                  fontSize: 28,
                  fontWeight:
                      FontWeight.bold,
                ),
              )
            else if (item.displayMode ==
                'hours')
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  BigTimeUnit(
                    value: hours,
                    label: 'HOURS',
                  ),
                  BigTimeUnit(
                    value: minutes,
                    label: 'MIN',
                  ),
                  BigTimeUnit(
                    value: seconds,
                    label: 'SEC',
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  BigTimeUnit(
                    value: days,
                    label: 'DAYS',
                  ),
                  BigTimeUnit(
                    value: hoursPart,
                    label: 'HOURS',
                  ),
                  BigTimeUnit(
                    value: minutes,
                    label: 'MIN',
                  ),
                  BigTimeUnit(
                    value: seconds,
                    label: 'SEC',
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// BIG TIME UNIT
// ============================================================

class BigTimeUnit
    extends StatelessWidget {
  final int value;
  final String label;

  const BigTimeUnit({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          '$value',
          style:
              const TextStyle(
            fontSize: 28,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        const SizedBox(
          height: 4,
        ),
        Text(
          label,
          style:
              const TextStyle(
            fontSize: 9,
            color:
                Colors.white38,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// COUNTDOWN CARD
// ============================================================

class CountdownCard
    extends StatelessWidget {
  final CountdownItem item;
  final bool isPrimary;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDeadline;

  const CountdownCard({
    super.key,
    required this.item,
    required this.isPrimary,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDeadline,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final remaining =
        item.target.difference(
      DateTime.now(),
    );

    final totalSeconds =
        remaining.inSeconds < 0
            ? 0
            : remaining.inSeconds;

    final days =
        totalSeconds ~/ 86400;

    final hours =
        totalSeconds ~/ 3600;

    final hoursPart =
        (totalSeconds % 86400) ~/ 3600;

    final minutes =
        (totalSeconds % 3600) ~/ 60;

    final seconds =
        totalSeconds % 60;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              110,
            ),
        child: Column(
          children: [

            Row(
              children: [
                Text(
                  item.emoji,
                  style:
                      const TextStyle(
                    fontSize: 28,
                  ),
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        item.title,
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        item.tagline,
                        maxLines: 1,
                        overflow:
                            TextOverflow
                                .ellipsis,
                        style:
                            const TextStyle(
                          color:
                              Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                PopupMenuButton<
                    String>(
                  onSelected:
                      (value) {
                    if (value ==
                        'edit') {
                      onEdit();
                    }

                    if (value ==
                        'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder:
                      (context) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child:
                            Text('Edit'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child:
                            Text('Delete'),
                      ),
                    ];
                  },
                ),
              ],
            ),

            const SizedBox(
              height: 18,
            ),

            if (item.displayMode ==
                'hours')
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  SmallTimeUnit(
                    value: hours,
                    label: 'HOURS',
                  ),
                  SmallTimeUnit(
                    value: minutes,
                    label: 'MIN',
                  ),
                  SmallTimeUnit(
                    value: seconds,
                    label: 'SEC',
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .spaceBetween,
                children: [
                  SmallTimeUnit(
                    value: days,
                    label: 'DAYS',
                  ),
                  SmallTimeUnit(
                    value: hoursPart,
                    label: 'HOURS',
                  ),
                  SmallTimeUnit(
                    value: minutes,
                    label: 'MIN',
                  ),
                  SmallTimeUnit(
                    value: seconds,
                    label: 'SEC',
                  ),
                ],
              ),

            const SizedBox(
              height: 16,
            ),

            SizedBox(
              width: double.infinity,
              child: isPrimary
                  ? OutlinedButton.icon(
                      onPressed: null,
                      icon:
                          const Icon(
                        Icons.check_circle,
                      ),
                      label:
                          const Text(
                        'Primary Goal',
                      ),
                    )
                  : FilledButton
                      .tonalIcon(
                      onPressed:
                          onSelect,
                      icon:
                          const Icon(
                        Icons
                            .push_pin_outlined,
                      ),
                      label:
                          const Text(
                        'Set as Primary Goal',
                      ),
                    ),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onSetDeadline,
                icon: const Icon(
                  Icons.hourglass_bottom,
                ),
                label: const Text(
                  'Set as Deadline',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SMALL TIME UNIT
// ============================================================

class SmallTimeUnit
    extends StatelessWidget {
  final int value;
  final String label;

  const SmallTimeUnit({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Column(
      children: [
        Text(
          '$value',
          style:
              const TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 3,
        ),

        Text(
          label,
          style:
              const TextStyle(
            fontSize: 8,
            color:
                Colors.white38,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// EDITOR
// ============================================================

class CountdownEditorPage
    extends StatefulWidget {
  final CountdownItem? existingItem;

  const CountdownEditorPage({
    super.key,
    this.existingItem,
  });

  @override
  State<CountdownEditorPage>
      createState() =>
          _CountdownEditorPageState();
}

class _CountdownEditorPageState
    extends State<
        CountdownEditorPage> {

  late TextEditingController
      titleController;

  late TextEditingController
      taglineController;

  late TextEditingController
      emojiController;

  late DateTime selectedDate;

  bool showInApp = true;

  String displayMode = 'days';

  @override
  void initState() {
    super.initState();

    final item =
        widget.existingItem;

    titleController =
        TextEditingController(
      text: item?.title ?? '',
    );

    taglineController =
        TextEditingController(
      text: item?.tagline ?? '',
    );

    emojiController =
        TextEditingController(
      text: item?.emoji ?? '🎯',
    );

    selectedDate =
        item?.target ??
            DateTime.now().add(
          const Duration(days: 30),
        );

    showInApp =
        item?.showInApp ?? true;

    displayMode =
        item?.displayMode ?? 'days';
  }

  @override
  void dispose() {
    titleController.dispose();
    taglineController.dispose();
    emojiController.dispose();

    super.dispose();
  }

  // ==========================================================
  // DATE PICKER
  // ==========================================================

  Future<void> chooseDate() async {
    final picked =
        await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked == null) {
      return;
    }

    setState(() {
      selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      );
    });
  }

  // ==========================================================
  // SAVE GOAL
  // ==========================================================

  Future<void> saveGoal() async {
  final title = titleController.text.trim();
  

  final tagline = taglineController.text.trim();

  final emoji = emojiController.text.trim();

  if (title.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please enter a goal name.',
        ),
      ),
    );

    return;
  }

  final result = CountdownItem(
    id: widget.existingItem?.id ??
        DateTime.now()
            .millisecondsSinceEpoch
            .toString(),

    title: title,

    tagline: tagline.isEmpty
        ? 'Keep going. You can do this.'
        : tagline,

    emoji: emoji.isEmpty
        ? '🎯'
        : emoji,

    target: selectedDate,

    showInApp: showInApp,

    displayMode: displayMode,

    startTime:
        widget.existingItem?.startTime ??
            DateTime.now(),
  );

  // Save the goal first.
  // Notification permission should NOT block goal creation.
  if (mounted) {
    Navigator.pop(
      context,
      result,
    );
  }

  // Try to schedule notification separately.
  // If permission/alarm scheduling fails,
  // the goal has already been saved.
  try {
    await scheduleDailyGoalNotification(result);
  } catch (e) {
    debugPrint(
      'Notification scheduling failed: $e',
    );
  }
}

  // ==========================================================
  // BUILD EDITOR
  // ==========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final editing =
        widget.existingItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Edit Goal'
              : 'Add Goal',
        ),
      ),

      body: ListView(
        padding:
            const EdgeInsets.all(20),

        children: [

          // ==================================================
          // GOAL NAME
          // ==================================================

          TextField(
            controller:
                titleController,
            decoration:
                const InputDecoration(
              labelText:
                  'Goal Name',
              hintText:
                  'Example: Get My Dream Job',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // TAGLINE
          // ==================================================

          TextField(
            controller:
                taglineController,
            maxLength: 500,
            maxLines: 4,
            decoration:
                const InputDecoration(
              labelText:
                  'Motivational Line',
              hintText:
                  'Write your own motivation...',
              border:
                  OutlineInputBorder(),
              alignLabelWithHint:
                  true,
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          // ==================================================
          // EMOJI
          // ==================================================

          TextField(
            controller:
                emojiController,
            decoration:
                const InputDecoration(
              labelText:
                  'Goal Emoji',
              hintText:
                  '🎯',
              border:
                  OutlineInputBorder(),
            ),
          ),

          const SizedBox(
            height: 20,
          ),

          // ==================================================
          // TARGET DATE
          // ==================================================

          Card(
            child: ListTile(
              leading:
                  const Icon(
                Icons.calendar_month,
              ),

              title:
                  const Text(
                'Target Date',
              ),

              subtitle:
                  Text(
                '${selectedDate.day}/'
                '${selectedDate.month}/'
                '${selectedDate.year}',
              ),

              trailing:
                  FilledButton(
                onPressed:
                    chooseDate,
                child:
                    const Text(
                  'Change',
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          // ==================================================
          // DISPLAY MODE
          // ==================================================

          Card(
            child: Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    'Countdown Display',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Choose how you want '
                    'the remaining time displayed.',
                    style: TextStyle(
                      color:
                          Colors.white60,
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'days',
                        icon: Icon(
                          Icons.calendar_today,
                        ),
                        label:
                            Text('Days'),
                      ),

                      ButtonSegment<String>(
                        value: 'hours',
                        icon: Icon(
                          Icons.access_time,
                        ),
                        label:
                            Text('Hours'),
                      ),
                    ],

                    selected: {
                      displayMode,
                    },

                    onSelectionChanged:
                        (selection) {
                      setState(() {
                        displayMode =
                            selection.first;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          // ==================================================
          // SHOW IN APP
          // ==================================================

          SwitchListTile(
            title:
                const Text(
              'Show on main screen',
            ),

            subtitle:
                const Text(
              'Show this countdown '
              'inside the app.',
            ),

            value:
                showInApp,

            onChanged:
                (value) {
              setState(() {
                showInApp =
                    value;
              });
            },
          ),

          const SizedBox(
            height: 30,
          ),

          // ==================================================
          // SAVE
          // ==================================================

          SizedBox(
            height: 55,
            child:
                FilledButton.icon(
              onPressed:
                  saveGoal,

              icon:
                  const Icon(
                Icons.save,
              ),

              label:
                  Text(
                editing
                    ? 'Save Changes'
                    : 'Add Goal',
              ),
            ),
          ),
        ],
      ),
    );
  }
}