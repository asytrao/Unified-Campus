import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfessorCommunityChatPage extends StatefulWidget {
  final String communityId;
  final String communityName;

  const ProfessorCommunityChatPage({
    super.key,
    required this.communityId,
    required this.communityName,
  });

  @override
  State<ProfessorCommunityChatPage> createState() =>
      _ProfessorCommunityChatPageState();
}

class _ProfessorCommunityChatPageState
    extends State<ProfessorCommunityChatPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Design constants matching other professor pages
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _accentBlue = Color(0xFFD6EBFB);

  @override
  void initState() {
    super.initState();
    // Auto-scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser!;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? {};

    await _firestore
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': user.uid,
          'senderName': userData['name'] ?? 'Unknown',
          'senderRole': userData['role'] ?? 'professor',
          'createdAt': FieldValue.serverTimestamp(),
        });

    _messageController.clear();

    // Auto-scroll to bottom after sending
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = _firestore
        .collection('communities')
        .doc(widget.communityId)
        .collection('messages')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: GestureDetector(
          onTap: _showCommunityInfo,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.communityName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      "Community Chat",
                      style: TextStyle(fontSize: 12, color: _textDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showCommunityInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(_primary),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                if (messages.isEmpty) {
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
                            Icons.chat_bubble_outline_rounded,
                            size: 40,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No messages yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Start the conversation!",
                          style: TextStyle(
                            fontSize: 14,
                            color: _textDark.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // newest messages at bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final data = messages[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == _auth.currentUser!.uid;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: _MessageBubble(
                        text: data['text'] ?? "",
                        senderName: data['senderName'] ?? "Unknown",
                        senderRole: data['senderRole'] ?? 'student',
                        isMe: isMe,
                        timestamp: data['createdAt'] != null
                            ? (data['createdAt'] as Timestamp).toDate()
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message Input Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _surface,
              border: Border(
                top: BorderSide(color: _textDark.withOpacity(0.1), width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F2F5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _textDark.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: _textDark),
                      decoration: const InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: TextStyle(color: _textDark),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: sendMessage,
                    tooltip: "Send Message",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommunityInfo() {
    final communityDoc = _firestore
        .collection('communities')
        .doc(widget.communityId)
        .get();

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return FutureBuilder<DocumentSnapshot>(
              future: communityDoc,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final memberIds = List<String>.from(data['members'] ?? []);
                final adminIds = List<String>.from(data['admins'] ?? []);

                return Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: _textDark.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: _primary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.communityName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['description'] ?? "Community Chat",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: _textDark.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            _buildUserList("Admins", adminIds),
                            const SizedBox(height: 16),
                            _buildUserList("Members", memberIds),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildUserList(String title, List<String> userIds) {
    if (userIds.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$title (${userIds.length})",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 8),
        FutureBuilder<List<DocumentSnapshot>>(
          future: Future.wait(
            userIds.map((id) => _firestore.collection('users').doc(id).get()),
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final userDocs = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userDocs.length,
              itemBuilder: (context, index) {
                final doc = userDocs[index];
                final userData = doc.data() as Map<String, dynamic>? ?? {};
                final name = userData['name'] ?? 'Unknown';
                final role = userData['role'] ?? 'student';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _primary.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: _primary),
                    ),
                  ),
                  title: Text(name, style: const TextStyle(color: _textDark)),
                  subtitle: Text(
                    role,
                    style: TextStyle(color: _textDark.withOpacity(0.7)),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// Custom widget for message bubbles
class _MessageBubble extends StatelessWidget {
  final String text;
  final String senderName;
  final String senderRole;
  final bool isMe;
  final DateTime? timestamp;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _accentBlue = Color(0xFFD6EBFB);

  const _MessageBubble({
    required this.text,
    required this.senderName,
    required this.senderRole,
    required this.isMe,
    this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: senderRole == 'professor'
                  ? const Color(0xFFFBE3C8)
                  : _accentBlue,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                senderName.isNotEmpty ? senderName[0].toUpperCase() : "?",
                style: TextStyle(
                  color: senderRole == 'professor'
                      ? const Color(0xFFE67E22)
                      : _primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? _primary : _surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe) ...[
                  Row(
                    children: [
                      Text(
                        senderName,
                        style: TextStyle(
                          color: senderRole == 'professor'
                              ? const Color(0xFFE67E22)
                              : _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (senderRole == 'professor') ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBE3C8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "PROF",
                            style: TextStyle(
                              color: Color(0xFFE67E22),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : _textDark,
                    fontSize: 14,
                  ),
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(timestamp!),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : _textDark.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 8),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.person_rounded, color: _primary, size: 16),
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}
