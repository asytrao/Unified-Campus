import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_chat_page.dart';

class CommunitiesPage extends StatefulWidget {
  const CommunitiesPage({super.key});

  @override
  State<CommunitiesPage> createState() => _CommunitiesPageState();
}

class _CommunitiesPageState extends State<CommunitiesPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? department, year, uid;
  bool loading = true;

  // Dark theme constants (match student_home.dart)
  static const Color _primary = Color(0xFF00D4AA);
  static const Color _textDark = Color(0xFFFFFFFF);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _background = Color(0xFF0A0A0A);

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      final data = userDoc.data()!;
      uid = _auth.currentUser!.uid;
      department = data['department'];
      year = data['year'];

      // ensure class group exists
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
    if (department == null || year == null) return;

    final groupId = "${department!.trim()}_${year!.trim()}";
    final groupRef = _firestore.collection('communities').doc(groupId);

    final snapshot = await groupRef.get();
    if (!snapshot.exists) {
      // Get all professors in this department
      final professorsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'professor')
          .where('department', isEqualTo: department)
          .get();

      final admins = professorsSnapshot.docs.map((doc) => doc.id).toList();

      // Get all students in this department and year
      final studentsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'student')
          .where('department', isEqualTo: department)
          .where('year', isEqualTo: year)
          .get();

      final members = studentsSnapshot.docs.map((doc) => doc.id).toList();

      await groupRef.set({
        'name': "$department $year Class Group",
        'department': department,
        'year': year,
        'createdAt': FieldValue.serverTimestamp(),
        'isClassGroup': true,
        'members': members,
        'admins': admins,
        'description': 'Official class group for $department $year students',
      });
    } else {
      // Add current user to members if not already there
      await groupRef.update({
        'members': FieldValue.arrayUnion([uid]),
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
              style: TextStyle(color: _textDark),
              decoration: InputDecoration(
                labelText: "Community name",
                labelStyle: TextStyle(color: _textDark.withOpacity(0.7)),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              style: TextStyle(color: _textDark),
              decoration: InputDecoration(
                labelText: "Description (optional)",
                labelStyle: TextStyle(color: _textDark.withOpacity(0.7)),
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(color: _textDark.withOpacity(0.7)),
            ),
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
                });
                Navigator.pop(context);
                // Navigate directly to chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CommunityChatPage(
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
                style: TextStyle(
                  color: _textDark.withOpacity(0.7),
                  fontSize: 16,
                ),
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
              '$year • $department',
              style: TextStyle(fontSize: 12, color: _textDark.withOpacity(0.7)),
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
            .where('members', arrayContains: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_primary),
              ),
            );
          }
          final communities = snapshot.data!.docs;

          if (communities.isEmpty) {
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
                      Icons.groups_outlined,
                      size: 40,
                      color: _textDark.withOpacity(0.5),
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
                      colors: [_primary, Color(0xFF00B894)], // _primaryDark
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
                                  "Connect with classmates",
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
                      'Communities (${communities.length})',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ...communities.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final communityId = doc.id;
                  final name = data['name'] ?? "Unnamed Community";
                  final isClassGroup = data['isClassGroup'] ?? false;
                  final description = data['description'] ?? '';
                  final memberCount = (data['members'] as List?)?.length ?? 0;

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
                            builder: (_) => CommunityChatPage(
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
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A2A), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isClassGroup
                    ? const Color(0xFF4A90E2).withOpacity(0.2)
                    : const Color(0xFF9B59B6).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isClassGroup ? Icons.school_rounded : Icons.groups_rounded,
                color: isClassGroup
                    ? const Color(0xFF4A90E2)
                    : const Color(0xFF9B59B6),
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
                      color: Color(0xFFFFFFFF),
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
                              ? const Color(0xFF4A90E2).withOpacity(0.2)
                              : const Color(0xFF9B59B6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isClassGroup ? "Class Group" : "Community",
                          style: TextStyle(
                            color: isClassGroup
                                ? const Color(0xFF4A90E2)
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
                        color: const Color(0xFFB0B0B0),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$memberCount members',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFB0B0B0),
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB0B0B0),
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
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Color(0xFFB0B0B0),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
