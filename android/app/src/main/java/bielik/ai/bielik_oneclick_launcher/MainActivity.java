package bielik.ai.bielik_oneclick_launcher;

import io.flutter.embedding.android.FlutterActivity;

public class MainActivity extends FlutterActivity {
    private IncomingTextChannel incomingText;

    @Override
    protected void onCreate(android.os.Bundle state) {
        super.onCreate(state);
        incomingText.restore(state);
        incomingText.accept(getIntent());
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
        DeviceResourcesChannel.register(
            getApplicationContext(),
            flutterEngine.getDartExecutor().getBinaryMessenger()
        );
    }
}
