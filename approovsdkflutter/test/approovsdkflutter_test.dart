import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:approovsdkflutter/approovsdkflutter.dart';

void main() {
  const MethodChannel channel = MethodChannel('approovsdkflutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Approovsdkflutter.platformVersion, '42');
  });
}
