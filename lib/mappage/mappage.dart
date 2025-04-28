//contains most of the processing for mappage functionality. 

import 'package:flutter/material.dart';
import 'dart:convert'; // for json encoding/decoding
import 'package:hive/hive.dart'; // noSQL database for document storage
import 'package:collection/collection.dart';

import '../documents/documents.dart';
import '../documents/document_details_page.dart';
import 'line.dart';
import 'contextmenu.dart';
import 'map_previews.dart';

class MapPage extends StatefulWidget {
  final List<Document> documents;
  final List<Line> lines;
  MapPage({required this.documents, required this.lines});
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  OverlayEntry? _overlayEntry;
  Offset? _tapPosition;
  List<DocumentPreview> documentPreviews = [];
  bool _isDrawingMode = false;
  DocumentPreview? _sourcePreview;
  List<Line> _lines = [];
  List<Offset> centerPositions = [];
  Map<String, GlobalKey<State<StatefulWidget>>> _previewKeys = {};
  bool _isDeleteMode = false;

GlobalKey<State<StatefulWidget>> getGlobalKeyForDocumentPreview(String documentTitle) {
  if (!_previewKeys.containsKey(documentTitle)) {
    _previewKeys[documentTitle] = GlobalKey<State<StatefulWidget>>();
  }
  return _previewKeys[documentTitle]!;
}

@override
void initState() {
  super.initState();
  _loadPreviewLocations().then((_) {
  _updateLinesAndRedraw();
    _loadLines();
  });
}

// logic handling the preview box lifecycle
void updateDocumentPreviewColor(String documentId, Color newColor) { // find the documentPreview by documentId and update its color
  setState(() {
    var previewToUpdate = documentPreviews.firstWhereOrNull((preview) => preview.document.id == documentId);
    if (previewToUpdate != null) {
      previewToUpdate.document.backgroundColor = newColor;
    }
  });
}
Future<void> _savePreviewLocations() async {
var prefs = await Hive.openBox('prefs');
  List<String> serializedPreviews = documentPreviews.map((preview) {
    return '${preview.document.id};${preview.position.dx};${preview.position.dy}';
  }).toList();

final String encodedPreviews = jsonEncode(serializedPreviews);
await prefs.put('documentPreviews', encodedPreviews);
}
Future<void> _loadPreviewLocations() async {
  var prefs = await Hive.openBox('prefs');
  final String? previewsStr = prefs.get('documentPreviews');
  List<String> serializedPreviews = previewsStr != null ? List<String>.from(jsonDecode(previewsStr)) : [];

  List<DocumentPreview> validPreviews = [];

  for (var data in serializedPreviews) {
    List<String> splitData = data.split(';');
    String docId = splitData[0]; // unique document ID

    // check if the document still exists
    Document? doc = widget.documents.firstWhereOrNull((d) => d.id == docId);

    // if the document exists, create a preview for it
    if (doc != null) {
      double x = double.parse(splitData[1]);
      double y = double.parse(splitData[2]);

      validPreviews.add(DocumentPreview(
        document: doc,
        position: Offset(x, y),
        key: GlobalKey(),
      ));
    }
  }
  setState(() {
    documentPreviews = validPreviews;
  });
}
void _onDragEnd(DraggableDetails details, int index) {
  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final Offset localOffset = renderBox.globalToLocal(details.offset);
  setState(() {
    documentPreviews[index].position = localOffset;
  });
  _savePreviewLocations();
  _updateLinesAndRedraw();
}
void _onPreviewTap(DocumentPreview preview) {
  if (_isDrawingMode) {
    if (_sourcePreview == null) {
      _sourcePreview = preview;
    } else {
      _handleLineDrawing(_sourcePreview!, preview);
      _sourcePreview = null;
    }
  } else {
    _openDocumentPage(preview.document);
  }
}
void _openDocumentPage(Document document) async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DocumentDetailsScreen(
        document: document,
        documents: widget.documents,
        lines: _lines,
        onUpdateColor: updateDocumentPreviewColor,
      ),
    ),
  );
  if (result == 'deleted') { // check if the result indicates that a document was deleted
    DocumentPreview? previewToDelete = documentPreviews.firstWhereOrNull( // find the preview that corresponds to the deleted document
      (preview) => preview.document.id == document.id);
    if (previewToDelete != null) {
      _deletePreview(previewToDelete);
    }
  }
}
void _deletePreview(DocumentPreview preview) {
    setState(() {
      _lines.removeWhere((line) => // remove lines connected to deleted preview
          line.sourceId == documentPreviews.indexOf(preview) ||
          line.destinationId == documentPreviews.indexOf(preview));
      documentPreviews.remove(preview);
      _savePreviewLocations(); // save the updated map
      _saveLines(); // save the updated lines
      _updateLinesAndRedraw(); // refresh and push to gui
    });
  }

