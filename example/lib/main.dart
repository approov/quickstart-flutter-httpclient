/*
 * Copyright (c) 2020 CriticalBlue Ltd.
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart'; // https://pub.dev/packages/logger

// *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
//import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';

// Shapes server URLs
// API v1 is unprotected; API v2 is protected by Approov
const String API_VERSION = 'v1';
const String HELLO_URL = "https://shapes.approov.io/$API_VERSION/hello";
const String SHAPE_URL = "https://shapes.approov.io/$API_VERSION/shapes";

void main() {
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
    Log.i(
        "$TAG: Hello button pressed. Attempting to get a hello response from the Approov shapes server...");
    setState(() {
      _statusText = "Checking connectivity...";
      _statusImageName = "images/approov.png";
    });
    // Create a client
    try {
      http.Client client = http.Client();
      http.Response response = await client.get(Uri.parse(HELLO_URL));
      if (response.statusCode == 200) {
        Log.i(
            "$TAG: Received a hello response from the Approov shapes server: ${utf8.decode(response.bodyBytes)}");
        _statusText = '${response.statusCode}: ${response.reasonPhrase}';
        _statusImageName = 'images/hello.png';
      } else {
        Log.i("$TAG: Error on hello request: ${response.statusCode}");
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
    Log.i(
        "$TAG: Shape button pressed. Attempting to get a shape response from the Approov shapes server...");
    setState(() {
      _statusText = "Checking app authenticity...";
      _statusImageName = "images/approov.png";
    });
    try {
      // Create a client
      http.Client client = http.Client();
      // *** UNCOMMENT THE LINE BELOW FOR APPROOV (and comment out the line above) ***
      //http.Client client = ApproovClient('<enter-your-config-string-here>');

      http.Response response = await client.get(Uri.parse(SHAPE_URL));
      if (response.statusCode == 200) {
        Log.i(
            "$TAG: Received a shape response from the Approov shapes server: ${utf8.decode(response.bodyBytes)}");
        Map<String, dynamic> json = jsonDecode(response.body);
        _statusText = '${response.statusCode}: ${response.reasonPhrase}';
        _statusImageName =
            'images/${(json["shape"] as String).toLowerCase()}.png';
      } else {
        Log.i("$TAG: Error on shape request: ${response.statusCode}");
        Map<String, dynamic> json = jsonDecode(response.body);
        _statusText =
            "${response.statusCode}: ${response.reasonPhrase}\n${json['status']}";
        _statusImageName = 'images/confused.png';
      }
    } catch (e) {
      _statusText = e.toString();
      _statusImageName = 'images/confused.png';
      Log.e("$TAG: ${e.toString()}");
    }
    setState(() {});
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
    TextStyle buttonStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      //            color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        // Hello button
        FlatButton(
            onPressed: hello,
            child: Text(
              'Hello',
//            style: buttonStyle,
            )),
        // Shape button
        FlatButton(
          onPressed: shape,
          child: Text(
            'Shape',
//            style: buttonStyle,
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
