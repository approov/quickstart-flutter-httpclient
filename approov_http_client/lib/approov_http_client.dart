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
import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:crypto/crypto.dart';
import 'package:collection/collection.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart' as httpio;
import 'package:logger/logger.dart';
import 'package:pem/pem.dart';
import 'package:shared_preferences/shared_preferences.dart';


// logger
final Logger Log = Logger();


/// Potential status results from an attempt to fetch an Approov token
enum TokenFetchStatus {
  SUCCESS, // token was successfully received
  NO_NETWORK, // there is no token because there is no network connectivity currently
  MITM_DETECTED, // there is no token because there is a Man-In-The-Middle (MITM) to the Approov cloud service
  POOR_NETWORK, // no token could be obtained due to poor network connectivity
  NO_APPROOV_SERVICE, // no token could be obtained, perhaps because Approov services are down
  BAD_URL, // provided URL was not https or otherwise in the correct format
  UNKNOWN_URL, // provided URL is not one that one configured for Approov
  UNPROTECTED_URL, // provided URL does not need an Approov token
  NO_NETWORK_PERMISSION, // app does not have ACCESS_NETWORK_STATE or INTERNET permission
  MISSING_LIB_DEPENDENCY, // app is missing a needed library dependency
  INTERNAL_ERROR // there has been an internal error in the SDK
}


/// Results from an Approov token fetch
class TokenFetchResult {
  // Status of the last Approov token fetch
  TokenFetchStatus tokenFetchStatus = TokenFetchStatus.INTERNAL_ERROR;
  // Token string of the last Approov token fetch. This may be an empty string if the fetch did not succeed
  String token = "";
  // An Attestation Response Code (ARC) providing details of the device properties. This is the empty string if no ARC
  // was obtained.
  String ARC = "";
  // Indicates whether a new configuration is available from fetchConfig()
  bool isConfigChanged = false;
  // Indicates whether current user APIs must be updated to reflect a new version available from getPins(). Calling
  // getPins() will clear this flag for the next Approov token fetch.
  bool isForceApplyPins = false;
  // Measurement configuration if the last token fetch was to perform an integrity measurement and was successful.
  Uint8List measurementConfig = Uint8List(0);
  // Loggable Approov token string.
  String loggableToken = "";

  // Convenience constructor
  TokenFetchResult.fromTokenFetchResultMap(Map aTokenFetchResultMap) {
    TokenFetchStatus? newTokenFetchStatus =
      EnumToString.fromString(TokenFetchStatus.values, aTokenFetchResultMap["TokenFetchStatus"]);
    if (newTokenFetchStatus != null)
      tokenFetchStatus = newTokenFetchStatus;
    token = aTokenFetchResultMap["Token"];
    ARC = aTokenFetchResultMap["ARC"];
    isConfigChanged = aTokenFetchResultMap["IsConfigChanged"];
    isForceApplyPins = aTokenFetchResultMap["IsForceApplyPins"];
    Uint8List? newMeasurementConfig = aTokenFetchResultMap["MeasurementConfig"];
    if (newMeasurementConfig != null)
      measurementConfig = newMeasurementConfig;
    loggableToken = aTokenFetchResultMap["LoggableToken"];
  }
}


// Approov Service (SDK and utilities) TODO comment
class ApproovService {
  static const MethodChannel _channel = const MethodChannel('approov_http_client');

