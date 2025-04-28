//mappage document previews

import 'package:flutter/material.dart';

import '../documents/documents.dart';

class DocumentPreview {
  final Document document;
  Offset position;
  final GlobalKey key;
  DocumentPreview({
    required this.document,
    required this.position,
    required this.key,
  });
}

class DocumentPreviewWidget extends StatelessWidget {
  final Document document;
  final VoidCallback onDelete;
  final bool isDeleteMode;

  DocumentPreviewWidget(this.document, {super.key, required this.onDelete, required this.isDeleteMode});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: document.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            document.title,
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
        if (isDeleteMode)
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onDelete,
              child: CircleAvatar(
                backgroundColor: Colors.red,
                radius: 12,
                child: Icon(Icons.close, size: 18, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}