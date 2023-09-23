import 'dart:io';
import 'package:http/http.dart' as http;

enum DataSource { url, asset }

class DataResponse {
  String content;
  DateTime? lastModified;
  DataSource source;
  DataResponse(this.content, this.lastModified, this.source);
}

Future<DataResponse> _readDataFromUrl(Uri uri) async {
  final response = await http.get(uri);
  final lastModified = response.headers['last-modified']?.parseHttpDate();
  return DataResponse(response.body, lastModified, DataSource.url);
}

Future<DataResponse> readPlanData() async {
  final remoteUri = Uri.parse("http://alkor.info/plan/plan.txt");
  final localUri = Uri.parse("assets/data/plan.txt");
  return _readDataFromUrl(
      Uri.base.scheme.startsWith("http") && Uri.base.host != remoteUri.host
          ? localUri
          : remoteUri);
}

extension StringExtensions on String {
  DateTime? parseHttpDate() => HttpDate.parse(this);
}