  /// Initialize the Approov SDK. This must be called prior to any other methods on the Approov SDK. The SDK is
  /// initialized with a base configuration and an optional update configuration and comment. The base configuration is
  /// a signed JWT token string that is obtained from the Approov administration portal and contains all necessary
  /// parameters to initialize the SDK.
  ///
  /// @param initialConfig is the initial configuration string and must be present
  /// @param dynamicConfig is any dynamic update configuration string or null if there is none
  /// @param reserved is provided for future usage
  /// @throws Exception if the provided configuration is not valid
  static Future<void> initialize(String initialConfig, String? dynamicConfig, String? reserved) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "initialConfig": initialConfig,
      "dynamicConfig": dynamicConfig,
      "comment": reserved,
    };
    try {
      await _channel.invokeMethod('initialize', arguments);
      isInitialized = true;
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Fetches the current configuration for the SDK. Normally this method returns the latest configuration that is
  /// available and is cached in the SDK. Thus the method will return quickly. However, if this method is called when
  /// there has been no prior call to fetch an Approov token then a network request to the Approov cloud service will be
  /// made to obtain any latest configuration update. The maximum timeout period is set to be quite short but the caller
  /// must be aware that this delay may occur.
  ///
  /// @return String representation of the configuration.
  static Future<String> fetchConfig() async {
    try {
      await ensureInitialized();
      String config = await _channel.invokeMethod('fetchConfig');
      return config;
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Gets the device ID used by Approov to identify the particular device that the SDK is running on. Note that
  /// different Approov apps on the same device will return a different ID. Moreover, the ID may be changed by an
  /// uninstall and reinstall of the app.
  ///
  /// @return String representation of the device ID.
  static Future<String> getDeviceID() async {
    try {
      await ensureInitialized();
      String deviceID = await _channel.invokeMethod('getDeviceID');
      return deviceID;
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Fetches the pins from the current configuration of the SDK. This is returned as a map from URL domain (hostname
  /// only) to the possible pins for that domain. If there is no map entry for a domain then that indicates that the
  /// connection is not specifically pinned. The type of pin requested determines the data in each of the pins. This is
  /// typically the base64 encoding of the hash of some aspect of the certificate. A connection is considered to be
  /// valid if any certificate in the chain presented is one with the same hash as one in the array of hashes. Note that
  /// if the isForceApplyPins flag was set on the last Approov token fetch then this clears the flag for future fetches
  /// as it indicates that the latest pin information has been read.
  ///
  /// @param pinType is the type of pinning information that is required
  /// @return Map from domain to the list of strings providing the pins
  static Future<Map/*<String, List<String> >*/ > getPins(String pinType) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "pinType": pinType,
    };
    try {
      await ensureInitialized();
      Map/*<String, List<String>>*/ pins = await _channel.invokeMethod('getPins', arguments);
      return pins;
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Initiates a request to obtain an Approov token and other results. If an Approov token fetch has been completed
  /// previously and the tokens are unexpired then this may return the same one without a need to perform a network
  /// transaction.
  /// Note though that the caller should never cache the Approov token as it may become invalidated at any point.
  ///
  /// If a new Approov token is required then a more extensive app measurement is performed that involves communicating
  /// with the Approov cloud service. Thus this method may take up to several seconds to complete. There is also a
  /// chance that due to poor network connectivity or other factors an Approov token cannot be obtained, and this is
  /// reflected in the returned status.
  ///
  /// All calls must provide a URL which provides the high level domain of the API to which the Approov token is going
  /// to be sent. Different API domains will have different Approov tokens associated with them so it is important that
  /// the Approov token is only sent to requests for that domain. If the domain has not been configured in the Approov
  /// admin portal then an error is obtained.
  ///
  /// @param url provides the top level domain URL for which a token is being fetched
  /// @return results of fetching a token
  static Future<TokenFetchResult> fetchApproovToken(String url) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "url": url,
    };
    try {
      await ensureInitialized();
      Map tokenFetchResultMap = await _channel.invokeMethod('fetchApproovTokenAndWait', arguments);
      return TokenFetchResult.fromTokenFetchResultMap(tokenFetchResultMap);
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Sets a hash of the given data value into any future Approov tokens obtained in the 'pay' claim. If the data values
  /// are transmitted to the API backend along with the Approov token then this allows the backend to check that the
  /// data value was indeed known to the app at the time of the token fetch and hasn't been spoofed. If the data is the
  /// same as any previous one set then the token does not need to be updated.
  /// Otherwise the next token fetch causes a new attestation to fetch a new token. Note that this should not be done
  /// frequently due to the additional latency on token fetching that will be caused. The hash appears in the 'pay'
  /// claim of the Approov token as a base64 encoded string of the SHA256 hash of the data. Note that the data is hashed
  /// locally and never sent to the Approov cloud service.
  ///
  /// @param data is the data whose SHA256 hash is to be included in future Approov tokens
  static Future<void> setDataHashInToken(String data) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "data": data,
    };
    try {
      await ensureInitialized();
      await _channel.invokeMethod('setDataHashInToken', arguments);
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Obtains an integrity measurement proof that is used to show that the app and its environment have not changed
  /// since the time of the original integrity measurement.
  /// The proof does an HMAC calculation over the secret integrity measurement value which is salted by a provided
  /// nonce. This proves that the SDK is able to reproduce the integrity measurement value.
  ///
  /// @param nonce is a 16-byte (128-bit) nonce value used to salt the proof HMAC
  /// @param measurementConfig is the measurement configuration obtained from a previous token fetch results
  /// @return 32-byte (256-bit) measurement proof value
  static Future<Uint8List> getIntegrityMeasurementProof(Uint8List nonce, Uint8List measurementConfig) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "nonce": nonce,
      "measurementConfig": measurementConfig,
    };
    try {
      await ensureInitialized();
      Uint8List integrityMeasurementProof = await _channel.invokeMethod('getIntegrityMeasurementProof', arguments);
      return integrityMeasurementProof;
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Obtains a device measurement proof that is used to show that the device environment has not changed since the time
  /// of the original integrity measurement. This allows the app version, including the Approov SDK, to be updated while
  /// preserving the device measurement. The proof does an HMAC calculation over the secret device measurement value
  /// which is salted by a provided nonce. This proves that the SDK is able to reproduce the device measurement value.
  ///
  /// @param nonce is a 16-byte (128-bit) nonce value used to salt the proof HMAC
  /// @param measurementConfig is the measurement configuration obtained from a previous token fetch results
  /// @return 32-byte (256-bit) measurement proof value
  static Future<Uint8List> getDeviceMeasurementProof(Uint8List nonce, Uint8List measurementConfig) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "nonce": nonce,
      "measurementConfig": measurementConfig,
    };
    try {
      await ensureInitialized();
      Uint8List deviceMeasurementProof = await _channel.invokeMethod('getDeviceMeasurementProof', arguments);
      return deviceMeasurementProof;
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Gets the signature for the given message. This uses an account specific message signing key that is
  /// transmitted to the SDK after a successful token fetch if the facility is enabled for the account and
  /// the token is received from the primary (rather than failover) Approov cloud. Note
  /// that if the attestation failed then the signing key provided is actually random so that the
  /// signature will be incorrect. An Approov token should always be included in the message
  /// being signed and sent alongside this signature to prevent replay attacks.
  ///
  /// @param the message for which to et the signature
  /// @return base64 encoded signature of the message, or null if no signing key is available
  static Future<String> getMessageSignature(String message) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "message": message,
    };
    try {
      await ensureInitialized();
      String messageSignature = await _channel.invokeMethod('getMessageSignature', arguments);
      return messageSignature;
    } catch (err) {
      throw Exception('$err');
    }
  }

  /// Sets a user defined property on the SDK. This may provide information about the
  /// app state or aspects of the environment it is running in. This has no direct
  /// impact on Approov except it is visible as a property on attesting devices and
  /// can be analyzed using device filters. Note that properties longer than 128
  /// characters are ignored and all non ASCII characters are removed.
  ///
  /// @param property to be set, which may be null
  static Future<void> setUserProperty(String property) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "property": property,
    };
    try {
      await ensureInitialized();
      await _channel.invokeMethod('setUserProperty', arguments);
    } catch (err) {
      throw Exception('$err');
    }
  }

  // logging tag
  static const String TAG = "ApproovService";

  // keys for the Approov shared preferences
  static const String APPROOV_CONFIG = "approov-config";
  static const String APPROOV_PREFS = "approov-prefs";

  // header that will be added to Approov enabled requests
  static const String APPROOV_HEADER = "Approov-Token";
  static const String X_APPROOV_HEADER = "X-Approov-Token";

  // any prefix to be added before the Approov token, such as "Bearer "
  static const String APPROOV_TOKEN_PREFIX = "";

  // Indicates whether Approov-Flutter has been initialized
  static bool isInitialized = false;

  // any header to be used for binding in Approov tokens or null if not set
  // TODO why is this not static in other integrations?
  static String? bindingHeader; // TODO? Make this client-specific

  /// Initializes Approov-Flutter.
  ///
  /// @param context the Application context
  /// @param config the initial service config string
  static Future<void> ensureInitialized() async {
    if (isInitialized) {
      return;
    }
    WidgetsFlutterBinding.ensureInitialized();
    String initialConfig;
    try {
      initialConfig = await rootBundle.loadString('approov-initial.config');
    } catch (e) {
      // It is fatal if the SDK cannot read an initial configuration
      Log.e("$TAG: Approov initial configuration read failed: ${e.toString()}");
      return;
    }
    String? dynamicConfig = await getApproovDynamicConfig();
    // initialize the Approov SDK
    try {
      await initialize(initialConfig, dynamicConfig, null);
      isInitialized = true;
    } catch (e) {
      Log.e("$TAG:  Approov initialization failed: ${e.toString()}");
      return;
    }

    // if we didn't have a dynamic configuration (after the first launch on the app) then we fetch the latest and write
    // it to local storage now
    if (dynamicConfig == null) {
      updateDynamicConfig();
    }
  }

  /// Prefetches an Approov token in the background. The placeholder domain "www.approov.io" is simply used to initiate
  /// the fetch and does not need to be a valid API for the account. This method can be used to lower the effective
  /// latency of a subsequent token fetch by starting the operation earlier so the subsequent fetch may be able to use a
  /// cached token.
  void prefetchApproovToken() async {
    TokenFetchResult result = await ApproovService.fetchApproovToken("www.approov.io");
    if (result.tokenFetchStatus == TokenFetchStatus.UNKNOWN_URL)
      Log.i("$TAG: Approov prefetch success");
    else
      Log.i("$TAG: Approov prefetch failure: ${result.tokenFetchStatus.toString()}");
  }

  /// Writes the latest dynamic configuration that the Approov SDK has.
  static void updateDynamicConfig() async {
    Log.i("$TAG: Approov dynamic configuration updated");
    putApproovDynamicConfig(await fetchConfig());
  }

  /// Stores an application's dynamic configuration string in non-volatile storage.
  ///
  /// The default implementation stores the string in shared preferences, and setting the config string to null is
  /// equivalent to removing the config.
  ///
  /// @param config a config string
  static void putApproovDynamicConfig(String config) {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(APPROOV_CONFIG, config);
    });
  }

  /// Returns the application's dynamic configuration string from non-volatile storage.
  ///
  /// The default implementation retrieves the string from shared preferences.
  ///
  /// @return config string, or null if not present
  static Future<String?> getApproovDynamicConfig() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? dynamicConfig = prefs.getString(APPROOV_CONFIG);
    return dynamicConfig;
  }

  /// Sets a binding header that must be present on all requests using the Approov service. A
  /// header should be chosen whose value is unchanging for most requests (such as an
  /// Authorization header). A hash of the header value is included in the issued Approov tokens
  /// to bind them to the value. This may then be verified by the backend API integration. This
  /// method should typically only be called once.
  ///
  /// @param header is the header to use for Approov token binding
  static void setBindingHeader(String header) {
    bindingHeader = header;
  }

  /// Adds Approov to the given request by adding the Approov token in a header. If a binding header has been specified
  /// then this should be available. If it is not currently possible to fetch an Approov token (typically due to no or
  /// poor network) then an exception is thrown and a later retry should be made.
  ///
  /// @param request is the HttpClientRequest to which Approov is being added
  /// @throws Exception if it is not possible to obtain an Approov token
  static Future<void> addApproovToHttpClientRequest(HttpClientRequest request, {String approovHeader = APPROOV_HEADER}) async {
    // just return if we couldn't initialize the SDK
    if (!isInitialized) {
      Log.e("$TAG: Cannot add Approov due to initialization failure");
      return;
    }

    // update the data hash based on any token binding header
    String? bh = bindingHeader;
    if (bh != null) {
      String? headerValue = request.headers.value(bh);
      if (headerValue == null) throw Exception("Approov missing token binding header: " + bh);
      setDataHashInToken(headerValue);
    }

    // request an Approov token for the domain
    String host = request.uri.host;
    TokenFetchResult approovResults = await fetchApproovToken(host);

    // provide information about the obtained token or error (note "approov token -check" can
    // be used to check the validity of the token and if you use token annotations they
    // will appear here to determine why a request is being rejected)
    Log.i("$TAG: Approov Token for $host: ${approovResults.loggableToken}");

    // update any dynamic configuration
    if (approovResults.isConfigChanged) {
      updateDynamicConfig();
      removeAllCertificates();
    }

    // check the status of Approov token fetch
    if (approovResults.tokenFetchStatus == TokenFetchStatus.SUCCESS) {
      // we successfully obtained a token so add it to the header for the request
      request.headers.set(approovHeader, APPROOV_TOKEN_PREFIX + approovResults.token, preserveHeaderCase: true);
    } else if ((approovResults.tokenFetchStatus != TokenFetchStatus.NO_APPROOV_SERVICE) &&
        (approovResults.tokenFetchStatus != TokenFetchStatus.UNKNOWN_URL) &&
        (approovResults.tokenFetchStatus != TokenFetchStatus.UNPROTECTED_URL)) {
      // we have failed to get an Approov token in such a way that there is no point in proceeding
      // with the request - generally a retry is needed, unless the error is permanent
      throw Exception("Approov token fetch failed: " + approovResults.tokenFetchStatus.toString());
    }
  }

  // The cached host certificates
  static Map<String, List<Uint8List>?> _hostCertificates = Map<String, List<Uint8List>>();

  /// Retrieves the certificates for the specified host. These are cached in the native part of the Flutter-Approov
  /// plugin, so normally do not require communication over the network to retrieve them.
  ///
  /// @param host is the URL specifying the host for which to retrieve the certificates (e.g. "www.example.com")
  /// @return a list of certificates (each as a Uint8list) for the host specified in the URL, null if an error occurred,
  /// or an empty list if no suitable certificates are available.
  static Future<List<Uint8List>?> getHostCertificates(Uri url) async {
    final Map<String, dynamic> arguments = <String, dynamic>{
      "url": url.toString(),
    };
    List<Uint8List>? hostCertificates = _hostCertificates[url.host];
    if (hostCertificates == null) {
      try {
        List fetchedHostCertificates = await _channel.invokeMethod('fetchHostCertificates', arguments);
        if (fetchedHostCertificates != null && fetchedHostCertificates.length != 0) {
          hostCertificates = [];
          for (final cert in fetchedHostCertificates) {
            hostCertificates.add(cert as Uint8List);
          }
          // Cache the host certificates
          _hostCertificates[url.host] = hostCertificates;
        }
      } catch (err) {
        // Do not throw an exception, but let the function return null
      }
    }
    return hostCertificates;
  }

  /// Removes the certificates for the specified host from the cache in the native part of the Flutter-Approov plugin.
  /// This causes them to be retrieved over the network the next time getCertificates() is called.
  ///
  /// @param host is the host for which to remove the certificates (e.g. "www.example.com")
  static Future<void> removeCertificates(String host) async {
    _hostCertificates[host] = null;
  }

  /// Removes all certificates from the cache in the native part of the Flutter-Approov plugin. This is required when
  /// the Approov pins change.
  static Future<void> removeAllCertificates() async {
    _hostCertificates.clear();
  }

  /// Create a security context that enforces pinning to host certificates whose SPKI SHA256 digest match an Approov
  /// pin. If no certificates match, the security context does not contain any host certificates and creating a TLS
  /// connection to the host will fail.
  ///
  /// @param host is the name of the host
  /// @param approovPins is the set of pins for the host as configured in Approov
  /// @return a security context that enforces pinning by using the host certificates that match the pins set in Approov
  static Future<SecurityContext> approovSecurityContext(Uri url, Set<String> approovPins) async {
    // Determine the list of X.509 ASN.1 DER host certificates that match any Approov pins for the host
    List<Uint8List> pinCerts = await ApproovService._hostPinCertificates(url, approovPins);
    // Add the certificates to the security context
    SecurityContext securityContext = SecurityContext(withTrustedRoots: false);
    if (Platform.isAndroid) {
      // On Android add the entire list of certificates at once
      String pemCertificates = "";
      for (final pinCert in pinCerts) {
        String pemCertificate = PemCodec(PemLabel.certificate).encode(pinCert);
        pemCertificates += pemCertificate;
      }
      Uint8List pemCertificatesBytes = AsciiEncoder().convert(pemCertificates);
      securityContext.setTrustedCertificatesBytes(pemCertificatesBytes);
    } else if (Platform.isIOS) {
      // On iOS certificates have to be added one by one. TODO Link
      for (final pinCert in pinCerts) {
        String pemCertificate = PemCodec(PemLabel.certificate).encode(pinCert);
        Uint8List pemCertificatesBytes = AsciiEncoder().convert(pemCertificate);
        securityContext.setTrustedCertificatesBytes(pemCertificatesBytes);
      }
    }
    return securityContext;
  }

  /// Gets all certificates of a host that match the Approov pins for that host. A match is determined by comparing
  /// the certificate's SPKI's SHA256 digest with the Approov pins.
  ///
  /// @param host is the name of the host
  /// @param approovPins is the set of pins for the host as configured in Approov
  /// @return a list of host certificates that match the Approov pins
  static Future<List<Uint8List>> _hostPinCertificates(Uri url, Set<String> approovPins) async {
    // Get certificates for host
    List<Uint8List> hostCertificates = await ApproovService.getHostCertificates(url) as List<Uint8List>;
    if (hostCertificates == null) {
      Log.e("$TAG: Cannot get certificates for host of URL $url");
      return [];
    }

    // Collect only those certificates for pinning that match the Approov pins
    List<Uint8List> hostPinCerts = [];
    for (final cert in hostCertificates) {
      Uint8List serverSpkiSha256Digest = Uint8List.fromList(_spkiSha256Digest(cert).bytes);
      for (final pin in approovPins) {
        if (ListEquality().equals(base64.decode(pin), serverSpkiSha256Digest)) {
          hostPinCerts.add(cert);
        }
      }
    }
    return hostPinCerts;
  }

  /// Computes the SHA256 digest of the Subject Public Key Info (SPKI) of an ASN1.DER encoded certificate
  ///
  /// @param certificate for which to compute the SPKI digest
  /// @return the SHA256 digest of the certificate's SPKI
  static Digest _spkiSha256Digest(Uint8List certificate) {
    ASN1Parser asn1Parser = ASN1Parser(certificate);
    ASN1Sequence signedCert = asn1Parser.nextObject() as ASN1Sequence;
    ASN1Sequence cert = signedCert.elements[0] as ASN1Sequence;
    ASN1Sequence spki = cert.elements[6] as ASN1Sequence;
    Digest spkiDigest = sha256.convert(spki.encodedBytes);
    return spkiDigest;
  }
}


