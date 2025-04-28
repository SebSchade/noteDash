//full screen document page

import 'package:flutter/material.dart';
import 'dart:convert'; // for json encoding/decoding
import 'package:hive/hive.dart'; // noSQL database for document storage
import 'package:collection/collection.dart';

import '../mappage/map_previews.dart';
import 'documents.dart';
import '../mappage/line.dart';

class DocumentDetailsScreen extends StatefulWidget { // full screen document page
  final Document document;
  final List<Document> documents;
  final List<Line> lines;
  final Function(String, Color) onUpdateColor;

  DocumentDetailsScreen({required this.document, required this.documents, required this.lines, required this.onUpdateColor,});
  @override
  _DocumentDetailsScreenState createState() => _DocumentDetailsScreenState();
}

class _DocumentDetailsScreenState extends State<DocumentDetailsScreen> {
  List<Document> connectedDocuments = [];
  late TextEditingController _titleController;
  late TextEditingController _editingController;
  late Color selectedColor;
  List<DocumentPreview> documentPreviews = [];
  final List<Color> tertiaryColors = [
    Colors.amber.shade100, Colors.teal.shade100, Colors.lime.shade100,
    Colors.pink.shade100, Colors.purple.shade100, Colors.indigo.shade100,
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
    _editingController = TextEditingController(text: widget.document.text);
    selectedColor = widget.document.backgroundColor;
    _findConnectedDocuments();
  }

  void onColorUpdate(Color newColor) {
    setState(() {
      selectedColor = newColor; // update the local state with the new color
      widget.document.backgroundColor = newColor; // update the document's color
      widget.onUpdateColor(widget.document.id, newColor); // call the callback to update the MapPage
  }); 
  }
  
  void _findConnectedDocuments() { // find documents connected by lines on MapPage
    connectedDocuments = widget.lines.where((line) {
      return line.sourceId == widget.document.id || line.destinationId == widget.document.id;
    }).map((line) {
      String connectedDocumentId = line.sourceId == widget.document.id ? line.destinationId : line.sourceId;
      return widget.documents.firstWhereOrNull((doc) => doc.id == connectedDocumentId && doc.id != widget.document.id);
    }).whereType<Document>().toList();
  }
  Widget colorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tertiaryColors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = color;
              onColorUpdate(selectedColor);
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: selectedColor == color ? Colors.black : Colors.transparent, width: 2),
            ),
            width: 24,
            height: 24,
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _editingController.dispose();
    super.dispose();
  }

  void updateDocumentPreviewColor(String documentId, Color newColor) {
  setState(() {
    // find the documentPreview by documentId and update its color
    var previewToUpdate = documentPreviews.firstWhereOrNull((preview) => preview.document.id == documentId);
    if (previewToUpdate != null) {
      previewToUpdate.document.backgroundColor = newColor;
    }
  });
}

Future<void> _saveData() async {
  var prefs = await Hive.openBox('prefs');
  final String encodedData = jsonEncode(widget.documents.map((doc) => doc.toMap()).toList());
  await prefs.put('documents', encodedData);
}

  Future<bool> _onWillPop() async {
    widget.document.title = _titleController.text;
    widget.document.text = _editingController.text;
    widget.document.backgroundColor = selectedColor;
    _saveData(); // save changes universally
    Navigator.pop(context, _editingController.text);
    return false;
  }
  
Future<void> _deleteDocument() async {
  final box = await Hive.openBox('prefs');
  final String? documentsStr = box.get('documents');
  if (documentsStr != null) {
    List<Map<String, dynamic>> documentsList = List<Map<String, dynamic>>.from(jsonDecode(documentsStr));
    documentsList.removeWhere((doc) => doc['id'] == widget.document.id); // remove the document by its id
    final String updatedDocumentsStr = jsonEncode(documentsList); // serialize and save the updated documents list
    await box.put('documents', updatedDocumentsStr);
    Navigator.of(context)..pop('deleted')..pop('deleted');
  }
}

  void _confirmDeletion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Document"),
          content: Text("Are you sure you want to delete this document?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                _deleteDocument();
              },
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  _findConnectedDocuments();
  return WillPopScope(
    onWillPop: _onWillPop,
    child: Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleController,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          fontSize: 20,
          ),
          maxLength: 24,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: 'Document Title',
            counterText: '',
            suffixText: '(${24 - _titleController.text.length})',
          ),
          onChanged: (text) {
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              widget.document.title = _titleController.text;
              widget.document.text = _editingController.text;
              widget.document.backgroundColor = selectedColor;    _saveData();
              _saveData(); // save changes universally
              Navigator.pop(context, _editingController.text);
            },
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: MediaQuery.of(context).size.width,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selectedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // display connected documents as previews
                if (connectedDocuments.isNotEmpty)
                  Container(
                    height: 33,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: connectedDocuments.length,
                      itemBuilder: (context, index) {
                        Document doc = connectedDocuments[index];
                        return InkWell(
                          onTap: () { // navigate to the details screen of the tapped document
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DocumentDetailsScreen(
                                  document: doc,
                                  documents: widget.documents,
                                  lines: widget.lines,
                                  onUpdateColor: updateDocumentPreviewColor,
                                ),
                              ),
                            );
                          },
                          child: 
                          Container(
                            width: 100,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: doc.backgroundColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(5),
                              child: Text(
                                doc.title,
                                style: TextStyle(color: Colors.black, fontSize: 12),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                Container(padding: EdgeInsets.all(8),), // add space between connected docs section and colorPicker
                colorPicker(), // color picker section
                SizedBox(height: 16),
                TextField( // document editing section
                  controller: _editingController,
                  maxLines: null,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
          floatingActionButton: FloatingActionButton(
          onPressed: () => _confirmDeletion(context),
          foregroundColor: const Color.fromARGB(255, 57, 57, 57),
          backgroundColor: Colors.red,
          child: Icon(Icons.delete),
        ),
    ),
  );
}

}