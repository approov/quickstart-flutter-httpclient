#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint approov_http_client.podspec' to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'approov_http_client'
  s.version          = '0.0.3'
  s.summary          = 'Approov Http Client Flutter Plugin'
  s.description      = <<-DESC
The Approov Http Client Flutter Plugin provides drop-in replacements for the Dart IO library's HttpClient and for Client from the Flutter http package (https://pub.dev/packages/http). If a suitable Approov SDK is added and Approov is configured to protect an API, then the drop-ins will automatically set up pinning and add relevant headers for any request to the API.
                       DESC
  s.homepage         = 'https://github.com/approov/quickstart-flutter-httpclient'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'https://approov.io/' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }

  s.xcconfig = { 'OTHER_LDFLAGS' => '$(inherited) -framework Approov', 'ENABLE_BITCODE' => 'NO' }
  s.vendored_frameworks = 'Approov.xcframework'
end
