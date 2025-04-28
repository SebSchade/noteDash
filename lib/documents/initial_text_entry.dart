// where the user enters text the first time a new document is created

import 'package:flutter/material.dart';

class TextEntryDialog extends StatefulWidget { // for initial text entry of new document
  @override
  _TextEntryDialogState createState() => _TextEntryDialogState();
}

class _TextEntryDialogState extends State<TextEntryDialog> {
  List<Color> tertiaryColors = [
    Colors.amber.shade100, Colors.teal.shade100, Colors.lime.shade100,
    Colors.pink.shade100, Colors.purple.shade100, Colors.indigo.shade100,
  ];
  TextEditingController titleController = TextEditingController();
  TextEditingController textController = TextEditingController();
  Color selectedColor = Colors.grey;
  Widget colorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: tertiaryColors.map((color) {
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedColor = color;
            });
          },
          child: Container(
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
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            colorPicker(),
            SizedBox(height: 16),
            TextField(
              controller: titleController,
              maxLength: 24,
              decoration: InputDecoration(
                labelText: 'Title',
                counterText: '',
                suffixText: '(${24 - titleController.text.length})',
              ),
              onChanged: (text) {
                setState(() {});
              },
            ),
            SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: textController,
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                String title = titleController.text;
                String text = textController.text;
                Navigator.of(context).pop({'title': title, 'text': text, 'color': selectedColor});
              },
              icon: Icon(Icons.save),
              label: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}