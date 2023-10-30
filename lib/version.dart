import 'package:flutter/services.dart';

Future<String> getGitVersion() async =>
    (await rootBundle.loadString(".git/ORIG_HEAD")).trim();