// logic for getting document preview center location for title placement & relocation
Offset getCenter(GlobalKey key) {
  final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box != null && box.hasSize) {
    final Offset topLeftPosition = box.localToGlobal(Offset.zero);
    return topLeftPosition + Offset(box.size.width / 2, box.size.height / 2);
  }
  return Offset.zero; // handle cases where the RenderBox is not available
}
Offset? _getCenterPosition(GlobalKey key) {
  final RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final Offset topLeftPosition = box.localToGlobal(Offset.zero);
      return topLeftPosition + Offset(box.size.width / 2, box.size.height / 2);
    }
    return null;
  }
Map<String, Offset> calculatePositionsMap() {
  Map<String, Offset> positions = {};
    for (var preview in documentPreviews) {
      GlobalKey key = preview.key;
      Offset? center = _getCenterPosition(key);
      if (center != null) {
        positions[preview.document.id] = center;
      }
    }
    return positions;
  }

// logic handling lines & line drawing
void _handleLineDrawing(DocumentPreview sourcePreview, DocumentPreview destinationPreview) {
  String sourceId = sourcePreview.document.id;
  String destinationId = destinationPreview.document.id;
  // using IDs
  setState(() {
    final existingLineIndex = _lines.indexWhere((line) =>
      (line.sourceId == sourceId && line.destinationId == destinationId) ||
      (line.sourceId == destinationId && line.destinationId == sourceId));
    if (existingLineIndex != -1) {
      // remove existing line
      _lines.removeAt(existingLineIndex);
    } else {
      // add new line
      _lines.add(Line(sourceId, destinationId));
    }
    _saveLines();
  });
}
Future<void> _saveLines() async {
  var prefs = await Hive.openBox('prefs');
prefs = await Hive.openBox('prefs');
  List<String> serializedLines = _lines.map((line) {
    return '${line.sourceId};${line.destinationId}';
  }).toList();
  final String encodedLines = jsonEncode(serializedLines);
  await prefs.put('lines', encodedLines);
}
Future<void> _loadLines() async {
var prefs = await Hive.openBox('prefs');
final String? linesStr = prefs.get('lines');
List<String> serializedLines = linesStr != null ? List<String>.from(jsonDecode(linesStr)) : [];
  _lines = serializedLines.map((line) {
    var parts = line.split(';');
    return Line(parts[0], parts[1]);
  }).toList();
}
  void _updateLinesAndRedraw() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      List<Offset> newCenterPositions = List.filled(documentPreviews.length, Offset.zero);
      // update centerPositions based on document IDs in _lines
      for (var line in _lines) {
        var sourceIndex = documentPreviews.indexWhere((preview) => preview.document.id == line.sourceId);
        var destinationIndex = documentPreviews.indexWhere((preview) => preview.document.id == line.destinationId);
        if (sourceIndex != -1 && destinationIndex != -1) {
          var sourceKey = documentPreviews[sourceIndex].key;
          var destinationKey = documentPreviews[destinationIndex].key;

          var sourceCenter = _getCenterPosition(sourceKey);
          var destinationCenter = _getCenterPosition(destinationKey);

          if (sourceCenter != null) newCenterPositions[sourceIndex] = sourceCenter;
          if (destinationCenter != null) newCenterPositions[destinationIndex] = destinationCenter;
        }
      }
      setState(() {
        centerPositions = newCenterPositions;
      });
      _updateLinesAndRedraw();
    });
  }
