import Foundation
import Java
import Android
import AndroidOS
import AndroidApp
import AndroidContent
import AndroidNFC

import FusionNFC_Common

public class NFCManager {
	private var currentActivity: Activity? { Application.currentActivity }
	private var adapter: NfcAdapter? = nil  
	private var receiver = NFCReceiver()
  
	public required init(alertMessage: String) {
		let nfcManager = self.currentActivity?.getSystemService(name: ContextStatic.NFC_SERVICE) as? NfcManager
        self.adapter = nfcManager?.getDefaultAdapter()
	}
}

extension NFCManager: NFCManagerProtocol {
    public static var readingAvailable: Bool {
        return true
    }
    
    public func readTag(_ completion: @escaping (NFCMessage?) -> Void) {
    	print("pavlo read Tag called")
		enableNfcForegroundDispatch()

		NFCReceiver.shared.receiver = completion
    }
    
    public func writeTag(_ message: NFCMessage) {
    }
    
    private func enableNfcForegroundDispatch() {
        print("pavlo start enable")
//        let intent = self.currentActivity?.getIntent()?.addFlags(flags: Intent.FLAG_ACTIVITY_SINGLE_TOP)
		let intent =  Intent(packageContext: self.currentActivity, cls: receiver.getClass())
//		print("pavlo receiver get class = \(receiver.getClass())")
        let nfcPendingIntent = PendingIntent.getBroadcast(context: self.currentActivity, requestCode: 0, intent: intent, flags: 0)
        self.adapter?.enableForegroundDispatch(activity: self.currentActivity, intent: nfcPendingIntent, filters: [], techLists: [])
        print("pavlo end enable")        
    }
    
    private func disableNfcForegroundDispatch() {
		self.adapter?.disableForegroundDispatch(activity: self.currentActivity)
	}
}

public class NFCReceiver: Object, BroadcastReceiver {
	static let shared = NFCReceiver()
	var receiver: ((NFCMessage?) -> Void)?
	public func onReceive(context: Context?, intent: Intent?) {
    }
    
    static func didReceive(context: Context?, intent: Intent?) {
    	print("Pavlo static func")
    	guard let intent = intent else {
    		print("Pavlo return nil cause of instant")
    		NFCReceiver.shared.receiver?(nil)
    		return 
    	}
    	let action = intent.getAction()
        if NfcAdapter.ACTION_TAG_DISCOVERED == action ||
            NfcAdapter.ACTION_TECH_DISCOVERED == action ||
            NfcAdapter.ACTION_NDEF_DISCOVERED == action {
            let rawMsgs = intent.getParcelableArrayExtra(name: NfcAdapter.EXTRA_NDEF_MESSAGES)
            var msgs: [NdefMessage] = []
            if !rawMsgs.isEmpty {
				for rawMsg in rawMsgs {
					if let msg = rawMsg as? NdefMessage {
						msgs.append(msg)
					}
				}
            } 
                        
            if msgs.isEmpty {
            	print("Pavlo return nil cause of msg")
            	NFCReceiver.shared.receiver?(nil)
            } else {
            	let nfcMessage = parse(message: msgs[0])
            	if nfcMessage.textRecord != nil || nfcMessage.uriRecord != nil {
            		NFCReceiver.shared.receiver?(parse(message: msgs[0]))	
            	} else {
            		print("Pavlo return nil cause of nfcMessage")
            		NFCReceiver.shared.receiver?(nil)
            	}            	
            }
        } else {
          	print("Pavlo return nil cause of action")
            NFCReceiver.shared.receiver?(nil)        	
        }
	}
 
}

extension NFCReceiver {
    static func parse(message: NdefMessage) -> NFCMessage {
    	return NFCReceiver.getRecords(records: message.getRecords())
    }
    
    static func getRecords(records: [NdefRecord?]) -> NFCMessage {
        var nfcURIRecord: NFCURIRecord?
        var nfcTextRecord: NFCTextRecord?
        
    	for record in records {
    		if let uriRecord = NFCURIRecord.parse(record) {
                nfcURIRecord = uriRecord
            } else if let textRecord = NFCTextRecord.parse(record) {
                nfcTextRecord = textRecord
            } else {
            	nfcTextRecord = NFCTextRecord.getDefault(record)
            }
    	}
    	
    	return NFCMessage(uriRecord: nfcURIRecord, textRecord: nfcTextRecord)
    }
}

