import 'dart:io';

String fixture(String path) => File('test/fixtures/$path').readAsStringSync();
