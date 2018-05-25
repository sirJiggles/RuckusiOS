# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

def ruckusPods
    # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    
    pod 'FoldingCell'
    pod 'MKRingProgressView'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'ScalingCarousel'
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

target 'ruckus.watch' do
  use_frameworks!
end

target 'ruckus.watch Extension' do
  use_frameworks!
end
