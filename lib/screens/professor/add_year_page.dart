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
  final _formKey = GlobalKey<FormState>();
  bool loading = true;
  bool _isSaving = false;
  List<String> customYears = [];

  // Design constants matching other professor pages
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);
  static const Color _accentBlue = Color(0xFFD6EBFB);
  static const Color _accentGreen = Color(0xFFCFF3E6);
  static const Color _accentOrange = Color(0xFFFBE3C8);

  @override
  void initState() {
    super.initState();
    fetchProfessorDepartment();
  }

  @override
  void dispose() {
    _yearController.dispose();
    super.dispose();
  }

  Future<void> fetchProfessorDepartment() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      department = doc['department'];

      // Fetch existing custom years
      await fetchCustomYears();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching department: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> fetchCustomYears() async {
    if (department == null) return;

    try {
      final deptDoc = await _firestore
          .collection('departments')
          .doc(department)
          .get();
      if (deptDoc.exists) {
        final deptData = deptDoc.data() as Map<String, dynamic>;
        setState(() {
          customYears = List<String>.from(deptData['years'] ?? []);
        });
      }
    } catch (e) {
      print("Error fetching custom years: $e");
    }
  }

  Future<void> saveYear() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final year = _yearController.text.trim();
    if (year.isEmpty || department == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a year name")));
      return;
    }

    // Check if year already exists
    if (customYears.contains(year)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ $year already exists")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final deptRef = _firestore.collection('departments').doc(department);
      await deptRef.set({
        'years': FieldValue.arrayUnion([year]),
      }, SetOptions(merge: true));

      // Refresh the custom years list
      await fetchCustomYears();

      _yearController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("✅ $year added for $department")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error adding year: $e")));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> deleteYear(String year) async {
    if (department == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete year?'),
          content: Text(
            'Are you sure you want to delete "$year"? This will also remove all subjects and content associated with this year. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("🗑️ Deleting $year...")));

      // Remove from departments collection
      final deptRef = _firestore.collection('departments').doc(department);
      await deptRef.update({
        'years': FieldValue.arrayRemove([year]),
      });

      // Delete the entire subject collection for this year
      final docId =
          "${department!.trim().replaceAll(' ', '')}_${year.trim().replaceAll(' ', '')}";
      final subjectDoc = _firestore.collection('subjects').doc(docId);

      // Delete the document and all its subcollections
      try {
        await subjectDoc.delete();
      } catch (deleteError) {
        // If subject collection doesn't exist, that's fine
        print(
          "Note: Subject collection for $year was already deleted or didn't exist: $deleteError",
        );
      }

      // Refresh the custom years list
      await fetchCustomYears();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ $year successfully deleted"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Small delay to ensure deletion is complete before going back
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (e) {
      print("Error deleting year: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error deleting year: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: _background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Year Management',
              style: TextStyle(fontWeight: FontWeight.w700, color: _textDark),
            ),
            if (department != null)
              Text(
                department!,
                style: TextStyle(
                  fontSize: 12,
                  color: _textDark.withOpacity(0.65),
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add year card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add New Year',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: "Year Name (e.g. Fourth Year)",
                        prefixIcon: Icon(Icons.school),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => (val == null || val.trim().isEmpty)
                          ? 'Year name is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : saveYear,
                        icon: _isSaving
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: Text(_isSaving ? "Adding..." : "Add Year"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Custom years list
            if (customYears.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.list_alt, color: _primary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Custom Years (${customYears.length})",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: customYears.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final year = customYears[index];
                        return _YearTile(
                          year: year,
                          onDelete: () => deleteYear(year),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Default years info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _accentBlue,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline, color: _primary),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Default Years',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'First Year, Second Year, and Third Year are default years that cannot be deleted.',
                    style: TextStyle(fontSize: 14, color: _textDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YearTile extends StatelessWidget {
  final String year;
  final VoidCallback onDelete;

  static const Color _textDark = Color(0xFF2C3E50);

  const _YearTile({required this.year, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF2EC4B6).withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.calendar_today, color: Color(0xFF2EC4B6)),
      ),
      title: Text(
        year,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        onPressed: onDelete,
        tooltip: 'Delete year',
      ),
    );
  }
}
