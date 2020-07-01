import Foundation

protocol ProxyManagerDelegate: class {
    func onInfo(_ message: String)
    func onStatusUpdated()
}
