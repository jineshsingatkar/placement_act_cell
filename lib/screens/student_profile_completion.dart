import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentProfileCompletionPage extends StatefulWidget {
  final String fullName;

  const StudentProfileCompletionPage({required this.fullName, super.key});

  @override
  State<StudentProfileCompletionPage> createState() =>
      _StudentProfileCompletionPageState();
}

class _StudentProfileCompletionPageState
    extends State<StudentProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();

  String rollNo = '';
  String branch = '';
  double cgpa = 0.0;
  int backlogs = 0;
  String phone = '';

  final List<String> branches = [
    'CSE', 'IT', 'ECE', 'ME', 'CE', 'EEE', 'Other'
  ];

  void handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not authenticated. Please login again.")),
        );
        return;
      }

      final uid = user.uid;
      if (uid.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid user ID. Please login again.")),
        );
        return;
      }

      try {
        await FirebaseFirestore.instance.collection('students').doc(uid).set({
          'fullName': widget.fullName,
          'rollNo': rollNo,
          'branch': branch,
          'cgpa': cgpa,
          'backlogs': backlogs,
          'phone': phone,
          'status': 'pending',
        });

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile submitted for TPO verification")),
        );
      } catch (e) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error submitting profile: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(children: [
            Text("Name: ${widget.fullName}",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Roll Number'),
              onChanged: (val) => rollNo = val,
              validator: (val) => val != null && val.isNotEmpty ? null : 'Required',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Branch'),
              items: branches
                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                  .toList(),
              onChanged: (val) => branch = val ?? '',
              validator: (val) =>
              val == null || val.isEmpty ? 'Select a branch' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'CGPA'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => cgpa = double.tryParse(val) ?? 0.0,
              validator: (val) => val != null &&
                  double.tryParse(val) != null &&
                  double.tryParse(val)! <= 10
                  ? null
                  : 'Enter valid CGPA (0-10)',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Backlogs'),
              keyboardType: TextInputType.number,
              onChanged: (val) => backlogs = int.tryParse(val) ?? 0,
              validator: (val) =>
              val != null && int.tryParse(val) != null
                  ? null
                  : 'Enter valid number',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
              onChanged: (val) => phone = val,
              validator: (val) =>
              val != null && val.length == 10 ? null : 'Invalid number',
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: handleSubmit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Submit Profile"),
            ),
          ]),
        ),
      ),
    );
  }
}
