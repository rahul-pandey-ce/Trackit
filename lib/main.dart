import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/student_dashboard.dart';
import 'screens/viewer_search_screen.dart';
import 'screens/viewer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("TrackIt: App Starting...");
  
  try {
    debugPrint("TrackIt: Initializing Firebase with options...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("TrackIt: Firebase setup complete. Running App.");
    debugPrint("TrackIt: Firebase setup complete. Running App.");
  } catch (e, stack) {
    debugPrint("TrackIt: Error during initialization: $e");
    debugPrint("TrackIt: Stack trace: $stack");
    
    // If it's a duplicate app error, we can safely ignore it and proceed
    if (!e.toString().toLowerCase().contains('duplicate') && 
        !e.toString().toLowerCase().contains('already exists')) {

        
        // Only show error screen for NON-duplicate errors
        runApp(MaterialApp(
          home: Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to initialize app',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: $e',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
        return; // Exit
    }
    }
  
  debugPrint("TrackIt: Running App (Post-Init).");
  runApp(const TrackItApp());
}

class TrackItApp extends StatelessWidget {
  const TrackItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TRACKIT',
      theme: ThemeData(
        fontFamily: 'Inter',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: const Color(0xFF6C63FF), // Soft Violet
          secondary: const Color(0xFF4ECDC4), // Mint
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF2D3250), // Deep Navy
          elevation: 0,
        ),
      ),
      // 🚀 AUTH GATE (DECLARATIVE)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          debugPrint("TrackIt: Auth State: ${snapshot.connectionState}, Data: ${snapshot.data}");
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.red)));
          }
          
          if (snapshot.hasData && snapshot.data != null) {
            return RoleBasedHome(uid: snapshot.data!.uid);
          }
          
          return const LoginScreen();
        },
      ),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'viewer') {
          final studentUid = uri.pathSegments[1];
          return MaterialPageRoute(builder: (_) => ViewerDashboard(studentUid: studentUid));
        }
        return null;
      },
    );
  }
}

class RoleBasedHome extends StatelessWidget {
  final String uid;
  const RoleBasedHome({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    // ⚡️ Use StreamBuilder for real-time role detection
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref("users/$uid/role").onValue,
      builder: (context, snapshot) {
        debugPrint("TrackIt: DB Role State: ${snapshot.connectionState}, HasData: ${snapshot.hasData}");
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.green)));
        }
        
        if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
          final role = snapshot.data!.snapshot.value.toString();
          if (role == "viewer") {
            return const ViewerSearchScreen();
          } else {
            return StudentDashboard(uid: uid);
          }
        }
        
        // If role is null (e.g. new user race condition), show loading until it appears
        debugPrint("TrackIt: Role is null or loading...");
        return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.blue)));
      },
    );
  }
}