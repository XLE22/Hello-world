Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = "10.3"
s.name = "Webcom_api_ios_chat"
s.summary = "Webcom_api_ios_chat lets a developer create a chat application based on the Webcom SDK."

s.version = "1.0.0"
#s.license = { :type => "MIT", :file => "LICENSE" }
s.license = { :type => "Commercial", :text => "https://datasync.orange.com/terms/terms-of-service.html"}
s.author = { "Webcom" => "support.datasync@orange.com"}
s.homepage = "http://datasync.orange.com"
s.source = { :git => "ssh://gitolite@www.forge.orange-labs.fr/webcom/webcom-api-ios-chat.git", :tag => "#{s.version}" }

s.cocoapods_version = '>= 1.3.1'
s.framework = "UIKit"

s.vendored_frameworks = 'Content/Webcom.framework'
# '$SRCROOT/..' is used when the Pod is in development mode for the example.
# '$PODS_ROOT' is used when the Pod is in production mode.
s.xcconfig = { "FRAMEWORK_SEARCH_PATHS" => %Q["$SRCROOT/../Content" "$PODS_ROOT/#{s.name}/Content"] }

s.source_files = "Content/**/*.swift"
# s.resources = "Content/**/*.{png,jpeg,jpg,storyboard,storyboardc,xib}"

end
