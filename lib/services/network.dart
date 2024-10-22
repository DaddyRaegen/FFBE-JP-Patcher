import 'dart:convert';

import 'package:ffbe_patcher/models/Data.dart';
import 'package:http/http.dart' as http;

Future<Data> fetchData() async {
  final response = await http.get(Uri.parse('https://raw.githubusercontent.com/DaddyRaegen/FFBE-JP-Patch-Files/refs/heads/master/data.json'));
  
  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    Data data = Data.fromJson(jsonData);
    return data;
  } else {
    throw Exception('Failed to load events');
  }
}
