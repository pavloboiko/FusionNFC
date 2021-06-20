import Java
import Android
import AndroidOS
import AndroidApp
import AndroidContent
import AndroidNFC

import FusionLocation_Common

public class NFCManager {

	typealias AndroidLocationManager = AndroidLocation.LocationManager

	private var currentActivity: Activity? { Application.currentActivity }

	private let locationManager: AndroidLocationManager?
	private let locationListener: LocationListener
  
	public let usage: LocationUsage
	public var isOnlyOnce: Bool = false
  
  
	public required init(usage: LocationUsage) {
		self.usage = usage

		self.locationManager =
			Application.currentActivity?.getSystemService(name: ContextStatic.LOCATION_SERVICE)
			as? AndroidLocationManager
  
		self.locationListener = LocationListener()    
	}
}
