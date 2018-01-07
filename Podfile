# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def ruckusPods
    pod 'Google-Mobile-Ads-SDK'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'GVRSDK', '~> 0.8.0'
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
#  use_frameworks!
end

target 'ruckus.lite.watch' do
#    use_frameworks!
end

target 'ruckus.watch Extension' do
#  use_frameworks!
end
target 'ruckus.lite.watch Extension' do
#    use_frameworks!
end
