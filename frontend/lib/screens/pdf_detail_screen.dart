import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../models/models.dart';

class PdfDetailScreen extends StatefulWidget {
  final String id;
  const PdfDetailScreen({super.key, required this.id});

  @override
  State<PdfDetailScreen> createState() => _PdfDetailScreenState();
}

class _PdfDetailScreenState extends State<PdfDetailScreen> {
  final ApiService _apiService = ApiService();
  PdfDocument? _pdf;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final pdf = await _apiService.getPdfDetails(widget.id);
      setState(() {
        _pdf = pdf;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _viewPdf() async {
    if (_pdf == null) return;
    try {
      // In a real app, we might download to temp first or use a URL
      context.push('/view', extra: {'url': _pdf!.fileUrl, 'title': _pdf!.title});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_pdf == null) {
      return const Scaffold(body: Center(child: Text('PDF not found')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Resource Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 250,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Icon(Icons.picture_as_pdf, size: 100, color: Color(0xFFCCFF00)),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _pdf!.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'By ${_pdf!.author ?? "Unknown Author"} • ${_pdf!.year ?? "N/A"}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                _buildTag(_pdf!.categoryName ?? 'General'),
                if (_pdf!.fileSize != null) _buildTag('${(_pdf!.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB'),
              ],
            ),
            const SizedBox(height: 32),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _pdf!.description ?? 'No description available for this resource.',
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 48),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _viewPdf,
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Read Now'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFCCFF00),
                      foregroundColor: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.bookmark_border),
                    onPressed: () {
                      // Add to bookmarks
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFF69B4).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF69B4).withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFFFF69B4), fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
