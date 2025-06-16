import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentProfileViewerPage extends StatefulWidget {
  const StudentProfileViewerPage({super.key});

  @override
  State<StudentProfileViewerPage> createState() => _StudentProfileViewerPageState();
}

class _StudentProfileViewerPageState extends State<StudentProfileViewerPage> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchStudentProfile();
  }

  Future<void> fetchStudentProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'User not authenticated.';
          isLoading = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance.collection('students').doc(user.uid).get();
      if (!doc.exists) {
        setState(() {
          errorMessage = 'Profile not found.';
          isLoading = false;
        });
        return;
      }
      setState(() {
        studentData = doc.data();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching student profile: $e');
      setState(() {
        errorMessage = 'Failed to load profile.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : studentData == null
                  ? const Center(child: Text('No profile data found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _ProfileCard(
                          title: 'Full Name',
                          value: studentData!['fullName'] ?? '-',
                        ),
                        _ProfileCard(
                          title: 'Roll Number',
                          value: studentData!['rollNo'] ?? '-',
                        ),
                        _ProfileCard(
                          title: 'Branch',
                          value: studentData!['branch'] ?? '-',
                        ),
                        _ProfileCard(
                          title: 'CGPA',
                          value: studentData!['cgpa']?.toString() ?? '-',
                        ),
                        _ProfileCard(
                          title: 'Backlogs',
                          value: studentData!['backlogs']?.toString() ?? '-',
                        ),
                        _ProfileCard(
                          title: 'Phone',
                          value: studentData!['phone'] ?? '-',
                        ),
                        _ProfileCard(
                          title: 'Status',
                          value: studentData!['status'] ?? '-',
                        ),
                        if (studentData!['resumeUrl'] != null)
                          Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: const Text('Resume'),
                              subtitle: Text(studentData!['resumeUrl']),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () {
                                  // Optionally implement resume viewing
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final String title;
  final String value;
  const _ProfileCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
} 