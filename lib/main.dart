import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // noSQL database for document storage
import 'package:path_provider/path_provider.dart';

import 'home/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDir.path);
  return runApp(MyApp());
}
