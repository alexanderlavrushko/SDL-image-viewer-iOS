import Foundation
import UIKit

protocol SDLSetupDelegate: AnyObject {
    func sdlSetupViewControllerDidSave(appName: String, fullAppId: String)
}

class SDLSetupViewController: UIViewController {
    
    var sdlAppName: String?/* {
        didSet {
            textFieldAppName?.text = sdlAppName
        }
    }*/
    var sdlFullAppId: String?/* {
        didSet {
            textFieldFullAppId?.text = sdlFullAppId
        }
    }*/
    weak var delegate: SDLSetupDelegate?

    @IBOutlet weak var textFieldAppName: UITextField!
    @IBOutlet weak var textFieldFullAppId: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 13.0, *) {
            overrideUserInterfaceStyle = .light
        }
        textFieldAppName?.text = sdlAppName
        textFieldFullAppId?.text = sdlFullAppId
    }
    
    @IBAction func onTapSave(_ sender: Any) {
        guard let appName = textFieldAppName?.text, let fullAppId = textFieldFullAppId?.text else {
            return
        }
        sdlAppName = appName
        sdlFullAppId = fullAppId
        delegate?.sdlSetupViewControllerDidSave(appName: appName, fullAppId: fullAppId)
        navigationController?.popViewController(animated: true)
    }
}

extension SDLSetupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}
