import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../screens/student_dashboard.dart';
import '../screens/viewer_search_screen.dart';

Future<void> routeByRole(
    BuildContext context,
    String uid,
    ) async {
  final roleRef =
  FirebaseDatabase.instance.ref("users/$uid/role");

  final snap = await roleRef.get();
  
  // 🔥 LINT FIX: Check if context is still mounted after await
  if (!context.mounted) return;

  final role = snap.exists ? snap.value.toString() : "student";

  if (role == "viewer") {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ViewerSearchScreen(),
      ),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StudentDashboard(uid: uid),
      ),
    );
  }
}