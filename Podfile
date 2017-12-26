# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def ruckusPods
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    
    # Pods for ruckus
    pod 'MKRingProgressView', '~> 1.1'
    pod 'FoldingCell', '~> 2.0.3'
    #  For swift 4 and testing
    #  pod 'SwiftyStoreKit', :git => 'https://github.com/bizz84/SwiftyStoreKit', :branch => 'swift-4.0'
    pod 'SwiftyStoreKit', '~> 0.10'
    pod 'Google-Mobile-Ads-SDK'
    pod 'Fabric'
    pod 'Crashlytics'
#    pod 'CardboardSDK', '~> 0.7'
end

target 'ruckus' do
    ruckusPods
    
    target 'ruckusTests' do
        inherit! :search_paths
    end
    
    target 'ruckusUITests' do
        inherit! :search_paths
    end
end
target 'ruckus.lite' do
    ruckusPods
end

target 'ruckus.watch' do
  use_frameworks!
end

target 'ruckus.lite.watch' do
    use_frameworks!
end

target 'ruckus.watch Extension' do
  use_frameworks!
end
target 'ruckus.lite.watch Extension' do
    use_frameworks!
end
