

import 'dart:io';

import 'package:file_picker/file_picker.dart';


Future<File> getFile()
{
  return FilePicker.getFile(type:FileType.custom,allowedExtensions: ["pdf"]);
}