let URI_PREFIX_MAP = [0x00: "",
                      0x01: "http://www.",
                      0x02: "https://www.",
                      0x03: "http://",
                      0x04: "https://",
                      0x05: "tel:",
                      0x06: "mailto:",
                      0x07: "ftp://anonymous:anonymous@",
                      0x08: "ftp://ftp.",
                      0x09: "ftps://",
                      0x0A: "sftp://",
                      0x0B: "smb://",
                      0x0C: "nfs://",
                      0x0D: "ftp://",
                      0x0E: "dav://",
                      0x0F: "news:",
                      0x10: "telnet://",
                      0x11: "imap:",
                      0x12: "rtsp://",
                      0x13: "urn:",
                      0x14: "pop:",
                      0x15: "sip:",
                      0x16: "sips:",
                      0x17: "tftp:",
                      0x18: "btspp://",
                      0x19: "btl2cap://",
                      0x1A: "btgoep://",
                      0x1B: "tcpobex://",
                      0x1C: "irdaobex://",
                      0x1D: "file://",
                      0x1E: "urn:epc:id:",
                      0x1F: "urn:epc:tag:",
                      0x20: "urn:epc:pat:",
                      0x21: "urn:epc:raw:",
                      0x22: "urn:epc:",
                      0x23: "urn:nfc:"]
                      
extension NFCURIRecord {
	static func parse(_ record: NdefRecord?) -> NFCURIRecord? {
		guard let record = record else { return nil }
		let tnf = record.getTnf()
		
		if tnf == NdefRecord.TNF_WELL_KNOWN {
			return NFCURIRecord.parseWellKnown(record)
		} else if tnf == NdefRecord.TNF_ABSOLUTE_URI {
			return NFCURIRecord.parseAbsolute(record)
		}
		
		return nil
	}
	
	static func parseAbsolute(_ record: NdefRecord) -> NFCURIRecord? {
		let payload = record.getPayload()
		let uintArray = payload.map { UInt8(bitPattern: $0) }
        guard let urlStr = String(bytes: uintArray, encoding: .utf8),
              let url = URL(string: urlStr) else {
            return nil
        }
		
		return NFCURIRecord(url: url)
	}
	
	static func parseWellKnown(_ record: NdefRecord) -> NFCURIRecord? {
//		guard record.getType() == NdefRecord.RTD_URI else { return nil }
		
		let payload = record.getPayload()
		let uintArray = payload.map { UInt8(bitPattern: $0) }
        /*
         * payload[0] contains the URI Identifier Code, per the
         * NFC Forum "URI Record Type Definition" section 3.2.2.
         *
         * payload[1]...payload[payload.length - 1] contains the rest of
         * the URI.
         */		
        guard let prefix = URI_PREFIX_MAP[Int(uintArray[0])],
              let urlStr = String(bytes: uintArray.dropFirst(), encoding: .utf8),
              let url = URL(string: prefix + urlStr) else {
            return nil
        }
        
		return NFCURIRecord(url: url)        
	}
}

extension NFCTextRecord {
	static func parse(_ record: NdefRecord?) -> NFCTextRecord? {
		print("Pavlo NFCTextRecord parse start \(record != nil)")
        guard let record = record,
              record.getTnf() == NdefRecord.TNF_WELL_KNOWN else {
            return nil
        }
        print("Pavlo NFCTextRecord first passed!")
		let payload = record.getPayload()
		let uintArray = payload.map { UInt8(bitPattern: $0) }
        print("Pavlo NFCTextRecord second passed!")		
        /*
         * payload[0] contains the "Status Byte Encodings" field, per the
         * NFC Forum "Text Record Type Definition" section 3.2.1.
         *
         * bit7 is the Text Encoding Field.
         *
         * if (Bit_7 == 0): The text is encoded in UTF-8 if (Bit_7 == 1):
         * The text is encoded in UTF16
         *
         * Bit_6 is reserved for future use and must be set to zero.
         *
         * Bits 5 to 0 are the length of the IANA language code.
         */
        let textEncoding: String.Encoding = ((uintArray[0] & 0200) == 0) ? .utf8 : .utf16
        let languageCodeLength = Int(uintArray[0] & 0077)
        print("Pavlo NFCTextRecord third passed! textEncoding = \(textEncoding) length = \(languageCodeLength)")
        print("Pavlo NFCTextRecord third passed! langcode = \(String(bytes: uintArray[1..<languageCodeLength], encoding: .ascii))")
        print("Pavlo NFCTextRecord third passed! text = \(String(bytes: uintArray[languageCodeLength + 1..<uintArray.count - languageCodeLength - 1], encoding: textEncoding))")
        
        guard let languageCode = String(bytes: uintArray[1..<languageCodeLength], encoding: .ascii),
              let text = String(bytes: uintArray[languageCodeLength + 1..<uintArray.count - languageCodeLength - 1], encoding: textEncoding) else {
            return nil
        }
        print("Pavlo NFCTextRecord fourth passed! text = \(text) code = \(languageCode)")
        let textRecord = NFCTextRecord(string: text, locale: Locale(identifier: languageCode))
        print("Pavlo NFCTextRecord final passed!")
        return textRecord
	}
	
	static func getDefault(_ record: NdefRecord?) -> NFCTextRecord? {
		guard let record = record else { return nil }	
		let payload = record.getPayload()
		let uintArray = payload.map { UInt8(bitPattern: $0) }
        guard let text = String(bytes: uintArray, encoding: .utf8) else {
        	return nil
        }
        
        return NFCTextRecord(string: text, locale: Locale(identifier: "en"))        
	}
}