// ApproovHttpClient is a drop-in replacement for the Dart IO library's HttpClient.
// If Approov is configured to protect an API on a host, then an ApproovHTTPClient will automatically set up pinning and
// add relevant headers for a request. Otherwise the behaviour of ApproovHttpClient is the same as for the Dart IO
// library's HttpClient.
class ApproovHttpClient implements HttpClient {
  // logging tag
  static const String TAG = "ApproovHttpClient";

  // The name of the header used for transmitting the Approov token
  String? _approovHeader = null;

  // Set the name of the header used for transmitting the Approov token
  // @param header the name of the header. Only Approov-Token or X-Approov-Token are allowed.
  void set approovHeader(String header) {
    if (header != ApproovService.APPROOV_HEADER && header != ApproovService.X_APPROOV_HEADER) {
      throw "ApproovHttpClient: Approov header must be ${ApproovService.APPROOV_HEADER} or"
          " ${ApproovService.X_APPROOV_HEADER}";
    }
    if (_approovHeader != null) {
      throw "ApproovClient: Must not change Approov header after sending request";
    }
    _approovHeader = header;
  }

  // Internal HttpClient delegate, will be rebuilt if pinning fails (or pins change)
  HttpClient _inner = HttpClient();

  // The host to which the inner HttpClient delegate is connected and, optionally, pinning. Used to detect when to
  // re-create the inner HttpClient.
  String? _connectedHost;

