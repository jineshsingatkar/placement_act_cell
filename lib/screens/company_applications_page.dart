import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class CompanyApplicationsPage extends StatefulWidget {
  const CompanyApplicationsPage({super.key});

  @override
  State<CompanyApplicationsPage> createState() => _CompanyApplicationsPageState();
}

class _CompanyApplicationsPageState extends State<CompanyApplicationsPage> {
  String _selectedJobId = 'all';
  List<Map<String, dynamic>> _jobPostings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadJobPostings();
  }

  Future<void> _loadJobPostings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('job_postings')
          .where('companyId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _jobPostings = querySnapshot.docs
              .map((doc) => {
                    'id': doc.id,
                    ...doc.data(),
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading job postings: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateApplicationStatus(
    String applicationId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('applications')
          .doc(applicationId)
          .update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Application $status successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error updating application status: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Applications'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Job Filter
                if (_jobPostings.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter by Job Posting',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _selectedJobId,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'all',
                                  child: Text('All Job Postings'),
                                ),
                                ..._jobPostings.map((job) {
                                  return DropdownMenuItem(
                                    value: job['id'],
                                    child: Text(
                                      job['title'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedJobId = value!;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Applications List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _buildApplicationsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}'),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final applications = snapshot.data?.docs ?? [];

                      if (applications.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No applications found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Students will appear here once they apply to your job postings',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final application = applications[index].data() as Map<String, dynamic>;
                          final applicationId = applications[index].id;
                          
                          return _buildApplicationCard(application, applicationId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Stream<QuerySnapshot> _buildApplicationsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.empty();
    }

    Query query = FirebaseFirestore.instance
        .collection('applications')
        .where('companyId', isEqualTo: user.uid);

    if (_selectedJobId != 'all') {
      query = query.where('jobId', isEqualTo: _selectedJobId);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildApplicationCard(Map<String, dynamic> application, String applicationId) {
    final studentData = application['studentData'] as Map<String, dynamic>? ?? {};
    final jobData = application['jobData'] as Map<String, dynamic>? ?? {};
    final status = application['status'] as String? ?? 'pending';
    final appliedAt = application['createdAt'] as Timestamp?;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    (studentData['fullName'] as String? ?? 'S')
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        studentData['fullName'] ?? 'Unknown Student',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        jobData['title'] ?? 'Unknown Position',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(status),
              ],
            ),
            const SizedBox(height: 16),

            // Student Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.school,
                    label: 'Branch',
                    value: studentData['branch'] ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.grade,
                    label: 'CGPA',
                    value: studentData['cgpa']?.toString() ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.warning,
                    label: 'Backlogs',
                    value: studentData['backlogs']?.toString() ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Skills Match
            if (jobData['requiredSkills'] != null) ...[
              const Text(
                'Skills Match:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (jobData['requiredSkills'] as List<dynamic>).map((skill) {
                  final hasSkill = (studentData['skills'] as List<dynamic>? ?? [])
                      .contains(skill);
                  return Chip(
                    label: Text(
                      skill,
                      style: TextStyle(
                        fontSize: 12,
                        color: hasSkill ? Colors.white : Colors.grey,
                      ),
                    ),
                    backgroundColor: hasSkill ? Colors.green : Colors.grey.shade200,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Applied Date
            Text(
              'Applied: ${_formatDate(appliedAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                // View Resume
                if (studentData['resumeUrl'] != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _viewResume(studentData['resumeUrl']),
                      icon: const Icon(Icons.description),
                      label: const Text('View Resume'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                      ),
                    ),
                  ),
                if (studentData['resumeUrl'] != null) const SizedBox(width: 8),

                // Status Actions
                if (status == 'pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateApplicationStatus(
                        applicationId,
                        'shortlisted',
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Shortlist'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateApplicationStatus(
                        applicationId,
                        'rejected',
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (status == 'shortlisted') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateApplicationStatus(
                        applicationId,
                        'selected',
                      ),
                      icon: const Icon(Icons.star),
                      label: const Text('Select'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _updateApplicationStatus(
                        applicationId,
                        'rejected',
                      ),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Text(
                      'Status: ${status.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.schedule;
        break;
      case 'shortlisted':
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case 'selected':
        color = Colors.green;
        icon = Icons.star;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.close;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: color,
      avatar: Icon(icon, size: 16, color: Colors.white),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _viewResume(String resumeUrl) async {
    try {
      final uri = Uri.parse(resumeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open resume')),
        );
      }
    } catch (e) {
      debugPrint('Error opening resume: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening resume')),
      );
    }
  }
}
