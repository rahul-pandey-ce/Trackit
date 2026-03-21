import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/study_service.dart';

class StudentDashboard extends StatefulWidget {
  final String uid;

  const StudentDashboard({super.key, required this.uid});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final StudyService _studyService = StudyService();
  late DatabaseReference sessionRef;
  late DatabaseReference userRef;
  Timer? _uiTimer;

  bool running = false;
  bool isCountingDown = false;
  int countdownValue = 5;
  int startTime = 0; // millis
  int elapsedBefore = 0; // seconds
  int displaySeconds = 0;
  int dailyTargetMinutes = 30;
  Map<String, int> weeklyStats = {};
  String userName = "Focus Master";
  
  // 📊 Stats View Toggle
  String statsView = "Week"; 
  bool _processingStop = false;

  // Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color secondaryColor = Color(0xFF4ECDC4);
  static const Color bgColor = Color(0xFFF5F7FF);

  @override
  void initState() {
    super.initState();
    sessionRef = FirebaseDatabase.instance.ref("sessions/${widget.uid}");
    userRef = FirebaseDatabase.instance.ref("users/${widget.uid}");

    // Sync User Name
    userRef.child("name").onValue.listen((event) {
      if (mounted && event.snapshot.value != null) {
        setState(() => userName = event.snapshot.value.toString());
      }
    });

    // Sync Session State
    sessionRef.onValue.listen((event) {
      if (!mounted) return;
      
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      if (event.snapshot.value == null) {
        sessionRef.set({
          "isRunning": false,
          "startTime": 0,
          "elapsedBefore": 0,
          "lastDate": today,
        });
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final String lastDate = data["lastDate"] ?? "";
      
      setState(() {
        running = data["isRunning"] ?? false;
        isCountingDown = data["isCountingDown"] ?? false;
        countdownValue = data["countdownValue"] ?? 5;
        startTime = data["startTime"] ?? 0;
        
        if (lastDate != today) {
          elapsedBefore = 0;
          displaySeconds = 0;
          sessionRef.update({
            "elapsedBefore": 0,
            "lastDate": today,
            "isRunning": false,
            "startTime": 0,
          });
        } else {
          elapsedBefore = data["elapsedBefore"] ?? 0;
        }
      });
    });

    // Sync Target
    _studyService.dailyTargetStream(widget.uid).listen((target) {
      if (mounted) setState(() => dailyTargetMinutes = target);
    });

    // Sync Stats
    _studyService.getWeeklyStatsUpdates(widget.uid).listen((stats) {
      if (mounted) setState(() => weeklyStats = stats);
    });

    // UI Timer
    _uiTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      
      int currentSec;
      if (!running) {
        currentSec = 0; // Reset to 0 when not running
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        final delta = (now - startTime) ~/ 1000;
        currentSec = delta > 0 ? delta : 0; // Prevent negative display

        // Auto-Stop Check
        if (!_processingStop && (elapsedBefore + currentSec) >= dailyTargetMinutes * 60) {
          stopTimer();
        }
      }
      
      if (currentSec != displaySeconds) {
        setState(() => displaySeconds = currentSec);
      }
    });
  }

  String getMotivationalQuote() {
    final mins = displaySeconds ~/ 60;
    if (mins < 30) {
      return "Every big journey begins with small steps. Keep pushing!";
    } else if (mins < 60) {
      return "You're building momentum! Half an hour of pure focus.";
    } else if (mins < 120) {
      return "Incredible! You've crossed the one-hour mark. Stay in the zone.";
    } else if (mins < 240) {
      return "Legendary Focus! 2+ hours and still going strong.";
    } else {
      return "God-tier productivity! You are a master of your time.";
    }
  }

  void startTimer() {
    sessionRef.update({
      "isCountingDown": true,
      "countdownValue": 5,
      "isRunning": false,
    });
    
    // Local Countdown
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !isCountingDown) {
        timer.cancel();
        return;
      }
      
      if (countdownValue > 1) {
        sessionRef.update({"countdownValue": countdownValue - 1});
      } else {
        timer.cancel();
        sessionRef.update({
          "isCountingDown": false,
          "isRunning": true,
          "startTime": ServerValue.timestamp,
        });
      }
    });
  }

  void cancelCountdown() {
    sessionRef.update({
      "isCountingDown": false,
      "countdownValue": 5,
      "isRunning": false,
    });
  }

  void stopTimer() async {
    if (_processingStop) return;
    _processingStop = true;

    // Optimistic update to prevent re-entry from UI timer
    setState(() => running = false);

    final now = DateTime.now().millisecondsSinceEpoch;
    final totalSessionSeconds = (now - startTime) ~/ 1000;
    final totalTodaySeconds = elapsedBefore + totalSessionSeconds;

    await sessionRef.set({
      "isRunning": false,
      "startTime": 0,
      "elapsedBefore": totalTodaySeconds,
      "lastDate": DateFormat('yyyy-MM-dd').format(DateTime.now()),
    });

    await _studyService.saveSession(widget.uid, totalSessionSeconds, dailyTargetMinutes);

    if (!mounted) {
      _processingStop = false;
      return;
    } 
    _showFeedback(totalTodaySeconds);
    _processingStop = false;
  }

  void _showFeedback(int totalTodaySeconds) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Session Summary", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(totalTodaySeconds < dailyTargetMinutes * 60 
          ? "Good effort! You've logged some valuable study time. 📈"
          : "Amazing! You've officially crushed your goal for today. 🚀"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("DONE", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🖼️ Immersive Dashboard Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/dashboard_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 🌫️ Clear Glass Layer (Zero Blur, High Transparency)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.05),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildProfileCard(),
                  const SizedBox(height: 32),
                  _buildTimerSection(),
                  const SizedBox(height: 48),
                  _buildProgressCard(),
                  const SizedBox(height: 32),
                  _buildQuoteCard(),
                  const SizedBox(height: 32),
                  _buildStatsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Dark Glass
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Focus Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: _showTargetPicker,
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Dark Glass
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor.withOpacity(0.8), width: 2),
            ),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: primaryColor.withOpacity(0.2),
              child: const Icon(Icons.person_rounded, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Welcome back,", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _showEditNameDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.uid));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("ID Copied!"), behavior: SnackBarBehavior.floating),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key_outlined, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.uid.substring(0, 6)}...",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection() {
    final min = displaySeconds ~/ 60;
    final sec = displaySeconds % 60;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Soft Animated Background Pulse
            if (running)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 1.0, end: 1.2),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return Container(
                    width: 240 * value,
                    height: 240 * value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primaryColor.withOpacity(0.05 / value),
                    ),
                  );
                },
                onEnd: () {}, 
              ),
            
            // Main Timer Circle
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.6), // Dark Glass
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 20),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isCountingDown ? "$countdownValue" : "$min:${sec.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: isCountingDown ? 100 : 64, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.white,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    isCountingDown ? "PREPARING..." : (running ? "FOCUS ON" : "READY?"),
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        _buildFocusButton(),
      ],
    );
  }

  Widget _buildFocusButton() {
    return GestureDetector(
      onTap: isCountingDown ? cancelCountdown : (running ? stopTimer : startTimer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 72,
        width: isCountingDown ? 240 : 220,
        decoration: BoxDecoration(
          color: isCountingDown ? Colors.white : (running ? Colors.white : primaryColor),
          borderRadius: BorderRadius.circular(36),
          border: (isCountingDown || running) ? Border.all(color: Colors.redAccent.withOpacity(0.5), width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: (isCountingDown || running ? Colors.redAccent : primaryColor).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(
              isCountingDown ? Icons.close_rounded : (running ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded),
              color: isCountingDown || running ? Colors.redAccent : Colors.white,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              isCountingDown ? "CANCEL FOCUS" : (running ? "END SESSION" : "START FOCUS"),
              style: TextStyle(
                color: isCountingDown || running ? Colors.redAccent : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    double progress = (displaySeconds / (dailyTargetMinutes * 60)).clamp(0.0, 1.0);
    bool goalReached = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Dark Glass
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Progress", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (goalReached ? secondaryColor : primaryColor).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%", 
                  style: TextStyle(color: goalReached ? secondaryColor : const Color(0xFF9995FF), fontWeight: FontWeight.bold, fontSize: 13)
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 14,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(goalReached ? secondaryColor : primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.flag_rounded, size: 16, color: goalReached ? secondaryColor : primaryColor),
              const SizedBox(width: 8),
              Text(
                goalReached 
                  ? "Goal Smashed! 🌟"
                  : "${dailyTargetMinutes - (displaySeconds ~/ 60)}m more to reach goal.",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6), // Dark Glass
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Text(
            getMotivationalQuote(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
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
            const Text("Statistics", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
            _buildStatsToggle(),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6), // Dark Glass
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
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
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
              child: Text(
                view,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
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
                  child: Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700)),
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

  void _showEditNameDialog() {
    final TextEditingController nameEdit = TextEditingController(text: userName == "Focus Master" ? "" : userName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Your Name", style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameEdit,
          decoration: InputDecoration(
            hintText: "Enter your real name",
            filled: true,
            fillColor: bgColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("CANCEL", style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(
            onPressed: () async {
              if (nameEdit.text.trim().isNotEmpty) {
                await userRef.update({"name": nameEdit.text.trim()});
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("UPDATE"),
          ),
        ],
      ),
    );
  }

  void _showTargetPicker() {
    int tempTarget = dailyTargetMinutes;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Daily Focus Goal", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF2D3250))),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_rounded, color: primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Text("$tempTarget min", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryColor)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Slider(
                value: tempTarget.toDouble(),
                min: 15,
                max: 480,
                divisions: 31,
                activeColor: primaryColor,
                inactiveColor: primaryColor.withOpacity(0.1),
                onChanged: (val) => setModalState(() => tempTarget = val.toInt()),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    await _studyService.setDailyTarget(widget.uid, tempTarget);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                  child: const Text("CONFIRM GOAL", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
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
