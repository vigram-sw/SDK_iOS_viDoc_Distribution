
set -e

echo "--- INPUT VALIDATION ---"

if [[ "$#" != 1 ]]; then
    echo "Please provide new version as a single argument."
    exit 1
fi

echo "--- PREPARATION ---"

TAG="$1"
NAME="Vigram"

echo "--- PODSPEC CREATION ---"

echo "
Pod::Spec.new do |s|
    s.name         = '$NAME'
    s.version      = '$TAG'
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
    s.source = { :git => 'https://github.com/vigram-gmbh/SDK_iOS_viDoc_Distribution.git', :tag => '$TAG' }
    s.author = { '$(git config user.name)' => '$(git config user.email)' }

    s.platform = :ios
    s.swift_version = '5.5'
    s.ios.deployment_target  = '15.0'
    s.default_subspec = 'Core'

    s.subspec 'Core' do |ss|
        ss.vendored_frameworks = 'VigramSDK.xcframework'
    end

    s.subspec 'Rx' do |ss|
        ss.source_files = 'VigramSDK+Rx/*.swift'
        ss.dependency '$NAME/Core'
	    ss.dependency 'RxSwift', '~> 6.2'
    end

end
# " > $NAME.podspec

 echo "--- COMMIT AND PUSH ---"

 git add .
 git commit -m "$NAME $TAG"
 git push

 echo "--- TAG ---"

 git tag "$TAG"
 git push origin "$TAG"

 echo "--- PODSPEC LINT ---"

 pod spec lint --quick
