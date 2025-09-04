import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorQueryPage extends StatefulWidget {
  final String subject;
  final String year;
  final String department;

  const ProfessorQueryPage({
    super.key,
    required this.subject,
    required this.year,
    required this.department,
  });

  @override
  State<ProfessorQueryPage> createState() => _ProfessorQueryPageState();
}

class _ProfessorQueryPageState extends State<ProfessorQueryPage> {
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    final docId =
        "${widget.department.trim().replaceAll(' ', '')}_${widget.year.trim().replaceAll(' ', '')}";
    final queryRef = FirebaseFirestore.instance
        .collection('queries')
        .doc(docId)
        .collection('subjectList')
        .doc(widget.subject.trim().replaceAll(' ', ''))
        .collection('queries')
        .orderBy('createdAt', descending: true);

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
              'Student Queries',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            Text(
              widget.subject,
              style: TextStyle(
                fontSize: 12,
                color: _textDark.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: queryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox,
                      size: 48,
                      color: _textDark.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No queries yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Students haven\'t asked any questions for this subject yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _textDark.withOpacity(0.6)),
                    ),
                  ],
                ),
              ),
            );
          }

          final queries = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: queries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = queries[index].data() as Map<String, dynamic>;
              final docRef = queries[index].reference;

              final studentName = data['studentName'] ?? 'Unknown';
              final question = data['question'] ?? '';
              final isResolved = data['isResolved'] ?? false;
              final solution = data['solution'] ?? '';

              return _QueryCard(
                studentName: studentName,
                question: question,
                isResolved: isResolved,
                solution: solution,
                onResolve: (solutionText) async {
                  await docRef.update({
                    'solution': solutionText,
                    'isResolved': true,
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("✅ Query marked as resolved"),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _QueryCard extends StatefulWidget {
  final String studentName;
  final String question;
  final bool isResolved;
  final String solution;
  final Function(String) onResolve;

  const _QueryCard({
    required this.studentName,
    required this.question,
    required this.isResolved,
    required this.solution,
    required this.onResolve,
  });

  @override
  State<_QueryCard> createState() => _QueryCardState();
}

class _QueryCardState extends State<_QueryCard> {
  late TextEditingController _solutionController;
  bool _isExpanded = false;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _accentBlue = Color(0xFFD6EBFB);
  static const Color _accentGreen = Color(0xFFCFF3E6);

  @override
  void initState() {
    super.initState();
    _solutionController = TextEditingController(text: widget.solution);
  }

  @override
  void dispose() {
    _solutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isResolved ? _accentGreen : _accentBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isResolved
                          ? Icons.check_circle
                          : Icons.help_outline,
                      color: widget.isResolved ? Colors.green : _primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.studentName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.question,
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: _textDark.withOpacity(0.8),
                          ),
                        ),
                        if (widget.isResolved) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Resolved',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _textDark.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: widget.isResolved
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solution:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.solution.isNotEmpty
                                ? widget.solution
                                : "No solution provided",
                            style: TextStyle(color: _textDark.withOpacity(0.8)),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: _solutionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Type your solution...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final solution = _solutionController.text.trim();
                              if (solution.isNotEmpty) {
                                widget.onResolve(solution);
                                setState(() => _isExpanded = false);
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Resolve Query'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
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
