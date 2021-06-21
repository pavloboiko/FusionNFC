import Foundation
import Java
import Android
import AndroidOS
import AndroidApp
import AndroidContent
import AndroidNFC

import FusionNFC_Common

public class NFCUtility {
	private var currentActivity: Activity? { Application.currentActivity }
	private var adapter: NfcAdapter? = nil  
	private var receiver: Class<NFCReceiver>?
  
	public required init(alertMessage: String) {
		let nfcManager = self.currentActivity?.getSystemService(name: ContextStatic.NFC_SERVICE) as? NfcManager
        self.adapter = nfcManager?.getDefaultAdapter()
        self.receiver = Class<NFCReceiver>()
	}
	

}

extension NFCUtility: NFCUtilityProtocol {
    public static var readingAvailable: Bool {
        return true
    }
    
    public func readTag(_ completion: @escaping (NFCMessage?) -> Void) {
    	print("pavlo read Tag called")
		enableNfcForegroundDispatch()
		guard let receiver = self.receiver else {
			completion(nil)
			return
		}
		receiver.cast(obj: NFCReceiver())?.receiver = completion
    }
    
    public func writeTag(_ message: NFCMessage) {
    }
    
    private func enableNfcForegroundDispatch() {
        print("pavlo start enable")
//        let intent = self.currentActivity?.getIntent()?.addFlags(flags: Intent.FLAG_ACTIVITY_SINGLE_TOP)
		let intent =  Intent(packageContext: self.currentActivity, cls: self.receiver)
        let nfcPendingIntent = PendingIntent.getBroadcast(context: self.currentActivity, requestCode: 0, intent: intent, flags: 0)
        self.adapter?.enableForegroundDispatch(activity: self.currentActivity, intent: nfcPendingIntent, filters: [], techLists: [])
        print("pavlo end enable")        
    }
    
    private func disableNfcForegroundDispatch() {
		self.adapter?.disableForegroundDispatch(activity: self.currentActivity)
	}
}

class NFCReceiver: Object, BroadcastReceiver {
	var receiver: ((NFCMessage?) -> Void)?
	public func onReceive(context: Context?, intent: Intent?) {
	    var uriRecord: NFCURIRecord?
        if let url = URL(string: "https://pavlo.com/") {
            uriRecord = NFCURIRecord(url: url)
        }
        
        let textRecord = NFCTextRecord(string: "Pavlo Test NFC", locale: Locale(identifier: "en"))
        let nfcMessage = NFCMessage(uriRecord: uriRecord, textRecord: textRecord)
        receiver?(nfcMessage)
		print("Pavlo really?")
    }    
}