# First, creat all frameworks for both architectures: 
xcodebuild -project ios_system.xcodeproj -alltargets -sdk iphoneos -configuration Release -quiet
xcodebuild -project ios_system.xcodeproj -alltargets -sdk iphonesimulator  -arch x86_64 -configuration Release -quiet

# then, merge them into XCframeworks:
for framework in awk curl_ios files ios_system shell ssh_cmd tar text
do
   rm -rf $framework.xcframework
   xcodebuild -create-xcframework -framework build/Release-iphoneos/$framework.framework -framework build/Release-iphonesimulator/$framework.framework -output $framework.xcframework
   # while we're at it, let's compute the checksum:
   rm -f $framework.xcframework.zip
   zip -r $framework.xcframework.zip $framework.xcframework
   swift package compute-checksum $framework.xcframework.zip
done
