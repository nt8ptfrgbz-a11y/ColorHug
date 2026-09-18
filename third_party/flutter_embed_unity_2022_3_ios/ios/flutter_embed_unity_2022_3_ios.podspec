#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_embed_unity_ios.podspec` to validate before publishing.
#

# This was added to check that the xcframework actually exists, because if it is not found
# Cocoapods will silently ignore it
framework_path = 'flutter_embed_unity_2022_3_ios/UnityFrameworkStubs/StaticFramework/UnityFramework.xcframework'
unless File.exist?(framework_path)
  # This will raise a visible error during 'pod install' or 'flutter run'
  raise "Error running flutter_embed_unity_2022_3_ios.podspec: #{framework_path} not found"
end

Pod::Spec.new do |s|
  s.name             = 'flutter_embed_unity_2022_3_ios'
  s.version          = '0.0.1'
  s.summary          = 'iOS platform implementation of flutter_embed_unity plugin'
  s.description      = <<-DESC
Embed Unity into an iOS Flutter app
                       DESC
  s.homepage         = 'https://github.com/learntoflutter/flutter_embed_unity'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Learn To Flutter' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'flutter_embed_unity_2022_3_ios/Sources/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
  
  # Add UnityFramework
  # Cocoapods requires the version of the UnityFramework static library which has been wrapped
  # in a framework bundle, because it understands .framework structures
  s.vendored_frameworks = framework_path
end
