package bielik.ai.bielik_oneclick_launcher;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    @Override
    public void configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        DeviceResourcesChannel.register(
            getApplicationContext(),
            flutterEngine.getDartExecutor().getBinaryMessenger()
        );
    }
}
