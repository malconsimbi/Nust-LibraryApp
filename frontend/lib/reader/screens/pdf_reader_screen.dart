import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/bookmark_panel.dart';
import '../widgets/reader_toolbar.dart';

class PdfReaderScreen extends StatefulWidget {
  final String url;
  final String title;
  final String? documentId;

  const PdfReaderScreen({
    super.key,
    required this.url,
    required this.title,
    this.documentId,
  });

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  final List<String> _bookmarks = [];
  bool _isLoading = true;

  Future<void> _addBookmark() {
    final int currentPage = _pdfViewerController.pageNumber;
    final String bookmark = 'Page $currentPage';
    
    if (!_bookmarks.contains(bookmark)) {
      setState(() {
        _bookmarks.add(bookmark);
        _bookmarks.sort((a, b) {
          final int pA = int.tryParse(a.replaceAll('Page ', '')) ?? 0;
          final int pB = int.tryParse(b.replaceAll('Page ', '')) ?? 0;
          return pA.compareTo(pB);
        });
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added bookmark for page $currentPage')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This page is already bookmarked')),
      );
    }
    return Future.value();
  }

  void _jumpToPage(int pageNumber) {
    _pdfViewerController.jumpToPage(pageNumber);
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the document.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        backgroundColor: const Color(0xFFFF3D1B),
        foregroundColor: Colors.white,
      actions: [
        ReaderToolbar(
          onDownload: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Download started...')),
          ),
          onBookmarks: () => Scaffold.of(context).openEndDrawer(),
          onAddBookmark: _addBookmark,
        ),
        IconButton(
          icon: const Icon(Symbols.open_in_new),
          tooltip: 'Open in browser',
          onPressed: _openInBrowser,
        ),
      ],
    ),
    endDrawer: BookmarkPanel(
      bookmarks: _bookmarks,
      onBookmarkTap: _jumpToPage,
    ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.url,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              setState(() {
                _isLoading = false;
              });
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              setState(() {
                _isLoading = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to load PDF: ${details.error}')),
              );
            },
          ),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFF3D1B)),
                  SizedBox(height: 16),
                  Text('Loading document...', style: TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
