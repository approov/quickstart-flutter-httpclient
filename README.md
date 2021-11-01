# Approov Quickstart: Flutter HTTP Client

This quickstart is written specifically for Android and iOS apps that are implemented using [`Flutter`](https://flutter.dev/) and the [`Dart HTTPClient class from the dart:io library`](https://api.dart.dev/stable/2.9.3/dart-io/HttpClient-class.html) or the [`Flutter HTTP package`](https://pub.dev/packages/http). If this is not your situation then please check if there is a more relevant Quickstart guide available.

This quickstart provides the basic steps for integrating Approov into your app. A more detailed step-by-step guide using a [Shapes App Example](https://github.com/approov/quickstart-flutter-httpclient/blob/master/SHAPES-EXAMPLE.md) is also available.

To follow this guide you should have received an onboarding email for a trial or paid Approov account.

## ADDING approov_service_flutter_httpclient

The Approov integration is available via [`Github`](https://github.com/approov/approov-service-flutter-httpclient) package. This allows inclusion into the project by simply specifying a dependency in the `pubspec.yaml` files for the app. In the `dependencies:` section of `pubspec.yaml` file add the following package reference:

```yaml
approov_service_flutter_httpclient:
     git: https://github.com/approov/approov-service-flutter-httpclient.git
```

This package is actually an open source wrapper layer that allows you to easily use Approov with `Flutter`. This has a further dependency to the closed source [Android Approov SDK](https://github.com/approov/approov-android-sdk) and [iOS Approov SDK](https://github.com/approov/approov-ios-sdk) packages. Those are automatically added as dependencies for the platform specific targets.

### ANDROID

The `approov_service_flutter_httpclient` adds an additional repository to the `build.gradle` project file:

```gradle
maven { url 'https://jitpack.io' }
```

and two implementation dependecies:

```gradle
dependencies {
    implementation 'com.squareup.okhttp3:okhttp:3.14.2'
    implementation 'com.github.approov:approov-android-sdk:2.7.0'
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
// Import the package
import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';
...
...
http.Client client = ApproovClient(
          '<enter-your-config-string-here>');
```

The `<enter-your-config-string-here>` is a custom string that configures your Approov account access. This will have been provided in your Approov onboarding email.

This initializes Approov when the app is first created. Please note that you must provide the initialization String every time you instantiate an `ApproovClient` but the underlying SDK only actually initializes the library once.

## USING APPROOV SERVICE

After initializing the `ApproovClient` you can perform requests and await responses like so:

```Dart
http.Response response = await client.get(Uri.parse('https://approov.io'));
```

This adds the `Approov-Token` header and pins the connections.

## CHECKING IT WORKS

Initially you won't have set which API domains to protect, so the interceptor will not add anything. It will have called Approov though and made contact with the Approov cloud service. You will see logging from Approov saying `UNKNOWN_URL`.

Your Approov onboarding email should contain a link allowing you to access [Live Metrics Graphs](https://approov.io/docs/latest/approov-usage-documentation/#metrics-graphs). After you've run your app with Approov integration you should be able to see the results in the live metrics within a minute or so. At this stage you could even release your app to get details of your app population and the attributes of the devices they are running upon.

However, to actually protect your APIs there are some further steps you can learn about in [Next Steps](https://github.com/approov/quickstart-flutter-httpclient/blob/master/NEXT-STEPS.md).





