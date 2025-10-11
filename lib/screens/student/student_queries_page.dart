import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudentQueriesPage extends StatefulWidget {
  final String subject;
  final String department;
  final String year;

  const StudentQueriesPage({
    super.key,
    required this.subject,
    required this.department,
    required this.year,
  });

  @override
  State<StudentQueriesPage> createState() => _StudentQueriesPageState();
}

class _StudentQueriesPageState extends State<StudentQueriesPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _queryController = TextEditingController();

  late final CollectionReference queryCollection;

  // Dark theme constants
  static const Color _primary = Color(0xFF00D4AA);
  static const Color _primaryDark = Color(0xFF00B894);
  static const Color _background = Color(0xFF0A0A0A);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _surfaceVariant = Color(0xFF2A2A2A);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFFB0B0B0);
  static const Color _textTertiary = Color(0xFF808080);
  static const Color _accentBlue = Color(0xFF4A90E2);
  static const Color _accentPurple = Color(0xFF9B59B6);
  static const Color _accentOrange = Color(0xFFE67E22);
  static const Color _accentGreen = Color(0xFF27AE60);
  static const Color _accentRed = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();

    final docId =
        "${widget.department.trim().replaceAll(' ', '')}_${widget.year.trim().replaceAll(' ', '')}";
    final subjectId = widget.subject.trim().replaceAll(' ', '');

    // Matches Firestore structure
    queryCollection = _firestore
        .collection('queries')
        .doc(docId)
        .collection('subjectList')
        .doc(subjectId)
        .collection('queries');
  }

  Future<void> postQuery() async {
    final queryText = _queryController.text.trim();
    if (queryText.isEmpty) return;

    try {
      final user = _auth.currentUser;
      final userDoc = await _firestore.collection('users').doc(user!.uid).get();
      final userData = userDoc.data() ?? {};
      final userName = userData['name'] ?? 'Student';
      final rollNumber = userData['rollNumber'];

      await queryCollection.add({
        'question': queryText, // Changed to match professor page's field
        'studentId': user.uid,
        'studentName': userName,
        'studentRollNumber': rollNumber,
        'isResolved': false,
        'solution': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _queryController.clear();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error posting query: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.subject} Queries',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                fontSize: 20,
              ),
            ),
            Text(
              '${widget.year} • ${widget.department}',
              style: const TextStyle(fontSize: 12, color: _textSecondary),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: queryCollection
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.help_outline_rounded,
                            size: 40,
                            color: _textTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No queries yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Be the first to ask a question",
                          style: TextStyle(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                final queries = snapshot.data!.docs;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, _primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(
                                    Icons.help_outline_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Student Queries",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Text(
                                        "Ask questions, get answers",
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Queries List
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Questions & Answers (${queries.length})',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...queries.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final question = data['question'] ?? '';
                        final studentName = data['studentName'] ?? 'Unknown';
                        final isResolved = data['isResolved'] ?? false;
                        final solution = data['solution'] ?? '';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: _QueryCard(
                            question: question,
                            studentName: studentName,
                            isResolved: isResolved,
                            solution: solution,
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
          ),

          // Query Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              border: Border(top: BorderSide(color: _surfaceVariant, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _surfaceVariant, width: 1),
                    ),
                    child: TextField(
                      controller: _queryController,
                      style: const TextStyle(color: _textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Type your question...",
                        hintStyle: TextStyle(color: _textTertiary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: postQuery,
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    tooltip: "Send Query",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom widget for query cards
class _QueryCard extends StatelessWidget {
  final String question;
  final String studentName;
  final bool isResolved;
  final String solution;

  const _QueryCard({
    required this.question,
    required this.studentName,
    required this.isResolved,
    required this.solution,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
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
                  color: isResolved
                      ? const Color(0xFF27AE60).withOpacity(0.2)
                      : const Color(0xFFE67E22).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isResolved
                      ? Icons.check_circle_rounded
                      : Icons.help_outline_rounded,
                  color: isResolved
                      ? const Color(0xFF27AE60)
                      : const Color(0xFFE67E22),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "by $studentName",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isResolved
                            ? const Color(0xFF27AE60).withOpacity(0.2)
                            : const Color(0xFFE67E22).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isResolved ? "Resolved" : "Pending",
                        style: TextStyle(
                          color: isResolved
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFE67E22),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF),
            ),
          ),

          if (isResolved && solution.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF27AE60).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_rounded,
                        color: const Color(0xFF27AE60),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Solution",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    solution,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0B0B0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
