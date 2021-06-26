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
	private let receiver = NFCReceiver()
  
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

		receiver.receiver = completion
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
	var receiver: ((NFCMessage?) -> Void)?
	public func onReceive(context: Context?, intent: Intent?) {
    }
    
    static func didReceive(context: Context?, intent: Intent?) {
    	print("Pavlo static func")
    }
}