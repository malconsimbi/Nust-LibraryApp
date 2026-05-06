import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

class ReaderToolbar extends StatelessWidget {
  final VoidCallback onDownload;
  final VoidCallback onBookmarks;
  final VoidCallback onAddBookmark;

  const ReaderToolbar({
    super.key,
    required this.onDownload,
    required this.onBookmarks,
    required this.onAddBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onAddBookmark, 
          icon: const Icon(Symbols.bookmark_add),
          tooltip: 'Bookmark current page',
        ),
        IconButton(
          onPressed: onDownload, 
          icon: const Icon(Symbols.download),
          tooltip: 'Download PDF',
        ),
        IconButton(
          onPressed: onBookmarks, 
          icon: const Icon(Symbols.bookmarks),
          tooltip: 'View bookmarks',
        ),
      ],
    );
  }
}
