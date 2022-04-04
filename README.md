# Approov Quickstart: Flutter HTTP Client

This quickstart is written specifically for Android and iOS apps that are implemented using [`Flutter`](https://flutter.dev/) and the [`Dart HTTPClient class from the dart:io library`](https://api.dart.dev/stable/2.9.3/dart-io/HttpClient-class.html) or the [`Flutter HTTP package`](https://pub.dev/packages/http). If this is not your situation then please check if there is a more relevant Quickstart guide available.

This quickstart provides the basic steps for integrating Approov into your app. A more detailed step-by-step guide using a [Shapes App Example](https://github.com/approov/quickstart-flutter-httpclient/blob/master/SHAPES-EXAMPLE.md) is also available.

To follow this guide you should have received an onboarding email for a trial or paid Approov account.

Thie [Flutter](https://flutter.dev) package requires version 2.12.0 with Dart 2.17.0. At the time of writing (3rd April 2022) this is only accessible via the Flutter `beta` channel, not the `stable` channel. This is necessary because of the need to execute channel handlers on [background threads](https://docs.flutter.dev/development/platform-integration/platform-channels?tab=ios-channel-objective-c-tab#executing-channel-handlers-on-background-threads), which is only a recently added capability.

## ADDING THE APPROOV CLIENT

The Approov integration is available via [`Github`](https://github.com/approov/approov-service-flutter-httpclient) package. This allows inclusion into the project by simply specifying a dependency in the `pubspec.yaml` files for the app. In the `dependencies:` section of `pubspec.yaml` file add the following package reference:

```yaml
approov_service_flutter_httpclient:
     git: https://github.com/approov/approov-service-flutter-httpclient.git
```

This package is actually an open source wrapper layer that allows you to easily use Approov with `Flutter`. This has a further dependency to the closed source [Android Approov SDK](https://github.com/approov/approov-android-sdk) and [iOS Approov SDK](https://github.com/approov/approov-ios-sdk) packages. Those are automatically added as dependencies for the platform specific targets.

The `approov_service_flutter_httpclient` package provides a number of accessible classes:

1. `ApproovService` provides a higher level interface to the underlying Approov SDK
2. `ApproovException`, and derived `ApproovNetworkException` and `ApproovRejectionException`, provide special exception classes for Approov related errors 
3. `ApproovHttpClient` which is a drop-in replacement for the Dart IO library's `HttpClient` and calls the `ApproovService`
4. `ApproovClient` which is a drop-in replacement for Client from the Flutter http package (https://pub.dev/packages/http) and internally uses an `ApproovHttpClient` object


### ANDROID

The `approov_service_flutter_httpclient` indirectly adds an additional repository to the project files:

```gradle
maven { url 'https://jitpack.io' }
```

and two implementation dependencies:

```gradle
dependencies {
    implementation 'com.squareup.okhttp3:okhttp:4.9.3'
    implementation 'com.github.approov:approov-android-sdk:3.0.0'
}
``` 

### ANDROID MANIFEST CHANGES

The following app permissions need to be available in the manifest to use Approov:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Note that the minimum SDK version you can use with the Approov package is 21 (Android 5.0). 

Please [read this](https://approov.io/docs/latest/approov-usage-documentation/#targetting-android-11-and-above) section of the reference documentation if targetting Android 11 (API level 30) or above.

### IOS

The `approov_service_flutter_httpclient` generates a [Cocoapods](https://cocoapods.org) dependency file which must be installed by executing:

```Bash
pod install
```

in the directory containing the ios project files.

## INITIALIZING APPROOV SERVICE

The `ApproovClient` declared in the `approov_service_flutter_httpclient` package can be used as a drop in replacement for [Client](https://pub.dev/packages/http) from the Flutter http package. It will handle any request in the same way but with the additional features provided by the `Approov SDK`. The only additional requirement when using `ApproovClient` is providing an initialization string during object creation:

```Dart
import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';
...
...
http.Client client = ApproovClient('<enter-your-config-string-here>');
```

The `<enter-your-config-string-here>` is a custom string that configures your Approov account access. This will have been provided in your Approov onboarding email.

This initializes Approov when the app is first created. Please note that you must provide the initialization String every time you instantiate an `ApproovClient` but the underlying SDK only actually initializes the library once.

## USING APPROOV SERVICE

After initializing the `ApproovClient` you can perform requests and await responses like so:

```Dart
http.Response response = await client.get(Uri.parse('https://approov.io'));
```

This client includes an interceptor that protects channel integrity (with either pinning or managed trust roots). The interceptor may also add `Approov-Token` or substitute app secret values, depending upon your integration choices. You should thus use this client for all API calls you may wish to protect.

## CHECKING IT WORKS

Initially you won't have set which API domains to protect, so the interceptor will not add anything. It will have called Approov though and made contact with the Approov cloud service. You will see logging from Approov saying `UNKNOWN_URL`.

Your Approov onboarding email should contain a link allowing you to access [Live Metrics Graphs](https://approov.io/docs/latest/approov-usage-documentation/#metrics-graphs). After you've run your app with Approov integration you should be able to see the results in the live metrics within a minute or so. At this stage you could even release your app to get details of your app population and the attributes of the devices they are running upon.

## NEXT STEPS
To actually protect your APIs there are some further steps. Approov provides two different options for protecting APIs:

* [TOKEN PROTECTION](https://github.com/approov/quickstart-flutter-httpclient/blob/master/TOKEN-PROTECTION.md): You should use this if you control the backend API(s) being protected and are able to modify them to ensure that a valid Approov token is being passed by the app. An [Approov Token](https://approov.io/docs/latest/approov-usage-documentation/#approov-tokens) is short lived crytographically signed JWT proving the authenticity of the call.

* [SECRET PROTECTION](https://github.com/approov/quickstart-flutter-httpclient/blob/master/SECRET-PROTECTION.md): If you do not control the backend API(s) being protected, and are therefore unable to modify it to check Approov tokens, you can use this approach instead. It allows app secrets, and API keys, to be protected so that they no longer need to be included in the built code and are only made available to passing apps at runtime.

Note that it is possible to use both approaches side-by-side in the same app, in case your app uses a mixture of 1st and 3rd party APIs.

## USE WITH DIO
It is also possible to use Approov with the [`dio`](https://pub.dev/packages/dio) networking stack, since this uses `http.Client` internally. When constructing a `dio` object you need to modify the underlying client used as follows:

```Dart
    var dio = Dio();
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
      return ApproovHttpClient('<enter-your-config-string-here>');
    };
```
