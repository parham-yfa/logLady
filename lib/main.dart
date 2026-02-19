import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ---------------------------------------------------------
// 🚀 INITIALIZATION
// ---------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    // ⚠️ REPLACE WITH YOUR ACTUAL KEYS
    url: 'https://rcizfrkctjctjgicizvz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjaXpmcmtjdGpjdGpnaWNpenZ6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzExNjUzODcsImV4cCI6MjA4Njc0MTM4N30.BxhUM1Tur_YKKwU40XIeqm9Mi0diO6A1f_zNoZEa6V8', 
  );

  runApp(const LogLadyApp());
}

class LogLadyApp extends StatelessWidget {
  const LogLadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D3436)),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  // ---------------------------------------------------------
  // 🎛️ CONFIGURATION: LEGACY STARTING POINTS
  // ---------------------------------------------------------
  final int legacyStreakDays = 5000;     // She starts with a 12-day streak
  final int legacyStackCount = 50;     // She has done double-sessions 25 times before
  
  // ---------------------------------------------------------
  // 🌍 LOCALIZATION ENGINE
  // ---------------------------------------------------------
  bool _isTurkish = false; // Default to English

  String t(String key) {
    const Map<String, Map<String, String>> dict = {
      'en': {
        'good_morning': 'Good Morning Log Lady,',
        'fitness_hq': 'Logland',
        'streak_title': 'Streak Depth',
        'momentum': 'Momentum',
        'velocity': 'Velocity Score',
        'anchor': 'Routine Anchor',
        'stacking': 'Habit Stacking',
        'stacks': 'Stacks',
        'recent': 'Recent Logs',
        'log_btn': 'Log Activity',
        'save': 'Save Entry',
        'activity_label': 'Activity Type',
        'duration_label': 'Duration',
        'custom_min': 'Custom min',
        'add_tag_title': 'Add New Tag',
        'enter_tag': 'Activity Name',
        'add': 'Add',
        'cancel': 'Cancel',
        'window': 'Window',
        'consistency': 'consistency',
        'double_sessions': 'Double sessions',
        'tip_shield': 'Tip: Select "Rest" to use Shield Protection',
        'daily': 'Daily', 'weekly': 'Weekly', 'monthly': 'Monthly',
        'days': 'days', 'wks': 'weeks', 'mos': 'months',
        'streak_desc': 'The number of consecutive days, weeks, or months you have logged activity.',
        'momentum_desc': 'A weighted score based on your activity frequency over the last 30 days.',
        'anchor_desc': 'The 2-hour time window where you are most consistent with your sessions.',
        'stacking_desc': 'The total count of days where you performed more than one activity.',
        'weekly_activity': 'Weekly Activity (mins)',
      },
      'tr': {
        'good_morning': 'Log Lady Günaydın,',
        'fitness_hq': 'Logland',
        'streak_title': 'Seri Derinliği',
        'momentum': 'Momentum',
        'velocity': 'Hız Puanı',
        'anchor': 'Rutin Çapası',
        'stacking': 'Zincirleme',
        'stacks': 'Zincir',
        'recent': 'Son Kayıtlar',
        'log_btn': 'Aktivite Ekle',
        'save': 'Kaydet',
        'activity_label': 'Aktivite Türü',
        'duration_label': 'Süre',
        'custom_min': 'Özel dk',
        'add_tag_title': 'Yeni Etiket Ekle',
        'enter_tag': 'Aktivite Adı',
        'add': 'Ekle',
        'cancel': 'İptal',
        'window': 'Aralık',
        'consistency': 'tutarlılık',
        'double_sessions': 'Çift antrenman',
        'tip_shield': 'İpucu: Seriyi korumak için "Rest" seçin',
        'daily': 'Günlük', 'weekly': 'Hft', 'monthly': 'Aylık',
        'days': 'gün', 'wks': 'hafta', 'mos': 'ay',
        'streak_desc': 'Aktivite kaydettiğiniz ardışık gün, hafta veya ay sayısı.',
        'momentum_desc': 'Son 30 gündeki aktivite sıklığınıza dayalı ağırlıklı bir puan.',
        'anchor_desc': 'Antrenmanlarınızda en tutarlı olduğunuz 2 saatlik zaman aralığı.',
        'stacking_desc': 'Birden fazla aktivite yaptığınız toplam gün sayısı.',
        'weekly_activity': 'Haftalık Aktivite (dk)',
      }
    };
    return dict[_isTurkish ? 'tr' : 'en']![key] ?? key;
  }

  // ---------------------------------------------------------
  // 📊 STATE VARIABLES
  // ---------------------------------------------------------
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Default Tags
  List<String> _activityTags = ['Yoga', 'HIIT', 'Walk', 'Run', 'Pilates', 'Weights', 'Swim', 'Rest'];
  
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _chartAnimation = CurvedAnimation(parent: _chartController, curve: Curves.easeOutQuart);
    _chartController.forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logStream = Supabase.instance.client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .order('activity_date', ascending: false);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: logStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        
        final logs = snapshot.data!;
        final historicalTags = logs.map((e) => e['type'] as String).toSet();
        final metrics = _calculateSmartMetrics(logs);

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                // HEADER & LANGUAGE TOGGLE
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t('good_morning'), style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 14)),
                            Text(t('fitness_hq'), style: GoogleFonts.inter(color: const Color(0xFF2D3436), fontWeight: FontWeight.w800, fontSize: 28)),
                          ],
                        ),
                        // Language Toggle Button
                        GestureDetector(
                          onTap: () => setState(() => _isTurkish = !_isTurkish),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Text(_isTurkish ? "TR" : "EN", style: const TextStyle(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 4),
                                const Icon(Icons.language, size: 16),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

                // DASHBOARD GRID
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      
                      // ROW 1: DAILY & WEEKLY STREAKS
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmartCard(
                              title: t('daily'),
                              icon: Icons.local_fire_department,
                              iconColor: Colors.orange,
                              description: t('streak_desc'),
                              content: Text("${metrics['streak_daily']} ${t('days')}", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSmartCard(
                              title: t('weekly'),
                              icon: Icons.calendar_view_week,
                              iconColor: Colors.deepOrange,
                              description: t('streak_desc'),
                              content: Text("${metrics['streak_weekly']} ${t('weeks')}", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ROW 2: MONTHLY STREAK & HABIT STACKING
                      Row(
                        children: [
                          Expanded(
                            child: _buildSmartCard(
                              title: t('monthly'),
                              icon: Icons.calendar_month,
                              iconColor: Colors.red,
                              description: t('streak_desc'),
                              content: Text("${metrics['streak_monthly']} ${t('months')}", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSmartCard(
                              title: t('stacking'),
                              icon: Icons.layers,
                              iconColor: Colors.pinkAccent,
                              description: t('stacking_desc'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("${metrics['stacks']}", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                                  Text(t('double_sessions'), style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // WEEKLY ACTIVITY CHART
                      _buildActivityChart(logs),
                      const SizedBox(height: 12),

                      // CALENDAR
                      Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.all(12),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          calendarFormat: CalendarFormat.twoWeeks, 
                          calendarStyle: const CalendarStyle(
                            todayDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                            selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                          ),
                          calendarBuilders: CalendarBuilders(
                            markerBuilder: (context, day, events) {
                              if (events.isEmpty) return null;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: events.take(4).map((e) {
                                  final log = e as Map<String, dynamic>;
                                  return Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                    width: 6, height: 6,
                                    decoration: BoxDecoration(
                                      color: _getActivityColor(log['type'].toString()),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                          eventLoader: (day) {
                            return logs.where((log) => isSameDay(DateTime.parse(log['activity_date']), day)).toList();
                          },
                          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      Text(t('recent'), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 10),
                    ]),
                  ),
                ),

                // LOG LIST
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final log = logs[index];
                        final activityType = log['type'].toString();
                        final activityColor = _getActivityColor(activityType);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: activityColor.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_getActivityIcon(activityType), 
                                color: activityColor, size: 22),
                            ),
                            title: Text(activityType, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("${DateFormat.MMMd().format(DateTime.parse(log['activity_date']))} • ${log['duration']} mins"),
                            trailing: IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.grey[400]),
                              onPressed: () async => await Supabase.instance.client.from('activity_logs').delete().match({'id': log['id']}),
                            ),
                          ),
                        );
                      },
                      childCount: logs.length,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FloatingActionButton.extended(
                onPressed: () => _showSmartLogSheet(context, historicalTags),
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                elevation: 0,
                label: Text(
                  t('log_btn'),
                  style: const TextStyle(color: Color(0xFF2D3436), fontWeight: FontWeight.bold, fontSize: 16),
                ),
                icon: const Icon(Icons.add, color: Color.fromARGB(255, 45, 52, 54)),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  // ---------------------------------------------------------
  // 🧠 SMART METRIC CALCULATIONS
  // ---------------------------------------------------------
  Map<String, dynamic> _calculateSmartMetrics(List<Map<String, dynamic>> logs) {
    // 1. STREAK DEPTH
    final logDates = logs
        .map((log) => DateTime.parse(log['activity_date'] as String))
        .map((date) => DateTime(date.year, date.month, date.day))
        .toSet();

    int currentStreak = 0;
    if (logDates.isNotEmpty) {
      DateTime today = DateTime.now();
      DateTime currentDate = DateTime(today.year, today.month, today.day);

      // A streak is valid if there's a log today or yesterday.
      // If no log today, we check if the streak ended yesterday.
      if (!logDates.contains(currentDate)) {
        currentDate = currentDate.subtract(const Duration(days: 1));
      }

      // Now, count backwards from the last active day.
      while (logDates.contains(currentDate)) {
        currentStreak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      }
    }
    
    // 2. HABIT STACKING
    // Count distinct days that appear more than once
    Map<String, int> dailyFreq = {};
    for (var log in logs) {
      String d = log['activity_date'].toString().split('T')[0];
      dailyFreq[d] = (dailyFreq[d] ?? 0) + 1;
    }
    int stacks = legacyStackCount + dailyFreq.values.where((c) => c > 1).length;

    int daily = legacyStreakDays + currentStreak;

    return {
      'streak_daily': daily,
      'streak_weekly': (daily / 7).ceil(),
      'streak_monthly': (daily / 30).ceil(),
      'stacks': stacks,
    };
  }

  // ---------------------------------------------------------
  // 🎨 UI BUILDERS
  // ---------------------------------------------------------
  Widget _buildSmartCard({
  required String title, 
  required IconData icon, 
  required Color iconColor, 
  required Widget content, 
  String? description // This must be here
}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 8))]),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [Icon(icon, size: 18, color: iconColor), const SizedBox(width: 8), Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400]))]),
            if (description != null) // Only shows 'i' if description is provided
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                onPressed: () => _showInfoDialog(title, description),
              ),
          ],
        ),
        const SizedBox(height: 16),
        content,
      ],
    ),
  );
}

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 📝 NEW: TAG-BASED ADD LOG SHEET
  // ---------------------------------------------------------
  void _showSmartLogSheet(BuildContext context, Set<String> historicalTags) {
    String selectedTag = "";
    int selectedDuration = 0;
    final customDurationCtrl = TextEditingController();
    DateTime selectedDate = _selectedDay ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final displayTags = {..._activityTags, ...historicalTags}.toList();
            
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 24),
                  
                  // 1. ACTIVITY TAGS
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(t('activity_label'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      onPressed: () {
                         TextEditingController newTagCtrl = TextEditingController();
                         showDialog(context: context, builder: (c) => AlertDialog(
                           title: Text(t('add_tag_title')),
                           content: TextField(controller: newTagCtrl, decoration: InputDecoration(hintText: t('enter_tag'))),
                           actions: [
                             TextButton(onPressed: () => Navigator.pop(c), child: Text(t('cancel'))),
                             TextButton(onPressed: () {
                               if (newTagCtrl.text.isNotEmpty) {
                                 setState(() => _activityTags.add(newTagCtrl.text));
                                 setModalState(() {});
                                 Navigator.pop(c);
                               }
                             }, child: Text(t('add'))),
                           ],
                         ));
                      },
                    )
                  ]),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: displayTags.map((tag) {
                      final isSelected = selectedTag == tag;
                      final tagColor = _getActivityColor(tag);
                      return InputChip(
                        label: Text(tag),
                        selected: isSelected,
                        showCheckmark: false,
                        selectedColor: tagColor,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                        onSelected: (bool selected) {
                          setModalState(() => selectedTag = selected ? tag : "");
                        },
                        deleteIcon: const Icon(Icons.close, size: 16),
                        deleteIconColor: isSelected ? Colors.white70 : Colors.grey,
                        onDeleted: () {
                          showDialog(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Delete Tag'),
                              content: Text('Are you sure you want to delete "$tag"?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: Text(t('cancel')),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _activityTags.remove(tag));
                                    setModalState(() {});
                                    Navigator.pop(dialogContext);
                                  },
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  if (selectedTag.toLowerCase().contains('rest'))
                    Padding(padding: const EdgeInsets.only(top: 8), child: Text(t('tip_shield'), style: const TextStyle(color: Colors.green, fontSize: 12, fontStyle: FontStyle.italic))),

                  const SizedBox(height: 24),

                  // 2. DURATION
                  Text(t('duration_label'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: [30, 45, 60, 90].map((min) {
                      return ChoiceChip(
                        label: Text("$min min"),
                        selected: selectedDuration == min,
                        onSelected: (s) {
                          setModalState(() {
                            selectedDuration = s ? min : 0;
                            customDurationCtrl.clear();
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: customDurationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: t('custom_min'),
                      filled: true, fillColor: const Color(0xFFF0F2F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    ),
                    onChanged: (val) {
                      setModalState(() => selectedDuration = int.tryParse(val) ?? 0);
                    },
                  ),

                  const SizedBox(height: 30),
                  
                  // SAVE BUTTON
                  ElevatedButton(
                    onPressed: (selectedTag.isEmpty || selectedDuration == 0) ? null : () async {
                      await Supabase.instance.client.from('activity_logs').insert({
                        'activity_date': selectedDate.toIso8601String(), 
                        'type': selectedTag, 
                        'duration': selectedDuration
                      });
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D3436),
                      disabledBackgroundColor: Colors.grey.shade300,
                      minimumSize: const Size(double.infinity, 56), 
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                    ),
                    child: Text(t('save'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ), // End of Column
            ); // End of Padding
          },
        );
      },
    );
  } // This closes _showSmartLogSheet correctly

  // --- HELPER METHODS ---
  IconData _getActivityIcon(String type) {
    final t = type.toLowerCase();
    if (t.contains('yoga')) { return Icons.self_improvement; }
    if (t.contains('walk')) { return Icons.directions_walk; }
    if (t.contains('run') || t.contains('hiit')) { return Icons.directions_run; }
    if (t.contains('weight') || t.contains('gym') || t.contains('pilates')) { return Icons.fitness_center; }
    if (t.contains('swim')) { return Icons.pool; }
    if (t.contains('rest')) { return Icons.shield; }
    return Icons.sports_score;
  }

  Color _getActivityColor(String type) {
    final t = type.toLowerCase();
    if (t.contains('yoga')) return Colors.purple;
    if (t.contains('walk')) return Colors.blue;
    if (t.contains('run') || t.contains('hiit')) return Colors.orange;
    if (t.contains('weight') || t.contains('gym') || t.contains('pilates')) return Colors.indigo;
    if (t.contains('swim')) return Colors.cyan;
    if (t.contains('rest')) return Colors.green;
    return Colors.grey;
  }

  Widget _buildActivityChart(List<Map<String, dynamic>> logs) {
    List<int> dailyTotals = List.filled(7, 0);
    List<String> dayLabels = List.filled(7, '');
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < 7; i++) {
      DateTime d = today.subtract(Duration(days: 6 - i));
      dayLabels[i] = DateFormat.E().format(d);
    }

    for (var log in logs) {
      DateTime logDate = DateTime.parse(log['activity_date']);
      DateTime date = DateTime(logDate.year, logDate.month, logDate.day);
      int diff = today.difference(date).inDays;
      if (diff >= 0 && diff < 7) {
        dailyTotals[6 - diff] += (log['duration'] as int);
      }
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t('weekly_activity'), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          const SizedBox(height: 20),
          Expanded(
            child: AnimatedBuilder(
              animation: _chartAnimation,
              builder: (context, child) => CustomPaint(
                painter: BarChartPainter(dailyTotals, dayLabels, animationValue: _chartAnimation.value),
                size: Size.infinite,
              ),
            ),
          ),
        ],
      ),
    );
  }
} // This closes _DashboardScreenState

class BarChartPainter extends CustomPainter {
  final List<int> values;
  final List<String> labels;
  final double animationValue;

  BarChartPainter(this.values, this.labels, {this.animationValue = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()..color = Colors.red..style = PaintingStyle.fill;
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    int maxVal = values.reduce(math.max);
    if (maxVal == 0) maxVal = 60;

    double barWidth = (size.width / values.length) * 0.4;
    double spacing = size.width / values.length;
    double bottomLabelHeight = 20.0;
    double topValueHeight = 15.0;
    double availableBarHeight = size.height - bottomLabelHeight - topValueHeight;

    for (int i = 0; i < values.length; i++) {
      double barHeight = (values[i] / maxVal) * availableBarHeight * animationValue;
      double x = i * spacing + (spacing - barWidth) / 2;
      double y = size.height - bottomLabelHeight - barHeight;

      RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(rect, paint);

      // Draw Value (Minutes)
      if (values[i] > 0) {
        textPainter.text = TextSpan(
          text: '${values[i]}',
          style: GoogleFonts.inter(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + (barWidth - textPainter.width) / 2, y - 14));
      }

      textPainter.text = TextSpan(
        text: labels[i],
        style: GoogleFonts.inter(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + (barWidth - textPainter.width) / 2, size.height - 15));
    }
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) => true;
}