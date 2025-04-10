/*
 * Copyright (c) 2025 Approov Ltd.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
 * documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
 * Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

// *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
//import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';

// Shapes API v1 is protected by an API key only - this is used initially and for SECRETS PROTECTION
// v3 is protected by an API key and an Approov token - use this for API PROTECTION
const String API_VERSION = 'v1';

// Endpoint URLs to be used
const String HELLO_URL = "https://shapes.approov.io/$API_VERSION/hello";
const String SHAPE_URL = "https://shapes.approov.io/$API_VERSION/shapes";

// API key 'yXClypapWNHIifHUWmBIyPFAm' used to protect the shapes endpoint. Change this to 'shapes_api_key_placeholder' when
// using SECRETS PROTECTION
const API_KEY = "yXClypapWNHIifHUWmBIyPFAm";

void main() {
  // *** UNCOMMENT THE TWO LINES BELOW FOR APPROOV ***
  //ApproovService.initialize('<enter-your-config-string-here>');

  // *** UNCOMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION ***
  //ApproovService.addSubstitutionHeader("api-key", null);

  // execute the main function of the app
  runApp(Shapes());
}

class Shapes extends StatefulWidget {
  @override
  _ShapesState createState() => _ShapesState();
}

class _ShapesState extends State<Shapes> {
  // logger
  static Logger Log = Logger();

  // logging tag
  static const String TAG = "APPROOV SHAPES FLUTTER";

  // Name of the image that shows the current app status
  String _statusImageName = 'images/approov.png';

  // Status text to display below the image
  String _statusText = '';

  // Function called when 'Hello' button is pressed
  void hello() async {
    Log.i("$TAG: Hello button pressed. Checking connectivity...");
    setState(() {
      _statusText = "Checking connectivity...";
      _statusImageName = "images/approov.png";
    });
    try {
      http.Client client = http.Client();
      http.Response response = await client.get(Uri.parse(HELLO_URL));
      if (response.statusCode == 200) {
        Log.i("$TAG: Received connectivity response: ${utf8.decode(response.bodyBytes)}");
        _statusText = '${response.statusCode}: ${response.reasonPhrase}';
        _statusImageName = 'images/hello.png';
      } else {
        Log.i("$TAG: Error on connectivity request: ${response.statusCode}");
        _statusText = "${response.statusCode}: ${response.reasonPhrase}";
        _statusImageName = 'images/confused.png';
      }
    } catch (e) {
      _statusText = e.toString();
      _statusImageName = 'images/confused.png';
      Log.e("$TAG: ${e.toString()}");
    }
    setState(() {});
  }

  // Function called when 'Shape' button is pressed
  void shape() async {
    Log.i("$TAG: Shape button pressed. Attempting to get a shape response from the Approov shapes server...");
    setState(() {
      _statusText = "Getting a shape...";
      _statusImageName = "images/approov.png";
    });
    try {
      // *** COMMENT THE LINE BELOW FOR APPROOV ***
      http.Client client = http.Client();

      // *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
      //http.Client client = ApproovClient();

      http.Response response = await client.get(Uri.parse(SHAPE_URL), headers: {"api-key": API_KEY});
      if (response.statusCode == 200) {
        Log.i("$TAG: Received a shape response from the Approov shapes server: ${utf8.decode(response.bodyBytes)}");
        Map<String, dynamic> json = jsonDecode(response.body);
        _statusText = '${response.statusCode}: ${response.reasonPhrase}';
        _statusImageName = 'images/${(json["shape"] as String).toLowerCase()}.png';
      } else {
        Log.i("$TAG: Error on shape request: ${response.statusCode}");
        Map<String, dynamic> json = jsonDecode(response.body);
        _statusText = "${response.statusCode}: ${response.reasonPhrase}\n${json['status']}";
        _statusImageName = 'images/confused.png';
      }
    } catch (e) {
      _statusText = e.toString();
      _statusImageName = 'images/confused.png';
      Log.e("$TAG: ${e.toString()}");
    }
    setState(() {});
  }

  // Function called when 'Shape (Isolate)' button is pressed
  void shapeIsolate() async {
    Log.i(
        "$TAG: Shape (Isolate) button pressed. Attempting to get a shape response from the Approov shapes server via an Isolate...");
    setState(() {
      _statusText = "Getting a shape...";
      _statusImageName = "images/approov.png";
    });
    final resultPort = ReceivePort();
    RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    await Isolate.spawn(_isolateFetch, [resultPort.sendPort, rootIsolateToken]);
    final shape = await resultPort.first;
    _statusText = "Received from Isolate";
    _statusImageName = 'images/$shape.png';
    setState(() {});
  }

  // Function run within an isolate to fetch a Shape
  static Future<String> _isolateFetch(List<dynamic> args) async {
    SendPort responsePort = args[0];
    RootIsolateToken rootIsolateToken = args[1];
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    String shape = "confused";
    try {
      // *** COMMENT THE LINE BELOW FOR APPROOV ***
      http.Client client = http.Client();

      // *** UNCOMMENT THE TWO LINES BELOW FOR APPROOV ***
      //ApproovService.initialize('<enter-your-config-string-here>');
      //http.Client client = ApproovClient();

      // *** UNCOMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION ***
      //ApproovService.addSubstitutionHeader("api-key", null);

      http.Response response = await client.get(Uri.parse(SHAPE_URL), headers: {"api-key": API_KEY});
      if (response.statusCode == 200) {
        Log.i("$TAG: Received a shape response from the Approov shapes server: ${utf8.decode(response.bodyBytes)}");
        Map<String, dynamic> json = jsonDecode(response.body);
        shape = (json["shape"] as String).toLowerCase();
      } else {
        Log.i("$TAG: Error on shape request: ${response.statusCode}");
      }
    } catch (e) {
      Log.e("$TAG: ${e.toString()}");
    }
    Isolate.exit(responsePort, shape);
  }

  // Widget displaying the status of the app as an image and an explanatory text
  Widget statusImgTxt(String statusImageName, String statusText) {
    return Column(
      children: [
        // Status image
        Image.asset(
          statusImageName,
          width: 600,
          height: 240,
          fit: BoxFit.contain,
        ),
        // Status text
        Text(statusText),
      ],
    );
  }

  // Widget for the 'Hello' and 'Shape' buttons
  Widget buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Hello button
        TextButton(
            onPressed: hello,
            child: Text(
              'Hello',
            )),
        // Shape button
        TextButton(
          onPressed: shape,
          child: Text(
            'Shape',
          ),
        ),
        // Shape Isolate button
        TextButton(
          onPressed: shapeIsolate,
          child: Text(
            'Shape (Isolate)',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Approov Shapes',
      home: Scaffold(
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text(
              'Approov Shapes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w400,
              ),
            ),
            statusImgTxt(_statusImageName, _statusText),
            buttons(),
          ],
        ),
      ),
    );
  }
}
