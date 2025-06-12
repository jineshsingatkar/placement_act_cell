import 'package:flutter/material.dart';

class StudentProfileCompletionPage extends StatefulWidget {
  const StudentProfileCompletionPage({super.key});

  @override
  State<StudentProfileCompletionPage> createState() =>
      _StudentProfileCompletionPageState();
}

class _StudentProfileCompletionPageState
    extends State<StudentProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();

  String fullName = '';
  String rollNo = '';
  String branch = '';
  double cgpa = 0.0;
  int backlogs = 0;
  String phone = '';

  final List<String> branches = [
    'CSE',
    'IT',
    'ECE',
    'ME',
    'CE',
    'EEE',
    'Other'
  ];

  void handleSubmit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile submitted for TPO verification")),
      );

      // TODO: Store in Firestore + navigate to waiting screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                onChanged: (val) => fullName = val,
                validator: (val) =>
                val != null && val.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration:
                const InputDecoration(labelText: 'College Roll Number'),
                onChanged: (val) => rollNo = val,
                validator: (val) =>
                val != null && val.isNotEmpty ? null : 'Required',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Branch'),
                value: branch.isNotEmpty ? branch : null,
                items: branches
                    .map((b) =>
                    DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (val) => setState(() => branch = val ?? ''),
                validator: (val) =>
                val == null || val.isEmpty ? 'Select a branch' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CGPA'),
                keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
                onChanged: (val) => cgpa = double.tryParse(val) ?? 0.0,
                validator: (val) => val != null &&
                    double.tryParse(val) != null &&
                    double.tryParse(val)! >= 0 &&
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
                child: const Text("Submit Profile"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
