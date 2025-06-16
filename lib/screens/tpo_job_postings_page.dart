import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TPOJobPostingsPage extends StatefulWidget {
  const TPOJobPostingsPage({super.key});

  @override
  State<TPOJobPostingsPage> createState() => _TPOJobPostingsPageState();
}

class _TPOJobPostingsPageState extends State<TPOJobPostingsPage> {
  String _selectedStatus = 'all';
  String _selectedCompany = 'all';
  List<String> _companies = ['all'];

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .where('status', isEqualTo: 'approved')
          .get();

      final companies = <String>['all'];
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        if (data['name'] != null) {
          companies.add(data['name']);
        }
      }

      if (mounted) {
        setState(() {
          _companies = companies;
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Postings Management'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                      DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCompany,
                    decoration: const InputDecoration(
                      labelText: 'Company',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _companies.map((company) {
                      return DropdownMenuItem(
                        value: company,
                        child: Text(
                          company == 'all' ? 'All Companies' : company,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCompany = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Job Postings List
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
                          'No job postings found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Companies will appear here once they post jobs',
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
    Query query = FirebaseFirestore.instance.collection('job_postings');

    // Apply status filter
    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    // Apply company filter
    if (_selectedCompany != 'all') {
      query = query.where('companyName', isEqualTo: _selectedCompany);
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
    final positions = job['positions'] ?? 1;
    final applications = job['applications'] ?? 0;
    final status = job['status'] ?? 'pending';
    final createdAt = job['createdAt'] as Timestamp?;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'PENDING';
        statusIcon = Icons.schedule;
        break;
      case 'active':
        statusColor = Colors.green;
        statusText = 'ACTIVE';
        statusIcon = Icons.check_circle;
        break;
      case 'inactive':
        statusColor = Colors.grey;
        statusText = 'INACTIVE';
        statusIcon = Icons.pause_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'REJECTED';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'UNKNOWN';
        statusIcon = Icons.help;
    }

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
                Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: statusColor,
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
                    icon: Icons.schedule,
                    label: 'Type',
                    value: jobType,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.trending_up,
                    label: 'Experience',
                    value: experienceLevel,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.people,
                    label: 'Positions',
                    value: positions.toString(),
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.how_to_reg,
                    label: 'Applications',
                    value: applications.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
            if (status == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateJobStatus(jobId, 'active'),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateJobStatus(jobId, 'rejected'),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Reject', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'active') ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateJobStatus(jobId, 'inactive'),
                      icon: const Icon(Icons.pause, color: Colors.white),
                      label: const Text('Deactivate', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showJobDetails(job),
                      icon: const Icon(Icons.info, color: Colors.deepPurple),
                      label: const Text('View Details', style: TextStyle(color: Colors.deepPurple)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _updateJobStatus(jobId, 'active'),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: const Text('Activate', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showJobDetails(job),
                      icon: const Icon(Icons.info, color: Colors.deepPurple),
                      label: const Text('View Details', style: TextStyle(color: Colors.deepPurple)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Colors.deepPurple),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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

  Future<void> _updateJobStatus(String jobId, String newStatus) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await FirebaseFirestore.instance
          .collection('job_postings')
          .doc(jobId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job posting ${newStatus == 'active' ? 'approved' : newStatus} successfully!'),
            backgroundColor: newStatus == 'active' ? Colors.green : 
                           newStatus == 'rejected' ? Colors.red : Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating job status: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                'Industry: ${job['companyIndustry'] ?? 'Unknown'}',
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
              const SizedBox(height: 8),
              Text(
                'Job Type: ${job['jobType'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Experience Level: ${job['experienceLevel'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Positions: ${job['positions'] ?? 1}',
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
              if (job['requiredSkills'] != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Required Skills:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  children: (job['requiredSkills'] as List<dynamic>)
                      .map((skill) => Chip(
                            label: Text(skill.toString()),
                            backgroundColor: Colors.deepPurple.shade100,
                          ))
                      .toList(),
                ),
              ],
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