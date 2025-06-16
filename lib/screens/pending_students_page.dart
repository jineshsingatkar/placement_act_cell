import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PendingStudentsPage extends StatelessWidget {
  const PendingStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Student Approvals')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No pending students.'));
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              final data = student.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  title: Text(data['fullName'] ?? 'Unnamed'),
                  subtitle: Text(
                    'Branch: ${data['branch']} • CGPA: ${data['cgpa']} • Backlogs: ${data['backlogs']}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          _updateStatus(student.id, 'approved');
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          _updateStatus(student.id, 'rejected');
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(docId)
          .update({'status': newStatus});
    } catch (e) {
      // Handle error - you might want to show a snackbar or dialog here
      // Using debugPrint instead of print for production code
      debugPrint('Error updating student status: $e');
    }
  }
}
