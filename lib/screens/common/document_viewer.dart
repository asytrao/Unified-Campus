import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentViewer extends StatefulWidget {
  final String documentUrl;
  final String documentName;
  final String documentType; // 'pdf', 'image', 'other'

  const DocumentViewer({
    super.key,
    required this.documentUrl,
    required this.documentName,
    required this.documentType,
  });

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _checkDocumentType();
  }

  void _checkDocumentType() {
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _openExternally() async {
    try {
      final uri = Uri.parse(widget.documentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showError('Cannot open document externally');
      }
    } catch (e) {
      _showError('Error opening document: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      errorMessage = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.network(
      widget.documentUrl,
      onDocumentLoadFailed: (details) {
        setState(() {
          errorMessage = 'Failed to load PDF. The file may be protected or require authentication.';
        });
      },
    );
  }

  Widget _buildImageViewer() {
    return InteractiveViewer(
      panEnabled: true,
      boundaryMargin: const EdgeInsets.all(20),
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.documentUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load image',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _openExternally,
                    child: const Text('Open Externally'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnsupportedViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.description,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Preview not available',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'File type: ${widget.documentType.toUpperCase()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open Externally'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.documentName,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: _openExternally,
            icon: const Icon(Icons.open_in_new),
            tooltip: 'Open externally',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _openExternally,
                        child: const Text('Open Externally'),
                      ),
                    ],
                  ),
                )
              : _buildDocumentContent(),
    );
  }

  Widget _buildDocumentContent() {
    switch (widget.documentType.toLowerCase()) {
      case 'pdf':
        return _buildPdfViewer();
      case 'image':
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return _buildImageViewer();
      default:
        return _buildUnsupportedViewer();
    }
  }
}

// Helper function to determine document type from URL or filename
String getDocumentType(String url) {
  final uri = Uri.parse(url);
  final path = uri.path.toLowerCase();
  
  if (path.endsWith('.pdf')) {
    return 'pdf';
  } else if (path.endsWith('.jpg') || 
             path.endsWith('.jpeg') || 
             path.endsWith('.png') || 
             path.endsWith('.gif') || 
             path.endsWith('.webp')) {
    return 'image';
  } else if (path.endsWith('.doc') || path.endsWith('.docx')) {
    return 'document';
  } else if (path.endsWith('.xls') || path.endsWith('.xlsx')) {
    return 'spreadsheet';
  } else if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
    return 'presentation';
  } else {
    return 'other';
  }
}