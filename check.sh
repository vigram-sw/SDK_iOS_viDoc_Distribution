
echo "--- PREPARATION ---"

POD_NAME="Vigram"
POD_URL="git@github.com:vigram-gmbh/SDK_iOS_viDoc_Distribution.git"
INFO_PLIST_PATH="VigramSDK.xcframework/ios-arm64/VigramSDK.framework/Info.plist"

WORKSPACE="VigramSDK-DistributionApp.xcworkspace"
SCHEME="VigramSDK-DistributionApp"
COMMIT="$(git rev-parse HEAD)"

if [[ $1 = "build" ]]; then
  IS_RELEASE=false
elif [[ $1 = "release" ]]; then
  IS_RELEASE=true
  TAG="$(git describe --exact-match --tags $(git log -n1 --pretty='%h'))"
  EXPECTED_VERSION="$POD_NAME ($TAG)"
else
  echo "Please provide a command."
  exit 1
fi

echo "--- CHECKING INFO.PLIST ---"

INFO_PLIST="$(cat "$INFO_PLIST_PATH")"
if [[ $INFO_PLIST != *"CFBundleVersion"* ]]; then
    cat "$INFO_PLIST"
    echo "CFBundleVersion missing."
    exit 1
else
   echo "CFBundleVersion exists!"
fi

echo "--- MOVE TO EXAMPLE ---"

cd Example/Cocoapods

echo "

platform :ios, '15.0'

target '$SCHEME' do

  use_frameworks!

  pod '$POD_NAME', :git => '$POD_URL', :commit => '$COMMIT'

end

" > Podfile

echo "--- POD INSTALL ---"

pod cache clean --all
pod repo update
pod deintegrate
pod install

echo "--- CHECK POD VERSION ---"

ACTUAL_VERSION="$(cat Podfile.lock | grep -o "$POD_NAME ([0-9]*\.[0-9]*\.[0-9]*[^ ]*)")"

if [[ IS_RELEASE = true ]] && [[ $EXPECTED_VERSION != $ACTUAL_VERSION ]]; then
  echo "Versions did not match: $EXPECTED_VERSION != $ACTUAL_VERSION"
  cat Podfile.lock
  exit 1
fi

if [[ "$(cat Podfile.lock)" != *":commit: $COMMIT"* ]]; then
  echo "Release was not pulled from the right commit."
  cat Podfile.lock
  exit 1
fi

echo "--- BUILD AND TEST EXAMPLE ---"

xcodebuild clean build test -workspace $WORKSPACE -scheme $SCHEME -destination "platform=iOS Simulator,name=$SIMULATOR"
