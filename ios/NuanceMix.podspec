require "json"

package = JSON.parse(File.read(File.join(__dir__, "../package.json")))
folly_compiler_flags = '-DFOLLY_NO_CONFIG -DFOLLY_MOBILE=1 -DFOLLY_USE_LIBCPP=1 -Wno-comma -Wno-shorten-64-to-32'

Pod::Spec.new do |s|
  s.name     = "NuanceMix"
  s.version  = "0.0.1"
  s.license  = "Apache License, Version 2.0"
  s.authors  = { 'cleblanc' => 'chris.leblanc@nuance.com' }
  s.homepage = "beta.mix.nuance.com/mix/landing/"
  s.summary = "Xaas CoreTech gRPC SampleApp"
  s.source = { :git => 'https://git.labs.nuance.com/mob-ps/react-native-nuance-mix.git' }

  s.ios.deployment_target = "7.1"
  s.osx.deployment_target = "10.9"

  # Base directory where the .proto files are.
  src = "./v1"
  google_api = "./v1/google/api"
  google_proto = "./v1/google/protobuf"

  # Run protoc with the Objective-C and gRPC plugins to generate protocol messages and gRPC clients.
  s.dependency "!ProtoCompiler-gRPCPlugin", "~> 1.0"

  # Pods directory corresponding to this app's Podfile, relative to the location of this podspec.
  pods_root = 'Pods'

  # Path where Cocoapods downloads protoc and the gRPC plugin.
  protoc_dir = "#{pods_root}/\!ProtoCompiler"
  protoc = "#{protoc_dir}/protoc"
  plugin = "#{pods_root}/\!ProtoCompiler-gRPCPlugin/grpc_objective_c_plugin"

  # Directory where the generated files will be placed.
  dir = "#{pods_root}/#{s.name}-grpc"

  s.prepare_command = <<-CMD
    mkdir -p #{dir}
    mkdir -p #{dir}/google
    mkdir -p #{dir}/google/api
# NLU proto files
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/interpretation-common.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/multi-intent-interpretation.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/result.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{google_api} \
        -I #{google_proto} \
        -I #{protoc_dir} \
        #{src}/runtime.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/single-intent-interpretation.proto
# TTS proto files
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/nuance_tts.proto
# ASR proto files
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/nuance_asr.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/nuance_asr_result.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/nuance_asr_resource.proto
# DLG proto files
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/dlg_messages.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/dlg_common_messages.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/error_details.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/status_code.proto
# RPC proto files
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{protoc_dir} \
        #{src}/status.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{google_api} \
        -I #{google_proto} \
        -I #{protoc_dir} \
        #{src}/dlg_interface.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{google_api} \
        -I #{google_proto} \
        -I #{protoc_dir} \
        #{src}/google/api/annotations.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{google_api} \
        -I #{google_proto} \
        -I #{protoc_dir} \
        #{src}/google/api/http.proto
    #{protoc} \
        --plugin=protoc-gen-grpc=#{plugin} \
        --objc_out=#{dir} \
        --grpc_out=#{dir} \
        -I #{src} \
        -I #{google_api} \
        -I #{google_proto} \
        -I #{protoc_dir} \
        #{src}/google/protobuf/descriptor.proto
  CMD

  # Files generated by protoc
  s.subspec "Messages" do |ms|
    ms.source_files = "#{dir}/*.pbobjc.{h,m}", "#{dir}/**/*.pbobjc.{h,m}"
    ms.header_mappings_dir = dir
    ms.requires_arc = false
    # The generated files depend on the protobuf runtime.
    ms.dependency "Protobuf"
  end

  # Files generated by the gRPC plugin
  s.subspec "Services" do |ss|
    ss.source_files = "#{dir}/*.pbrpc.{h,m}", "#{dir}/**/*.pbrpc.{h,m}"
    ss.header_mappings_dir = dir
    ss.requires_arc = false
    # The generated files depend on the gRPC runtime, and on the files generated by protoc.
    ss.dependency "gRPC-ProtoRPC"
    ss.dependency "#{s.name}/Messages"
  end

  s.header_mappings_dir = "Pods/NuanceMix-grpc"

  s.source_files = "Audio/*.{h,m,mm,c,a}", "Utils/*.{h,m,mm,c,a}", "Pods/NuanceMix-grpc/*.pbrpc.{h, m, mm}", "Pods/NuanceMix-grpc/*.pbobjc.{h, m, mm}", "Pods/NuanceMix-grpc/**"

  s.pod_target_xcconfig = {
    # This is needed by all pods that depend on Protobuf:
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) GPB_USE_PROTOBUF_FRAMEWORK_IMPORTS=1',
    # This is needed by all pods that depend on gRPC-RxLibrary:
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES',
  }
end
