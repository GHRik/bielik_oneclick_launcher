package bielik.ai.bielik_oneclick_launcher;

import android.content.Intent;
import android.os.Bundle;
import java.util.ArrayList;
import java.util.ArrayDeque;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;

final class IncomingTextChannel implements EventChannel.StreamHandler {
    static final String ACTION = TextImportRequest.ACTION;
    private final ArrayDeque<String> pending = new ArrayDeque<>();
    private EventChannel.EventSink sink;

    IncomingTextChannel(BinaryMessenger messenger) {
        new EventChannel(messenger, "bielik/incoming_text").setStreamHandler(this);
    }

    static String readText(Intent intent, boolean internal) {
        if (intent == null || !"text/plain".equals(intent.getType())) return null;
        String action = intent.getAction();
        String key;
        if (internal && ACTION.equals(action)) {
            key = Intent.EXTRA_TEXT;
        } else if (!internal && Intent.ACTION_PROCESS_TEXT.equals(action)) {
            key = Intent.EXTRA_PROCESS_TEXT;
        } else if (!internal && Intent.ACTION_SEND.equals(action)) {
            key = Intent.EXTRA_TEXT;
        } else {
            return null;
        }
        try {
            CharSequence value = intent.getCharSequenceExtra(key);
            return TextImportRequest.validate(action, intent.getType(), value, internal);
        } catch (RuntimeException error) {
            return null;
        }
    }

    void accept(Intent intent) {
        String text = readText(intent, true);
        if (text == null) return;
        intent.removeExtra(Intent.EXTRA_TEXT);
        intent.setAction(Intent.ACTION_MAIN);
        pending.add(text);
        drain();
    }

    void restore(Bundle state) {
        if (state == null) return;
        ArrayList<String> saved = state.getStringArrayList("bielik.pendingText");
        if (saved != null) pending.addAll(saved);
        drain();
    }

    void save(Bundle state) {
        state.putStringArrayList("bielik.pendingText", new ArrayList<>(pending));
    }

    private void drain() {
        while (sink != null && !pending.isEmpty()) sink.success(pending.removeFirst());
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        sink = events;
        drain();
    }

    @Override
    public void onCancel(Object arguments) {
        sink = null;
    }
}
