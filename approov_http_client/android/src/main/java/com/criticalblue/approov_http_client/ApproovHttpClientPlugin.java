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

package com.criticalblue.approov_http_client;

import android.content.Context;

import com.criticalblue.approovsdk.Approov;

import java.net.URL;
import java.security.cert.Certificate;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import javax.net.ssl.HttpsURLConnection;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


/** ApproovHttpClientPlugin */
public class ApproovHttpClientPlugin implements FlutterPlugin, MethodCallHandler {

  /// The MethodChannel for the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  // Connect timeout (in ms) for host certificate fetch
  private static final int FETCH_CERTIFICATES_TIMEOUT_MS = 3000;

  // Application context passed to Approov initialization
  private static Context appContext;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "approov_http_client");
    channel.setMethodCallHandler(this);
    appContext = flutterPluginBinding.getApplicationContext();
  }

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  public static void registerWith(Registrar registrar) {
    final MethodChannel channel = new MethodChannel(registrar.messenger(), "approov_http_client");
    channel.setMethodCallHandler(new ApproovHttpClientPlugin());
    appContext = registrar.context();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("initialize")) {
      try {
        Approov.initialize(appContext, call.argument("initialConfig"), call.argument("dynamicConfig"),
          call.argument("comment"));
        result.success(null);
      } catch(Exception e) {
        result.error("Approov.initialize", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("fetchConfig")) {
      try {
        result.success(Approov.fetchConfig());
      } catch(Exception e) {
        result.error("Approov.fetchConfig", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("getDeviceID")) {
      try {
        result.success(Approov.getDeviceID());
      } catch(Exception e) {
        result.error("Approov.getDeviceID", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("getPins")) {
      try {
        result.success(Approov.getPins((String) call.argument("pinType")));
      } catch(Exception e) {
        result.error("Approov.getPins", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("fetchApproovTokenAndWait")) {
      try {
        Approov.TokenFetchResult tokenFetchResult = Approov.fetchApproovTokenAndWait(call.argument("url"));
        HashMap<String, Object> tokenFetchResultMap = new HashMap<>();
        tokenFetchResultMap.put("TokenFetchStatus", tokenFetchResult.getStatus().toString());
        tokenFetchResultMap.put("Token", tokenFetchResult.getToken());
        tokenFetchResultMap.put("ARC", tokenFetchResult.getARC());
        tokenFetchResultMap.put("IsConfigChanged", tokenFetchResult.isConfigChanged());
        tokenFetchResultMap.put("IsForceApplyPins", tokenFetchResult.isForceApplyPins());
        tokenFetchResultMap.put("MeasurementConfig", tokenFetchResult.getMeasurementConfig());
        tokenFetchResultMap.put("LoggableToken", tokenFetchResult.getLoggableToken());
        result.success(tokenFetchResultMap);
      } catch(Exception e) {
        result.error("Approov.fetchApproovTokenAndWait", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("setDataHashInToken")) {
      try {
        Approov.setDataHashInToken((String) call.argument("data"));
        result.success(null);
      } catch(Exception e) {
        result.error("Approov.setDataHashInToken", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("getIntegrityMeasurementProof")) {
      try {
        result.success(Approov.getIntegrityMeasurementProof(call.argument("nonce"), call.argument("measurementConfig")));
      } catch(Exception e) {
        result.error("Approov.getIntegrityMeasurementProof", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("getDeviceMeasurementProof")) {
      try {
        result.success(Approov.getDeviceMeasurementProof(call.argument("nonce"), call.argument("measurementConfig")));
      } catch(Exception e) {
        result.error("Approov.getDeviceMeasurementProof", e.getLocalizedMessage(), null);
      }

    } else if (call.method.equals("getMessageSignature")) {
      try {
        String messageSignature = Approov.getMessageSignature((String) call.argument("message"));
        result.success(messageSignature);
      } catch(Exception e) {
        result.error("Approov.getMessageSignature", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("setUserProperty")) {
      try {
        Approov.setUserProperty(call.argument("property"));
        result.success(null);
      } catch(Exception e) {
        result.error("Approov.setUserProperty", e.getLocalizedMessage(), null);
      }
    } else if (call.method.equals("fetchHostCertificates")) {
      try {
        final URL url = new URL(call.argument("url"));
        // Fetch host certificates for URL
        HostCertificatesFetcher hostCertificateFetcher = new HostCertificatesFetcher();
        final List<byte[]> hostCertificates = hostCertificateFetcher.fetchCertificates(url);
        result.success(hostCertificates);
      } catch (Exception e) {
        result.error("fetchHostCertificates", e.getLocalizedMessage(), null);
      }
    } else {
      result.notImplemented();
    }
  }


  // Certificates fetcher that is running the network operations to get the certificates in a background thread (as
  // opposed to the UI thread) to prevent NetworkOnMainThreadException
  private static class HostCertificatesFetcher {

    // Host certificates to return from fetchHostCertificates()
    List<byte[]> hostCertificates;

    // Any exception thrown in the inner thread
    Exception exception;

    // Fetches the certificates from the host specified in the URL, without sending a request
    public List<byte[]> fetchCertificates(URL url) throws Exception {
      hostCertificates = null;
      exception = null;
      Thread getCertsThread = new Thread(() -> {
        try {
          final HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
          connection.setConnectTimeout(FETCH_CERTIFICATES_TIMEOUT_MS);
          connection.connect();
          Certificate[] certificates = connection.getServerCertificates();
          hostCertificates = new ArrayList<>(certificates.length);
          for (Certificate certificate : certificates) {
            hostCertificates.add(certificate.getEncoded());
          }
          connection.disconnect();
        } catch (Exception e) {
          exception = e;
        }
      });
      getCertsThread.start();
      getCertsThread.join();
      if (exception != null) {
        throw exception;
      }
      return hostCertificates;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

}