  // Indicates whether the ApproovHttpClient has been closed by calling close().
  bool _isClosed = false;

  // State required to implement getters and setters required by the HttpClient interface
  Future<bool> Function(Uri url, String scheme, String realm)? _authenticate;
  final List _credentials = [];
  String Function(Uri url)? _findProxy;
  Future<bool> Function(String host, int port, String scheme, String realm)? _authenticateProxy;
  final List _proxyCredentials = [];
  bool Function(X509Certificate cert, String host, int port)? _badCertificateCallback;

  /// Certificate check function for the badCertificateCallback of HttpClient. This is called if the pinning
  /// certificate check failed, which can indicate a certificate update on the server or a Man-in-the-Middle (MitM)
  /// attack.
  /// Invalidates the certificates for the given host so they will be refreshed and the communication with the server
  /// can be re-established for the case of a certificate update. Returns false to prevent the request to be sent for
  /// the case of a MitM attack.
  ///
  /// @param cert is the certificate which could not be authenticated
  /// @param host is the host name of the server to which the request is being sent
  /// @param port is the port of the server
  bool certificateCheck(X509Certificate cert, String host, int port) {
    Function(X509Certificate cert, String host, int port)? badCertificateCallback = _badCertificateCallback;
    if (badCertificateCallback != null) {
      // Call the original function for its side effects
      badCertificateCallback(cert, host, port);
    }

    // Reset host certificates and inner HttpClient to force them to be recreated
    ApproovService.removeCertificates(host);
    _connectedHost = null;
    return false;
  }

