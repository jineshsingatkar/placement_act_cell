import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class ResumeService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Pick a PDF file from device
  static Future<File?> pickResumeFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        debugPrint('File picked: ${file.path}');
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking file: $e');
      return null;
    }
  }

  /// Upload resume to Firebase Storage
  static Future<String?> uploadResume(
    File file, {
    required Function(double) onProgress,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return null;
      }

      final fileName = 'resumes/${user.uid}.pdf';
      final ref = _storage.ref().child(fileName);

      // Upload file with progress tracking
      final uploadTask = ref.putFile(file);
      
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Resume uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading resume: $e');
      return null;
    }
  }

  /// Save resume URL to Firestore
  static Future<bool> saveResumeUrl(String downloadUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return false;
      }

      await _firestore
          .collection('students')
          .doc(user.uid)
          .update({'resumeUrl': downloadUrl});
      
      debugPrint('Resume URL saved to Firestore');
      return true;
    } catch (e) {
      debugPrint('Error saving resume URL: $e');
      return false;
    }
  }

  /// Get current resume URL from Firestore
  static Future<String?> getCurrentResumeUrl() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return null;
      }

      final doc = await _firestore
          .collection('students')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        return data?['resumeUrl'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting resume URL: $e');
      return null;
    }
  }

  /// Delete resume from Storage and Firestore
  static Future<bool> deleteResume() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return false;
      }

      // Delete from Storage
      final fileName = 'resumes/${user.uid}.pdf';
      final ref = _storage.ref().child(fileName);
      await ref.delete();

      // Remove URL from Firestore
      await _firestore
          .collection('students')
          .doc(user.uid)
          .update({'resumeUrl': FieldValue.delete()});

      debugPrint('Resume deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting resume: $e');
      return false;
    }
  }
} 