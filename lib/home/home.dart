// home page, including search functionality

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert'; // for json encoding/decoding
import 'package:hive/hive.dart'; // noSQL database for document storage
import 'package:reorderables/reorderables.dart'; // for reorderable list
import 'package:url_launcher/url_launcher.dart';

import '../mappage/mappage.dart';
import '../documents/documents.dart';
import '../documents/document_details_page.dart';
import 'home_previews.dart';
import '../documents/initial_text_entry.dart';
import '../mappage/line.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system, // use system theme mode.
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Document> documents = [];
  List<Line> _lines = [];
  List<Document> filteredDocuments = [];
  String searchQuery = "";
  Set<Color> selectedColors = {};
  Color? selectedColorFilter;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadDocuments();
  }

  void _updateDocumentColor(String documentId, Color color) {
    setState(() {
      // find the document by its ID and update its color
      final documentIndex = documents.indexWhere((doc) => doc.id == documentId);
      if (documentIndex != -1) {
        documents[documentIndex].backgroundColor = color;
        _saveData();
        _saveDocuments();
      }
    });
  }

  Future<void> _loadDocuments() async {
    final String? documentsStr = await Hive.box('prefs').get('documents');
    if (documentsStr != null) {
      setState(() {
        final List<Map<String, dynamic>> json = List<Map<String, dynamic>>.from(jsonDecode(documentsStr));
        documents = json.map((map) => Document.fromMap(map)).toList();
      });
    }
  }
  Future<void> _saveDocuments() async {
    final String encodedData = jsonEncode(documents.map((doc) => doc.toMap()).toList());
    await Hive.box('prefs').put('documents', encodedData);
  }
  void _onDocumentPressed(Document document) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentDetailsScreen(
          document: document,
          documents: documents,
          lines: _lines,
          onUpdateColor: _updateDocumentColor,
        ),
      ),
    );
    if (result == 'deleted') {
      _loadDocuments();
    } else if (result is String) {
      setState(() {
        document.text = result; // update the document's text with the edited text
        _saveData(); // save any changes to the document list
      });
    }
  }

  Future<void> _loadData() async {
    var prefs = await Hive.openBox('prefs');
    final String? documentsStr = prefs.get('documents');
    if (documentsStr != null) {
      setState(() {
        final List<dynamic> json = jsonDecode(documentsStr);
        documents = json.map((map) => Document.fromMap(map as Map<String, dynamic>)).toList();
      });
    }
  }
  Future<void> _saveData() async {
    var prefs = await Hive.openBox('prefs');
    final String encodedData = jsonEncode(documents.map((doc) => doc.toMap()).toList());
    await prefs.put('documents', encodedData);
  }

  void _filterDocuments() { // for highlighted searched query amoung documents
    setState(() {
      filteredDocuments = documents.where((doc) {
        // check if search query is in the title or text of document
        final searchMatch = doc.title.toLowerCase().contains(searchQuery.toLowerCase()) || 
                            doc.text.toLowerCase().contains(searchQuery.toLowerCase());
        final colorMatch = selectedColorFilter == null || doc.backgroundColor.value == selectedColorFilter!.value;
        return searchMatch && colorMatch;
      }).toList();
    });
  }
  void _updateSearchQuery(String query) { // for search function at top of home screen
    setState(() {
      searchQuery = query;
    });
  }


  void _onStarPressed(Document document, Color selectedColor) {
    setState(() {
      document.isStarred = !document.isStarred;
      document.backgroundColor = selectedColor; // update the background color for starred document
      if (document.isStarred) {
        documents.remove(document);
        documents.insert(0, document);
      }
      _saveData();
    });
  }

void _showCustomColorPickerDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      List<Color> colors = [
        Colors.amber.shade100,
        Colors.teal.shade100,
        Colors.lime.shade100,
        Colors.pink.shade100,
        Colors.purple.shade100,
        Colors.indigo.shade100,
      ];

