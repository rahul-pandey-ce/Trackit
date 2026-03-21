import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // 🔐 SIGN UP
  Future<User> signUp(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!;
    } catch (e) {
      rethrow;
    }
  }

  // 🔐 LOGIN
  Future<User> login(String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user!;
    } catch (e) {
      rethrow;
    }
  }

  // 🧾 UPDATE USER ROLE & NAME
  Future<void> updateRole(
      String uid,
      String email,
      String role, {
        String? name,
      }) async {
    final userRef = _db.child("users/$uid");
    
    final updates = {
      "email": email,
      "role": role,
    };
    
    if (name != null) {
      updates["name"] = name;
    }
    
    await userRef.update(updates);
  }
}