  /// Create an HTTP client with pinning enabled for the given host if so configured in Approov. The state for the new
  /// HTTP client is copied from the current inner delegate.
  ///
  /// @param host for which to set up pinning
  /// @return the new HTTP client
  Future<HttpClient> _createApproovHttpClient(Uri url) async {
    // Get pins from Approov
    Map pins = await ApproovService.getPins("public-key-sha256");

    HttpClient? httpClient;
    if (pins == null || pins[url.host] == null || (pins[url.host] as List).isEmpty) {
      // There are no pins set in Approov. This client does not check pinning
      httpClient = HttpClient();
    }

    if (httpClient == null) {
      // Create HttpClient with pinning enabled
      Set<String> approovPins = HashSet();
      for (final pin in pins[url.host]) {
        approovPins.add(pin);
      }
      SecurityContext securityContext = await ApproovService.approovSecurityContext(url, approovPins);
      httpClient = HttpClient(context: securityContext);
    }

    _connectedHost = url.host;

    // Copy state from previous inner HttpClient to the new one
    HttpClient? inner = _inner;
    if (inner != null) {
      httpClient.idleTimeout = inner.idleTimeout;
      httpClient.connectionTimeout = inner.connectionTimeout;
      httpClient.maxConnectionsPerHost = inner.maxConnectionsPerHost;
      httpClient.autoUncompress = inner.autoUncompress;
      httpClient.authenticate = _authenticate;
      for (var credential in _credentials) {
        httpClient.addCredentials(credential[0], credential[1], credential[2]);
      }
      httpClient.findProxy = _findProxy;
      httpClient.authenticateProxy = _authenticateProxy;
      for (var proxyCredential in _proxyCredentials) {
        httpClient.addProxyCredentials(
            proxyCredential[0], proxyCredential[1], proxyCredential[2], proxyCredential[3]);
      }
      httpClient.badCertificateCallback = certificateCheck;
    }
    return httpClient;
  }

