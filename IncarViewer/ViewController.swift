import UIKit
import Photos

class ViewController: UIViewController {
    
    private let settingKey_KeepLibraryOpen = "settingKeepLibraryOpen"
    private let settingKey_AspectFit = "settingAspectFit"
    private let settingKey_ImageBackgroundColor = "settingImageBackgroundColor"
    private let settingKey_SDLAppName = "settingSDLAppName"
    private let settingKey_SDLFullAppId = "settingSDLFullAppId"
    
    enum MyColor: Int {
        case unknown = 0
        case orange
        case black
        case white
        case gray
        case green
        case blue
    }
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var labelScreenInfo: UILabel!
    @IBOutlet weak var labelImageInfo: UILabel!
    @IBOutlet weak var switchKeepLibraryOpen: UISwitch!
    @IBOutlet weak var switchAspectFit: UISwitch!
    
    private var imageBackgroundColor = MyColor.unknown
    
    private let timeFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        
        timeFormatter.dateFormat = "HH:mm:ss"
        textView.layoutManager.allowsNonContiguousLayout = false //solves the problem that scrollRangeToVisible doesn't work
        
        switchKeepLibraryOpen.isOn = UserDefaults.standard.bool(forKey: settingKey_KeepLibraryOpen)
        switchAspectFit.isOn = UserDefaults.standard.bool(forKey: settingKey_AspectFit)
        
        if let color = MyColor(rawValue: UserDefaults.standard.integer(forKey: settingKey_ImageBackgroundColor)) {
            imageBackgroundColor = color
        }
        
        appendLog("App started")
        appendLog("appName=\(sdlAppName)")
        appendLog("fullAppId=\(sdlFullAppId)")
        
        ProxyManager.setup(appName: sdlAppName, fullAppId: sdlFullAppId)
        ProxyManager.sharedManager.delegate = self
        ProxyManager.sharedManager.connect()
        
        updateImageContentMode()
        updateImageBackground()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let downloadController = segue.destination as? DownloadController {
            downloadController.delegate = self
        } else if let setupController = segue.destination as? SDLSetupViewController {
            setupController.sdlAppName = sdlAppName
            setupController.sdlFullAppId = sdlFullAppId
            setupController.delegate = self
        }
    }

    
    @IBAction func onTapSDLSetup(_ sender: Any) {
        performSegue(withIdentifier: "ShowSDLSetup", sender: nil)
    }
    
    @IBAction func onTapPickImage(_ sender: Any) {
        pickImage()
    }
    
    @IBAction func onTapDownloadImage(_ sender: Any) {
        performSegue(withIdentifier: "ShowDownloadImage", sender: nil)
    }
    
    @IBAction func onTapClearText(_ sender: Any) {
        textView.text = ""
    }
    @IBAction func onSwitchKeepLibraryOpen(_ sender: Any) {
        UserDefaults.standard.set(switchKeepLibraryOpen.isOn, forKey: settingKey_KeepLibraryOpen)
    }
    
    @IBAction func onSwitchAspectFit(_ sender: Any) {
        UserDefaults.standard.set(switchAspectFit.isOn, forKey: settingKey_AspectFit)
        updateImageContentMode()
    }
    
    @IBAction func onTapOrange(_ sender: Any) { setImageBackgroundColor(.orange) }
    @IBAction func onTapBlack(_ sender: Any) { setImageBackgroundColor(.black) }
    @IBAction func onTapWhite(_ sender: Any) { setImageBackgroundColor(.white) }
    @IBAction func onTapGray(_ sender: Any) { setImageBackgroundColor(.gray) }
    @IBAction func onTapGreen(_ sender: Any) { setImageBackgroundColor(.green) }
    @IBAction func onTapBlue(_ sender: Any) { setImageBackgroundColor(.blue) }
    
    func pickImage() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        if (UIImagePickerController.isSourceTypeAvailable(imagePicker.sourceType)) {
            present(imagePicker, animated: true)
        }
        else {
            appendLog("Error: isSourceTypeAvailable(.photoLibrary) = false")
        }
    }
    
    func updateImageContentMode() {
        ProxyManager.sharedManager.imageView.contentMode = (switchAspectFit.isOn ? .scaleAspectFit : .scaleToFill)
    }
    
    func updateImageBackground() {
        var color = UIColor.orange
        
        switch (imageBackgroundColor) {
        case .unknown: color = .orange
        case .orange:  color = .orange
        case .black:   color = .black
        case .white:   color = .white
        case .gray:    color = .darkGray
        case .green:   color = UIColor(red: 0, green: 0.5, blue: 0.09, alpha: 1)
        case .blue:    color = UIColor(red: 0, green: 0.09, blue: 0.57, alpha: 1)
        }
        ProxyManager.sharedManager.imageView.backgroundColor = color
    }
    
    func setImageBackgroundColor(_ color: MyColor) {
        imageBackgroundColor = color
        UserDefaults.standard.set(imageBackgroundColor.rawValue, forKey: settingKey_ImageBackgroundColor)
        updateImageBackground()
    }
    
    func appendLog(_ message: String) {
        textView.text = textView.text + (textView.text.isEmpty ? "" : "\n") + "\(timeFormatter.string(from: Date())) \(message)"
        let lastSymbol = NSMakeRange(textView.text.count - 1, 1)
        textView.scrollRangeToVisible(lastSymbol)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if (!switchKeepLibraryOpen.isOn) {
            dismiss(animated: true)
        }
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            appendLog("Error: didFinishPickingMedia, but no image")
            return
        }
        
        var imageName = ""
        if let url = info[UIImagePickerControllerReferenceURL] as? NSURL {
            if let asset = PHAsset.fetchAssets(withALAssetURLs: [url as URL], options: nil).firstObject {
                if let resource = PHAssetResource.assetResources(for: asset).first {
                    imageName = resource.originalFilename
                }
            }
        }
        
        ProxyManager.sharedManager.imageView.image = image
        updateImageBackground()

        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        labelImageInfo.text = "\(width)x\(height)    \(imageName)"
        
        appendLog("Image updated \(imageName)")
    }
}

