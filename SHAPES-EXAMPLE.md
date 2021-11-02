# Shapes Example

This quickstart is written specifically for native Android apps that are written in Kotlin and use [`Flutter`](https://flutter.dev/) and the [`Dart HTTPClient class from the dart:io library`](https://api.dart.dev/stable/2.9.3/dart-io/HttpClient-class.html) or the [`Flutter HTTP package`](https://pub.dev/packages/http) for making the API calls that you wish to protect with Approov. This quickstart provides a step-by-step example of integrating Approov into an app using a simple `Shapes` example that shows a geometric shape based on a request to an API backend that can be protected with Approov.

## WHAT YOU WILL NEED
* Access to a trial or paid Approov account
* The `approov` command line tool [installed](https://approov.io/docs/latest/approov-installation/) with access to your account
* [Android Studio](https://developer.android.com/studio) installed (version ArticFox 2020.3.1 is used in this guide) if you will build the Android app
* [Xcode](https://developer.apple.com/xcode/) installed (version 13.0 is used in this guide) to build iOS version of application
* [Cocoapods](https://cocoapods.org) installed to support iOS building (1.11.2 used in this guide)
* [Flutter](https://flutter.dev) version 2.5.3 used in this guide with Dart 2.14.4
* The contents of this repo



## RUNNING THE SHAPES APP WITHOUT APPROOV

The Shapes App is a simple Flutter application which demonstrates using the [Client class](https://pub.dev/documentation/http/latest/http/Client-class.html) of the Flutter [http package](https://pub.dev/packages/http) and the [HttpClient class](https://api.dart.dev/stable/2.10.1/dart-io/HttpClient-class.html) of the Dart [IO library](https://api.dart.dev/stable/2.10.1/dart-io/dart-io-library.html) to make HTTP requests.

Before building the Flutter Shapes app, make sure that your system is set up for Flutter development by following the instructions at [Flutter Get Started](https://flutter.dev/docs/get-started/install).

<p>
    <img src="readme-images/flutter-shapes-app-start.png" width="256" title="Shapes App">
</p>

The application consists mostly of boilerplate code, apart from the definitions of the shapes server’s URLs and the onPressed callbacks (`hello()` and `shape()`) for the buttons along the bottom of the screen.

The _Hello_ and _Shape_ buttons initiate API requests to the shapes server, using the the Flutter http package's Client. For example, the _Hello_ button initiates a `GET` request to the `shapes.approov.io/v1/hello` endpoint.

On a successful _hello_ request to `/v1/hello`, the client app will say hello with a smile, while a failure or unsuccessful response will return a frown with some explanation of the error. The purpose of this simple endpoint is really just to test connectivity and to verify that you have built, installed and run the demo app correctly.

<a>
    <img src="readme-images/flutter-shapes-app-okay.png" width="256" title="Shapes App Good">
</a>

<a>
    <img src="readme-images/flutter-shapes-app-fail.png" width="256" title="Shapes App Fail">
</a>

A successful _shapes_ request to `/v1/shapes` returns one of four possible shapes:

<a>
    <img src="readme-images/flutter-shape-triangle.png" width="256" title="Triangle">
</a>

<a>
    <img src="readme-images/flutter-shape-circle.png" width="256" title="Circle">
</a>

<a>
    <img src="readme-images/flutter-shape-square.png" width="256" title="Square">
</a>

<a>
    <img src="readme-images/flutter-shape-rectangle.png" width="256" title="Rectangle">
</a>

### Running the App

To run the app on an attached device, open a shell terminal at the `quickstart-flutter-httpclient/example` directory and type:

```
$ flutter run
```

You should now be able to use the app to say hello and get shapes.

See the following sections if you have a problem with building or running.

### Android Potential Issues
If the Android build fails with `Manifest merger failed : Attribute application@label value=([...]) from AndroidManifest.xml:11:9-46 is also present at [approov-sdk.aar] AndroidManifest.xml:12:9-41 value=(@string/app_name)`, then open `quickstart-flutter-httpclient/example/android/app/src/main/AndroidManifest.xml` in an editor and make the following changes.

- Add the schema as an attribute in the `manifest` tag:

```
    <manifest ...
        xmlns:tools="http://schemas.android.com/tools"
        ... >
```
- Add the `android:label` and `tools` attributes to the `application` tag:
```
    <application ...
        android:label="@string/app_name"
        tools:replace="label"
        ... >
```

### iOS Potential Issues

If the iOS build fails with an error related to `Pods-Runner` then navigate inside `ios` folder using `cd ios` and run `pod install`.

If the iOS build fails with a signing error, open the Xcode project located in `quickstart-flutter-httpclient/example/ios/Runner.xcworkspace`:

```
$ open ios/Runner.xcworkspace
```

and select your code signing team in the _Signing & Capabilities_ section of the project.

Also ensure you modify the app's `Bundle Identifier` so it contains a unique string (you can simply append your company name). This is to avoid Apple rejecting a duplicate `Bundle Identifier` when code signing is performed. Then return to the shell and repeat the failed build step.

## ADDING APPROOV SUPPORT

Approov protection is provided through the `approov_service_flutter_httpclient` plugin for both, Android and iOS mobile platforms. This plugin handles all Approov related functionality, such as downloading and instalation of Approov SDK library, initialization, managing of initial and update configurations, fetching of Approov tokens, adding these to API requests as necessary, and manages certificate public key pinning. The plugin also requests all necessary network permissions.

In the configuration file `quickstart-flutter-httpclient/example/pubspec.yaml` find the location marked with
```
# *** UNCOMMENT THE SECTION BELOW FOR APPROOV ***
```
and change them as shown

1. Add the dependency for the approov_service_flutter_httpclient package
```
  # *** UNCOMMENT THE SECTION BELOW FOR APPROOV ***
  approov_service_flutter_httpclient:
     git: https://github.com/approov/approov_service_flutter_httpclient.git
```

In the source file `quickstart-flutter-httpclient/example/lib/main.dart` find the two locations marked with a comment
```
// *** UNCOMMENT THE SECTION BELOW FOR APPROOV ***
```
and change them to read

1. Import the approov_http_client package
```
// *** UNCOMMENT THE LINE BELOW FOR APPROOV ***
import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';
```

2. Create a Client.
```
// http.Client client = http.Client();
// *** UNCOMMENT THE LINE BELOW FOR APPROOV (and comment out the line above) ***
client = ApproovClient('<enter-your-config-string-here>');
```

### Select the Correct Shapes Endpoint

The Shapes server provides the app with shapes using multiple versions of an API: version 1 (https://shapes.approov.io/v1/shapes) which is _not_ protected by Approov, and version 2 (https://shapes.approov.io/v2/shapes) which _is_ protected by Approov.

Now that we’re using Approov, let’s switch to use version 2 of the Shapes API. Edit the Dart source in `quickstart-flutter-httpclient/example/lib/main.dart` find the line of code:

```
const String API_VERSION = 'v1'; // API v1 is unprotected; API v2 is protected by Approov
```
and change the Shapes server URLs to the v2 API path:
```
const String API_VERSION = 'v2'; // API v1 is unprotected; API v2 is protected by Approov
```

### Ensure the Shapes API is Added

In order for Approov tokens to be generated for `https://shapes.approov.io/v2/shapes` it is necessary to inform Approov about it. If you are using a demo account this is unnecessary as it is already set up. For a trial account do:

```
$ approov api -add shapes.approov.io
```

Tokens for this domain will be automatically signed with the specific secret for this domain, rather than the normal one for your account. After a short delay of no more than 30 seconds the new API settings become active.


### Build and Run the App Again

Build the app on your preferred platform (Approov requires building for a device on iOS).

For iOS: Note that it may be necessary to run the command `pod update` in the `quickstart-flutter-httpclient/example/ios` directory first as the Flutter Shapes app is built using the CocoaPods dependency framework.

Install and run the app on a device or an emulator and examine the logging. You should see in the logs that Approov is successfully fetching tokens, but the Shapes API is not returning valid shapes:

<p>
    <img src="readme-images/flutter-shape-invalid.jpg" width="256" title="Invalid">
</p>

**Warning:** Never log tokens in a released app as this could permit hackers to harvest data from your API while the token has not expired! Always use _[loggable](https://www.approov.io/docs/latest/approov-usage-documentation/#loggable-tokens)_ Approov tokens for debugging.


## REGISTER YOUR APP WITH APPROOV

Although the application is now receiving and forwarding tokens with your API calls, the tokens are not yet properly signed, because the attestation service does not recognize your application. Once you register the app with the Approov service, untampered apps will attest successfully and begin to fetch and transmit valid tokens.

Approov command line tools are provided for Windows, MacOS, and Linux platforms. Select the proper operating system executable. In a shell in your `quickstart-flutter-httpclient/example` directory:

For Android:

```
$ approov registration -add build/app/outputs/flutter-apk/app-debug.apk
```

For iOS: It is necessary to build an app archive (.ipa extension) and export it to a convenient location, for example the `quickstart-flutter-httpclient` directory. Install the app's .ipa on the device in order to ensure that the installed version and the registered version are the same. Assuming you have built an app archive, signed it and exported it to `quickstart-flutter-httpclient/Runner\ 2021-02-04\ 14-27-30/ApproovHttpClient_example.ipa`, the registration command is:

```
$ approov registration -add ../../Runner\ 2021-02-04\ 14-27-30/ApproovHttpClient_example.ipa
```


## RUN THE SHAPES APP WITH APPROOV

Wait for the registration to propagate to the Approov service. This can take up to 30 seconds.

Then restart the application on your device to flush out any bad tokens, tap _Shape_ and you should see:

<p>
    <img src="readme-images/flutter-shape-triangle.png" width="256" title="Success">
</p>

or any of the four possible shapes returned by the server. Congratulations, your API is now Approoved!


## WHAT IF I DON'T GET SHAPES

If you still don't get a valid shape then there are some things you can try. Remember this may be because the device you are using has some characteristics that cause rejection for the currently set [Security Policy](https://approov.io/docs/latest/approov-usage-documentation/#security-policies) on your Approov account:

* Ensure that the version of the app you are running is exactly the one you registered with Approov.
* Look at the [`logcat`](https://developer.android.com/studio/command-line/logcat) or the MacOS `Console` application output from the device. Information about any Approov token fetched or an error is output at the `INFO` level, e.g. `2020-02-10 13:55:55.774 10442-10705/io.approov.shapes I/ApproovInterceptor: Approov Token for shapes.approov.io: {"did":"+uPpGUPeq8bOaPuh+apuGg==","exp":1581342999,"ip":"1.2.3.4","sip":"R-H_vE"}`. You can easily [check](https://approov.io/docs/latest/approov-usage-documentation/#loggable-tokens) the validity and find out any reason for a failure.
* Consider using an [Annotation Policy](https://approov.io/docs/latest/approov-usage-documentation/#annotation-policies) during initial development to directly see why the device is not being issued with a valid token.
* Use `approov metrics` to see [Live Metrics](https://approov.io/docs/latest/approov-usage-documentation/#live-metrics) of the cause of failure.
* You can use a debugger or emulator and get valid Approov tokens on a specific device by [whitelisting](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy). As a shortcut, when you are first setting up, you can add a [device security policy](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy) using the `latest` shortcut as discussed so that the `device ID` doesn't need to be extracted from the logs or an Approov token.
* Approov token data is logged to the console using a secure mechanism - that is, a _loggable_ version of the token is logged, rather than the _actual_ token for debug purposes. This is covered [here](https://www.approov.io/docs/latest/approov-usage-documentation/#loggable-tokens). The code which performs this is:

```Dart
const result = await ApproovService.fetchApproovToken(url);
console.log("Fetched Approov token: " + result.loggableToken);
```

and the logged token is specified in the variable `result.loggableToken`.

The Approov token format (discussed [here](https://www.approov.io/docs/latest/approov-usage-documentation/#token-format)) includes an `anno` claim which can tell you why a particular Approov token is invalid and your app is not correctly authenticated with the Approov Cloud Service. The various forms of annotations are described [here](https://www.approov.io/docs/latest/approov-usage-documentation/#annotation-results).

