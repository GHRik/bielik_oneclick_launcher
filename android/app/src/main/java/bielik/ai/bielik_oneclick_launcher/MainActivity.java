package bielik.ai.bielik_oneclick_launcher;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    private IncomingTextChannel incomingText;

    @Override
    protected void onCreate(android.os.Bundle state) {
        super.onCreate(state);
        incomingText.restore(state);
        android.content.Intent intent = getIntent();
        if (intent != null && TextImportRequest.isNewDelivery(state != null, intent.getFlags())) {
            incomingText.accept(intent);
        }
    }

    @Override
    protected void onNewIntent(android.content.Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        incomingText.accept(intent);
    }

    @Override
    protected void onSaveInstanceState(android.os.Bundle state) {
        incomingText.save(state);
        super.onSaveInstanceState(state);
    }

    @Override
    public void configureFlutterEngine(io.flutter.embedding.engine.FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        incomingText = new IncomingTextChannel(flutterEngine.getDartExecutor().getBinaryMessenger());
        ApkUpdateChannel.register(this, flutterEngine.getDartExecutor().getBinaryMessenger());
        AppInfoChannel.register(getApplicationContext(), flutterEngine.getDartExecutor().getBinaryMessenger());
        AppExitChannel.register(getApplicationContext(), flutterEngine.getDartExecutor().getBinaryMessenger());
        DeviceResourcesChannel.register(
            getApplicationContext(),
            flutterEngine.getDartExecutor().getBinaryMessenger()
        );
    }
}
