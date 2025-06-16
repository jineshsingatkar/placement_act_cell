import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'student_profile_completion.dart';
import 'company_profile_completion.dart';
import 'company_dashboard.dart';

class LoginSignupPage extends StatefulWidget {
  final String role;

  const LoginSignupPage({required this.role, super.key});

  @override
  State<LoginSignupPage> createState() => _LoginSignupPageState();
}

class _LoginSignupPageState extends State<LoginSignupPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginKey = GlobalKey<FormState>();
  final _signupKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  String name = '';
  String phone = '';

  @override
  void initState() {
    super.initState();
    bool isTPO = widget.role == 'TPO';
    _tabController = TabController(length: isTPO ? 1 : 2, vsync: this);
  }

  void showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  Future<void> handleLogin() async {
    if (_loginKey.currentState!.validate()) {
      final error = await AuthService.signIn(email: email, password: password);
      if (!mounted) return;
      
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful')),
        );

        if (widget.role == 'TPO') {
          Navigator.pushReplacementNamed(context, '/tpo_dashboard');
          return;
        }

        if (widget.role == 'Student') {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final doc = await FirebaseFirestore.instance
              .collection('students')
              .doc(uid)
              .get();

          if (!mounted) return;

          final data = doc.data();

          if (data == null) {
            // Show profile completion if no record found
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StudentProfileCompletionPage(fullName: 'Unknown'),
              ),
            );
          } else {
            final status = data['status'];
            if (status == 'pending') {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Pending Approval"),
                  content: const Text("Your profile is under review by the TPO."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } else if (status == 'approved') {
              Navigator.pushReplacementNamed(context, '/student_dashboard');
            } else {
              showErrorDialog("Rejected", "Your profile was rejected by the TPO.");
            }
          }
        }

        if (widget.role == 'Company') {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          final doc = await FirebaseFirestore.instance
              .collection('companies')
              .doc(uid)
              .get();

          if (!mounted) return;

          final data = doc.data();

          if (data == null) {
            // Show profile completion if no record found
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => CompanyProfileCompletionPage(companyName: 'Unknown'),
              ),
            );
          } else {
            final status = data['status'];
            if (status == 'pending') {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Pending Approval"),
                  content: const Text("Your company profile is under review by the TPO."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } else if (status == 'approved') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompanyDashboardPage(),
                ),
              );
            } else {
              showErrorDialog("Rejected", "Your company profile was rejected by the TPO.");
            }
          }
        }
      } else {
        showErrorDialog("Login Failed", error);
      }
    }
  }

  Future<void> handleSignup() async {
    if (_signupKey.currentState!.validate()) {
      final error = await AuthService.signUp(email: email, password: password);
      if (!mounted) return;
      
      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup successful')),
        );

        if (widget.role == 'Student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => StudentProfileCompletionPage(fullName: name),
            ),
          );
        }

        if (widget.role == 'Company') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CompanyProfileCompletionPage(companyName: name),
            ),
          );
        }
      } else {
        showErrorDialog("Signup Failed", error);
      }
    }
  }

  Widget loginTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _loginKey,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (v) => email = v,
              validator: (v) =>
              v != null && v.contains('@') ? null : 'Enter valid email',
            ),
            const SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (v) => password = v,
              validator: (v) =>
              v != null && v.length >= 6 ? null : 'Min 6 characters',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: handleLogin,
              child: const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }

  Widget signupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _signupKey,
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: widget.role == 'Company' ? 'Company Name' : 'Full Name',
              ),
              onChanged: (v) => name = v,
              validator: (v) =>
              v != null && v.isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              onChanged: (v) => email = v,
              validator: (v) =>
              v != null && v.contains('@') ? null : 'Invalid email',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              onChanged: (v) => phone = v,
              validator: (v) =>
              v != null && v.length >= 10 ? null : 'Invalid phone',
            ),
            const SizedBox(height: 16),
            TextFormField(
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              onChanged: (v) => password = v,
              validator: (v) =>
              v != null && v.length >= 6 ? null : 'Min 6 characters',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: handleSignup,
              child: const Text('Signup'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTPO = widget.role == 'TPO';

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Portal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: isTPO
              ? const [Tab(text: 'Login')]
              : const [Tab(text: 'Login'), Tab(text: 'Signup')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: isTPO ? [loginTab()] : [loginTab(), signupTab()],
      ),
    );
  }
}
