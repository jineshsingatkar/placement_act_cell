import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'student_profile_completion.dart';
import '../services/auth_service.dart';

class LoginSignupPage extends StatefulWidget {
  final String role;
  const LoginSignupPage({required this.role, super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String name = '';
  String phone = '';
  String companyName = '';

  @override
  void initState() {
    super.initState();
    bool isTPO = widget.role == 'TPO';
    _tabController = TabController(length: isTPO ? 1 : 2, vsync: this);
  }

  void showErrorDialog(String title, String content) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
    ));
  }

  Future<void> handleLogin() async {
    if (_loginKey.currentState!.validate()) {
      final error = await AuthService.signIn(email: email, password: password);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful')));
        // TODO: Navigate to dashboard
      } else {
        showErrorDialog("Login Failed", error);
      }
    }
  }

  Future<void> handleSignup() async {
    if (_signupKey.currentState!.validate()) {
      final error = await AuthService.signUp(email: email, password: password);
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signup successful')));

        if (widget.role == 'Student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentProfileCompletionPage()),
          );
        }
      } else {
        showErrorDialog("Signup Failed", error);
      }
    }
  }

  Widget loginTab() {
    bool isTPO = widget.role == 'TPO';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _loginKey,
        child: Column(children: [
          const SizedBox(height: 20),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            onChanged: (v) => email = v,
            validator: (v) => v != null && v.contains('@') ? null : 'Email required',
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
            onChanged: (v) => password = v,
            validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: handleLogin,
            child: const Text('Login', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () async {
                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Email needed")));
                  return;
                }
                final error = await AuthService.resetPassword(email: email);
                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Reset link sent to $email")));
                } else {
                  showErrorDialog("Reset Failed", error);
                }
              },
              child: const Text("Forgot Password?"),
            ),
          ),
          if (!isTPO)
            const Text("Can't reset? Contact your TPO.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget signupTab() {
    bool isCompany = widget.role == 'Company';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _signupKey,
        child: Column(children: [
          const SizedBox(height: 20),
          if (isCompany) ...[
            TextFormField(
              decoration: const InputDecoration(labelText: 'Company Name', prefixIcon: Icon(Icons.business)),
              onChanged: (v) => companyName = v,
              validator: (v) => v != null && v.isNotEmpty ? null : '"Required',
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
            onChanged: (v) => name = v,
            validator: (v) => v != null && v.isNotEmpty ? null : 'Required',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            onChanged: (v) => email = v,
            validator: (v) => v != null && v.contains('@') ? null : 'Invalid email',
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
            keyboardType: TextInputType.phone,
            onChanged: (v) => phone = v,
            validator: (v) => v != null && v.length >= 10 ? null : 'Invalid phone',
          ),
          const SizedBox(height: 16),
          TextFormField(
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
            onChanged: (v) => password = v,
            validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: handleSignup,
            child: const Text('Signup', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isTPO = widget.role == 'TPO';
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Portal', style: GoogleFonts.poppins()),
        centerTitle: true,
        bottom: TabBar(
            controller: _tabController,
            tabs: isTPO ? const [Tab(text: 'Login')] : const [Tab(text: 'Login'), Tab(text: 'Signup')]),
      ),
      body: TabBarView(controller: _tabController,
        children: isTPO ? [loginTab()] : [loginTab(), signupTab()],
      ),
    );
  }
}
