import WatchKit

enum WatchResolution {
    case Watch38mm, Watch42mm, Unknown
}

extension WKInterfaceDevice {
    class func currentResolution() -> WatchResolution {
        let watch38mmRect = CGRect(x: 0, y: 0, width: 136, height: 170)
        let watch42mmRect = CGRect(x: 0, y: 0, width: 156, height: 195)
        
        let currentBounds = WKInterfaceDevice.current().screenBounds
        
        switch currentBounds {
        case watch38mmRect:
            return .Watch38mm
        case watch42mmRect:
            return .Watch42mm
        default:
            return .Unknown
        }
    }
}
