package FusionNFC_Android;
import android.util.Log;

public class NFCReceiver extends android.content.BroadcastReceiver {
  private long _ptr;
  
  public void onReceive(android.content.Context context, android.content.Intent intent) {
  	Log.e("pavlo", context.toString());
  	Log.e("pavlo", intent.toString());
  	Log.e("pavlo", _ptr + "");
    onReceiveImpl(_ptr ,context ,intent);
  }
  private native void onReceiveImpl(long _ptr, android.content.Context context, android.content.Intent intent);
  
}
