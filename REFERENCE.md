# Reference
This provides a reference for all of the static methods defined on `ApproovService`. These are available if you import:

```Dart
import 'package:approov_service_flutter_httpclient/approov_service_flutter_httpclient.dart';
```

Various methods may throw an `ApproovException` if there is a problem. The member `cause` provides a descriptive message.

If a method throws an `ApproovNetworkException` (a subclass of `ApproovException`) then this indicates the problem was caused by a networking issue, and a user initiated retry should be allowed.

If a method throws an `ApproovRejectionException` (a subclass of `ApproovException`) the this indicates the problem was that the app failed attestation. An additional member `arc` provides the [Attestation Response Code](https://approov.io/docs/latest/approov-usage-documentation/#attestation-response-code), which could be provided to the user for communication with your app support to determine the reason for failure, without this being revealed to the end user. The member `rejectionReasons` provides the [Rejection Reasons](https://approov.io/docs/latest/approov-usage-documentation/#rejection-reasons) if the feature is enabled, providing a comma separated list of reasons why the app attestation was rejected.

## initialize
Initializes the Approov SDK and thus enables the Approov features. The `config` will have been provided in the initial onboarding or email or can be [obtained](https://approov.io/docs/latest/approov-usage-documentation/#getting-the-initial-sdk-configuration) using the Approov CLI. 

```Dart
static Future<void> initialize(String config, [String? comment]) async
```

This will throw an `ApproovException` if a second attempt is made at initialization with a different `config`.

An optional `comment` parameter may also be provided to support [Reinitializing the SDK](https://approov.io/docs/latest/approov-direct-sdk-integration/#reinitializing-the-sdk).

## setProceedOnNetworkFail
If the provided `proceed` value is `true` then this indicates that the network interceptor should proceed anyway if it is not possible to obtain an Approov token due to a networking failure. If this is called then the backend API can receive calls without the expected Approov token header being added, or without header/query parameter substitutions being made. This should only ever be used if there is some particular reason, perhaps due to local network conditions, that you believe that traffic to the Approov cloud service will be particularly problematic.

```Dart
static void setProceedOnNetworkFail(bool proceed)
```

Note that this should be used with *CAUTION* because it may allow a connection to be established before any dynamic pins have been received via Approov, thus potentially opening the channel to a MitM.

## setDevKey
[Sets a development key](https://approov.io/docs/latest/approov-usage-documentation/#using-a-development-key) in order to force an app to be passed. This can be used if the app has to be resigned in a test environment and would thus fail attestation otherwise.

```Dart
static void setDevKey(String devKey) async
```

## setApproovHeader
Sets the `header` that the Approov token is added on, as well as an optional `prefix` String (such as "`Bearer `"). Set `prefix` to the empty string if it is not required. By default the token is provided on `Approov-Token` with no prefix.

```Dart
static void setApproovHeader(String header, String prefix)
```

## setBindingHeader
Sets a binding `header` that may be present on requests being made. This is for the [token binding](https://approov.io/docs/latest/approov-usage-documentation/#token-binding) feature. A header should be chosen whose value is unchanging for most requests (such as an Authorization header). If the `header` is present, then a hash of the `header` value is included in the issued Approov tokens to bind them to the value. This may then be verified by the backend API integration.

```Dart
static void setBindingHeader(String header)
```

## addSubstitutionHeader
Adds the name of a `header` which should be subject to [secure strings](https://approov.io/docs/latest/approov-usage-documentation/#secure-strings) substitution. This means that if the `header` is present then the value will be used as a key to look up a secure string value which will be substituted into the `header` value instead. This allows easy migration to the use of secure strings. A `requiredPrefix` may be specified to deal with cases such as the use of "`Bearer `" prefixed before values in an authorization header. Set `requiredPrefix` to `null` if it is not required.

```Dart
static void addSubstitutionHeader(String header, String? requiredPrefix)
```

## removeSubstitutionHeader
Removes a `header` previously added using `addSubstitutionHeader`.

```Dart
static void removeSubstitutionHeader(String header)
```

## substituteQueryParam
Substitutes the given `queryParameter` in the `uri` if it is present. If no substitution is made then the original `uri` is returned, otherwise a new one is constructed with the revised query parameter value. Since this modifies the `uri` itself this must be done before making the request. If it is not currently possible to fetch secure strings then an `ApproovException` will be thrown.

```Dart
static Future<Uri> substituteQueryParam(Uri uri, String queryParameter) async
```

## addExclusionURLRegex
Adds an exclusion URL [regular expression](https://regex101.com/) via the `urlRegex` parameter. If a URL for a request matches this regular expression then it will not be subject to any Approov protection.

```Dart
static void addExclusionURLRegex(String urlRegex)
```

Note that this facility must be used with *EXTREME CAUTION* due to the impact of dynamic pinning. Pinning may be applied to all domains added using Approov, and updates to the pins are received when an Approov fetch is performed. If you exclude some URLs on domains that are protected with Approov, then these will be protected with Approov pins but without a path to update the pins until a URL is used that is not excluded. Thus you are responsible for ensuring that there is always a possibility of calling a non-excluded URL, or you should make an explicit call to fetchToken if there are persistent pinning failures. Conversely, use of those option may allow a connection to be established before any dynamic pins have been received via Approov, thus potentially opening the channel to a MitM.

## removeExclusionURLRegex
Removes an exclusion URL regular expression (`urlRegex`) previously added using `addExclusionURLRegex`.

```Dart
static void removeExclusionURLRegex(String urlRegex)
```

## prefetch
Performs a fetch to lower the effective latency of a subsequent token fetch or secure string fetch by starting the operation earlier so the subsequent fetch may be able to use cached data. This initiates the prefetch in a background thread.

```Dart
static void prefetch() async
```

## precheck
Performs a precheck to determine if the app will pass attestation. This requires [secure strings](https://approov.io/docs/latest/approov-usage-documentation/#secure-strings) to be enabled for the account, although no strings need to be set up.

```Dart
static Future<void> precheck() async
```

This throws `ApproovException` if the precheck failed. 

## getDeviceID
Gets the [device ID](https://approov.io/docs/latest/approov-usage-documentation/#extracting-the-device-id) used by Approov to identify the particular device that the SDK is running on. Note that different Approov apps on the same device will return a different ID. Moreover, the ID may be changed by an uninstall and reinstall of the app. The function throws `ApproovException` if there was a problem.

```Dart
static Future<String> getDeviceID() async
```

This throws `ApproovException` if there was a problem obtaining the device ID.

## setDataHashInToken
Directly sets the [token binding](https://approov.io/docs/latest/approov-usage-documentation/#token-binding) hash to be included in subsequently fetched Approov tokens. If the hash is different from any previously set value then this will cause the next token fetch operation to fetch a new token with the correct payload data hash. The hash appears in the `pay` claim of the Approov token as a base64 encoded string of the SHA256 hash of the data. Note that the data is hashed locally and never sent to the Approov cloud service. This is an alternative to using `setBindingHeader` and you should not use both methods at the same time.

```Dart
static Future<void> setDataHashInToken(String data) async
```

This throws `ApproovException` if there was a problem changing the data hash.

## fetchToken
Performs an Approov token fetch for the given `url`. This should be used in situations where it is not possible to use the networking interception to add the token. Note that the returned token should NEVER be cached by your app, you should call this function when it is needed.

```Dart
static Future<String> fetchToken(String url) async
```

This throws `ApproovException` if there was a problem obtaining an Approov token.

## getAccountMessageSignature
Gets the [message signature](https://approov.io/docs/latest/approov-usage-documentation/#message-signing) for the given `message`. This is returned as a base64 encoded signature. This feature uses an account specific message signing key that is transmitted to the SDK after a successful fetch if the facility is enabled for the account. Note that if the attestation failed then the signing key provided is actually random so that the signature will be incorrect. An Approov token should always be included in the message being signed and sent alongside this signature to prevent replay attacks.

```Dart
static Future<String> getAccountMessageSignature(String message) async
```

This throws `ApproovException` if there was a problem obtaining a signature.

## fetchSecureString
Fetches a [secure string](https://approov.io/docs/latest/approov-usage-documentation/#secure-strings) with the given `key` if `newDef` is `null`. This returns `null` if the `key` has not been defined. If `newDef` is not `null` then a secure string for the particular app instance may be defined. In this case the new value is returned as the secure string. Use of an empty string for `newDef` removes the string entry. Note that the returned string should NEVER be cached by your app, you should call this function when it is needed.

```Dart
static Future<String?> fetchSecureString(String key, String? newDef) async
```

This throws `ApproovException` if there was a problem obtaining the secure string.

## fetchCustomJWT
Fetches a [custom JWT](https://approov.io/docs/latest/approov-usage-documentation/#custom-jwts) with the given marshaled JSON `payload`.

```Dart
static Future<String> fetchCustomJWT(String payload) async
```

This throws `ApproovException` if there was a problem obtaining the custom JWT.

## getLastARC
Obtains the last [Attestation Response Code](https://ext.approov.io/docs/latest/approov-usage-documentation/#attestation-response-code) provided a network request to the Approov servers has succeeded.

```Dart
static Future<String> getLastARC() async
```
The `ARC` code is useful to correlate a particular request rejection from your back end API due to Approov issuing an invalid JWT token. In the event of no network available this function returns an empty string. This function should be used with *CAUTION* and instead rely on a customized error response from the server which includes the `ARC` code if one is available. 

## getPins
Fetches the pins from the current configuration of the SDK. This is returned as a map from URL domain (hostname only) to the possible pins for that domain. If there is no map entry for a domain then that indicates that the connection is not specifically pinned, or managed trust roots should be used if they are present (keyed from the "*" domain). The type of pin requested determines the data in each of the pins. This is typically the base64 encoding of the hash of some aspect of the certificate. A connection is considered to be valid if any certificate in the chain presented is one with the same hash as one in the array of hashes.

```Dart
static Future<Map> getPins(String pinType) async
```

