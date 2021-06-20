import Foundation

public struct NFCMessage {
    public let uriRecord: NFCURIRecord?
    public let textRecord: NFCTextRecord?
}

public struct NFCURIRecord {
    public let url: URL
}

public struct NFCTextRecord {
    public let string: String
    public let locale: Locale
}

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