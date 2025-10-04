import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'professor_community_chat_page.dart';

class ProfessorCommunitiesPage extends StatefulWidget {
  final String year;
  final String department;

  const ProfessorCommunitiesPage({
    super.key,
    required this.year,
    required this.department,
  });

  @override
  State<ProfessorCommunitiesPage> createState() =>
      _ProfessorCommunitiesPageState();
}

class _ProfessorCommunitiesPageState extends State<ProfessorCommunitiesPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? uid;
  bool loading = true;

  // Design constants matching other professor pages
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);
  static const Color _accentBlue = Color(0xFFD6EBFB);

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      uid = _auth.currentUser!.uid;

      // Ensure class group exists
      await createClassGroupIfNotExists();

      setState(() => loading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading communities: $e")));
      setState(() => loading = false);
    }
  }

  Future<void> createClassGroupIfNotExists() async {
    final groupId = "${widget.department.trim()}_${widget.year.trim()}";
    final groupRef = _firestore.collection('communities').doc(groupId);

    final snapshot = await groupRef.get();
    if (!snapshot.exists) {
      // Get all professors in this department
      final professorsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'professor')
          .where('department', isEqualTo: widget.department)
          .get();

      final admins = professorsSnapshot.docs.map((doc) => doc.id).toList();

      // Get all students in this department and year
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('department', isEqualTo: widget.department)
          .where('year', isEqualTo: widget.year)
          .get();

      final members = studentsSnapshot.docs.map((doc) => doc.id).toList();

      await groupRef.set({
        'name': "${widget.department} ${widget.year} Class Group",
        'department': widget.department,
        'year': widget.year,
        'createdAt': FieldValue.serverTimestamp(),
        'isClassGroup': true,
        'members': members,
        'admins': admins,
        'description':
            'Official class group for ${widget.department} ${widget.year} students',
      });
    }
  }

  Future<void> createNewCommunity() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _surface,
        title: const Text(
          "Create New Community",
          style: TextStyle(color: _textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                labelText: "Community name",
                labelStyle: TextStyle(color: _textDark),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: const TextStyle(color: _textDark),
              decoration: const InputDecoration(
                labelText: "Description (optional)",
                labelStyle: TextStyle(color: _textDark),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: _textDark)),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            child: const Text("Create", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final docRef = await _firestore.collection('communities').add({
                  'name': name,
                  'description': descController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'isClassGroup': false,
                  'members': [uid],
                  'admins': [uid],
                  'createdBy': uid,
                  'department': widget.department,
                  'year': widget.year,
                });
                Navigator.pop(context);
                // Navigate directly to chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfessorCommunityChatPage(
                      communityId: docRef.id,
                      communityName: name,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: _background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading communities...',
                style: TextStyle(color: _textDark, fontSize: 16),
              ),
            ],
          ),
        ),
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
              'Communities',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _textDark,
                fontSize: 20,
              ),
            ),
            Text(
              '${widget.year} • ${widget.department}',
              style: TextStyle(fontSize: 12, color: _textDark.withOpacity(0.6)),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_rounded),
              tooltip: "Create Community",
              onPressed: createNewCommunity,
              color: Colors.white,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('communities')
            .where('department', isEqualTo: widget.department)
            .where('year', isEqualTo: widget.year)
            .where('admins', arrayContains: uid)
            .snapshots(),
        builder: (context, adminSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('communities')
                .where('department', isEqualTo: widget.department)
                .where('year', isEqualTo: widget.year)
                .where('members', arrayContains: uid)
                .snapshots(),
            builder: (context, memberSnapshot) {
              if (!adminSnapshot.hasData || !memberSnapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primary),
                  ),
                );
              }
              // Merge both lists and remove duplicates
              final adminDocs = adminSnapshot.data!.docs;
              final memberDocs = memberSnapshot.data!.docs;
              final allDocs = {
                for (var doc in [...adminDocs, ...memberDocs]) doc.id: doc,
              }.values.toList();

              if (allDocs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _accentBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.groups_outlined,
                          size: 40,
                          color: _primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No communities yet",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create your first community to get started",
                        style: TextStyle(
                          fontSize: 14,
                          color: _textDark.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: createNewCommunity,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("Create Community"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

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
                          colors: [_primary, const Color(0xFF26A69A)],
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
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Your Communities",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Text(
                                      "Connect with students",
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

                    // Communities List
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
                          'Communities (${allDocs.length})',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ...allDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final communityId = doc.id;
                      final name = data['name'] ?? "Unnamed Community";
                      final isClassGroup = data['isClassGroup'] ?? false;
                      final description = data['description'] ?? '';
                      final memberCount =
                          (data['members'] as List?)?.length ?? 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _CommunityCard(
                          name: name,
                          description: description,
                          isClassGroup: isClassGroup,
                          memberCount: memberCount,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProfessorCommunityChatPage(
                                  communityId: communityId,
                                  communityName: name,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
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

// Custom widget for community cards
class _CommunityCard extends StatelessWidget {
  final String name;
  final String description;
  final bool isClassGroup;
  final int memberCount;
  final VoidCallback onTap;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _accentBlue = Color(0xFFD6EBFB);

  const _CommunityCard({
    required this.name,
    required this.description,
    required this.isClassGroup,
    required this.memberCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isClassGroup ? _accentBlue : const Color(0xFFE8D5F2),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isClassGroup
                    ? _primary.withOpacity(0.2)
                    : const Color(0xFF9B59B6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isClassGroup ? Icons.school_rounded : Icons.groups_rounded,
                color: isClassGroup ? _primary : const Color(0xFF9B59B6),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isClassGroup
                              ? _primary.withOpacity(0.2)
                              : const Color(0xFF9B59B6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isClassGroup ? "Class Group" : "Community",
                          style: TextStyle(
                            color: isClassGroup
                                ? _primary
                                : const Color(0xFF9B59B6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.people_rounded,
                        size: 14,
                        color: _textDark.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount members',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textDark.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: _textDark.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: _textDark,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
