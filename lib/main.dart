import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/landing_page.dart';
import 'screens/tpo_dashboard.dart';
import 'screens/student_dashboard_page.dart';
import 'screens/company_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PlacementActCellApp());
}

class PlacementActCellApp extends StatelessWidget {
  const PlacementActCellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlacementActCell',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/tpo_dashboard': (context) => const TPODashboardPage(),
        '/student_dashboard': (context) => const StudentDashboardPage(),
        '/company_dashboard': (context) => const CompanyDashboardPage(),
        // You can add more like:
        // '/company_dashboard': (context) => const CompanyDashboardPage(),
      },
    );
  }
}