  @override
  Future<HttpClientRequest> open(String method, String host, int port, String path) async {
    if (!_isClosed && _connectedHost != host) {
      Uri url = Uri(scheme: "https", host: host, port: port, path: path);
      HttpClient httpClient = await _createApproovHttpClient(url);
      _inner.close();
      _inner = httpClient;
    }
    HttpClientRequest httpClientRequest = await _inner.open(method, host, port, path);
    if (!_isClosed) {
      String? approovHeader = _approovHeader;
      if (approovHeader == null)
        approovHeader = ApproovService.APPROOV_HEADER;
      await ApproovService.addApproovToHttpClientRequest(httpClientRequest, approovHeader: approovHeader);
    }
    return httpClientRequest;
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    if (!_isClosed && _connectedHost != url.host) {
      HttpClient httpClient = await _createApproovHttpClient(url);
      _inner.close();
      _inner = httpClient;
    }
    HttpClientRequest httpClientRequest = await _inner.openUrl(method, url);
    if (!_isClosed) {
      String? approovHeader = _approovHeader;
      if (approovHeader == null)
        approovHeader = ApproovService.APPROOV_HEADER;
      await ApproovService.addApproovToHttpClientRequest(httpClientRequest, approovHeader: approovHeader);
    }
    return httpClientRequest;
  }

