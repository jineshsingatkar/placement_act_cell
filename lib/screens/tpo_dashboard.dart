import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pending_students_page.dart';
import 'pending_companies_page.dart';


class TPODashboardPage extends StatelessWidget {
  const TPODashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TPO Dashboard'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const ListTile(
                title: Text(
                  'Placements Overview',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Pie chart removed temporarily due to compatibility issues.'),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                buildFeatureCard(
                  icon: Icons.pending_actions,
                  title: 'Pending Students',
                  subtitle: 'Approve student profiles',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingStudentsPage()),
                    );
                  },
                ),
                buildFeatureCard(
                  icon: Icons.business,
                  title: 'Pending Companies',
                  subtitle: 'Review company profiles',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PendingCompaniesPage()),
                    );
                  },
                ),
                buildFeatureCard(
                  icon: Icons.work,
                  title: 'Job Postings',
                  subtitle: 'Manage job descriptions',
                  onTap: () {
                    // TODO: Navigate to job postings management
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!')),
                    );
                  },
                ),
                buildFeatureCard(
                  icon: Icons.admin_panel_settings,
                  title: 'Add Another TPO',
                  subtitle: 'Create new TPO accounts',
                  onTap: () {
                    // TODO: Navigate to add TPO screen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: Colors.deepPurple),
                const SizedBox(height: 8),
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
