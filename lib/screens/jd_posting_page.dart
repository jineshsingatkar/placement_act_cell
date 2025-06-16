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
  bool _isSubmitting = false;

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
        const SnackBar(
          content: Text('Please select at least one required skill'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
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
          const SnackBar(
            content: Text('Company profile not found'),
            backgroundColor: Colors.red,
          ),
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

      // Navigate back
      Navigator.pop(context);

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
          _isSubmitting = false;
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Post Job Description'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.post_add,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Job Posting',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fill in the details below to create a new job posting',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information Section
                    _buildSectionHeader(
                      icon: Icons.info,
                      title: 'Basic Information',
                      subtitle: 'Essential job details',
                    ),
                    const SizedBox(height: 16),

                    // Job Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'Job Title',
                      hint: 'e.g., Flutter Developer, Software Engineer',
                      icon: Icons.work,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Job title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Job Type and Experience Level Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedJobType,
                            label: 'Job Type',
                            icon: Icons.schedule,
                            items: _jobTypes,
                            onChanged: (value) {
                              setState(() {
                                _selectedJobType = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDropdown(
                            value: _selectedExperienceLevel,
                            label: 'Experience Level',
                            icon: Icons.trending_up,
                            items: _experienceLevels,
                            onChanged: (value) {
                              setState(() {
                                _selectedExperienceLevel = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Location and Salary Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _locationController,
                            label: 'Location',
                            hint: 'e.g., Remote, New York, NY',
                            icon: Icons.location_on,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Location is required';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            controller: _salaryController,
                            label: 'Salary Range',
                            hint: 'e.g., $50,000 - $80,000',
                            icon: Icons.attach_money,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Salary range is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Number of Positions
                    _buildTextField(
                      controller: _positionsController,
                      label: 'Number of Positions',
                      hint: 'e.g., 2',
                      icon: Icons.people,
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
                    const SizedBox(height: 24),

                    // Job Description Section
                    _buildSectionHeader(
                      icon: Icons.description,
                      title: 'Job Description',
                      subtitle: 'Detailed role information',
                    ),
                    const SizedBox(height: 16),

                    _buildTextArea(
                      controller: _descriptionController,
                      label: 'Job Description',
                      hint: 'Provide a detailed description of the role, responsibilities, and what the candidate will be doing...',
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

                    _buildTextArea(
                      controller: _requirementsController,
                      label: 'Requirements & Qualifications',
                      hint: 'List the required qualifications, experience, and skills...',
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requirements are required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Required Skills Section
                    _buildSectionHeader(
                      icon: Icons.checklist,
                      title: 'Required Skills',
                      subtitle: 'Select skills required for this position',
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                                backgroundColor: Colors.grey.shade100,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              );
                            }).toList(),
                          ),
                          if (_selectedSkills.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Selected: ${_selectedSkills.join(', ')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitJobPosting,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isSubmitting
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
                                  Text(
                                    'Creating Job Posting...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                            : const Text(
                                'Create Job Posting',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.deepPurple, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          alignLabelWithHint: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}
