import UIKit

class LiveUpdateController: UIViewController {
    
    var url: URL?
    public weak var delegate: DownloadDelegate?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var labelStatus: UILabel!
    @IBOutlet weak var labelScreenInfo: UILabel!
    @IBOutlet weak var labelImageInfo: UILabel!
    @IBOutlet weak var viewStatusBackground: UIView!
    
    private let timeFormatter = DateFormatter()
    private var buttonSwitchAspectFit: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }

        timeFormatter.dateFormat = "HH:mm:ss"
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        self.title = "Updating every 2 sec"
        
        let text = ProxyManager.sharedManager.imageView.contentMode == .scaleAspectFit ? "Fill" : "Aspect fit"
        buttonSwitchAspectFit = UIBarButtonItem(title: text, style: .plain, target: self, action: #selector(onTapSwitchAspectFit))
        
        navigationItem.rightBarButtonItems = [buttonSwitchAspectFit]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadImage()
        
        if let size = ProxyManager.sharedManager.screenSize {
            self.labelScreenInfo.text = "Screen: \(Int(size.width))x\(Int(size.height))"
        }
        else {
            self.labelScreenInfo.text = "Screen size unavailable"
        }
    }
    
    func loadImage() {
        guard let url = url else {
            onError("Error: URL == nil (live update)", willKeepTrying: false)
            return
        }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        let session = URLSession.shared.dataTask(with: request) {
            [weak self] data, response, error in
            
            guard let strongSelf = self else { return }
            
            DispatchQueue.main.async {
                guard error == nil else {
                    strongSelf.onError("Error: \(String(describing: error))", willKeepTrying: true)
                    strongSelf.scheduleImageUpdate(inSeconds: 2)
                    return
                }
                guard let responseData = data else {
                    strongSelf.onError("Error: no data in response", willKeepTrying: true)
                    strongSelf.scheduleImageUpdate(inSeconds: 2)
                    return
                }
                guard let image = UIImage(data: responseData) else {
                    strongSelf.onError("Error during parsing image", willKeepTrying: true)
                    strongSelf.scheduleImageUpdate(inSeconds: 2)
                    return
                }
            
                strongSelf.imageView.image = image
                strongSelf.labelStatus.text = "\(strongSelf.timeFormatter.string(from: Date())) updated"
                strongSelf.viewStatusBackground.backgroundColor = UIColor.green
                
                let width = Int(image.size.width * image.scale)
                let height = Int(image.size.height * image.scale)
                strongSelf.labelImageInfo.text = "Image: \(width)x\(height)    \(url.lastPathComponent)"
                
                strongSelf.delegate?.onDownloadImage(image, withName: url.lastPathComponent)
                strongSelf.scheduleImageUpdate(inSeconds: 2)
            }
        }
        session.resume()
        delegate?.onDownloadInfo("Loading (live) \(url.lastPathComponent)")
    }
    
    func onError(_ message: String, willKeepTrying: Bool) {
        labelImageInfo.text = ""
        viewStatusBackground.backgroundColor = UIColor.red
        if (willKeepTrying) {
            let fileName = url?.lastPathComponent ?? ""
            labelStatus.text = "\(timeFormatter.string(from: Date())) error (will keep trying \(fileName)"
        }
        else {
            labelStatus.text = "Error (check log on the first screen)"
        }
        delegate?.onDownloadInfo(message)
    }
    
    func scheduleImageUpdate(inSeconds: Int) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(inSeconds), execute: {
            [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.loadImage()
        })
    }

    @objc func onTapSwitchAspectFit() {
        let oldContentMode = ProxyManager.sharedManager.imageView.contentMode
        let newContentMode = (oldContentMode == .scaleAspectFit ? UIViewContentMode.scaleToFill : UIViewContentMode.scaleAspectFit)
        ProxyManager.sharedManager.imageView.contentMode = newContentMode
        buttonSwitchAspectFit.title = newContentMode == .scaleAspectFit ? "Fill" : "Aspect fit"
    }
}
