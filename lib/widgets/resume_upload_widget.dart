import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/resume_service.dart';

class ResumeUploadWidget extends StatefulWidget {
  const ResumeUploadWidget({super.key});

  @override
  State<ResumeUploadWidget> createState() => _ResumeUploadWidgetState();
}

class _ResumeUploadWidgetState extends State<ResumeUploadWidget> {
  String? currentResumeUrl;
  bool isLoading = false;
  double uploadProgress = 0.0;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentResume();
  }

  Future<void> _loadCurrentResume() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = await ResumeService.getCurrentResumeUrl();
      setState(() {
        currentResumeUrl = url;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading resume: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _uploadResume() async {
    try {
      // Pick file
      final file = await ResumeService.pickResumeFile();
      if (file == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No file selected')),
          );
        }
        return;
      }

      setState(() {
        isUploading = true;
        uploadProgress = 0.0;
      });

      // Upload file
      final downloadUrl = await ResumeService.uploadResume(
        file,
        onProgress: (progress) {
          setState(() {
            uploadProgress = progress;
          });
        },
      );

      if (downloadUrl == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload resume')),
          );
        }
        setState(() {
          isUploading = false;
        });
        return;
      }

      // Save URL to Firestore
      final success = await ResumeService.saveResumeUrl(downloadUrl);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume uploaded successfully!')),
          );
          setState(() {
            currentResumeUrl = downloadUrl;
            isUploading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save resume URL')),
          );
          setState(() {
            isUploading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error in upload process: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          isUploading = false;
        });
      }
    }
  }

  Future<void> _viewResume() async {
    if (currentResumeUrl == null) return;

    try {
      final uri = Uri.parse(currentResumeUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open resume')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening resume: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening resume')),
        );
      }
    }
  }

  Future<void> _deleteResume() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Resume'),
        content: const Text('Are you sure you want to delete your resume?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      final success = await ResumeService.deleteResume();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume deleted successfully')),
          );
          setState(() {
            currentResumeUrl = null;
            isLoading = false;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete resume')),
          );
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error deleting resume: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.upload_file, color: Colors.deepPurple),
                const SizedBox(width: 8),
                const Text(
                  'Resume',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (isUploading) ...[
              const Text('Uploading resume...'),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: uploadProgress),
              const SizedBox(height: 8),
              Text('${(uploadProgress * 100).toStringAsFixed(1)}%'),
            ] else if (currentResumeUrl != null) ...[
              const Text(
                'Resume uploaded successfully!',
                style: TextStyle(color: Colors.green),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _viewResume,
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Resume'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _deleteResume,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Resume',
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'No resume uploaded yet.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadResume,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Resume (PDF)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 