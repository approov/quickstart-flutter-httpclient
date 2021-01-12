/**
* Copyright 2020 CriticalBlue Ltd.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
* associated documentation files (the "Software"), to deal in the Software without restriction,
* including without limitation the rights to use, copy, modify, merge, publish, distribute,
* sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all copies or
* substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
* NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
* DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
* OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import "ApproovHttpClientPlugin.h"
#import "Approov/Approov.h"


// TODO comment
@interface HostCertificatesFetcher: NSObject<NSURLSessionTaskDelegate>

// Host certificates for the current connection
@property NSArray<FlutterStandardTypedData *> *hostCertificates;

// Get the host certificates for an URL
- (NSArray<FlutterStandardTypedData *> *)fetchCertificates:(NSURL *)url;

@end


// Timeout for a getting the host certificates
static const NSTimeInterval FETCH_CERTIFICATES_TIMEOUT = 3;


// TODO comment
@implementation ApproovHttpClientPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"approov_http_client"
            binaryMessenger:[registrar messenger]];
  ApproovHttpClientPlugin* instance = [[ApproovHttpClientPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
    if ([@"initialize" isEqualToString:call.method]) {
        NSError* error = nil;
        NSString *initialConfig = nil;
        if (call.arguments[@"initialConfig"] != [NSNull null]) initialConfig = call.arguments[@"initialConfig"];
        NSString *dynamicConfig = nil;
        if (call.arguments[@"dynamicConfig"] != [NSNull null]) dynamicConfig = call.arguments[@"dynamicConfig"];
        NSString *comment = nil;
        if (call.arguments[@"comment"] != [NSNull null]) comment = call.arguments[@"comment"];
        [Approov initialize:initialConfig updateConfig:dynamicConfig comment:comment error:&error];
        if (error == nil) {
            result(nil);
        } else {
            result([FlutterError errorWithCode:[NSString stringWithFormat:@"%ld", (long)error.code]
                message:error.domain details:error.localizedDescription]);
        }
    } else if ([@"fetchConfig" isEqualToString:call.method]) {
        result([Approov fetchConfig]);
    } else if ([@"getDeviceID" isEqualToString:call.method]) {
        result([Approov getDeviceID]);
    } else if ([@"getPins" isEqualToString:call.method]) {
        result([Approov getPins:call.arguments[@"pinType"]]);
    } else if ([@"fetchApproovTokenAndWait" isEqualToString:call.method]) {
        ApproovTokenFetchResult *tokenFetchResult = [Approov fetchApproovTokenAndWait:call.arguments[@"url"]];
        NSMutableDictionary *tokenFetchResultMap = [NSMutableDictionary dictionary];
        tokenFetchResultMap[@"TokenFetchStatus"] = [Approov stringFromApproovTokenFetchStatus:tokenFetchResult.status];
        tokenFetchResultMap[@"Token"] = tokenFetchResult.token;
        tokenFetchResultMap[@"ARC"] = tokenFetchResult.ARC;
        tokenFetchResultMap[@"IsConfigChanged"] = [NSNumber numberWithBool:tokenFetchResult.isConfigChanged];
        tokenFetchResultMap[@"IsForceApplyPins"] = [NSNumber numberWithBool:tokenFetchResult.isForceApplyPins];
        tokenFetchResultMap[@"MeasurementConfig"] = tokenFetchResult.measurementConfig;
        tokenFetchResultMap[@"LoggableToken"] = tokenFetchResult.loggableToken;
        result((NSDictionary*)tokenFetchResultMap);
    } else if ([@"setDataHashInToken" isEqualToString:call.method]) {
        [Approov setDataHashInToken:call.arguments[@"data"]];
        result(nil);
    } else if ([@"getIntegrityMeasurementProof" isEqualToString:call.method]) {
        result([Approov getIntegrityMeasurementProof:call.arguments[@"nonce"] :call.arguments[@"measurementConfig"]]);
    } else if ([@"getDeviceMeasurementProof" isEqualToString:call.method]) {
        result([Approov getDeviceMeasurementProof:call.arguments[@"nonce"] :call.arguments[@"measurementConfig"]]);
    } else if ([@"getMessageSignature" isEqualToString:call.method]) {
        result([Approov getMessageSignature:call.arguments[@"message"]]);
    } else if ([@"setUserProperty" isEqualToString:call.method]) {
        [Approov setUserProperty:call.arguments[@"property"]];
        result(nil);
    } else if ([@"fetchHostCertificates" isEqualToString:call.method]) {
        NSURL *url = [NSURL URLWithString:call.arguments[@"url"]];
        if (url == nil) {
            result([FlutterError errorWithCode:[NSString stringWithFormat:@"%d", -1]
                message:NSURLErrorDomain
                details:[NSString stringWithFormat:@"Fetch host certificates invalid URL: %@", call.arguments[@"url"]]]);
        } else {
            HostCertificatesFetcher *hostCertificatesFetcher = [[HostCertificatesFetcher alloc] init];
            NSArray<FlutterStandardTypedData *> *hostCerts = [hostCertificatesFetcher fetchCertificates:url];
            result(hostCerts);
        }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end

// TODO comment
@implementation HostCertificatesFetcher

// Fetches the certificates for a host by setting up an HTTPS GET request and harvesting the certificates
- (NSArray<FlutterStandardTypedData *> *)fetchCertificates:(NSURL *)url
{
    _hostCertificates = nil;

    // Create the Session
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfig.timeoutIntervalForResource = FETCH_CERTIFICATES_TIMEOUT;
    NSURLSession* URLSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];

    // Create the request
    NSMutableURLRequest *certFetchRequest = [NSMutableURLRequest requestWithURL:url];
    [certFetchRequest setTimeoutInterval:FETCH_CERTIFICATES_TIMEOUT];
    [certFetchRequest setHTTPMethod:@"GET"];

    // Set up a semaphore so we can detect when the request completed
    dispatch_semaphore_t certFetchComplete = dispatch_semaphore_create(0);

    // Get session task to issue the request, write back any error on completion and signal the semaphore
    // to indicate that it is complete
    __block NSError *certFetchError = nil;
    NSURLSessionTask *certFetchTask = [URLSession dataTaskWithRequest:certFetchRequest
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
        {
            certFetchError = error;
            dispatch_semaphore_signal(certFetchComplete);
        }];

    // Make the request
    [certFetchTask resume];

    // Wait on the semaphore which shows when the network request is completed - note we do not use
    // a timeout here since the NSURLSessionTask has its own timeouts
    dispatch_semaphore_wait(certFetchComplete, DISPATCH_TIME_FOREVER);

    // We expect error cancelled because URLSession:task:didReceiveChallenge:completionHandler: always deliberately
    // fails the challenge because we don't need the request to succeed to retrieve the certificates
    if (!certFetchError) {
        // If no error occurred, the certificate check of the NSURLSessionTaskDelegate protocol has not been called.
        //  Don't return any host certificates
        NSLog(@"Failed to get host certificates: Error: unknown\n");
        return nil;
    }
    if (certFetchError && certFetchError.code != NSURLErrorCancelled) {
        // If an error other than NSURLErrorCancelled occurred, don't return any host certificates
        NSLog(@"Failed to get host certificates: Error: %@\n", certFetchError.localizedDescription);
        return nil;
    }
    // The host certificates have been collected by the URLSession:task:didReceiveChallenge:completionHandler:
    // method below
    return _hostCertificates;
}

// Collect the host certificates using the certificate check of the NSURLSessionTaskDelegate protocol
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
    completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    // Ignore any requests that are not related to server trust
    if (![challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
        return;

    // Check we have a server trust
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    if (!serverTrust) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }

    // Check the validity of the server trust
    SecTrustResultType result;
    OSStatus aStatus = SecTrustEvaluate(serverTrust, &result);
    if (errSecSuccess != aStatus) {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        return;
    }

    // Collect all the certs in the chain
    CFIndex certCount = SecTrustGetCertificateCount(serverTrust);
    NSMutableArray<FlutterStandardTypedData *> *certs = [NSMutableArray arrayWithCapacity:(NSUInteger)certCount];
    for (int certIndex = 0; certIndex < certCount; certIndex += 1) {
        // get the chain certificate
        SecCertificateRef cert = SecTrustGetCertificateAtIndex(serverTrust, certIndex);
        if (!cert) {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
            return;
        }
        NSData *certData = (NSData *) CFBridgingRelease(SecCertificateCopyData(cert));
        FlutterStandardTypedData *certFSTD = [FlutterStandardTypedData typedDataWithBytes:certData];
        [certs addObject:certFSTD];
    }
    // Set the host certs to be returned from fetchCertificates:
    _hostCertificates = certs;
    // Fail the challenge as we only wanted the certificates
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
}

@end

