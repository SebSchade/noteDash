//context menu for new mappage document preview creation

import 'package:flutter/material.dart';

import '../documents/documents.dart';

class DocumentContextMenu extends StatefulWidget {
  final List<Document> documents;
  final Function(Document) onDocumentSelected;
  final VoidCallback onClose;
  DocumentContextMenu({
    required this.documents, 
    required this.onDocumentSelected, 
    required this.onClose,
  });
  @override
  _DocumentContextMenuState createState() => _DocumentContextMenuState();
}

class _DocumentContextMenuState extends State<DocumentContextMenu> {
  String _searchQuery = '';
  List<Document> filteredDocuments = [];
  @override
  void initState() {
    super.initState();
    filteredDocuments = widget.documents;
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      filteredDocuments = widget.documents
          .where((doc) => doc.title.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8.0),
      child: Stack(
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: 200.0, // Set a maximum width
            ),
            height: 300.0,
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: _updateSearchQuery,
                    decoration: InputDecoration(
                      labelText: 'Search',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8.0),
                      bottomRight: Radius.circular(8.0),
                    ),
                    child: ListView.builder(
                      itemCount: filteredDocuments.length,
                      itemBuilder: (context, index) {
                        Document doc = filteredDocuments[index];
                        return Container(
                          width: double.infinity, // Extend to the full width
                          decoration: BoxDecoration(
                            color: doc.backgroundColor,
                            // Remove this if you want the color to extend to the edges
                            // borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text(
                              doc.title,
                              style: TextStyle(color: Colors.black),
                            ),
                            onTap: () => widget.onDocumentSelected(doc),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 15,
            top: 15,
            child: GestureDetector(
              onTap: widget.onClose,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                padding: EdgeInsets.all(5),
                child: Icon(Icons.close, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
