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
import 'package:logger/logger.dart';

// *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';

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
        Log.i(
            "$TAG: Received connectivity response: ${utf8.decode(response.bodyBytes)}");
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
    Log.i(
        "$TAG: Shape button pressed. Attempting to get a shape response from the Approov shapes server...");
    setState(() {
      _statusText = "Getting a shape...";
      _statusImageName = "images/approov.png";
    });
    try {
      // *** COMMENT THE LINE BELOW FOR APPROOV ***
      //http.Client client = http.Client();
      // *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
      String configString =
          "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJ2ZXJzaW9uIjp7Im1ham9yX2NvdW50Ijo3LCJtaW5vcl9jb3VudCI6MH0sImFjY291bnRfaWQiOiJzdGcxMDAxIiwia2V5X2lkIjoia2V5MCIsInB1YmxpY19rZXkiOiJNRmt3RXdZSEtvWkl6ajBDQVFZSUtvWkl6ajBEQVFjRFFnQUVwNUUwR1ZCdkUvMmE2RU5kZExHeUlnSHRQUWJFY1hZdXJCM1UvZllUOXgySkFQdkRCUU5iR3Z4Q0FzMHE3aHFoMmlLSUM2ZTkrOFlBR0N6K3JFRi9SZz09IiwicmVpbml0X2hhc2giOiJkRTArMEtGMXVEaGJJTWFURitjMXFDVDdoTHhiaWZJOGRYeE9sc2hCSzZnPSIsImJhY2tzdG9wX3RpbWVvdXQiOjMwMDAwLCJuZXR3b3JrX3J1bGVzIjp7ImF0dGVzdCI6W1siYXR0ZXN0MSIsImh0dHBzOi8vcGx5cnMtYXR0LXN0ZzEwMDEuY3JpdGljYWwuYmx1ZS9hdHRlc3QiLDYwMDAsWzQwOCw1MDAsNTAyLDUwNF0sNTAwLDE1MDBdLFsiYXR0ZXN0MiIsImh0dHBzOi8vcGx5cnMtYXR0LXN0ZzEwMDEuY3JpdGljYWwuYmx1ZS9hdHRlc3QiLDMwMDAsWzQwOCw1MDAsNTAyLDUwNF0sNTAwLDE1MDBdXSwiY2FsaWJyYXRlIjpbWyJjYWxpYnJhdGUiLCJodHRwczovL3BseXJzLWF0dC1zdGcxMDAxLmNyaXRpY2FsLmJsdWUvYXR0ZXN0Iiw1MDAwLFtdLDAsMF1dLCJjb25maWciOltbImZldGNoIiwiaHR0cHM6Ly9wbHlycy1hdHQtc3RnMTAwMS5jcml0aWNhbC5ibHVlL2F0dGVzdCIsMzAwMCxbXSwwLDBdXSwiZmFpbG92ZXIiOltbImZhaWxvdmVyMSIsImh0dHBzOi8vZGV2LmFwcHJvb3ZhbC5jb20vdG9rZW4iLDQwMDAsWzQwOCw1MDAsNTAyLDUwNF0sMCwxMDAwXSxbImZhaWxvdmVyMiIsImh0dHBzOi8vZGV2LmFwcHJvb3ZhbC5jb20vdG9rZW4iLDIwMDAsW10sMCwwXV0sInJlYXR0ZXN0IjpbWyJyZWF0dGVzdDEiLCJodHRwczovL3BseXJzLWF0dC1zdGcxMDAxLmNyaXRpY2FsLmJsdWUvYXR0ZXN0Iiw2MDAwLFs0MDgsNTAwLDUwMiw1MDRdLDUwMCwxNTAwXSxbInJlYXR0ZXN0MiIsImh0dHBzOi8vcGx5cnMtYXR0LXN0ZzEwMDEuY3JpdGljYWwuYmx1ZS9hdHRlc3QiLDMwMDAsWzQwOCw1MDAsNTAyLDUwNF0sNTAwLDE1MDBdXSwicmVmcmVzaCI6W1sicmVmcmVzaDEiLCJodHRwczovL3BseXJzLWF0dC1zdGcxMDAxLmNyaXRpY2FsLmJsdWUvYXR0ZXN0Iiw2MDAwLFs0MDgsNTAwLDUwMiw1MDRdLDUwMCwxNTAwXSxbInJlZnJlc2gyIiwiaHR0cHM6Ly9wbHlycy1hdHQtc3RnMTAwMS5jcml0aWNhbC5ibHVlL2F0dGVzdCIsMzAwMCxbNDA4LDUwMCw1MDIsNTA0XSw1MDAsMTUwMF1dLCJyZXBvcnQiOltbInJlcG9ydCIsImh0dHBzOi8vcGx5cnMtYXR0LXN0ZzEwMDEuY3JpdGljYWwuYmx1ZS9hdHRlc3QiLDMwMDAsW10sMCwwXV19LCJhcHByb292X3BpbnMiOnsicGx5cnMtYXR0LXN0ZzEwMDEuY3JpdGljYWwuYmx1ZSI6eyJwdWJsaWMta2V5LXNoYTI1NiI6WyJzMmVwekIwQXZNQ0d1WE5QdlFRb0JjWTNZQ0swbVFaWHV5YzRHaW0zeTFzPSJdfX0sInVzZXJfYXBpX3BpbnMiOnsiKiI6eyJwdWJsaWMta2V5LXNoYTI1NiI6WyIrK01CZ0RINVdHdkw5QmNuNUJlMzBjUmNMMGY1TytOeW9YdVd0UWRYMWFJPSIsIi9IaERBT3lOOU5QUnV0ZGpnMUdDa1kxU3FmOENPTDMybGFITm05dVlNaHc9IiwiL1RjYjZwZFYvMkRJZ295RW00NVNGZDVUTFdHd0NZVmZvSzFqRFpEdStDND0iLCIvcUszMWtYN3B6MTFQQjdKcDRjTVFPSDNzTVZoNlNlNWhiOXhHR2JqYnlJPSIsIi91aXZrcEYxYUg5R09LUDhtRDI0N05EbDRxZytjMzgvdDN0TUl2eTZ3S1k9IiwiL3pRdnRzVEl2VENrY0c5elNKVTU4WjV1U013RjlHSlVaVTltRU52RlFPaz0iLCIwY1JUZCt2YzFoak5GbEhjTGdMQ0hYVWVXcW44MGJOREgvYnM5cU1UU1BvPSIsIjI4SGpvVkk0b0VnN3piajk3R0Z1QStjRnBJNHFVQkZYeXQ4N25ITVJ4ZVU9IiwiM1Y3UndKRDU5RWdHRzZxVXByc1JBWFZFNmU3Nm9nekhGTTVzWXo5ZHhpaz0iLCIzbnRwTXVuRVJZTE9EZUI2dmF0KzZwREhYVzBxQnpNZDlYdlZ5NGhWUFJNPSIsIjRFb0NMT012VE04c2YyQkdLSHVDaWpLcENmWG5VVVIvZy8wc2NmYjlnWE09IiwiNEdaSDVTWVFGZ3crZzhRdEl1T2FxSFVNV0Uxc0pLK3UxVXBoRmtkQ0FBbz0iLCI0VTVSaVI4MGtpUSs2bUU3d3NnVTFISWtzaVRGZlRnV25wV09NTFBlM3VRPSIsIjU4cVJ1L3V4aDRnRmV6cUFjRVJ1cFNrUllCbEJBdmZjdzdtRWpHUExuTlU9IiwiNU9rNUpTcitjTDJmSE5LVkF3TVR1cVFOVllaQjgxc2p0SEZMUStnZlZEWT0iLCI1Y28zdkh0c05obDV2R3NTUEttaDJ3R1FSdGYvWDFmZnVGU3huUkN3YUM4PSIsIjY4VmZJZWlOU2Uzb0hBQjFxd2l6eHp1QjhQTStOOWRrR2gwQnR1WUMzSjA9IiwiNnJEZVdrWkJrQkN3R3kxVlZUL0JFYXFDdEQyVGxlMytycXFNZHVhdEdaVT0iLCI2cndZWEU2QzJVS3hwWmVMbzhBWUZJZldzN21YVGx4Sjl5OXRDOWxqY1ZBPSIsIjdLRHhnVUFzNTZobEt6RzAwRGJmSkg0Nk1MZjBHbERaSHNUNUN3QnJRNkU9IiwiODBPT0k3UE9VeVVpK3M4d2VTUDFqOUdHQ09tNmV0M0REcFVyUThTV0ZzTT0iLCI4QUVma3Z6NXZqYkhwYk51ZThoaXF5RHBUdk52Nm9wV0hiQ28xM1VNSDFFPSIsIjhjYTZad3o4aU9UZlVwYzhya0lQQ2dpZDFIUVVUK1dBYkVJQVpPRlpFaWs9IiwiOSt6ZTFjWmdSOUtPMWtaclZEeEE0SFE2dm9IUkNTVk56NFJkVEN4NFU4VT0iLCI5OHAzcGhEajFDUkhKQWFTMjlWOC9SUFBCQ3JOSUdMbXBpdUh1ZTJCd2FjPSIsIjlJdXQxOTlxQm1rTkN1TVRjN0VvVmZqZTJ4UlJmellxTVRFQnpKak1helU9IiwiQUcxNzUxVmQyQ0FtUkN4UEdpZW9Eb21obUp5NGV6UkVqdElaVEJnWmJWND0iLCJCK2hVOG1wOHZUaVpKNm9FRy83eHRzMGgzUlE0R0syVWZjWlZxZVdIL29nPSIsIkI2S1FUVXYvbGdUcUV6R3VtUTZmL2pNU011YWV5NG9JelVuWTQwZFgyMEU9IiwiQlJ6NStwWGtEcHVEN2E3YWFXSDJGb3g0ZWNSbUFYSkhuTjFScXdQT3Bpcz0iLCJCVmNLNXVzUHpyUWhEbTIzbElhM0NVeXZJQVFCNFVtMlozUkJ0ZkplUkpzPSIsIkJtQUxsTUF4aTdhV2Z3eDNoOHlLRURLaGVjVHBYanhYWUxNdUtROS83SnM9IiwiQzUrbHBaN3RjVndtd1FJTWNSdFBic1F0V0xBQlhoUXplam5hMHdIRnI4TT0iLCJDTE9tTTEvT1h2U1BqdzVVT1liQWY5R0tPeEltRXA5aGhrdTlXOTBmSE1rPSIsIkRIcktweEFpWnlDN3lVQTBudUxtRklaU3FKMi9RR29qTElsZmJjZU91NW89IiwiRGdYcHV5T0ducmFKM0ZhRG5jN0VkYU91ZGZwclVMeGFTWGcyREw1bk15TT0iLCJEb3V4aTc3dnM0RytJYi9Cb2diVEZ5bUVZcTBRU0ZYd1NnVkNhWmNJMDlRPSIsIkVMbzBoY3FMdG9nS3VWTWFRR1BrQUJWVlZoeC9MZ1ZSWmZTYkxYVDhYMnM9IiwiRWxYS3ZvRlMrbVRmbEM5NlIwRitLZmxzSE9FYitNaE95K0tCWE1Fb0NCQT0iLCJGSjh1NWp1YVhsZ0RKQXAzRGNtUi9DNDBSZVlvTWNKRnBKdkU4ZmM0LzV3PSIsIkZlN1RPVmxMTUUrTStFZTBkemNkalcvc1lmVGJLd0d2V0o1OFU3TmNya3c9IiwiRmZGS3hGeWNmYUl6MDBlUlpPZ1RmK05lNFBPSzZGZ1lQd2hCRHFncXhMUT0iLCJHL0FOWEk4VHdKVGRGK0FGQk04SWlJVVBFdjBHZjZINUxBL2I5Z3VHNHlFPSIsIkhxUEY1RDdXYkMyaW1EcENwS2ViSHBCbmhzNmZHMWhpRkJtZ0JHT29mVGc9IiwiSHZaR0pkcWk1ZFF6MTBTYTR4b2dEUkFsNEFFcWorejZjSk12aTFtYmRkMD0iLCJJL0x0L3o3ZWtDV2FuakQwQ3ZqNUVxWGxzMmxPYVRoRUEwSDJCZzRCVC9vPSIsIklDR1JmcGdtT1VYSVdjUS9IWFBMUVRrRlBFRlBvRHlqdkg3b2hoUXBqenM9IiwiSlVIbE82V3pzSHJMNXdsNnhLQStCQXdSejNwdFNtZkxJVDFWaTFBV2VnWT0iLCJKWmFRVGNUV21hNGd3czcwM09SL0tGazMxM1JrckRjSFJ2VXQ2bmE2RENnPSIsIkpkU1JQUFdIQ1hRVTBwMG05c0d4bEN6VzFrNnZSZEQ4K0JVbXJicVcweVE9IiwiSzg3b1dCV005VVpmeWRkdkRmb3hMKzhscE55b1VCMnB0R3RuMGZ2NkcyUT0iLCJLODlWT21iMWNKQU4zVEs2YmY0ZXpBYkpHQzFtTGNHMkRoOTdkbndyM1ZRPSIsIktvOHRpdkRyRWppWTkweUdhc1A2WnBCVTRqd1h2SHFWdlFJMEdTM0dOZEE9IiwiS3djY1dhQ2dybmF3NnRzcnJTTzYxRmdMYWNOZ0cyTU1McThHRTYrb1A1ST0iLCJMOFZtZWt1YUpuanRhc2F0SlVaZnkvWUpTL3paVUVDWHg2ajZSNjNsNklnPSIsIkxiS3VUUTBJcE54N2VseVJHemEwTGpCbzB1V0dWKyttR2k4dmFjVlR1Rmc9IiwiTGdiSzRmd2dzZ0RtKzNTRlY2UkVTK3lURjkvL0xrRlJacDRQZVVUd3FlQT0iLCJNNEJ3bXZPd2xyNDh3cVFGU0JRc0NsSUFLTnNKNHN0M3JpSUdZV3EyeTdRPSIsIk1obXdrUlQvU1ZvK3R1c0F3dS9xczBBQ3JsOEtWc2RubnFDSG8vb0Rmazg9IiwiTXltL29UdGdCNnRmdzNFL0Nzc29sQ2JpKzhtY3hjRVFxUlN4T1ZjV0FMWT0iLCJOMm9hY0lLbGs5ek1JTlZoMFJucHE0MHc4UnpESWRDamY2UWZEZktFNEJ3PSIsIk5JZG56YTA3M1NpeXVOMVRVYTdEREdqT3hjMXAwbmJmT0NmYnhQV0FaR1E9IiwiTmZVODRTWkdFZUF6UVA0MzRleDlUTW1HeFdFOXluRDlCS3BFVkY4dHJ5Zz0iLCJOcXZESmxhcy9HUmNZYmNXRThTL0ljZUg5Y3E3N2tnMGpWaFplQVBYcThrPSIsIk93MXp0TDVLaFVyY1BsSFg3NStraXUrN0xOMkNUV2U5eDlmUW1pcThMVU09IiwiUDVQei9QZWRJbDBoUHU5cVNqOVloYytFL2oxNmVqd1JWVFVYYUl3T0lRQT0iLCJRUHo4S0lkZHpML3J5OTlzMTBNekV0cGp4Ty9QTzlleHRRWENJQ0N1QW5RPSIsIlFYbnQyWUh2ZEhSM3RKWW1RSXIwUGFvc3A2dC9uZ2dzRUdENFFKWjNRMGc9IiwiUWtNV0orcDJ6SGhwZjVGZU5GV3hzdXlDL3k5amdPNWtJKzg4Q0VDMzVqRT0iLCJSVHQwZ0p0cEFaWW44dmhEQUIyMWxRemRIVVUzRUZQbjg5L2J3M0ZCRThZPSIsIlNYRW8vSkJsYTRjcEJJS3lJKyszSWtEK25FSWVlWk9ONWZnUkRMQytrRlk9IiwiU2tudHZTK1BnakM5VlpLekUxYy80Y0Z5cEYrcGdCSE1IdDI3TnEzai9PVT0iLCJVTXlHdXBiYk1tUEhta1BxMEhWVDJmVm1XZWFRZm5MWXdDWmplaHpjaGR3PSIsIlVRMGc1Y1IvWTg5bWF5RDJHdllyd0pta0tzZ2svNlJEb3RwOGtMR0FpcEU9IiwiVmVBTDRuZk9zRlJTbWZKUDJmaDM0cXp6S0ZMYlEvL05LYnluU3ptMHlmbz0iLCJWZmQ5NUJ3RGVTUW8rTlVZeFZFRUlsdmtPbFdZMlNhbEtLMWxQaHpPeDc4PSIsIlZqTFplL3AzVy9QSm5kNmxMOEpWTkJDR1FCWnluRkxkWlNUSXFjTzBTSjg9IiwiV0J6QldDRVdscFREbkNtUnRUNlRxNVJhUXJCMlpoZDB3dXp6aWpNanJPbz0iLCJXTjFoL3JOdXA5Sllja054Y0pGSnl4SVRONFpNckxMUW1aclNCem5RWkhjPSIsIldWV3VLUlYwcVRFMExQZEZEaFpsTHQ0ZUQ3TUpmaFZ4MzZ3UnlSVmdGV1E9IiwiV2Q4eGUvcWZUd3EzeWxGTmQzSXBhcUxIWmJoMlpOQ0xsdVZ6bWVOa2Nwdz0iLCJXb2lXUnlJT1ZOYTlpaGFCY2lSU0M3WEhqbGlZUzlWd1VHT0l1ZDRQQjE4PSIsIlhFR25PckxEWGZ6WGNmYjliajZQckp0R25UaHNyZHBXcVZ0a2JyU015alE9IiwiWTltdm0wZXhCazFKb1E1N2Y5Vm0yOGpLbzVsRm0vd29LY1Z4cll4dTgwbz0iLCJZRDkyOG95ZjY2Zyt4MUh0dG15TmRTUHFRUDVKL25SQ2RpbjFEYXU4OVZvPSIsIllJbGp4NHhGWG00MHNISkdpczRKVnMveGpUUmtQNTh3VzNGaStoZ1plZnc9IiwiWVFiQTQ2Q2ltWU1ZZFJKNzE5UE1HRm1BUFZFY3JCSHJiZ2hBM1JadndRND0iLCJZV0ZuSUJRenJxYkk1ZU1IQ3Z5dlowa1lqNEZMMGF1eGVhNk5yVHEvSnV3PSIsIllsVk1Gd0JWUTdJM0lWOEVKbzNOTDlIRWNDUUswOGhtRGlXdUxGbGpEMVU9IiwiYUIzRWdzS1d5RUFzYnJzZzVvTUpvN3lFWlNPdU5MbUVxRTdtbDZNeExiYz0iLCJhQ2RIK0xwaUc0Zk4wN3dwWHRYS3ZPY2lvY0RBTmowZGFMT0pLTko0Zng0PSIsImFFR1pYdDVuaElpQzh3cGRIdWlkMzVtMHJHZmtFbFAzeXRhK2JTY0ZRQWM9IiwiYVR5YXBySkZzN0FtRmpkMUNHUHEyMndraWhibExXOUx5UXlHdS9NdGNFST0iLCJhcGUxSElJWjZUNWQ3R1M2MVlCczNyRDROVnZrZm5Wd0VMY0NSVzRCcXYwPSIsImF6dFg2ZXlJMGJzOUFXTi84engybUxQSmRZSlY2ZkFlcVJlUFBuODdLMUk9IiwiYkVaTG1sc2pPbDZIVGFkbHdtOEVVQkRTM2MvMFY1VHd0TWZrcXZwUUZKVT0iLCJiYit1QU5ON25OYy9qN1I5NWxrWHJ3RGczZDlDMjg2c0lNRjhBblh1SUpVPSIsImJqWkxZVFBlNzl5N0lTYzhYMFJhSUsrOEJRT05Xd0ljRENGVEE1QVdORnM9IiwiY0NFV3pOaS9JK0ZrWnZEZzI2RHRhaU9hbkJ6V3FQV21hem12TlpVQ0E0VT0iLCJjR3V4QVh5RlhGa1dtNjFjRjRIUFdYOFMwc3JTOWowYVNxTjBrNEFQKzRBPSIsImRpR1Z3aVZZYnViQUkzUlc0aEI5eFU4ZS9DSDJHbmt1dlZGWkU4em1nekk9IiwiZHU2RmtEZE1jVlEzdThwcnVtQW82dDNpM0cyN3VNUDJFT2hSOFIwYXQvVT0iLCJkeWtIRjJGTEpmRXBaT3ZiT0xYNFBLcmNEMncyc0hkL2lBL0czdUhUT2N3PSIsImVHLzZWNFlZdzdtakVSZGVVSUZ2VGRvR0JjT0dueWx1dkZsRHZ3bjA2UVE9IiwiZWNxdlUwZm01S2xNam5pcGhKYjhkQUlQZ0o3ZUUvSWcrcllRVEkzdE1wOD0iLCJmMEtXL0Z0cVRqczEwOE5wWWo0MlNyR3ZPQjJQcHhJVk04bld4alBxSkdFPSIsImZOWjhKSTlwMkQvQytic0IzTEgzcldlalk5QkdCRGVXMEpoTU9pTWZhN0E9IiwiZmc2dGRydG9HZHd2VkZFYWhEVlBib3N3ZTUzWUlGanFiQUJQQWRuZHBkOD0iLCJnSTFvcy9xMGlFcGZseHJPZlJCVkRYcVZvV04zVHo3RGF2LzdJVCsrVEhRPSIsImdvc083L0pHVk9qL1dFR2luZFhVNCswd2xTeWtOQ1dua29OQWNnalRuUlk9IiwiZ3JYNFRhOUhwWng2dFNIa21DcnZwQXBUUUdvNjdDWURudnByTGc1eVJNRT0iLCJob1d0aFE5L1ZzMFdsRHZMY0xRMDV6VnVHNHZjWVRRRzR1cU41R0NTdGpZPSIsImhxYVBCUUEwRW1wVURUbmJMRitSZnZacWxQdVdHZm9lellKODZrYTZETEE9IiwiaHIxMmpOcFU0VzFUTVFTNGk0REpqRHJIRDFrd2txYmh1a09OTi9UcVR0ST0iLCJoeHFSbFBUdTFiTVMvMERJVEIxU1N1MHZkNHUvOGw4VGpQZ2ZhQXA2M0djPSIsImk3V1RxVHZoME9pb0lydUlmRlI0a01QbkJxclMycmRpVlBsL3MydUMvQ1k9IiwiajlFU3c4ZzNEeFI5WE0wNmZZWmV1TjFVQjRPNnhwL0dBSWpqZEQvek0zZz0iLCJqU0k3cFFCOWdFeWN4Z2ZKQU9NdUlHWnNXa244S2RWYTBTMzdhTmN1NVhzPSIsImpVRjlzdDJMOWVNSVRSNC9HVzFZT0VuWUc5MU1BTWNMblRrMm5wYTR4NEk9IiwialhaM1pMUEwyZ2lTblFjcUlxVmg5TnpkRzhWOVBMM2NsSXhIMHJSL2tTST0iLCJqb0JHN0V5c0FWcFFmT0RTMEJWS1MwRG81Q3N4WmMrbFJsY1VOUkV0RitVPSIsImtzUm9lV0p1OHN3ZXpxVU1jdnRlT0ZoRUNWOGh5L095Zzh1QzVybjhhbGc9Iiwia3hnaWI0eURyK1IvWDBmQ1Qxbk9FdHVveHpzWUcrNXJMcUgwQ2dhOEdHaz0iLCJsQWNxMC9XUGNQa3dtT1dsOXNCTWxzY1F2WVNkZ3hoSkdhNlE2NGtLNUFBPSIsImxTd2dPY0FrUHJVVjNYUFlQOE5rTVlTSFQrc0lZcW1EZHpIdG0wZEM0WG89IiwibUVmbFpUNWVub1IxRnVYTGdZWUdxblZFb1p2bWY5YzJiVkJwaU9qWVEwYz0iLCJtbEwvYWp5MjQxT2doV2ZnM0p3NVd6QU5ZS0lpa3F1TUdNRmxheW1EcnBBPSIsIm5UZmtxWW5xczRndEVXQlMvSXRZUkdjQ3kxazNKdVJnVERlVmxBeHhBK0k9Iiwib0Mrdm9aTEl5NEhMRTBGVlQ1d0Z0eHpLS29rTERSS1kxb05rZkpZZSs5OD0iLCJva2E0SXZscy9zd1ZVVmJsUjJsWGhGU1NyUE1oaCt5S0x2RXRpV0dOY1IwPSIsIm95RDAxVFRYdnBmQnJvM1FTWmMxdklsY01qcmRMVGlML005bUxDUFgrWm89IiwicWlZd3A3WVhzRTBLS1V1cmVveXFwUUZ1YmI1Z1NEZW9Pb1Z4bjZ0bWZyVT0iLCJyL21Ja0czZUVwVmRtK3Uva28vY3d4ek9NbzFiazRUeUhJbEJ5aWJpQTVFPSIsInJuK1dMTG5tcDl2M3VEUDdHUHFiY2FpUmRkK1VuQ01yYXA3M3l6M3l1L3c9Iiwic0QySHNGYlFqTW5VNW5YdkdjcURxMU5USVdpb0pZV1l2bkxtMkZ4OTE4RT0iLCJzTFZqTlVhRllmVzduNkV0Z0JlRXBqT2xjbkJkTlBNclpEUkYzNml3QmRFPSIsInN2Y3BpMUsvTER5c1RkL25MZVRXZ3F4WWxYV1ZtQzhyWWpBYTlaZkdtY1U9IiwidDBDTFRTdmdJNHVqY0FUZE5PSjJ4Z0diMHZKTW5iZlVtQTlmYkRXYVM4dz0iLCJ1MUlJYlFZNTZOc3pKM1dzajA2RU5ka3M2d0QwNGs4by9BNnI0a0IzTG9BPSIsInVVd1pnd0RPeGNCWHJRY250d3Ura1lGcGtpVmtPYWV6TDBXWUVaM2FuSmM9IiwidlJVKzE3QkRUMmlHc1h2T2k3NkU3VFFNY1RMWEFxajArakdQZFc3TDF2TT0iLCJ3clBER2tvcGhRcW84ODlIS2hGcC8zRzBGbGVmYWtTQzdIZEV1RDM1aUt3PSIsIngvUTdUUFczRldncFQ0SXJVM1ltQmZiZDBWeXQ3T2M1NmVMRHk2WWVuV2M9IiwieDRRelBTQzgxMEs1L2NNamIwNVFtNGszQnc1ekJuNGxUZE8vbkVXL1RkND0iLCJ4RVMxdG16bDF4NGJYa0R5YzRYSlhML1NTZ1cxYjNES3dKa3ZEMURETjV3PSIsInk2MTdIVGhJU2Q4SlJyZnVqbjlmZk9PdTJIYjlwN3lkTU5peGJ5bi9MRk09IiwieVVJbUxBeDhDcFc3RlN0eHhDVlczYjZhQlBxRGVEYzFVTkszemlmWlVxTT0iLCJ6SlNsb0RHZjkzcE15dDJDSEV4WlowNUUxU2dXeTlIZjRzZGhOd3JVMGh3PSIsInpyR1VFY1pRVXNkWCtVSHJnbXlXbEI1TkNOQ1d4OXQrZnFQRStNRS9HaE09Il19LCJhcHByb292LmlvIjp7InB1YmxpYy1rZXktc2hhMjU2IjpbXX0sInNoYXBlcy5hcHByb292LmlvIjp7InB1YmxpYy1rZXktc2hhMjU2IjpbImlqZHVEOGQzNmtXWHRkWkttTEY3TklHTVRNMGF4blA3NlJvL25OcXRRak09Il19LCJ4LmNvbSI6eyJwdWJsaWMta2V5LXNoYTI1NiI6W119fX0.MT_K8jSVbATNot8nd0mbuhuTk91S5s-M8cKnYDowviXcvn0okFXxthNiS6gj107y9TJDSeilLRoWAqDYIFg2qg";
      http.Client client = ApproovClient(configString,
          "options:did:SXZvU3VwZXJTZWNyZXREb250VGVsbA==:vcNgDYI1NgiXACKHfyEjew==");

      // *** UNCOMMENT THE LINE BELOW FOR APPROOV USING SECRETS PROTECTION ***
      //ApproovService.addSubstitutionHeader("api-key", null);

      http.Response response =
          await client.get(Uri.parse(SHAPE_URL), headers: {"api-key": API_KEY});
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
    );
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
