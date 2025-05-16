import UIKit

struct DeviceHelper {
    static var isiPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}