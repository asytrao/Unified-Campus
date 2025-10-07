import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/document_viewer.dart';

class ViewDocumentsPage extends StatefulWidget {
  const ViewDocumentsPage({super.key});

  @override
  State<ViewDocumentsPage> createState() => _ViewDocumentsPageState();
}

class _ViewDocumentsPageState extends State<ViewDocumentsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedFilter = 'all'; // all, approved, pending, rejected
  
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Documents'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Documents')),
              const PopupMenuItem(value: 'approved', child: Text('Approved')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'rejected', child: Text('Rejected')),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getFilterLabel(_selectedFilter),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getDocumentsStream(),
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
                    Icons.description_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Documents will appear here once uploaded',
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
                onView: () => _viewDocument(data),
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getDocumentsStream() {
    Query query = _firestore.collection('documents');
    
    if (_selectedFilter != 'all') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }
    
    return query.orderBy('uploadedAt', descending: true).snapshots();
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'all':
        return 'All';
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'All';
    }
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
}

class _DocumentCard extends StatelessWidget {
  final String documentId;
  final Map<String, dynamic> data;
  final VoidCallback onView;

  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;

  const _DocumentCard({
    required this.documentId,
    required this.data,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Unknown Document';
    final uploaderName = data['uploaderName'] as String? ?? 'Unknown User';
    final uploadedAt = data['uploadedAt'] as Timestamp?;
    final status = data['status'] as String? ?? 'pending';
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w600,
                    ),
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility),
                label: const Text('View Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primary,
                  side: BorderSide(color: _primary),
                ),
              ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
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