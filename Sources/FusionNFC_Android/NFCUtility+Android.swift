import Java
import Android
import AndroidOS
import AndroidApp
import AndroidContent
import AndroidNFC

import FusionLocation_Common

public class NFCManager {
	private var currentActivity: Activity? { Application.currentActivity }
	private var adapter: NfcAdapter? = null  
  
	public required init(alertMessage: String) {
		let nfcManager = self.currentActivity?.getSystemService(ContextStatic.NFC_SERVICE) as? NfcManager
        self.adapter = nfcManager.getDefaultAdapter()
	}
}

extension NFCUtility: NFCUtilityProtocol {
    public static var readingAvailable: Bool {
        return true
    }
    
    public func readTag(_ completion: @escaping (NFCMessage?) -> Void) {
        let intent = self.currentActivity?.getIntent()?.addFlags(IntentStatic.FLAG_ACTIVITY_SINGLE_TOP)
        let nfcPendingIntent = PendingIntent.getActivity(self.currentActivity, 0, intent, 0)
        self.adapter?.enableForegroundDispatch(self.currentActivity, nfcPendingIntent, null, null)
    }
    
    public func writeTag(_ message: NFCMessage) {
    }
}
