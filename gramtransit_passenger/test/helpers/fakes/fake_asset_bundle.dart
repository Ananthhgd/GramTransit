import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FakeAssetBundle extends CachingAssetBundle {
  final String? returnedString;
  final Object? thrownError;
  int loadCount = 0;

  FakeAssetBundle({this.returnedString, this.thrownError});

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    loadCount++;
    if (thrownError != null) {
      throw thrownError!;
    }
    if (returnedString != null) {
      return returnedString!;
    }
    throw FlutterError('Unable to load asset: $key');
  }

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError('Only loadString is faked');
  }
}
