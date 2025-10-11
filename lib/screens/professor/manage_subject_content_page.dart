import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../common/document_viewer.dart';

class ManageSubjectContentPage extends StatefulWidget {
  final String subject;
  final String year;
  final String department;

  const ManageSubjectContentPage({
    super.key,
    required this.subject,
    required this.year,
    required this.department,
  });

  @override
  State<ManageSubjectContentPage> createState() =>
      _ManageSubjectContentPageState();
}

class _ManageSubjectContentPageState extends State<ManageSubjectContentPage> {
  final _firestore = FirebaseFirestore.instance;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;
  String selectedType = "Assignment";
  String selectedFilter = "All";
  String _searchQuery = '';

  late final DocumentReference subjectDoc;
  late final String docId;
  late final String subjectId;

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
    docId =
        "${widget.department.trim().replaceAll(' ', '')}_${widget.year.trim().replaceAll(' ', '')}";
    subjectId = widget.subject.trim().replaceAll(' ', '');

    subjectDoc = _firestore
        .collection('subjects')
        .doc(docId)
        .collection('subjectList')
        .doc(subjectId);

    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> addContent() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();

    try {
      setState(() => _isAdding = true);

      await subjectDoc.set({
        'name': widget.subject,
        'year': widget.year,
        'department': widget.department,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await subjectDoc.collection('content').add({
        'title': title,
        'description': desc,
        'type': selectedType,
        'createdAt': FieldValue.serverTimestamp(),
        'subjectId': subjectId,
        'docId': docId,
      });

      _titleController.clear();
      _descController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Content added successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error adding content: $e")));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _confirmDelete(DocumentReference ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete content?'),
          content: const Text('This action cannot be undone.'),
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

    if (shouldDelete == true) {
      await ref.delete();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('🗑️ Deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.subject} Content',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            Text(
              '${widget.year} • ${widget.department}',
              style: TextStyle(
                fontSize: 12,
                color: _textDark.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search content by title or description',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: _surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in [
                        'All',
                        'Assignment',
                        'Practical',
                        'Notes',
                        'Project',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: selectedFilter == filter,
                            onSelected: (_) =>
                                setState(() => selectedFilter = filter),
                            backgroundColor: _surface,
                            selectedColor: _primary.withOpacity(0.2),
                            checkmarkColor: _primary,
                            labelStyle: TextStyle(
                              color: selectedFilter == filter
                                  ? _primary
                                  : _textDark,
                              fontWeight: selectedFilter == filter
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Add content form
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
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
                        'Create New Content',
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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Title is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Description is required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Content Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textDark.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final type in const [
                        'Assignment',
                        'Practical',
                        'Notes',
                        'Project',
                      ])
                        ChoiceChip(
                          label: Text(type),
                          selected: selectedType == type,
                          onSelected: (_) =>
                              setState(() => selectedType = type),
                          backgroundColor: _surface,
                          selectedColor: _primary.withOpacity(0.2),
                          checkmarkColor: _primary,
                          labelStyle: TextStyle(
                            color: selectedType == type ? _primary : _textDark,
                            fontWeight: selectedType == type
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isAdding
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: Text(_isAdding ? "Adding..." : "Add Content"),
                      onPressed: _isAdding ? null : addContent,
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

          // Content list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: subjectDoc
                  .collection('content')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: _textDark.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No content added yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: _textDark.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create your first content above",
                          style: TextStyle(
                            fontSize: 14,
                            color: _textDark.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs;

                // Apply client-side filters
                if (selectedFilter != 'All') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['type'] ?? '') == selectedFilter;
                  }).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title = (data['title'] ?? '')
                        .toString()
                        .toLowerCase();
                    final desc = (data['description'] ?? '')
                        .toString()
                        .toLowerCase();
                    return title.contains(_searchQuery) ||
                        desc.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: _textDark.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No matching content',
                          style: TextStyle(
                            fontSize: 16,
                            color: _textDark.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: TextStyle(
                            fontSize: 14,
                            color: _textDark.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final contentId = docs[index].id;
                    final type = (data['type'] ?? '').toString();
                    final title = (data['title'] ?? '').toString();
                    final description = (data['description'] ?? '').toString();

                    Color badgeColor;
                    switch (type) {
                      case 'Assignment':
                        badgeColor = Colors.blue;
                        break;
                      case 'Practical':
                        badgeColor = Colors.green;
                        break;
                      case 'Notes':
                        badgeColor = Colors.orange;
                        break;
                      case 'Project':
                        badgeColor = Colors.purple;
                        break;
                      default:
                        badgeColor = Colors.grey;
                    }

                    return _ContentTile(
                      title: title,
                      description: description,
                      type: type,
                      badgeColor: badgeColor,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContentSubmissionStatusPage(
                              department: widget.department,
                              year: widget.year,
                              subjectId: subjectId,
                              docId: docId,
                              contentId: contentId,
                              contentTitle: title,
                            ),
                          ),
                        );
                      },
                      onDelete: () => _confirmDelete(docs[index].reference),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ContentTile extends StatelessWidget {
  final String title;
  final String description;
  final String type;
  final Color badgeColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;

  const _ContentTile({
    required this.title,
    required this.description,
    required this.type,
    required this.badgeColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 6,
              height: 80,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getIconForType(type), color: badgeColor),
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
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: _textDark.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: onDelete,
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Assignment':
        return Icons.assignment;
      case 'Practical':
        return Icons.science;
      case 'Notes':
        return Icons.note;
      case 'Project':
        return Icons.work;
      default:
        return Icons.menu_book;
    }
  }
}

class ContentSubmissionStatusPage extends StatelessWidget {
  final String department;
  final String year;
  final String subjectId;
  final String docId;
  final String contentId;
  final String contentTitle;

  const ContentSubmissionStatusPage({
    super.key,
    required this.department,
    required this.year,
    required this.subjectId,
    required this.docId,
    required this.contentId,
    required this.contentTitle,
  });

  // Design constants
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);
  static const Color _accentBlue = Color(0xFFD6EBFB);
  static const Color _accentGreen = Color(0xFFCFF3E6);
  static const Color _accentOrange = Color(0xFFFBE3C8);

  void _openFile(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ No file URL available")),
      );
      return;
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DocumentViewer(
            documentUrl: url,
            documentName: 'Student Submission',
            documentType: _getDocumentType(url),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error opening file: $e")),
      );
    }
  }

  String _getDocumentType(String url) {
    return getDocumentType(url);
  }

  @override
  Widget build(BuildContext context) {
    final studentsRef = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('department', isEqualTo: department)
        .where('year', isEqualTo: year);

    final submissionsRef = FirebaseFirestore.instance
        .collection('subjects')
        .doc(docId)
        .collection('subjectList')
        .doc(subjectId)
        .collection('content')
        .doc(contentId)
        .collection('submissions');

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Submissions',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            Text(
              contentTitle,
              style: TextStyle(
                fontSize: 12,
                color: _textDark.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: studentsRef.snapshots(),
        builder: (context, studentsSnapshot) {
          if (!studentsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final students = studentsSnapshot.data!.docs;

          return StreamBuilder<QuerySnapshot>(
            stream: submissionsRef.snapshots(),
            builder: (context, submissionsSnapshot) {
              if (!submissionsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final submissions = submissionsSnapshot.data!.docs;
              final submittedIds = submissions.map((s) => s.id).toSet();

              final submitted = students
                  .where((s) => submittedIds.contains(s.id))
                  .toList();
              final notSubmitted = students
                  .where((s) => !submittedIds.contains(s.id))
                  .toList();

              final percentage = students.isEmpty
                  ? 0
                  : ((submitted.length / students.length) * 100).round();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress card
                    Container(
                      width: double.infinity,
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
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.analytics,
                                  color: _primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Submission Progress',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: _textDark,
                                      ),
                                    ),
                                    Text(
                                      '$percentage% completed',
                                      style: TextStyle(
                                        color: _textDark.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            value: students.isEmpty
                                ? 0
                                : submitted.length / students.length,
                            backgroundColor: _accentBlue,
                            valueColor: AlwaysStoppedAnimation<Color>(_primary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Submitted: ${submitted.length}',
                                style: TextStyle(
                                  color: _textDark.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Total: ${students.length}',
                                style: TextStyle(
                                  color: _textDark.withOpacity(0.7),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Submitted students
                    if (submitted.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Submitted',
                        count: submitted.length,
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 8),
                      ...submitted.map((s) {
                        QueryDocumentSnapshot? submissionDoc;
                        try {
                          submissionDoc = submissions.firstWhere(
                            (sub) => sub.id == s.id,
                          );
                        } catch (e) {
                          submissionDoc = null;
                        }

                        final fileUrl = submissionDoc != null
                            ? (submissionDoc['fileUrl'] ?? '')
                            : '';

                        return _StudentTile(
                          name: s['name'] ?? 'Unknown',
                          hasSubmission: true,
                          fileUrl: fileUrl,
                          onViewSubmission: fileUrl.isNotEmpty
                              ? () {
                                  print(
                                    "Student ${s['name']} file URL: $fileUrl",
                                  );
                                  _openFile(context, fileUrl);
                                }
                              : null,
                        );
                      }),
                      const SizedBox(height: 16),
                    ],

                    // Not submitted students
                    if (notSubmitted.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'Not Submitted',
                        count: notSubmitted.length,
                        icon: Icons.cancel,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 8),
                      ...notSubmitted.map(
                        (s) => _StudentTile(
                          name: s['name'] ?? 'Unknown',
                          hasSubmission: false,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  static const Color _textDark = Color(0xFF2C3E50);

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
      ],
    );
  }
}

class _StudentTile extends StatelessWidget {
  final String name;
  final bool hasSubmission;
  final String? fileUrl;
  final VoidCallback? onViewSubmission;

  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;

  const _StudentTile({
    required this.name,
    required this.hasSubmission,
    this.fileUrl,
    this.onViewSubmission,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: hasSubmission
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            child: Icon(
              hasSubmission ? Icons.check : Icons.close,
              size: 16,
              color: hasSubmission ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
          ),
          if (onViewSubmission != null)
            TextButton(onPressed: onViewSubmission, child: const Text('View')),
        ],
      ),
    );
  }
}