  @override
  Future<HttpClientRequest> get(String host, int port, String path) => open("get", host, port, path);

  @override
  Future<HttpClientRequest> getUrl(Uri url) => openUrl("get", url);

  @override
  Future<HttpClientRequest> post(String host, int port, String path) => open("post", host, port, path);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => openUrl("post", url);

  @override
  Future<HttpClientRequest> put(String host, int port, String path) => open("put", host, port, path);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => openUrl("put", url);

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) => open("delete", host, port, path);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => openUrl("delete", url);

  @override
  Future<HttpClientRequest> head(String host, int port, String path) => open("head", host, port, path);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => openUrl("head", url);

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) => open("patch", host, port, path);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => openUrl("patch", url);

  @override
  set idleTimeout(Duration timeout) => _inner.idleTimeout = timeout;
  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set connectionTimeout(Duration? timeout) => _inner.connectionTimeout = timeout;
  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set maxConnectionsPerHost(int? maxConnections) => _inner.maxConnectionsPerHost = maxConnections;
  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set autoUncompress(bool autoUncompress) => _inner.autoUncompress = autoUncompress;
  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set userAgent(String? userAgent) => _inner.userAgent = userAgent;
  @override
  String? get userAgent => _inner.userAgent;

  @override
  set authenticate(Future<bool> f(Uri url, String scheme, String realm)?) {
    _authenticate = f;
    _inner.authenticate = f;
  }

  @override
  void addCredentials(Uri url, String realm, HttpClientCredentials credentials) {
    _credentials.add({url, realm, credentials});
    _inner.addCredentials(url, realm, credentials);
  }

  @override
  set findProxy(String f(Uri url)?) {
    _findProxy = f;
    _inner.findProxy = f;
  }

  @override
  set authenticateProxy(Future<bool> f(String host, int port, String scheme, String realm)?) {
    _authenticateProxy = f;
    _inner.authenticateProxy = f;
  }

  @override
  void addProxyCredentials(String host, int port, String realm, HttpClientCredentials credentials) {
    _proxyCredentials.add({host, port, realm, credentials});
    _inner.addProxyCredentials(host, port, realm, credentials);
  }

  @override
  set badCertificateCallback(bool callback(X509Certificate cert, String host, int port)?) {
    _badCertificateCallback = callback;
    _inner.badCertificateCallback = certificateCheck;
  }

  @override
  void close({bool force: false}) async {
    if (_inner != null) {
      _inner.close(force: force);
      _isClosed = true;
    }
  }
}


