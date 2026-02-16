import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

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

class _DashboardScreenState extends State<DashboardScreen> {
  // ---------------------------------------------------------
  // 🎛️ CONFIGURATION: LEGACY STARTING POINTS
  // ---------------------------------------------------------
  final int legacyStreakDays = 5000;     // She starts with a 12-day streak
  final int legacyStackCount = 50;     // She has done double-sessions 25 times before
  final double legacyVelocity = 95;  // Her starting "Momentum Score"
  
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
        'daily': 'Daily', 'weekly': 'Wkly', 'monthly': 'Mthly',
        'days': 'days', 'wks': 'wks', 'mos': 'mos',
        'streak_desc': 'The number of consecutive days, weeks, or months you have logged activity.',
        'momentum_desc': 'A weighted score based on your activity frequency over the last 30 days.',
        'anchor_desc': 'The 2-hour time window where you are most consistent with your sessions.',
        'stacking_desc': 'The total count of days where you performed more than one activity.',
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
        'days': 'gün', 'wks': 'hf', 'mos': 'ay',
        'streak_desc': 'Aktivite kaydettiğiniz ardışık gün, hafta veya ay sayısı.',
        'momentum_desc': 'Son 30 gündeki aktivite sıklığınıza dayalı ağırlıklı bir puan.',
        'anchor_desc': 'Antrenmanlarınızda en tutarlı olduğunuz 2 saatlik zaman aralığı.',
        'stacking_desc': 'Birden fazla aktivite yaptığınız toplam gün sayısı.',
      }
    };
    return dict[_isTurkish ? 'tr' : 'en']![key] ?? key;
  }

  // ---------------------------------------------------------
  // 📊 STATE VARIABLES
  // ---------------------------------------------------------
  int _streakTabIndex = 0; // 0=Daily, 1=Weekly, 2=Monthly
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Default Tags
  List<String> _activityTags = ['Yoga', 'HIIT', 'Walk', 'Run', 'Pilates', 'Weights', 'Swim', 'Rest'];

  @override
  Widget build(BuildContext context) {
    final logStream = Supabase.instance.client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .order('activity_date', ascending: false);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: logStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final logs = snapshot.data!;
            final metrics = _calculateSmartMetrics(logs);

            return CustomScrollView(
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
                      
                      // ROW 1: MULTI-TIER STREAK & VELOCITY
                      Row(
                        children: [
                          Expanded(child: _buildInteractiveStreakCard(metrics)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSmartCard(
                              title: t('momentum'),
                              icon: Icons.speed,
                              iconColor: Colors.blueAccent,
                              description: t('momentum_desc'), // Added this
                              content: Column(
                                children: [
                                  SizedBox(
                                    height: 50,
                                    child: CustomPaint(painter: LineChartPainter(logs: logs), size: const Size(double.infinity, 50)),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(t('velocity'), style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                                      Text("${metrics['velocity'].toInt()}", 
                                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _getVelocityColor(metrics['velocity']))),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ROW 2: ROUTINE ANCHOR
                      _buildSmartCard(
                        title: t('anchor'),
                        icon: Icons.schedule,
                        iconColor: Colors.purpleAccent,
                        description: t('anchor_desc'), // Added this
                        content: Row(
                          children: [
                            Container(
                              height: 45, width: 45,
                              decoration: BoxDecoration(color: Colors.purple.withAlpha(20), shape: BoxShape.circle),
                              child: const Icon(Icons.wb_twilight, color: Colors.purple),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${t('window')}: ${metrics['anchor_time']}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                Text("${metrics['anchor_pct']}% ${t('consistency')}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ROW 3: HABIT STACKING
                      _buildSmartCard(
                        title: t('stacking'),
                        icon: Icons.layers,
                        iconColor: Colors.pinkAccent,
                        description: t('stacking_desc'), // Added this
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${metrics['stacks']}", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                            Text(t('double_sessions'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
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
                            todayDecoration: BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                            selectedDecoration: BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                            markerDecoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle),
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
                        final isRest = activityType.toLowerCase().contains('rest');
                        
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
                                color: isRest ? Colors.green.withAlpha(25) : Colors.grey.withAlpha(25),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_getActivityIcon(activityType), 
                                color: isRest ? Colors.green : Colors.black87, size: 22),
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
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSmartLogSheet(context),
        backgroundColor: const Color(0xFF2D3436),
        label: Text(t('log_btn'), style: const TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ---------------------------------------------------------
  // 🧠 SMART METRIC CALCULATIONS
  // ---------------------------------------------------------
  Map<String, dynamic> _calculateSmartMetrics(List<Map<String, dynamic>> logs) {
    // 1. STREAK DEPTH (Simplified Logic for Demo)
    // In a real app, you would iterate dates to find gaps.
    int daily = legacyStreakDays;
    // Check if we logged today/yesterday to keep streak alive
    if (logs.isNotEmpty) {
      final lastDate = DateTime.parse(logs.first['activity_date']);
      final diff = DateTime.now().difference(lastDate).inDays;
      if (diff <= 1) daily += 1; // Fake increment for visual feedback
    }
    
    // 2. MOMENTUM VELOCITY (Rolling Flywheel)
    DateTime now = DateTime.now();
    int last7 = logs.where((l) => DateTime.parse(l['activity_date']).isAfter(now.subtract(const Duration(days: 7)))).length;
    int last30 = logs.where((l) => DateTime.parse(l['activity_date']).isAfter(now.subtract(const Duration(days: 30)))).length;
    
    // Shield Logic: 'Rest' days count for streak but add less velocity
    int restDays = logs.where((l) => (l['type'] as String).contains('Rest')).length;
    
    // Algorithm: Base + (Recent * 3) + (Monthly * 0.5) - Decay
    double velocity = legacyVelocity + (last7 * 2.5) + (last30 * 0.5) + (restDays * 0.2);
    if (velocity > 100) velocity = 100;

    // 3. ROUTINE ANCHOR (2-Hour Window)
    Map<int, int> hourCounts = {};
    for (var log in logs) {
      // Use created_at for time of day analysis
      final dt = DateTime.parse(log['created_at']).toLocal();
      // Bucket into 2-hour windows (e.g., 6=6-8, 8=8-10)
      int windowStart = (dt.hour ~/ 2) * 2; 
      hourCounts[windowStart] = (hourCounts[windowStart] ?? 0) + 1;
    }
    
    String anchorTime = "--";
    int anchorPct = 0;
    
    if (hourCounts.isNotEmpty) {
      var topWindow = hourCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
      anchorTime = "${topWindow.key}:00 - ${topWindow.key + 2}:00";
      anchorPct = ((topWindow.value / logs.length) * 100).toInt();
    }

    // 4. HABIT STACKING
    // Count distinct days that appear more than once
    Map<String, int> dailyFreq = {};
    for (var log in logs) {
      String d = log['activity_date'].toString().split('T')[0];
      dailyFreq[d] = (dailyFreq[d] ?? 0) + 1;
    }
    int stacks = legacyStackCount + dailyFreq.values.where((c) => c > 1).length;

    return {
      'streak_daily': daily,
      'streak_weekly': (daily / 7).ceil(),
      'streak_monthly': (daily / 30).ceil(),
      'velocity': velocity,
      'anchor_time': anchorTime,
      'anchor_pct': anchorPct,
      'stacks': stacks,
    };
  }

  // ---------------------------------------------------------
  // 🎨 UI BUILDERS
  // ---------------------------------------------------------
  Widget _buildInteractiveStreakCard(Map<String, dynamic> metrics) {
    int val = metrics['streak_daily'];
    String label = t('days');
    if (_streakTabIndex == 1) { val = metrics['streak_weekly']; label = t('wks'); }
    if (_streakTabIndex == 2) { val = metrics['streak_monthly']; label = t('mos'); }

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
              Row(children: [
                const Icon(Icons.local_fire_department, size: 18, color: Colors.amber),
                const SizedBox(width: 8),
                Text(t('streak_title'), style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400])),
              ]),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.info_outline, size: 14, color: Colors.grey),
                onPressed: () => _showInfoDialog(t('streak_title'), t('streak_desc')),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold),
              children: [
                TextSpan(text: "$val", style: const TextStyle(fontSize: 32)),
                TextSpan(text: " $label", style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTab(t('daily'), 0),
              _buildTab(t('weekly'), 1),
              _buildTab(t('monthly'), 2),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTab(String text, int index) {
    bool isActive = _streakTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _streakTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? Colors.black : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.grey)),
      ),
    );
  }

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
            Row(children: [Icon(icon, size: 18, color: iconColor), const SizedBox(width: 8), Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[400]))]),
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
  void _showSmartLogSheet(BuildContext context) {
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
                    children: _activityTags.map((tag) {
                      final isSelected = selectedTag == tag;
                      final isRest = tag.toLowerCase().contains('rest');
                      return ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        selectedColor: isRest ? Colors.green.shade100 : Colors.black,
                        labelStyle: TextStyle(color: isSelected ? (isRest ? Colors.green.shade900 : Colors.white) : Colors.black),
                        onSelected: (bool selected) {
                          setModalState(() => selectedTag = selected ? tag : "");
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
  
  Color _getVelocityColor(double v) {
    if (v > 80) { return Colors.green; }
    if (v > 50) { return Colors.orange; }
    return Colors.red;
  }
} // This closes _DashboardScreenState

// --- MINI CHART PAINTER ---
class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> logs;
  LineChartPainter({required this.logs});
  @override
  void paint(Canvas canvas, Size size) {
    if (logs.isEmpty) return;
    Paint paint = Paint()..color = Colors.blueAccent.withAlpha(128)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    var path = Path();
    double stepX = size.width / 10;
    var recentLogs = logs.take(10).toList().reversed.toList();
    if (recentLogs.isEmpty) return;
    int maxDuration = recentLogs.map((l) => l['duration'] as int).reduce(math.max);
    if (maxDuration == 0) maxDuration = 100;
    for (int i = 0; i < recentLogs.length; i++) {
      double x = i * stepX;
      double y = size.height - ((recentLogs[i]['duration'] as int) / maxDuration * size.height);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}