import 'package:flutter/material.dart';
import 'package:placement_act_cell/screens/login_signup_page.dart';

class RoleButton extends StatelessWidget {
  final String role;
  final IconData icon;

  const RoleButton({
    super.key,
    required this.role,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoginSignupPage(role: role),
            ),
          );
        },
        icon: Icon(icon, size: 20),
        label: Text('Continue as $role', style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          elevation: 6,
          backgroundColor: Colors.white,
          foregroundColor: Colors.deepPurple,
          shadowColor: Colors.black26,
          minimumSize: const Size(250, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }
}
