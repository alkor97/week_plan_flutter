import 'dart:io';
import 'package:http/http.dart' as http;

class DataResponse {
  String content;
  DateTime? lastModified;
  DataResponse(this.content, this.lastModified);
}

abstract class DataProvider {
  Future<DataResponse> get();
}

class DataProviders {
  static DataProvider remote() => _RemoteDataProvider();
}

// implementation

class _RemoteDataProvider implements DataProvider {
  @override
  Future<DataResponse> get() {
    final remoteUri = Uri.parse("http://alkor.info/plan/plan.txt");
    final localUri = Uri.parse("data/plan.txt");
    return _readDataFromUrl(
        Uri.base.scheme.startsWith("http") && Uri.base.host != remoteUri.host
            ? localUri
            : remoteUri);
  }

  Future<DataResponse> _readDataFromUrl(Uri uri) async {
    final response = await http.get(uri);
    final lastModified = response.headers['last-modified']?.parseHttpDate();
    return DataResponse(response.body, lastModified);
  }
}

extension StringExtensions on String {
  DateTime? parseHttpDate() => HttpDate.parse(this);
}