// Approov client is a drop-in replacement for Client from the Flutter http package (https://pub.dev/packages/http).
// This class is designed to be composable. This makes it easy for external libraries to work with one another to add
// behavior to it. Libraries wishing to add behavior should create a subclass of BaseClient that wraps an ApproovClient
// and adds the desired behavior.
class ApproovClient extends http.BaseClient {
  // Internal client delegate
  http.Client? _inner;

  // The name of the header used for transmitting the Approov token
  String _approovHeader = ApproovService.APPROOV_HEADER;

  // Set the name of the header used for transmitting the Approov token
  // @param header the name of the header. Only Approov-Token or X-Approov-Token are allowed.
  void set approovHeader(String header) {
    if (header != ApproovService.APPROOV_HEADER && header != ApproovService.X_APPROOV_HEADER) {
      throw "ApproovClient: Approov header must be ${ApproovService.APPROOV_HEADER} or"
          " ${ApproovService.X_APPROOV_HEADER}";
    }
    if (_inner != null) {
      throw "ApproovClient: Must not change Approov header after sending request";
    }
    _approovHeader = header;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    http.Client? inner = _inner;
    if (inner == null) {
      ApproovHttpClient httpClient = ApproovHttpClient();
      httpClient.approovHeader = _approovHeader;
      inner = httpio.IOClient(httpClient);
      _inner = inner;
    }
    return inner.send(request);
  }

  @override
  void close() {
    http.Client? inner = _inner;
    if (inner != null) {
      inner.close();
      _inner = null;
    }
  }
}
