# Secrets Protection
You should use this option if you wish to protect access to 3rd party or managed APIs where you are not able to add an Approov token check to the backend. This allows client secrets, or API keys, used for access to be protected with Approov. Rather than build secrets into an app where they might be reverse engineered, they are only provided at runtime by Approov for apps that pass attestation. This substantially improves your protection and prevents these secrets being abused by attackers. Where you are able to modify the backend we recommend you use API Protection for further enchanced flexibility and security.

This quickstart provides straightforward implementation if the secret is currently supplied in a request header to the API. The quickstart interceptor is able to automatically rewrite headers as the requests are being made, to automatically substitute in the secret, but only if the app has passed the Approov attestation checks. If the app fails its checks then you can add a custom [rejection](#handling-rejections) handler.

These additional steps require access to the [Approov CLI](https://approov.io/docs/latest/approov-cli-tool-reference/), please follow the [Installation](https://approov.io/docs/latest/approov-installation/) instructions.

## ENABLING MANAGED TRUST ROOTS
Client secrets or API keys also need to be protected in transit. For 3rd party APIs you should not pin against their certificates since you are not in control of when they might changed. Instead the [Managed Trust Roots](https://approov.io/docs/latest/approov-usage-documentation/#managed-trust-roots) feature can be used to protect TLS.

Ensure managed trust roots are enabled using:

```
approov pin -setManagedTrustRoots on 
```
> Note that this command requires an [admin role](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

This ensures connections may only use official certificates, and blocks the use of self signed certificates that might be used by a Man-in-the-Middle (MitM) attacker.

## ADDING API DOMAINS
In order for secrets to be protected for particular API domains it is necessary to inform Approov about them. Execute the following command:

```
approov api -add <your-domain> -noApproovToken
```

This informs Approov that it should be active for the domain, but does not need to send Approov tokens for it. Adding the domain ensures that the channel will be protected against Man-in-the-Middle (MitM) attacks.

## MIGRATING THE SECRET INTO APPROOV
It is assumed that you already have some client secrets and/or API keys in your app that you would like to migrate for protection by Approov. To do this you first need to enable the [Secure Strings](https://approov.io/docs/latest/approov-usage-documentation/#secure-strings) feature:

```
approov secstrings -setEnabled
```

> Note that this command requires an [admin role](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

The quickstart integration works by allowing you to replace the secret in your app with a placeholder value instead, and then the placeholder value is mapped to the actual secret value on the fly by the interceptor (if the app passes Approov attestation). The shipped app code will only contain the placeholder values.

If your app currently uses `<secret-value>` then replace it in your app with the value `<secret-placeholder>`. Choose a suitable placeholder name to reflect the type of the secret. The placeholder value will be added to requests in the normal way, but you should be using the Approov enabled networking client to perfom the substituion.

You must inform Approov that it should substitute `<secret-placeholder>` for `<secret-value>` in requests as follows:

```
approov secstrings -addKey <secret-placeholder> -predefinedValue <secret-value>
```

> Note that this command also requires an [admin role](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

You can add up to 16 different secret values to be substituted in this way.

If the secret value is provided on the header `<secret-header>` then it is necessary to notify the `ApproovService` that the header is subject to substitution. You do this by making the call once:

```Dart
ApproovService.addSubstitutionHeader("<secret-header>", null);
```

With this in place the Approov interceptor should replace the `<secret-placeholder>` with the `<secret-value>` as required when the app passes attestation. Since the mapping lookup is performed on the placeholder value you have the flexibility of providing different secrets on different API calls, even if they passed with the same header name.

If the secret value is provided as a parameter in a URL query string then it is necessary to call a function that may rewrite the URL. This must be done before the request is made. For instance, if you wish to substitute the parameter `<secret-param>` then you must call:

```Dart
uri = await ApproovService.substituteQueryParam(uri, "<secret-param>");
```

If no substitution is made then the return value is the same as the input [Uri](https://api.dart.dev/stable/2.0.0/dart-core/Uri-class.html), otherwise a new `Uri` is created with the substituted parameter value. The call should transform any instance of a URL such as `https://mydomain.com/endpoint?<secret-param>=<secret-placeholder>` into `https://mydomain.com/endpoint?<secret-param>=<secret-value>`, if the app passes attestation and there is a secure string with the name `<secret-placeholder>`. The function call may throw `ApproovException` which you must handle. Note that this should only ever be applied to a `Uri` with a host domain that has been added to Approov, so that either pinning or managed trust roots protection is being applied.

Since earlier released versions of the app may have already leaked the `<secret-value>`, you may wish to refresh the secret at some later point when any older version of the app is no longer in use. You can of course do this update over-the-air using Approov without any need to modify the app.

## REGISTERING APPS
In order for Approov to recognize the app as being valid it needs to be registered with the service. Change directory to the top level of your app project and then register the app with Approov:

For Android:

```
$ approov registration -add build/app/outputs/flutter-apk/app-debug.apk
```

For iOS it is necessary to explicitly build an `.ipa` using the command `flutter build ipa`. This will provide the path of the `.ipa` that you can then register, e.g:

```
$ approov registration -add build/ios/ipa/YourApp.ipa
```

Remember if you are using bitcode then you must also use the `-bitcode` option with the registration.

> **IMPORTANT:** The registration takes up to 30 seconds to propagate across the Approov Cloud Infrastructure, therefore don't try to run the app again before this time has elapsed. During development of your app you can ensure the device [always passes](https://approov.io/docs/latest/approov-usage-documentation/#adding-a-device-security-policy) so you do not have to register the APK each time you modify it.

[Managing Registrations](https://approov.io/docs/latest/approov-usage-documentation/#managing-registrations) provides more details for app registrations, especially for releases to the Play Store. Note that you may also need to apply specific [Android Obfuscation](https://approov.io/docs/latest/approov-usage-documentation/#android-obfuscation) rules for your app when releasing it.

## HANDLING REJECTIONS
If the app is not recognized as being valid by Approov then an `ApproovRejectionException` is thrown on the request and the API call is not completed. The secret value will never be communicated to the app in this case.

Your app should specifically catch this exception and provide some feedback to the user to explain why the app is not working. The `ApproovRejectionException` has a `arc` member which provides an [Attestation Response Code](https://approov.io/docs/latest/approov-usage-documentation/#attestation-response-code) which can provide more information about the status of the device, without revealing any details to the end user.

If you wish to provide more direct feedback then enable the [Rejection Reasons](https://approov.io/docs/latest/approov-usage-documentation/#rejection-reasons) feature:

```
approov policy -setRejectionReasons on
```

> Note that this command requires an [admin role](https://approov.io/docs/latest/approov-usage-documentation/#account-access-roles).

You will then be able to use the `rejectionReasons` member on an `ApproovRejectionException` to obtain a comma separated list of [device properties](https://approov.io/docs/latest/approov-usage-documentation/#device-properties) responsible for causing the rejection.

## FURTHER OPTIONS
See [Exploring Other Approov Features](https://approov.io/docs/latest/approov-usage-documentation/#exploring-other-approov-features) for information about additional Approov features you may wish to try.

### Header Prefixes
In some cases the value to be substituted on a header may be prefixed by some fixed string. A common case is the presence of `Bearer` included in an authorization header to indicate the use of a bearer token. In this case you can specify a prefix as follows:

```Dart
ApproovService.addSubstitutionHeader("Authorization", "Bearer ");
```

This causes the `Bearer` prefix to be stripped before doing the lookup for the substitution, and the `Bearer` prefix added to the actual secret value as part of the substitution.

### App Instance Secure Strings
As shown, it is possible to set predefined secret strings that are only communicated to passing apps. It is also possible to get and set secure string values for each app instance. These are never communicated to the Approov cloud service, but are encrypted at rest using keys which can only be retrieved by passing apps.

Here is an example of calling the appropriate method in `ApproovService`:

```Dart
String key;
String? newDef;
String? secret;
// define key and newDef here
try {
    secret = await ApproovService.fetchSecureString(key, newDef);
}
on ApproovRejectionException catch(e) {
    // failure due to the attestation being rejected, e.arc and e.rejectionReasons may be used
}
on ApproovNetworkException catch(e) {
    // failure due to a potentially temporary networking issue, allow for a user initiated retry
}
on ApproovException catch(e) {
    // a more permanent error, see e.cause
}
// use `secret` as required, but never cache or store its value - note `secret` will be null if it is not defined
```

to lookup a secure string with the given `key`, returning `null` if it is not defined. Note that you should never cache this value in your code. Approov does the caching for you in a secure way. You may define a new value for the `key` by passing a new value in `newDef` rather than `null`. An empty string `newDef` is used to delete the secure string.

This method is also useful for providing runtime secrets protection when the values are not passed on headers. Secure strings set using this method may also be looked up using subsequent networking interceptor header substitutions. 

### Prefetching
If you wish to reduce the latency associated with substituting the first secret, then construct an `ApproovClient` soon after app initialization (to provide the configuration string) and then call:

```Dart
ApproovService.prefetch()
```

This initiates the process of fetching the required information as a background task, so that it is available immediately when subsequently needed. Note the information will automatically expire after approximately 5 minutes.

### Prechecking
You may wish to do an early check in your to present a warning to the user if the app is not going to be able to access secrets because it fails the attestation process. Here is an example of calling the appropriate method in `ApproovService`:

```Dart
try {
    await ApproovService.precheck();
}
on ApproovRejectionException catch(e) {
    // failure due to the attestation being rejected, e.arc and e.rejectionReasons may be used to present information to the user
    // (note e.rejectionReasons is only available if the feature is enabled, otherwise it is always an empty string)
}
on ApproovNetworkException catch(e) {
    // failure due to a potentially temporary networking issue, allow for a user initiated retry
}
on ApproovException catch(e) {
   // a more permanent error, see e.cause
}
// app has passed the precheck
```

> Note you should NEVER use this as the only form of protection in your app, this is simply to provide an early indication of failure to your users as a convenience. You must always also have secrets essential to the operation of your app, or access to backend API services, protected with Approov. This is because, although the Approov attestation itself is heavily secured, it may be possible for an attacker to bypass its result or prevent it being called at all. When the app is dependent on the secrets protected, it is not possible for them to be obtained at all without passing the attestation.
