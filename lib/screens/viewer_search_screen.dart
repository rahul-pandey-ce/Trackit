import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'viewer_dashboard.dart';

class ViewerSearchScreen extends StatefulWidget {
  const ViewerSearchScreen({super.key});

  @override
  State<ViewerSearchScreen> createState() => _ViewerSearchScreenState();
}

class _ViewerSearchScreenState extends State<ViewerSearchScreen> {
  final TextEditingController _uidController = TextEditingController();

  @override
  void dispose() {
    _uidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF6C63FF);
    const Color bgColor = Color(0xFFF5F7FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Track a Student", style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2D3250))),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
                  ],
                ),
                child: Icon(Icons.monitor_heart_rounded, size: 80, color: primaryColor),
              ),
              const SizedBox(height: 40),
              const Text(
                "Monitor Progress",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF2D3250)),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter the Unique ID provided by the student\nto start monitoring their focus sessions.",
                textAlign: TextAlign.center,
                style: TextStyle(color: const Color(0xFF2D3250).withOpacity(0.5), fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 48),
              Container(
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
                    TextField(
                      controller: _uidController,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3250)),
                      decoration: InputDecoration(
                        labelText: "Student UID",
                        labelStyle: TextStyle(color: const Color(0xFF2D3250).withOpacity(0.4)),
                        prefixIcon: Icon(Icons.vpn_key_rounded, color: primaryColor),
                        filled: true,
                        fillColor: bgColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: primaryColor, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
                        onPressed: () {
                          final uid = _uidController.text.trim();
                          if (uid.isNotEmpty) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ViewerDashboard(studentUid: uid)),
                            );
                          }
                        },
                        child: const Text("START MONITORING", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ),
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
}
