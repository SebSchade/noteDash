//document previews

import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../documents/documents.dart';

class DocumentBox extends StatelessWidget {
  final Document doc;
  final Function(Color) onStarPressed;
  final Function(Document) onDocumentPressed;
  final String searchQuery;
  DocumentBox({
    required this.doc,
    required this.onStarPressed,
    required this.onDocumentPressed,
    required this.searchQuery,
  });

List<TextSpan> _highlightedPreviewText() { // for highlighting during search function
  // find the first occurrence of the search query
  final int queryIndex = doc.text.toLowerCase().indexOf(searchQuery.toLowerCase());
  if (queryIndex == -1) {
    // if the search query isn't found, default to the start of the document
    return _highlightMatches(doc.text.substring(0, math.min(240, doc.text.length)), searchQuery);
  } else {
    // calculate start and end indices to center the preview around the search query
    int start = queryIndex - 120;
    if (start < 0) start = 0;
    int end = start + 240;
    if (end > doc.text.length) {
      end = doc.text.length;
      start = math.max(0, end - 240);
    }
    String previewText = doc.text.substring(start, end);
    // add ellipses if the preview is cut from the middle
    if (start > 0) previewText = '...$previewText';
    if (end < doc.text.length) previewText += '...';
    return _highlightMatches(previewText, searchQuery);
  }
}
  // method to generate TextSpans for highlighting matches
  List<TextSpan> _highlightMatches(String text, String searchQuery) {
    if (searchQuery.isEmpty) {
      return [TextSpan(text: text)];
    }
    final List<TextSpan> spans = [];
    final String lowerCaseText = text.toLowerCase();
    final String lowerCaseQuery = searchQuery.toLowerCase();
    int start = 0;
    int indexOfHighlight;
    while ((indexOfHighlight = lowerCaseText.indexOf(lowerCaseQuery, start)) != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + searchQuery.length),
        style: TextStyle(backgroundColor: Colors.yellow),
      ));
      start = indexOfHighlight + searchQuery.length;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }
    return spans;
  }
  @override
  Widget build(BuildContext context) { // build method for: DOCUMENT PREVIEWS ON HOME PAGE
    return GestureDetector(
      onTap: () => onDocumentPressed(doc),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: doc.isStarred ? Color(0xFFfaca74) : doc.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.title.length > 100 ? '${doc.title.substring(0, 100)}...' : doc.title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: _highlightedPreviewText(),
                style: TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => onStarPressed(doc.backgroundColor),
                  icon: Icon(doc.isStarred ? Icons.star : Icons.star_border),
                  color: Color.fromARGB(255, 34, 34, 34),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}