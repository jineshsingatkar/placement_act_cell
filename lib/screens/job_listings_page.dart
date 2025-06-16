import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JobListingsPage extends StatefulWidget {
  const JobListingsPage({super.key});

  @override
  State<JobListingsPage> createState() => _JobListingsPageState();
}

class _JobListingsPageState extends State<JobListingsPage> {
  String _selectedIndustry = 'All';
  String _selectedJobType = 'All';
  String _selectedExperienceLevel = 'All';
  List<String> _selectedSkills = [];
  
  List<String> _industries = ['All'];
  List<String> _jobTypes = ['All', 'Full-time', 'Part-time', 'Internship', 'Contract'];
  List<String> _experienceLevels = ['All', 'Entry Level', 'Mid Level', 'Senior Level', 'Lead'];
  List<String> _availableSkills = [
    'Flutter', 'Dart', 'React Native', 'JavaScript', 'Python', 'Java', 'C++', 'C#',
    'Node.js', 'React', 'Angular', 'Vue.js', 'HTML/CSS', 'SQL', 'MongoDB', 'Firebase',
    'AWS', 'Azure', 'Docker', 'Kubernetes', 'Git', 'REST API', 'GraphQL', 'Machine Learning',
    'Data Science', 'DevOps', 'UI/UX Design', 'Mobile Development', 'Web Development',
    'Backend Development', 'Frontend Development', 'Full Stack Development'
  ];

  @override
  void initState() {
    super.initState();
    _loadIndustries();
  }

  Future<void> _loadIndustries() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .where('status', isEqualTo: 'approved')
          .get();

      final industries = <String>{'All'};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['industry'] != null) {
          industries.add(data['industry']);
        }
      }

      if (mounted) {
        setState(() {
          _industries = industries.toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading industries: $e');
    }
  }

  Future<void> _applyToJob(String jobId, Map<String, dynamic> jobData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Check if already applied
      final existingApplication = await FirebaseFirestore.instance
          .collection('applications')
          .where('jobId', isEqualTo: jobId)
          .where('studentId', isEqualTo: user.uid)
          .get();

      if (existingApplication.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already applied to this job'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Get student data
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(user.uid)
          .get();

      if (!studentDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student profile not found')),
        );
        return;
      }

      final studentData = studentDoc.data()!;

      // Create application
      final applicationData = {
        'jobId': jobId,
        'studentId': user.uid,
        'companyId': jobData['companyId'],
        'studentData': studentData,
        'jobData': jobData,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('applications')
          .add(applicationData);

      // Update job posting applications count
      await FirebaseFirestore.instance
          .collection('job_postings')
          .doc(jobId)
          .update({
        'applications': FieldValue.increment(1),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Application submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error applying to job: $e');
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
        title: const Text('Job Listings'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Industry Filter
                  DropdownButtonFormField<String>(
                    value: _selectedIndustry,
                    decoration: const InputDecoration(
                      labelText: 'Industry',
                      border: OutlineInputBorder(),
                    ),
                    items: _industries.map((industry) {
                      return DropdownMenuItem(
                        value: industry,
                        child: Text(industry),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedIndustry = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Job Type Filter
                  DropdownButtonFormField<String>(
                    value: _selectedJobType,
                    decoration: const InputDecoration(
                      labelText: 'Job Type',
                      border: OutlineInputBorder(),
                    ),
                    items: _jobTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedJobType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Experience Level Filter
                  DropdownButtonFormField<String>(
                    value: _selectedExperienceLevel,
                    decoration: const InputDecoration(
                      labelText: 'Experience Level',
                      border: OutlineInputBorder(),
                    ),
                    items: _experienceLevels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedExperienceLevel = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Skills Filter
                  const Text(
                    'Required Skills:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableSkills.map((skill) {
                      final isSelected = _selectedSkills.contains(skill);
                      return FilterChip(
                        label: Text(skill),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSkills.add(skill);
                            } else {
                              _selectedSkills.remove(skill);
                            }
                          });
                        },
                        selectedColor: Colors.deepPurple.shade100,
                        checkmarkColor: Colors.deepPurple,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Job Listings
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildJobPostingsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final jobs = snapshot.data?.docs ?? [];

                if (jobs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No jobs found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or check back later',
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
                  padding: const EdgeInsets.all(16),
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    final job = jobs[index].data() as Map<String, dynamic>;
                    final jobId = jobs[index].id;
                    
                    return _buildJobCard(job, jobId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildJobPostingsStream() {
    Query query = FirebaseFirestore.instance
        .collection('job_postings')
        .where('status', isEqualTo: 'active');

    // Apply filters
    if (_selectedIndustry != 'All') {
      query = query.where('companyIndustry', isEqualTo: _selectedIndustry);
    }

    if (_selectedJobType != 'All') {
      query = query.where('jobType', isEqualTo: _selectedJobType);
    }

    if (_selectedExperienceLevel != 'All') {
      query = query.where('experienceLevel', isEqualTo: _selectedExperienceLevel);
    }

    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Widget _buildJobCard(Map<String, dynamic> job, String jobId) {
    final title = job['title'] ?? 'Unknown Position';
    final companyName = job['companyName'] ?? 'Unknown Company';
    final industry = job['companyIndustry'] ?? 'Unknown Industry';
    final location = job['location'] ?? 'Unknown Location';
    final salary = job['salary'] ?? 'Salary not specified';
    final jobType = job['jobType'] ?? 'Unknown Type';
    final experienceLevel = job['experienceLevel'] ?? 'Unknown Level';
    final description = job['description'] ?? 'No description available';
    final requirements = job['requirements'] ?? 'No requirements specified';
    final requiredSkills = job['requiredSkills'] as List<dynamic>? ?? [];
    final positions = job['positions'] ?? 1;
    final applications = job['applications'] ?? 0;
    final createdAt = job['createdAt'] as Timestamp?;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    companyName.substring(0, 1).toUpperCase(),
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
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Chip(
                      label: Text(
                        jobType,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$applications applications',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Job Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.location_on,
                    label: 'Location',
                    value: location,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.attach_money,
                    label: 'Salary',
                    value: salary,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.trending_up,
                    label: 'Experience',
                    value: experienceLevel,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Industry and Positions
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.business,
                    label: 'Industry',
                    value: industry,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.people,
                    label: 'Positions',
                    value: positions.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            const Text(
              'Job Description:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),

            // Required Skills
            if (requiredSkills.isNotEmpty) ...[
              const Text(
                'Required Skills:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: requiredSkills.map((skill) {
                  return Chip(
                    label: Text(
                      skill,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.grey.shade200,
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            // Posted Date
            Text(
              'Posted: ${_formatDate(createdAt)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showJobDetails(job),
                    icon: const Icon(Icons.info),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _applyToJob(jobId, job),
                    icon: const Icon(Icons.send),
                    label: const Text('Apply Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _showJobDetails(Map<String, dynamic> job) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(job['title'] ?? 'Job Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Company: ${job['companyName'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Location: ${job['location'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Salary: ${job['salary'] ?? 'Not specified'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(job['description'] ?? 'No description available'),
              const SizedBox(height: 16),
              const Text(
                'Requirements:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(job['requirements'] ?? 'No requirements specified'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
