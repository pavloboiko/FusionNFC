import Foundation

public struct NFCMessage {

public enum SessionUsage {
    case none
    case read
    case write
}

public protocol NFCUtilityProtocol {
    init(alertMessage: String)
    
    static var readingAvailable: Bool { get }
    func readTag(_ completion: @escaping (NFCMessage?) -> Void)
    func writeTag(_ message: NFCMessage)
}