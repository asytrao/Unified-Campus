import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddYearSectionPage extends StatefulWidget {
  const AddYearSectionPage({super.key});

  @override
  State<AddYearSectionPage> createState() => _AddYearSectionPageState();
}

class _AddYearSectionPageState extends State<AddYearSectionPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? department;
  final _yearController = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfessorDepartment();
  }

  Future<void> fetchProfessorDepartment() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      department = doc['department'];
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching department: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveYear() async {
    final year = _yearController.text.trim();
    if (year.isEmpty || department == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a year name")));
      return;
    }
    final deptRef = _firestore.collection('departments').doc(department);
    await deptRef.set({
      'years': FieldValue.arrayUnion([year]),
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("✅ $year added for $department")));
    Navigator.pop(context); // Go back to ProfessorHomePage
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Add Year Section')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _yearController,
              decoration: const InputDecoration(
                labelText: "Enter Year (e.g. Fourth Year)",
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: saveYear,
              icon: const Icon(Icons.save),
              label: const Text("Save Year"),
            ),
          ],
        ),
      ),
    );
  }
}