void _toggleDrawingMode() {
  setState(() {
    _isDrawingMode = !_isDrawingMode;
    _sourcePreview = null; // reset the source preview when leaving or entering drawing mode
  });
}

// context menu for preview creation
  void _showContextMenu(TapDownDetails details) { // context menu to select document to place on MapPage
    _tapPosition = details.globalPosition;
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }
  void _closeContextMenu() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }
  }
OverlayEntry _createOverlayEntry() {
  return OverlayEntry(
    builder: (context) => Positioned(
      top: 50,
      left: 50,
      right: 50,
      child: Center( // Use Center to horizontally center the content
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 200.0), // Set the maximum width
          child: DocumentContextMenu(
            documents: widget.documents,
            onDocumentSelected: _onDocumentSelected,
            onClose: _closeContextMenu,
          ),
        ),
      ),
    ),
  );
}
void _onDocumentSelected(Document selectedDocument) {
  _closeContextMenu();

    setState(() {
      documentPreviews.add(DocumentPreview(
        document: selectedDocument,
        position: _tapPosition!,
        key: GlobalKey(), // use a new GlobalKey for each preview
      ));
      _savePreviewLocations();
      _updateLinesAndRedraw();
    });
  }

@override
Widget build(BuildContext context) {
  List<Offset> centerPositions = []; 
  Map<String, Offset> positions = calculatePositionsMap();   // calculate center positions for each preview, ensuring it's using the latest positions
  for (var preview in documentPreviews) {
    Offset center = getCenter(preview.key);
    centerPositions.add(center);
  }
    CustomPainter linePainter = LinePainter(
      lines: _lines,
      positions: positions,
    );

  return Scaffold(
    body: Stack(
      children: [
        GestureDetector(
          onTapDown: (TapDownDetails details) {
            if (!_isDrawingMode) {
              _showContextMenu(details);
            }
          },
          child: CustomPaint(
            painter: linePainter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
        ),
        ...documentPreviews.map((preview) {
          int index = documentPreviews.indexOf(preview);
          return Positioned(
            left: preview.position.dx,
            top: preview.position.dy,
            child: Draggable(
              data: index,
              feedback: Material(
                elevation: 4.0,
                child: DocumentPreviewWidget(
                  preview.document,
                  key: GlobalKey(),
                  isDeleteMode: false,
                  onDelete: () {},
                ),
              ),
              onDragEnd: (dragDetails) => _onDragEnd(dragDetails, index),
              child: GestureDetector(
                onTap: () =>
                    _isDeleteMode ? _deletePreview(preview) : _onPreviewTap(preview),
                child: DocumentPreviewWidget(
                  preview.document,
                  key: preview.key, // use the preview's GlobalKey
                  isDeleteMode: _isDeleteMode,
                  onDelete: () => _deletePreview(preview),
                ),
              ),
            ),
          );
        }),
        Positioned(
          bottom: 25.0,
          left: 25.0,
          child: FloatingActionButton(
            onPressed: () => Navigator.pop(context, true),
            child: Icon(Icons.home),
          ),
        ),
        Positioned(
          bottom: 25.0,
          right: MediaQuery.of(context).size.width / 2 - 28,
          child: FloatingActionButton(
            onPressed: () {
              setState(() {
                _isDeleteMode = !_isDeleteMode;
              });
            },
            foregroundColor: const Color.fromARGB(255, 57, 57, 57),
            backgroundColor: _isDeleteMode ? Colors.red : Colors.grey,
            child: Icon(Icons.delete),
          ),
        ),
        Positioned(
          bottom: 25.0,
          right: 25.0,
          child: FloatingActionButton(
            onPressed: _toggleDrawingMode,
            foregroundColor: const Color.fromARGB(255, 57, 57, 57),
            backgroundColor: _isDrawingMode ? Colors.grey[700] : Colors.grey,
            child: Icon(_isDrawingMode ? Icons.edit_off : Icons.edit),
          ),
        ),
      ],
    ),
  );
}
}
