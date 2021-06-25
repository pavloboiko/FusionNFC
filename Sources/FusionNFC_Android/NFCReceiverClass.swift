import Foundation
import Java
import Android
import AndroidOS
import AndroidApp
import AndroidContent
import AndroidNFC

import FusionNFC_Common

public class NFCReceiver: Object, BroadcastReceiver {
	var receiver: ((NFCMessage?) -> Void)?
	public func onReceive(context: Context?, intent: Intent?) {
//	    var uriRecord: NFCURIRecord?
//        if let url = URL(string: "https://pavlo.com/") {
//            uriRecord = NFCURIRecord(url: url)
//        }
//        
//        let textRecord = NFCTextRecord(string: "Pavlo Test NFC", locale: Locale(identifier: "en"))
//        let nfcMessage = NFCMessage(uriRecord: uriRecord, textRecord: textRecord)
//        receiver?(nfcMessage)
		print("Pavlo really?")
    }
    
    static func pavlo(context: Context?, intent: Intent?) {
    	print("Pavlo static func")
    }
}