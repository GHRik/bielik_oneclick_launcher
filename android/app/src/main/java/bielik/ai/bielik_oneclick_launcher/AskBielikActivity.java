package bielik.ai.bielik_oneclick_launcher;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;

public class AskBielikActivity extends Activity {
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
        if (text == null) {
            Toast.makeText(this, "Nie można odebrać tekstu. Limit to 65 536 znaków.", Toast.LENGTH_LONG).show();
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
