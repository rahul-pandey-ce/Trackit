import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/study_service.dart';

class ViewerDashboard extends StatefulWidget {
  final String studentUid;

  const ViewerDashboard({super.key, required this.studentUid});

  @override
  State<ViewerDashboard> createState() => _ViewerDashboardState();
}

class _ViewerDashboardState extends State<ViewerDashboard> {
  final StudyService _studyService = StudyService();
  late DatabaseReference sessionRef;
  late DatabaseReference userRef;
  Timer? _uiTimer;

  bool running = false;
  bool isCountingDown = false;
  int countdownValue = 5;
  int startTime = 0;
  int elapsedBefore = 0;
  int displaySeconds = 0;
  int dailyTargetMinutes = 30;
  Map<String, int> weeklyStats = {};
  String studentName = "Student";
  
  // 📊 Stats View Toggle
  String statsView = "Week";

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color bgColor = Color(0xFFF5F7FF);

  @override
  void initState() {
    super.initState();
    sessionRef = FirebaseDatabase.instance.ref("sessions/${widget.studentUid}");
    userRef = FirebaseDatabase.instance.ref("users/${widget.studentUid}");

    // Sync Student Name
    userRef.child("name").onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() => studentName = event.snapshot.value.toString());
      }
    });

    // Sync Session Data
    sessionRef.onValue.listen((event) {
      if (!mounted || event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        running = data["isRunning"] ?? false;
        isCountingDown = data["isCountingDown"] ?? false;
        countdownValue = data["countdownValue"] ?? 5;
        startTime = data["startTime"] ?? 0;
        elapsedBefore = data["elapsedBefore"] ?? 0;
      });
    });

    // Sync Target
    _studyService.dailyTargetStream(widget.studentUid).listen((target) {
      if (mounted) setState(() => dailyTargetMinutes = target);
    });

    // Sync Stats
    _studyService.getWeeklyStatsUpdates(widget.studentUid).listen((stats) {
      if (mounted) setState(() => weeklyStats = stats);
    });

    // 🕒 REAL-TIME UI TIMER
    _uiTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!mounted) return;
      
      int currentSec;
      if (!running) {
        currentSec = 0; // Reset to 0 when student is not running
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        final delta = (now - startTime) ~/ 1000;
        currentSec = delta > 0 ? delta : 0; // Prevent negative display
      }
      
      if (currentSec != displaySeconds) {
        setState(() => displaySeconds = currentSec);
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("$studentName's Focus", style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2D3250))),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildLiveStatusCard(),
            const SizedBox(height: 32),
            _buildLargeProgressCircle(),
            const SizedBox(height: 32),
            _buildQuickInfoRow(),
            const SizedBox(height: 48),
            _buildStatsSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: (running ? secondaryColor : Colors.grey).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isCountingDown || running ? primaryColor : Colors.grey).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCountingDown ? Icons.timer_outlined : (running ? Icons.bolt_rounded : Icons.pause_rounded),
              color: isCountingDown || running ? primaryColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCountingDown ? "PREPARING" : (running ? "WORKING HARD" : "TAKING A BREAK"),
                  style: TextStyle(
                    color: isCountingDown ? primaryColor : (running ? secondaryColor : Colors.grey),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  isCountingDown ? "$studentName is Ready" : "$studentName is ${running ? 'Active' : 'Idle'}",
                  style: const TextStyle(color: Color(0xFF2D3250), fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeProgressCircle() {
    double progress = (displaySeconds / (dailyTargetMinutes * 60)).clamp(0.0, 1.0);
    final min = displaySeconds ~/ 60;
    final sec = displaySeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 200,
                width: 200,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 16,
                  backgroundColor: bgColor,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? secondaryColor : primaryColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCountingDown ? "$countdownValue" : "$min:${sec.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: isCountingDown ? 72 : 44, 
                      fontWeight: FontWeight.w900, 
                      color: isCountingDown ? secondaryColor : primaryColor, 
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    isCountingDown ? "READY IN..." : "FOCUS TIME", 
                    style: const TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "${(progress * 100).toInt()}% of Daily Goal",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF2D3250)),
          ),
          const SizedBox(height: 4),
          Text(
            "$min / $dailyTargetMinutes Minutes",
            style: TextStyle(color: const Color(0xFF2D3250).withOpacity(0.4), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoRow() {
    return Row(
      children: [
        _buildInfoBox("Status", isCountingDown ? "PREPARING" : (running ? "ACTIVE" : "IDLE"), isCountingDown ? primaryColor : (running ? secondaryColor : Colors.grey)),
        const SizedBox(width: 16),
        _buildInfoBox("Target", "$dailyTargetMinutes Min", primaryColor),
      ],
    );
  }

  Widget _buildInfoBox(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: const Color(0xFF2D3250).withOpacity(0.4), fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Activity", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2D3250))),
            _buildStatsToggle(),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: statsView == "Month" ? _buildMonthlySummary() : _buildChart(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8),
        ],
      ),
      child: Row(
        children: ["Day", "Week", "Month"].map((view) {
          bool active = statsView == view;
          return GestureDetector(
            onTap: () => setState(() => statsView = view),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? primaryColor : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(view,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: active ? Colors.white : const Color(0xFF2D3250).withOpacity(0.4),
                  )),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChart() {
    final groups = _generateBarGroups();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxY(groups),
        barGroups: groups,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: primaryColor,
            tooltipPadding: const EdgeInsets.all(8),
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                "${rod.toY.toInt()} min",
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                String label = "";
                if (statsView == "Day") {
                  label = "Today";
                } else if (statsView == "Week") {
                  final date = DateTime.now().subtract(Duration(days: 6 - value.toInt()));
                  label = DateFormat('E').format(date).substring(0, 1);
                } else {
                  if (value % 5 == 0) label = "${value.toInt() + 1}";
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Text(label, style: TextStyle(fontSize: 11, color: const Color(0xFF2D3250).withOpacity(0.3), fontWeight: FontWeight.w700)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _getMaxY(List<BarChartGroupData> groups) {
    double max = 60;
    for (var g in groups) {
      if (g.barRods.isNotEmpty && g.barRods[0].toY > max) max = g.barRods[0].toY;
    }
    return max * 1.3;
  }

  List<BarChartGroupData> _generateBarGroups() {
    List<BarChartGroupData> groups = [];
    final now = DateTime.now();

    if (statsView == "Day") {
      final todayKey = DateFormat('yyyy-MM-dd').format(now);
      final minutes = (weeklyStats[todayKey] ?? 0) ~/ 60;
      groups.add(_createBarGroup(0, minutes.toDouble()));
    } else if (statsView == "Week") {
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: 6 - i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final minutes = (weeklyStats[dateKey] ?? 0) ~/ 60;
        groups.add(_createBarGroup(i, minutes.toDouble()));
      }
    } else {
      for (int i = 0; i < 30; i++) {
        final date = now.subtract(Duration(days: 29 - i));
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        final minutes = (weeklyStats[dateKey] ?? 0) ~/ 60;
        groups.add(_createBarGroup(i, minutes.toDouble()));
      }
    }
    return groups;
  }

  BarChartGroupData _createBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      showingTooltipIndicators: [0],
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(statsView == "Month" ? 0.8 : 0.4),
              primaryColor
            ],
          ),
          width: statsView == "Month" ? 3 : 18,
          borderRadius: statsView == "Month" 
            ? BorderRadius.circular(10) 
            : const BorderRadius.vertical(top: Radius.circular(6)),
          // Removing backDraw for stability
        )
      ],
    );
  }

  Widget _buildMonthlySummary() {
    int totalSec = 0;
    int maxSec = 0;
    String bestDay = "N/A";
    int activeDays = 0;

    final now = DateTime.now();
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(date);
      final sec = weeklyStats[key] ?? 0;
      totalSec += sec;
      if (sec > maxSec) {
        maxSec = sec;
        bestDay = DateFormat('MMM d').format(date);
      }
      if (sec > 0) activeDays++;
    }

    final totalHrs = totalSec ~/ 3600;
    final totalMins = (totalSec % 3600) ~/ 60;
    final avgMins = activeDays > 0 ? (totalSec ~/ 60) ~/ activeDays : 0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            _buildSummaryItem("Total Focus", "$totalHrs h $totalMins m", Icons.timer_outlined),
            const SizedBox(width: 12),
            _buildSummaryItem("Daily Avg", "$avgMins min", Icons.analytics_outlined),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildSummaryItem("Best Day", bestDay, Icons.star_outline_rounded),
            const SizedBox(width: 12),
            _buildSummaryItem("Active Days", "$activeDays/30", Icons.calendar_today_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 11, color: const Color(0xFF2D3250).withOpacity(0.5), fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF2D3250))),
          ],
        ),
      ),
    );
  }
}