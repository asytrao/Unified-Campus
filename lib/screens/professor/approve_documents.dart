import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../common/document_viewer.dart';
import '../../services/notification_service.dart';

class ApproveDocumentsPage extends StatefulWidget {
  const ApproveDocumentsPage({super.key});

  @override
  State<ApproveDocumentsPage> createState() => _ApproveDocumentsPageState();
}

class _ApproveDocumentsPageState extends State<ApproveDocumentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Document Approval'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('documents')
            .where('status', isEqualTo: 'pending')
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending documents',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All documents have been reviewed',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              final data = doc.data() as Map<String, dynamic>;
              
              return _DocumentCard(
                documentId: doc.id,
                data: data,
                onApprove: () => _approveDocument(doc.id, data),
                onReject: () => _showRejectDialog(doc.id, data),
                onView: () => _viewDocument(data),
              );
            },
          );
        },
      ),
    );
  }

  void _viewDocument(Map<String, dynamic> data) {
    final url = data['url'] as String?;
    final name = data['name'] as String? ?? 'Document';
    
    if (url != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentViewer(
            documentUrl: url,
            documentName: name,
            documentType: getDocumentType(url),
          ),
        ),
      );
    }
  }

  Future<void> _approveDocument(String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('documents').doc(documentId).update({
        'status': 'approved',
        'approvedBy': _auth.currentUser?.uid,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to uploader
      if (data['uploadedBy'] != null) {
        await NotificationService.sendDocumentNotification(
          userId: data['uploadedBy'],
          documentId: documentId,
          action: 'approved',
          documentName: data['name'] ?? 'Document',
          professorName: _auth.currentUser?.displayName,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving document: $e')),
      );
    }
  }

  void _showRejectDialog(String documentId, Map<String, dynamic> data) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Document: ${data['name'] ?? 'Unknown'}'),
            const SizedBox(height: 16),
            const Text('Reason for rejection:'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter reason for rejection...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectDocument(documentId, data, reasonController.text);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectDocument(String documentId, Map<String, dynamic> data, String reason) async {
    try {
      await _firestore.collection('documents').doc(documentId).update({
        'status': 'rejected',
        'rejectedBy': _auth.currentUser?.uid,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason,
      });

      // Send notification to uploader
      if (data['uploadedBy'] != null) {
        await NotificationService.sendDocumentNotification(
          userId: data['uploadedBy'],
          documentId: documentId,
          action: 'rejected',
          documentName: data['name'] ?? 'Document',
          professorName: _auth.currentUser?.displayName,
          rejectionReason: reason,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document rejected'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting document: $e')),
      );
    }
  }
}

class _DocumentCard extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> data;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onView;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;

  const _DocumentCard({
    required this.documentId,
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Unknown Document';
    final uploaderName = data['uploaderName'] as String? ?? 'Unknown User';
    final uploadedAt = data['uploadedAt'] as Timestamp?;
    final subject = data['subject'] as String?;
    final year = data['year'] as String?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getFileIcon(name),
                    color: _primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Uploaded by $uploaderName',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textDark.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (subject != null || year != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (subject != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          fontSize: 12,
                          color: _primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (year != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        year,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            
            if (uploadedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Uploaded ${_formatDate(uploadedAt.toDate())}',
                style: TextStyle(
                  fontSize: 12,
                  color: _textDark.withOpacity(0.5),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primary,
                      side: BorderSide(color: _primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}