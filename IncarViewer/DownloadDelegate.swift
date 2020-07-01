import Foundation
import UIKit

protocol DownloadDelegate: class {
    func onDownloadImage(_ image: UIImage, withName name: String?)
    func onDownloadInfo(_ message: String)
    func shouldCloseDownloader() -> Bool
}
