import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:approov_http_client/approov_http_client.dart';

void main() {
  const MethodChannel channel = MethodChannel('approov_http_client');

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
    // expect(await ApproovHttpClient.platformVersion, '42');
  });
}
