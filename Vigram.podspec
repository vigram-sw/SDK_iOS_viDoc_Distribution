Pod::Spec.new do |s|
s.name         = 'Vigram'
s.version      = '0.5.10'
s.summary      = 'VigramSDK allows the seamless communication with the Vigram module.'
s.description  = <<-DESC
VigramSDK connects to the Vigram module, forwards Ntrip correction data to it and 
receives RTK and laser information.
DESC
s.homepage     = 'https://vigram.de'
s.license = { :type => 'Copyright', :text => <<-LICENSE
Copyright 2023
Permission is granted to...
LICENSE
}
s.source = { :git => 'https://github.com/vigram-gmbh/SDK_iOS_viDoc_Distribution.git', :tag => '0.5.10' }
s.author = { 'Iaroslav Khaustov' => 'iaroslav.khaustov@vigram.com' }
s.platform = :ios
s.swift_version = '5.7'
s.ios.deployment_target  = '15.0'
s.default_subspec = 'Core'
s.subspec 'Core' do |ss|
ss.vendored_frameworks = 'VigramSDK.xcframework'
end

s.subspec 'Rx' do |ss|
ss.source_files = 'VigramSDK+Rx/*.swift'
ss.dependency 'Vigram/Core'
ss.dependency 'RxSwift', '~> 6.2'
end

end

