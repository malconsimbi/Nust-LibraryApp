import 'package:flutter/material.dart';

class BookmarkPanel extends StatelessWidget {
  final List<String> bookmarks;
  final Function(int) onBookmarkTap;

  const BookmarkPanel({
    super.key, 
    required this.bookmarks,
    required this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      child: Drawer(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Saved pages', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            if (bookmarks.isEmpty) const Text('No page markers yet.'),
            ...bookmarks.asMap().entries.map((entry) {
              final item = entry.value;
              final pageNumber = int.tryParse(item.replaceAll('Page ', '')) ?? 1;
              
              return ListTile(
                title: Text(item),
                onTap: () {
                  Navigator.pop(context);
                  onBookmarkTap(pageNumber);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
