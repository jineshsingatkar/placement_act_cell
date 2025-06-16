import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JDPostingPage extends StatefulWidget {
  const JDPostingPage({super.key});

  @override
  State<JDPostingPage> createState() => _JDPostingPageState();
}

class _JDPostingPageState extends State<JDPostingPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _requirementsController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _positionsController = TextEditingController();
  
  String _selectedJobType = 'Full-time';
  String _selectedExperienceLevel = 'Entry Level';
  List<String> _selectedSkills = [];
  
  bool _isLoading = false;

  final List<String> _jobTypes = ['Full-time', 'Part-time', 'Internship', 'Contract'];
  final List<String> _experienceLevels = ['Entry Level', 'Mid Level', 'Senior Level', 'Lead'];
  final List<String> _availableSkills = [
    'Flutter', 'Dart', 'React Native', 'JavaScript', 'Python', 'Java', 'C++', 'C#',
    'Node.js', 'React', 'Angular', 'Vue.js', 'HTML/CSS', 'SQL', 'MongoDB', 'Firebase',
    'AWS', 'Azure', 'Docker', 'Kubernetes', 'Git', 'REST API', 'GraphQL', 'Machine Learning',
    'Data Science', 'DevOps', 'UI/UX Design', 'Mobile Development', 'Web Development',
    'Backend Development', 'Frontend Development', 'Full Stack Development'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _requirementsController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _positionsController.dispose();
    super.dispose();
  }

  Future<void> _submitJobPosting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one required skill')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Get company data
      final companyDoc = await FirebaseFirestore.instance
          .collection('companies')
          .doc(user.uid)
          .get();

      if (!companyDoc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company profile not found')),
        );
        return;
      }

      final companyData = companyDoc.data()!;

      final jobData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'requirements': _requirementsController.text.trim(),
        'location': _locationController.text.trim(),
        'salary': _salaryController.text.trim(),
        'positions': int.tryParse(_positionsController.text.trim()) ?? 1,
        'jobType': _selectedJobType,
        'experienceLevel': _selectedExperienceLevel,
        'requiredSkills': _selectedSkills,
        'companyId': user.uid,
        'companyName': companyData['name'],
        'companyIndustry': companyData['industry'],
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'applications': 0,
      };

      await FirebaseFirestore.instance
          .collection('job_postings')
          .add(jobData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job posting created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _formKey.currentState!.reset();
      setState(() {
        _selectedSkills.clear();
        _selectedJobType = 'Full-time';
        _selectedExperienceLevel = 'Entry Level';
      });

    } catch (e) {
      debugPrint('Error creating job posting: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Job Description'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Job Posting Guidelines',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '• Provide clear and detailed job descriptions\n'
                        '• List specific requirements and qualifications\n'
                        '• Include salary range and benefits\n'
                        '• Specify the number of positions available\n'
                        '• Select relevant skills and experience level',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Job Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Job Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Job title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Job Type
              DropdownButtonFormField<String>(
                value: _selectedJobType,
                decoration: const InputDecoration(
                  labelText: 'Job Type *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.schedule),
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
              const SizedBox(height: 16),

              // Experience Level
              DropdownButtonFormField<String>(
                value: _selectedExperienceLevel,
                decoration: const InputDecoration(
                  labelText: 'Experience Level *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.trending_up),
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

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'e.g., Remote, New York, NY, Bangalore, India',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Location is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Salary
              TextFormField(
                controller: _salaryController,
                decoration: const InputDecoration(
                  labelText: 'Salary Range *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'e.g., $50,000 - $80,000 per year',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Salary range is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Number of Positions
              TextFormField(
                controller: _positionsController,
                decoration: const InputDecoration(
                  labelText: 'Number of Positions *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                  hintText: 'e.g., 2',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Number of positions is required';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Job Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Job Description *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Detailed description of the role, responsibilities, and what the candidate will be doing...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Job description is required';
                  }
                  if (value.length < 100) {
                    return 'Please provide a more detailed description (at least 100 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Requirements
              TextFormField(
                controller: _requirementsController,
                decoration: const InputDecoration(
                  labelText: 'Requirements & Qualifications *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.checklist),
                  hintText: 'List the required qualifications, experience, and skills...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Requirements are required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Required Skills
              const Text(
                'Required Skills *',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the skills required for this position:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableSkills.map((skill) {
                  final isSelected = _selectedSkills.contains(skill);
                  return FilterChip(
                    label: Text(skill),
                    selected: isSelected,
                    onSelected: (_) => _toggleSkill(skill),
                    selectedColor: Colors.deepPurple.shade100,
                    checkmarkColor: Colors.deepPurple,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              if (_selectedSkills.isNotEmpty)
                Text(
                  'Selected: ${_selectedSkills.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitJobPosting,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Job Posting...'),
                          ],
                        )
                      : const Text(
                          'Create Job Posting',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
