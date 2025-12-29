# Approov Quickstart: Flutter HTTP Client

This quickstart is written specifically for Android and iOS apps that are implemented using [`Flutter`](https://flutter.dev/) and the [`HTTP Client`](https://pub.dev/documentation/http/latest/http/Client-class.html), the [`Dart IO HttpClient`](https://api.dart.dev/stable/latest/dart-io/HttpClient-class.html) or [`Dio`](https://pub.dev/packages/dio). If this is not your situation then please check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating Approov into your app. Additionally, a step-by-step tutorial guide using our [Shapes App Example](https://github.com/approov/quickstart-flutter-httpclient/blob/master/SHAPES-EXAMPLE.md) is also available.

To follow this guide you should have received an onboarding email for a trial or paid Approov account.

Note that the minimum OS requirement for iOS is 12 and for Android the minimum SDK version is 23 (Android 6.0). You cannot use Approov in apps that need to support OS versions older than this.

## ADDING THE APPROOV SERVICE DEPENDENCY

The Approov integration is available via [`pub-dev`](https://pub.dev/packages/approov_service_flutter_httpclient) package. This allows inclusion into the project by simply specifying a dependency in the `pubspec.yaml` files for the app. In the `dependencies:` section of `pubspec.yaml` file add the following package reference:

```yaml
approov_service_flutter_httpclient: ^3.5.5
```

This package is actually an open source wrapper layer that allows you to easily use Approov with `Flutter`. This has a further dependency to the closed source [Android Approov SDK](https://github.com/approov/approov-android-sdk) and [iOS Approov SDK](https://github.com/approov/approov-ios-sdk) packages. Those are automatically added as dependencies for the platform specific targets.

The `approov_service_flutter_httpclient` package provides a number of accessible classes:

1. `ApproovService` provides a higher level interface to the underlying Approov SDK
2. `ApproovException`, and derived `ApproovNetworkException` and `ApproovRejectionException`, provide special exception classes for Approov related errors
3. `ApproovHttpClient` which is a drop-in replacement for the Dart IO library's `HttpClient` and calls the `ApproovService`
4. `ApproovClient` which is a drop-in replacement for Client from the Flutter http package (https://pub.dev/packages/http) and internally uses an `ApproovHttpClient` object

### ANDROID MANIFEST CHANGES

The following app permissions need to be available in the manifest to use Approov:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Please [read this](https://approov.io/docs/latest/approov-usage-documentation/#targeting-android-11-and-above) section of the reference documentation if targeting Android 11 (API level 30) or above.

### IOS

The `approov_service_flutter_httpclient` generates a [Cocoapods](https://cocoapods.org) dependency file which can be installed by executing:

```Bash
pod install
```

in the directory containing the iOS project files.

## USING APPROOV WITH HTTP CLIENT

The `ApproovClient` declared in the `approov_service_flutter_httpclient` package can be used as a drop in replacement for [`HTTP Client`](https://pub.dev/documentation/http/latest/http/Client-class.html) from the Flutter http package. It will handle any request in the same way but with the additional features provided by the `Approov SDK`.

You must initialize the `ApproovService` as early as possible in the initialization of your app, ideally in the `main` function:

```Dart
import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';
...
ApproovService.initialize('<enter-your-config-string-here>');
```

The `<enter-your-config-string-here>` is a custom string that configures your Approov account access. This will have been provided in your Approov onboarding email.

You can then create an `ApproovClient` when needed as follows:

```Dart
...
http.Client client = ApproovClient();
```

After creating the `ApproovClient` you can perform requests and await responses as normal, for example:

```Dart
http.Response response = await client.get(Uri.parse('https://your.domain/api'));
```

This client includes an interceptor that protects channel integrity (with either pinning or managed trust roots) and may also add `Approov-Token` or substitute app secret values, depending upon your integration choices. You should thus use this client for all API calls you may wish to protect.

## USING APPROOV WITH DART IO HTTPCLIENT

The `ApproovHttpClient` declared in the `approov_service_flutter_httpclient` package can be used as a drop in replacement for the [`Dart IO HttpClient`](https://api.dart.dev/stable/latest/dart-io/HttpClient-class.html). It will handle any request in the same way but with the additional features provided by the `Approov SDK`. Create a client instance as follows

```Dart
import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';
...
HttpClient client = ApproovHttpClient();
```

After creatng the `ApproovHttpClient` you can perform requests and await responses as normal, for example:

```Dart
HttpClientRequest request = await client.getUrl(Uri.parse('https://your.domain/api'));
HttpClientResponse response = await request.close();
```

This client protects channel integrity (with either pinning or managed trust roots) and may also add `Approov-Token` or substitute app secret values, depending upon your integration choices. You should thus use this client for all API calls you may wish to protect.

## USING APPROOV WITH DIO
It is also possible to use Approov with the [`Dio`](https://pub.dev/packages/dio) networking stack, since this uses `HttpClient` internally. When constructing a `Dio` object you need to modify the underlying client used as follows:

```Dart
import 'package:dio/adapter.dart';
...
var dio = Dio();
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  return ApproovHttpClient();
};
```

After creatng the custom `Dio` you can perform requests and await responses as normal, for example:

```Dart
var response = await dio.get('https://your.domain/api');
```

This client protects channel integrity (with either pinning or managed trust roots) and may also add `Approov-Token` or substitute app secret values, depending upon your integration choices. You should thus use this client for all API calls you may wish to protect.

Note that if you are using [Sentry](https://docs.sentry.io/platforms/flutter/) then you must make any call to `addSentry` after updating `onHttpClientCreate` as Sentry modifies the Dio adapter to something other than `DefaultHttpClientAdapter`.

## ISOLATES
Note that it is possible to also use Approov from background isolates as well as the root isolate. This relies on support for [platform plugins in isolates
](https://docs.flutter.dev/perf/isolates#using-platform-plugins-in-isolates) that was introduced in Flutter 3.7. Note that you must follow the instructions given there regarding a call to `BackgroundIsolateBinaryMessenger.ensureInitialized` or else Approov will not work in the isolate.

Since each isolate has a completely independent state you must call `ApproovService.initialize` in each isolate. You should do this as soon as possible after its creation. Make sure you provide exactly the same `config` string provided in the root and all other isolates, since the underlying Approov SDK is shared between them all and can only have a single active configuration at one time. Note that the Approov implementation in the root isolate may be marginally faster than those in other isolates since it is able to use the method callbacks from native code which are not available to background isolates.

## CHECKING IT WORKS
Initially you won't have set which API domains to protect, so the interceptor will not add anything. It will have called Approov though and made contact with the Approov cloud service. You will see logging from Approov saying `UNKNOWN_URL`.

Your Approov onboarding email should contain a link allowing you to access [Live Metrics Graphs](https://approov.io/docs/latest/approov-usage-documentation/#metrics-graphs). After you've run your app with Approov integration you should be able to see the results in the live metrics within a minute or so. At this stage you could even release your app to get details of your app population and the attributes of the devices they are running upon.

## NEXT STEPS
To actually protect your APIs and/or secrets there are some further steps. Approov provides two different options for protection:

* [API PROTECTION](https://github.com/approov/quickstart-flutter-httpclient/blob/master/API-PROTECTION.md): You should use this if you control the backend API(s) being protected and are able to modify them to ensure that a valid Approov token is being passed by the app. An [Approov Token](https://approov.io/docs/latest/approov-usage-documentation/#approov-tokens) is short lived crytographically signed JWT proving the authenticity of the call.

* [SECRETS PROTECTION](https://github.com/approov/quickstart-flutter-httpclient/blob/master/SECRETS-PROTECTION.md): This allows app secrets, including API keys for 3rd party services, to be protected so that they no longer need to be included in the released app code. These secrets are only made available to valid apps at runtime.

Note that it is possible to use both approaches side-by-side in the same app.

See [REFERENCE](https://github.com/approov/quickstart-flutter-httpclient/blob/master/REFERENCE.md) for a complete list of all of the `ApproovService` methods.
