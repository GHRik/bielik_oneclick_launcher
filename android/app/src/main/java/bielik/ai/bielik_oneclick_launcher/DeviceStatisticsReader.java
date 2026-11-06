package bielik.ai.bielik_oneclick_launcher;

import android.content.Context;
import android.os.Debug;

import java.util.HashMap;
import java.util.Map;

final class DeviceStatisticsReader {

    Map<String, Object> read(Context context) {
        Map<String, Object> values = new HashMap<>();
        try {
            values.put("appRamBytes", Debug.getPss() * 1024L);
        } catch (RuntimeException ignored) {
        }
        return values;
    }
}
