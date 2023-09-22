require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'

Pod::Spec.new do |s|
  s.name     = "NuanceMix"
  s.version  = "0.0.1"
  s.license  = "Apache License, Version 2.0"
  s.authors  = { 'cleblanc' => 'chris.leblanc@nuance.com' }
  s.homepage = "mix.nuance.com"
  s.summary = "Xaas CoreTech gRPC SampleApp"
  s.source = { :git => 'https://github.com/nuance-communications/mix-react-native-mobile' }

  s.ios.deployment_target = "7.1"


  s.requires_arc = false
  s.pod_target_xcconfig = {
    # This is needed by all pods that depend on Protobuf:
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    # This is needed by all pods that depend on gRPC-RxLibrary:
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
    # Yikes
    'HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/../../node_modules/nuance-mix/ios/Pods/Headers/Public/NuanceMix"',
    'USER_HEADER_SEARCH_PATHS' => '"${PODS_ROOT}/../../node_modules/nuance-mix/ios/Pods/Headers/Public/NuanceMix"',
  }

  s.source_files = "ios/Audio/*.{h,m,mm,c,a}", "ios/Utils/*.{h,m,mm,c,a}", "ios/*.{h,m,mm,c,a}", "ios/Pods/NuanceMix-grpc/*.pbrpc.{h,m,mm}", "ios/Pods/NuanceMix-grpc/*.pbobjc.{h,m,mm}", "ios/Pods/NuanceMix-grpc/**/*.pbobjc.{h,m,mm}", "ios/NuanceMix/*.pbobjc.{h,m,mm}",  "ios/NuanceMix/*.pbrpc.{h,m,mm}", "ios/NuanceMix/google/api/*.pbobjc.{h,m,mm}", "ios/NuanceMix/google/protobuf/*.pbobjc.{h,m,mm}"
  s.vendored_libraries = "ios/dependencies/lib/*.a"

  s.dependency "React-Core" 
  s.dependency "Protobuf"
  s.dependency "gRPC-ProtoRPC"

  # Don't install the dependencies when we run `pod install` in the old architecture.  
  if ENV['RCT_NEW_ARCH_ENABLED'] == '1' then
    s.compiler_flags = folly_compiler_flags + " -DRCT_NEW_ARCH_ENABLED=1"
    s.pod_target_xcconfig = {
         "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/boost\"",
         "OTHER_CPLUSPLUSFLAGS" => "-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1",
         "CLANG_CXX_LANGUAGE_STANDARD" => "c++17"
    }
    s.dependency "React-Codegen"
    s.dependency "RCT-Folly"
    s.dependency "RCTRequired"
    s.dependency "RCTTypeSafety"
    s.dependency "ReactCommon/turbomodule/core"
  end
end
