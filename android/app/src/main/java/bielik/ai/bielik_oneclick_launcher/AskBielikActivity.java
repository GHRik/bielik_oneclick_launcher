package bielik.ai.bielik_oneclick_launcher;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.widget.Toast;
import java.io.IOException;
import java.io.InputStream;

public class AskBielikActivity extends Activity {
    private static final String NO_TEXT = "Nie można odebrać tekstu. Udostępnij tekst albo plik TXT.";
    private static final String TEXT_TOO_LONG = "Tekst jest za długi. Limit to 65 536 znaków.";
    private static final String FILE_TOO_LARGE = "Plik jest za duży. Limit to 64 KiB.";
    private static final String FILE_NOT_TEXT = "Plik nie jest tekstem UTF-8. Zapisz go w UTF-8.";
    private static final String FILE_EMPTY = "Udostępniony plik jest pusty.";
    private static final String FILE_UNREADABLE = "Nie udało się odczytać pliku.";

    @Override
    protected void onCreate(Bundle state) {
        super.onCreate(state);
        forwardText(getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        forwardText(intent);
    }

    private void forwardText(Intent source) {
        String text = IncomingTextChannel.readText(source, false);
        if (text != null) {
            finishWith(text, null);
            return;
        }
        Uri file = sharedFile(source);
        if (file == null) {
            finishWith(null, textTooLong(source) ? TEXT_TOO_LONG : NO_TEXT);
            return;
        }
        // Content providers may read from disk or the network.
        new Thread(() -> {
            String content = null;
            String problem = null;
            try (InputStream input = getContentResolver().openInputStream(file)) {
                if (input == null) throw new IOException("No stream");
                content = SharedTextFile.decode(SharedTextFile.read(input));
            } catch (SharedTextFile.Rejected rejected) {
                problem = rejected.failure == SharedTextFile.Failure.TOO_LARGE ? FILE_TOO_LARGE
                    : rejected.failure == SharedTextFile.Failure.EMPTY ? FILE_EMPTY
                    : FILE_NOT_TEXT;
            } catch (IOException | RuntimeException error) {
                problem = FILE_UNREADABLE;
            }
            String imported = content;
            String message = problem;
            runOnUiThread(() -> {
                // Closed or recreated while the file was being read: the new
                // instance, if any, reads the file itself.
                if (!isFinishing() && !isDestroyed()) finishWith(imported, message);
            });
        }, "ask-bielik-shared-file").start();
    }

    /** A file shared with SEND arrives as a content URI in EXTRA_STREAM instead of EXTRA_TEXT. */
    @SuppressWarnings("deprecation")
    private static Uri sharedFile(Intent source) {
        if (source == null
            || !Intent.ACTION_SEND.equals(source.getAction())
            || !"text/plain".equals(source.getType())) {
            return null;
        }
        try {
            Uri uri = source.getParcelableExtra(Intent.EXTRA_STREAM);
            return uri != null && "content".equals(uri.getScheme()) ? uri : null;
        } catch (RuntimeException error) {
            return null;
        }
    }

    private static boolean textTooLong(Intent source) {
        if (source == null) return false;
        try {
            CharSequence text = Intent.ACTION_PROCESS_TEXT.equals(source.getAction())
                ? source.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)
                : source.getCharSequenceExtra(Intent.EXTRA_TEXT);
            return text != null && text.length() > 65536;
        } catch (RuntimeException error) {
            return false;
        }
    }

    private void finishWith(String text, String problem) {
        if (text == null) {
            Toast.makeText(this, problem, Toast.LENGTH_LONG).show();
        } else {
            Intent target = new Intent(this, MainActivity.class);
            target.setAction(IncomingTextChannel.ACTION);
            target.setType("text/plain");
            target.putExtra(Intent.EXTRA_TEXT, text);
            target.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            startActivity(target);
        }
        finish();
    }
}