extension ViewController: ProxyManagerDelegate {
    func onInfo(_ message: String) {
        DispatchQueue.main.async {
            self.appendLog(message)
        }
    }
    
    func onStatusUpdated() {
        DispatchQueue.main.async {
            if let size = ProxyManager.sharedManager.screenSize {
                self.labelScreenInfo.text = "\(Int(size.width))x\(Int(size.height))"
            }
            else {
                self.labelScreenInfo.text = "unavailable"
            }
        }
    }
}

extension ViewController: DownloadDelegate {
    func onDownloadImage(_ image: UIImage, withName name: String?) {
        ProxyManager.sharedManager.imageView.image = image
        updateImageBackground()
        
        let imageName = name ?? ""
        let width = Int(image.size.width * image.scale)
        let height = Int(image.size.height * image.scale)
        labelImageInfo.text = "\(width)x\(height)    \(imageName)"
        
        appendLog("Image updated \(imageName)")
    }
    
    func onDownloadInfo(_ message: String) {
        appendLog(message)
    }
    
    func shouldCloseDownloader() -> Bool {
        return !switchKeepLibraryOpen.isOn
    }
}

extension ViewController {
    var sdlAppName: String {
        get { UserDefaults.standard.string(forKey: settingKey_SDLAppName) ?? "MyApp" }
        set { UserDefaults.standard.set(newValue, forKey: settingKey_SDLAppName) }
    }
    var sdlFullAppId: String {
        get { UserDefaults.standard.string(forKey: settingKey_SDLFullAppId) ?? "1234567890" }
        set { UserDefaults.standard.set(newValue, forKey: settingKey_SDLFullAppId) }
    }
}

extension ViewController: SDLSetupDelegate {
    func sdlSetupViewControllerDidSave(appName: String, fullAppId: String) {
        guard appName != sdlAppName || fullAppId != sdlFullAppId else {
            appendLog("SDL settings not changed")
            appendLog("appName=\(sdlAppName)")
            appendLog("fullAppId=\(sdlFullAppId)")
            return
        }
        
        appendLog("appName=\(appName)")
        appendLog("fullAppId=\(fullAppId)")
        appendLog("Creating new SDLManager")
        ProxyManager.sharedManager.delegate = nil
        ProxyManager.setup(appName: appName, fullAppId: fullAppId)
        ProxyManager.sharedManager.delegate = self
        ProxyManager.sharedManager.connect()
        sdlAppName = appName
        sdlFullAppId = fullAppId
    }
}
