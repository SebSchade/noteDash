//document objects & to/from Map

import 'package:flutter/material.dart';

class Document {
  String id; // unique identifier for each document
  String title;
  String text;
  bool isStarred;
  Color backgroundColor;

  Document({required this.id, required this.title, required this.text, this.isStarred = false, this.backgroundColor = const Color.fromARGB(255, 98, 98, 98)});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'isStarred': isStarred,
      'backgroundColor': backgroundColor.value,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map) {
    return Document(
      id: map['id'],
      title: map['title'],
      text: map['text'],
      isStarred: map['isStarred'],
      backgroundColor: Color(map['backgroundColor']),
    );
  }
}