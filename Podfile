platform :ios, '13.0'

target 'AIDOCK' do
  use_frameworks!

  # Pods for AIDOCK
  pod 'Masonry'
  pod 'QMUIKit'
  pod 'AFNetworking', '~> 4.0'
  pod 'YYCategories'
  pod 'AgoraRtcEngine_iOS'
  # RTM v2 手动集成: AgoraRtmKit.xcframework (aosl 由 RTC 的 AgoraInfra_iOS 提供)
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
