import Foundation
import SmartDeviceLink_iOS
import WebKit

class ProxyManager: NSObject {
    private(set) static var sharedManager: ProxyManager!

    let appName: String
    let fullAppId: String
    var imageView: UIImageView
    weak var delegate: ProxyManagerDelegate?

    private var sdlManager: SDLManager!
    private var carViewController: UIViewController
    
    static func setup(appName: String, fullAppId: String) {
        guard appName != sharedManager?.appName || fullAppId != sharedManager?.fullAppId else { return }
        sharedManager?.sdlManager.stop()
        sharedManager?.sdlManager = nil
        sharedManager = ProxyManager(appName: appName, fullAppId: fullAppId)
    }

    private init(appName: String, fullAppId: String) {
        self.appName = appName
        self.fullAppId = fullAppId
        imageView = UIImageView()
        imageView.backgroundColor = .orange
        carViewController = UIViewController()
        carViewController.view = imageView
        super.init()
        
        let lifecycleConfiguration = SDLLifecycleConfiguration(appName: appName, fullAppId: fullAppId)
        lifecycleConfiguration.appType = .navigation;

        if let appImage = UIImage(named: "IncarViewer") {
            let appIcon = SDLArtwork(image: appImage, name: "IncarViewer_icon", persistent: true, as: .PNG)
            lifecycleConfiguration.appIcon = appIcon
        }

        let streamConfig = SDLStreamingMediaConfiguration.autostreamingInsecureConfiguration(withInitialViewController: carViewController)
        let videoSettings: [String : Any] = [kVTCompressionPropertyKey_ProfileLevel as String: kVTProfileLevel_H264_Baseline_AutoLevel as String,
                                             kVTCompressionPropertyKey_RealTime as String: NSNumber(booleanLiteral: true),
                                             kVTCompressionPropertyKey_ExpectedFrameRate as String: NSNumber(integerLiteral: 15),
                                             kVTCompressionPropertyKey_Quality as String: NSNumber(floatLiteral: 0.5)]
        streamConfig.customVideoEncoderSettings = videoSettings

        let configuration = SDLConfiguration(lifecycle: lifecycleConfiguration,
                                             lockScreen: .disabled(),
                                             logging: .default(),
                                             streamingMedia: streamConfig,
                                             fileManager: nil,
                                             encryption: nil)
        sdlManager = SDLManager(configuration: configuration, delegate: self)
    }
    
    func connect() {
        self.delegate?.onInfo("SDLManager waiting for connection")

        sdlManager.start { (success, error) in
            if success {
                self.delegate?.onInfo("SDLManager connected")
                
                self.delegate?.onInfo("\(String(describing: self.sdlManager?.registerResponse))")
            }
            else {
                self.delegate?.onInfo("Error: SDLManager.start: \(String(describing: error))")
            }
            self.delegate?.onStatusUpdated()
        }
    }
    
    var screenSize: CGSize? {
        return sdlManager.streamManager?.screenSize
    }
}

//MARK: SDLManagerDelegate
extension ProxyManager: SDLManagerDelegate {
    func managerDidDisconnect() {
        self.delegate?.onInfo("SDLManager disconnected")
        self.delegate?.onStatusUpdated()
    }
    
    func hmiLevel(_ oldLevel: SDLHMILevel, didChangeToLevel newLevel: SDLHMILevel) {
        self.delegate?.onInfo("HMI level \(oldLevel.rawValue.rawValue) -> \(newLevel.rawValue.rawValue)")
        self.delegate?.onStatusUpdated()
    }
}
