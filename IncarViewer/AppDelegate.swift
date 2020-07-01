import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var timer: Timer?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(onTimer), userInfo: nil, repeats: true)
        
        return true
    }
    
    @objc func onTimer()
    {
        if (UIDevice.current.batteryState != .unplugged) {
            UIApplication.shared.isIdleTimerDisabled = true;
        }
        else {
            UIApplication.shared.isIdleTimerDisabled = false;
        }
    }
}
