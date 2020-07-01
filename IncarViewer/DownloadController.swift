import UIKit
import WebKit

class DownloadController: UIViewController {

    private let settingKey_LastURL = "settingLastURL"
    private let settingKey_SavedURL = "settingSavedURL"
    
    var webView: WKWebView!
    var buttonUseCurrentImage: UIBarButtonItem!
    var buttonLiveUpdateCurrentImage: UIBarButtonItem!
    
    public weak var delegate: DownloadDelegate?
    
    @IBOutlet weak var textFieldUrl: UITextField!
    @IBOutlet weak var placeholderView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }

        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        
        if let lastUrlString = UserDefaults.standard.string(forKey: settingKey_LastURL) {
            textFieldUrl.text = lastUrlString
        }
        
        buttonUseCurrentImage = UIBarButtonItem(title: "Pick this image", style: .plain, target: self, action: #selector(onTapPickThisImage))
        buttonLiveUpdateCurrentImage = UIBarButtonItem(title: "Live", style: .plain, target: self, action: #selector(onTapLiveUpdateImage))
    }

    override func viewDidLayoutSubviews() {
        webView?.frame = placeholderView.frame
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let liveUpdateController = segue.destination as! LiveUpdateController
        liveUpdateController.delegate = self.delegate
        liveUpdateController.url = sender as? URL
    }

    @IBAction func onTapGo(_ sender: Any) {
        if (webView == nil) {
            webView = WKWebView(frame: placeholderView.frame)
            webView.navigationDelegate = self
            view.addSubview(webView)
        }
        
        textFieldUrl.resignFirstResponder()
        guard let urlString = textFieldUrl.text else { return }
        guard let url = URL(string: urlString) else { return }
        
        UserDefaults.standard.set(url.absoluteString, forKey: settingKey_LastURL)
        
        webView.load(URLRequest(url: url))
    }
    
    @IBAction func onTapShowCurrentUrl(_ sender: Any) {
        guard let url = webView?.url else { return }
        textFieldUrl.text = url.absoluteString
    }
    
    @IBAction func onTapRestoreUrl(_ sender: Any) {
        if let savedUrlString = UserDefaults.standard.string(forKey: settingKey_SavedURL) {
            textFieldUrl.text = savedUrlString
        }
    }
    
    @IBAction func onTapSaveUrl(_ sender: Any) {
        guard let urlString = textFieldUrl.text else { return }
        guard let url = URL(string: urlString) else { return }
        UserDefaults.standard.set(url.absoluteString, forKey: settingKey_SavedURL)
    }
    
    @IBAction func onTapBack(_ sender: Any) {
        webView?.goBack()
    }
    
    @objc func onTapPickThisImage() {
        guard let url = webView.url else { return }
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10.0)
        
        let session = URLSession.shared.dataTask(with: request) {
            [weak self] data, response, error in
            
            guard let strongSelf = self else { return }
            DispatchQueue.main.async {
                guard error == nil else {
                    strongSelf.delegate?.onDownloadInfo("Error: \(String(describing: error))")
                    return
                }
                guard let responseData = data else {
                    strongSelf.delegate?.onDownloadInfo("Error: no data in response")
                    return
                }
                guard let image = UIImage(data: responseData) else {
                    strongSelf.delegate?.onDownloadInfo("Error during parsing image")
                    return
                }
                
                strongSelf.delegate?.onDownloadImage(image, withName: url.lastPathComponent)
                
                let shouldCloseUnw = strongSelf.delegate?.shouldCloseDownloader()
                if let shouldClose = shouldCloseUnw, shouldClose {
                    strongSelf.navigationController?.popViewController(animated: true)
                }
            }
        }
        session.resume()
        delegate?.onDownloadInfo("Loading image \(url.lastPathComponent)")
    }
    
    @objc func onTapLiveUpdateImage() {
        performSegue(withIdentifier: "StartLiveUpdate", sender: webView.url)
    }
}

extension DownloadController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        var isImageDetected = false
        if let pathExtension = webView.url?.pathExtension,
            (pathExtension.caseInsensitiveCompare("png") == .orderedSame ||
             pathExtension.caseInsensitiveCompare("jpg") == .orderedSame ||
             pathExtension.caseInsensitiveCompare("jpeg") == .orderedSame) {
            isImageDetected = true
        }
        
        if (isImageDetected && navigationItem.rightBarButtonItems?.first == nil) {
            navigationItem.rightBarButtonItems = [buttonLiveUpdateCurrentImage, buttonUseCurrentImage]
        }
        else if (!isImageDetected && navigationItem.rightBarButtonItems?.first != nil) {
            navigationItem.rightBarButtonItems = nil
        }
    }
}

extension DownloadController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