return Dialog(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
  child: Container(
    width: MediaQuery.of(context).size.width * 0.8,
    padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('filter search by color', style: Theme.of(context).textTheme.titleLarge),
        SizedBox(height: 10),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              setState(() {
                selectedColorFilter = color;
                Navigator.of(context).pop();
                _filterDocuments();
              });
            },
            child: Container(
              margin: EdgeInsets.all(4),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              width: 30,
              height: 30,
            ),
          )).toList(),
        ),
        SizedBox(height: 20),
        Container(
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              color: Color.fromARGB(255, 200, 200, 200),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    selectedColorFilter = null;
                    Navigator.of(context).pop();
                    _filterDocuments();
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15.0),
                ),
                child: Text('no filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 57, 57, 57))),
              ),
            ),
          ),
        ),
        SizedBox(height: 40),
        InkWell(
          onTap: () => launchUrl(Uri.parse('https://www.angentsoftworks.com/about')),
          child: Text('click here for help & contact info', style: Theme.of(context).textTheme.titleMedium),
        ),
        SizedBox(height: 10),
        InkWell(
          child: Text('copyright © 2024 Angent Softworks', style: Theme.of(context).textTheme.titleSmall),
        ),
        SizedBox(height: 10),
        InkWell(
          onTap: () => launchUrl(Uri.parse('https://www.angentsoftworks.com/projects/notedash/privacy')),
          child: Text('privacy policy', style: Theme.of(context).textTheme.titleSmall),
        ),
      ],
    ),
  ),
);
    },
  );
}

  void _navigateToMapPage() async {
    // use Navigator.push to navigate to MapPage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapPage(documents: documents, lines: _lines)),
    );
    // check the result. If MapPage signals that updates were made (=returning true), then reload the documents.
    if (result == true) {
      _loadDocuments(); 
      _loadData();
    }
  }

@override
Widget build(BuildContext context) {
  // this variable will determine which list to display based on the searchQuery being empty or not
  final List<Document> displayList = searchQuery.isEmpty ? documents : filteredDocuments;
  return Scaffold(
    appBar: AppBar(
      title: TextField(
        onChanged: (value) {
          _updateSearchQuery(value);
          _filterDocuments(); // update the filtered list every time the search query changes
        },
        decoration: InputDecoration(
          hintText: "search documents...",
          suffixIcon: Icon(Icons.search),
        ),
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.filter_list),
          onPressed: () => _showCustomColorPickerDialog(),
        ),
      ],
    ),
    body: Container(
      margin: EdgeInsets.only(bottom: 10.0),
      child: Padding(
        padding: EdgeInsets.all(10.0),
        child: CustomScrollView(
          slivers: <Widget>[
            ReorderableSliverList(
              delegate: ReorderableSliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  // using displayList here to ensure its showing filtered/search results correctly
                  final doc = displayList[index];
                  final Key uniqueKey = Key('${doc.title}_$index');
                  return SizedBox(
                    key: uniqueKey,
                    child: DocumentBox(
                      searchQuery: searchQuery, // pass the searchQuery to DocumentBox
                      doc: doc,
                      onStarPressed: (selectedColor) {
                        _onStarPressed(doc, selectedColor);
                      },
                      onDocumentPressed: (Document doc) => _onDocumentPressed(doc),
                    ),
                  );
                },
                childCount: displayList.length,
              ),
              onReorder: (int oldIndex, int newIndex) { // DOCUMENT LIST REORDERING LOGIC
                setState(() {
                  // work directly with the documents list for reordering
                  if (searchQuery.isNotEmpty || selectedColorFilter != null) {
                    // when filter/search is active, adjust the index based on displayList and update documents list accordingly
                    Document movedDoc = displayList.removeAt(oldIndex);
                    // find actual indexes in documents list
                    int oldIndexGlobal = documents.indexOf(movedDoc);
                    documents.removeAt(oldIndexGlobal);
                    if (newIndex > oldIndex) newIndex -= 1;
                    // calculate the new index in the context of the original documents list
                    int newIndexGlobal = newIndex >= displayList.length ? documents.length : documents.indexOf(displayList[newIndex]);
                    documents.insert(newIndexGlobal, movedDoc);
                  } else {
                    // no filter/search is active; reorder directly
                    Document movedDoc = documents.removeAt(oldIndex);
                    if (newIndex > documents.length) newIndex = documents.length;
                    documents.insert(newIndex, movedDoc);
                  }
                  _saveData();
                });
              },
            ),
          ],
        ),
      ),
    ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0, left: 25.0),
            child: FloatingActionButton(
              onPressed: () {
                _navigateToMapPage();
              },
              child: Icon(Icons.map),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 0.0, right: 25.0),
            child: FloatingActionButton(
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (BuildContext context) => TextEntryDialog(), // on "+" button press open new document dialog. Initialization passthrough below
                );
                if (result != null && result is Map) {
                  String uniqueId = Uuid().v4();
                  String title = result['title'] ?? '';
                  String text = result['text'] ?? '';
                  Color color = result['color'] ?? const Color.fromARGB(255, 148, 147, 147);
                  Document newDoc = Document(id: uniqueId, title: title, text: text, backgroundColor: color);
                  setState(() {
                    documents.insert(0, newDoc);
                    _saveData();
                  });
                }
              },
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
