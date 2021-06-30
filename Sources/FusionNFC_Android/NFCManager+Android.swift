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
		NFCReceiver.shared.usage = .read
		NFCReceiver.shared.receiver = completion
		
		enableNfcForegroundDispatch()
    }
    
    public func writeTag(_ message: NFCMessage) {
    	disableNfcForegroundDispatch()
		NFCReceiver.shared.usage = .write
		NFCReceiver.shared.message = message
		
		print("Pavlo write tag usage = \(NFCReceiver.shared.usage)")
		enableNfcForegroundDispatch()
    }
    
    public func disableForegroundDispatch() {
		disableNfcForegroundDispatch()
	}
	
    private func enableNfcForegroundDispatch() {
    	let testInt = 1
    	let testInt2 = 2
    	print("Pavlo testInt toJavaParameter = \(testInt.toJavaParameter())")
    	let testArray = [testInt.toJavaParameter(), testInt2.toJavaParameter()]
    	print("Pavlo testArray toJavaParameter = \(testArray.toJavaParameter())")
        print("pavlo start enable")
//        let intent = self.currentActivity?.getIntent()?.addFlags(flags: Intent.FLAG_ACTIVITY_SINGLE_TOP)
		let intent =  Intent(packageContext: self.currentActivity, cls: receiver.getClass())
//		print("pavlo receiver get class = \(receiver.getClass())")
        let nfcPendingIntent = PendingIntent.getBroadcast(context: self.currentActivity, requestCode: 0, intent: intent, flags: 0)
        self.adapter?.enableForegroundDispatch(activity: self.currentActivity, intent: nfcPendingIntent, filters: [], techLists: [])
        print("pavlo end enable")        
    }
    
    private func disableNfcForegroundDispatch() {
    	NFCReceiver.shared.message = nil
		self.adapter?.disableForegroundDispatch(activity: self.currentActivity)
	}
}

public class NFCReceiver: Object, BroadcastReceiver {
	static let shared = NFCReceiver()
	var receiver: ((NFCMessage?) -> Void)?
	var usage: SessionUsage = .none
	var message: NFCMessage?
	
	public func onReceive(context: Context?, intent: Intent?) {
		
    }
    
    static func didReceive(context: Context?, intent: Intent?) {
    	print("Pavlo static func")
    	guard let intent = intent else {
    		print("Pavlo return nil cause of instant")
    		NFCReceiver.shared.receiver?(nil)
    		return 
    	}
    	
		print("Pavlo didReceive usage = \(NFCReceiver.shared.usage)")    	
		if NFCReceiver.shared.usage == .read {
			readTag(intent)
		} else if NFCReceiver.shared.usage == .write {
			writeTag(intent)
		}
	}
 
 	private static func writeTag(_ intent: Intent) {
 		print("Pavlo writeTag message = \(NFCReceiver.shared.message != nil)")
 		guard let message = NFCReceiver.shared.message else { return }
		let action = intent.getAction()  	
        if NfcAdapter.ACTION_TAG_DISCOVERED == action ||
            NfcAdapter.ACTION_TECH_DISCOVERED == action ||
            NfcAdapter.ACTION_NDEF_DISCOVERED == action {
        	print("Pavlo writeTag discovered")
            let tag: Tag? = intent.getParcelableExtra(name: NfcAdapter.EXTRA_TAG)
    		let records = createRecord(message)
    		print("Pavlo writeTag records count = \(records.count) tag detect = \(tag != nil)") 
    		print("Pavlo writeTag toJavaParameter\(records.toJavaParameter())")
    		let ndefMessage = NdefMessage(records: records)
    		print("Pavlo writeTag get ndefMessage")
    		if let ndef = Ndef.get(tag: tag) {
        		print("Pavlo writeTag ndef get tag")
    			ndef.connect()
    			ndef.writeNdefMessage(msg: ndefMessage)
    			ndef.close()
        		print("Pavlo writeTag writeNdefMessage success!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    		}    		
        }
 	}
 	
 	private static func readTag(_ intent: Intent) {
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
            	print("Pavlo didReceive messages count = \(msgs.count)")
            	print("Pavlo didReceive messages = \(msgs)")            	
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
	static func createRecord(_ message: NFCMessage) -> [NdefRecord?] {
		var records: [NdefRecord?] = []
//		if let uriRecord = message.uriRecord {
//			let uri = uriRecord.url.absoluteString
//			let record = NdefRecord.createUri(uriString: uri)
//			records.append(record)
//		}
		
		if let textRecord = message.textRecord {
			if let lang = textRecord.locale.languageCode {
				let textBytes = Array(textRecord.string.utf8)
				let langBytes = Array(lang.utf8)
				let langLength = UInt8(langBytes.count)
				var uintArray: [UInt8] = []
				uintArray.append(langLength)
				uintArray.append(contentsOf: langBytes)
				uintArray.append(contentsOf: textBytes)
				let payload = uintArray.map { Int8(bitPattern: $0) }
				let record = NdefRecord(tnf: NdefRecord.TNF_WELL_KNOWN, _type: NdefRecord.RTD_TEXT, id: [], payload: payload)
				records.append(record)
			}
		}
    
    	return records
	}	
}

extension NFCReceiver {
    static func parse(message: NdefMessage) -> NFCMessage {
    	return NFCReceiver.getRecords(records: message.getRecords())
    }
    
    static func getRecords(records: [NdefRecord?]) -> NFCMessage {
        var nfcURIRecord: NFCURIRecord?
        var nfcTextRecord: NFCTextRecord?
        print("Pavlo getRecords records count = \(records.count)")
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
		guard record.getType() == NdefRecord.RTD_URI else { return nil }
		
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
              record.getTnf() == NdefRecord.TNF_WELL_KNOWN,
              record.getType() == NdefRecord.RTD_TEXT else {
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
        let textEncoding: String.Encoding = ((uintArray[0] & 0o0200) == 0) ? .utf8 : .utf16
        let languageCodeLength = Int(uintArray[0] & 0o0077)
        print("Pavlo NFCTextRecord third passed! textEncoding = \(textEncoding) length = \(languageCodeLength)")
        print("Pavlo NFCTextRecord third passed! uintArray = \(uintArray)")
//        print("Pavlo NFCTextRecord third passed! langcode = \(String(bytes: uintArray[1..<languageCodeLength], encoding: .ascii))")
//        print("Pavlo NFCTextRecord third passed! text = \(String(bytes: uintArray[languageCodeLength + 1..<uintArray.count - languageCodeLength - 1], encoding: textEncoding))")
        
        guard let languageCode = String(bytes: uintArray[1..<languageCodeLength], encoding: .ascii),
              let text = String(bytes: uintArray[languageCodeLength + 1..<uintArray.count], encoding: textEncoding) else {
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