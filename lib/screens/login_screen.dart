import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController name = TextEditingController();
  final AuthService auth = AuthService();

  String selectedRole = "student";
  bool isLogin = true;
  bool loading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🖼️ Relaxing Study Background
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 🌫️ Soft Frost Overlay (More Transparent)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white.withOpacity(0.15),
          ),
          Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🚀 Catchy but Soft Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 60,
                    color: Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  isLogin ? "Welcome Back" : "Join TrackIt",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3250),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isLogin ? "Sign in to continue your focus" : "Start your focus journey today",
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF2D3250).withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 48),

                // 📦 Frost Glass Form Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (!isLogin) ...[
                        _buildTextField(
                          controller: name,
                          label: "Full Name",
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),
                      ],
                      _buildTextField(
                        controller: email,
                        label: "Email Address",
                        icon: Icons.email_outlined,
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        controller: password,
                        label: "Password",
                        icon: Icons.lock_outline,
                        isPassword: true,
                      ),
                      const SizedBox(height: 24),
                      
                      // 🔘 Role Toggle Switch (Visible for Both Login & Register to Switch Context)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => selectedRole = "student"),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedRole == "student" ? const Color(0xFF6C63FF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: selectedRole == "student"
                                        ? [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Text(
                                    "Student",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedRole == "student" ? Colors.white : const Color(0xFF2D3250).withOpacity(0.5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => selectedRole = "viewer"),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: selectedRole == "viewer" ? const Color(0xFF4ECDC4) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: selectedRole == "viewer"
                                        ? [BoxShadow(color: const Color(0xFF4ECDC4).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                                        : [],
                                  ),
                                  child: Text(
                                    "Viewer",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: selectedRole == "viewer" ? Colors.white : const Color(0xFF2D3250).withOpacity(0.5),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      loading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: _handleAuth,
                                child: Text(
                                  isLogin ? "SIGN IN" : "CREATE ACCOUNT",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () => setState(() {
                    isLogin = !isLogin;
                    name.clear();
                  }),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Color(0xFF2D3250), fontSize: 15),
                      children: [
                        TextSpan(text: isLogin ? "New here? " : "Already have an account? "),
                        TextSpan(
                          text: isLogin ? "Create an account" : "Login",
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: type,
      style: const TextStyle(color: Color(0xFF2D3250), fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: const Color(0xFF2D3250).withOpacity(0.5)),
        prefixIcon: Icon(icon, color: const Color(0xFF6C63FF)),
        filled: true,
        fillColor: const Color(0xFFF9FAFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (email.text.isEmpty || password.text.isEmpty || (!isLogin && name.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => loading = true);

    try {
      if (isLogin) {
        final user = await auth.login(email.text.trim(), password.text.trim());
        // Update role on login to match the user's selection
        await auth.updateRole(
          user.uid,
          email.text.trim(),
          selectedRole,
        );
      } else {
        final user = await auth.signUp(email.text.trim(), password.text.trim());
        await auth.updateRole(
          user.uid,
          email.text.trim(),
          selectedRole,
          name: name.text.trim(),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Auth failed: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}