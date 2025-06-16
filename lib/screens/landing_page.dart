import 'package:flutter/material.dart';
import '../widgets/role_button.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key}); // ✅ Add const here if it's not already

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEEF1FF), Color(0xFFD2DAFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.school, size: 80, color: Colors.deepPurple),
                const SizedBox(height: 20),
                Text('PlacementActCell',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple)),
                const SizedBox(height: 40),
                RoleButton(role: 'Student', icon: Icons.person),
                RoleButton(role: 'TPO', icon: Icons.admin_panel_settings),
                RoleButton(role: 'Company', icon: Icons.business),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
