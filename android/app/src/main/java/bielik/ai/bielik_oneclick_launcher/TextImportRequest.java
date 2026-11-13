package bielik.ai.bielik_oneclick_launcher;

final class TextImportRequest {
    static final String ACTION = "bielik.ai.bielik_oneclick_launcher.ASK_BIELIK";

    /** Same value as Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY, usable in tests without Android. */
    static final int FLAG_LAUNCHED_FROM_HISTORY = 0x00100000;

    /**
     * Tells whether the intent that created the activity still has text to import.
     *
     * Android hands the original launch intent back when it recreates the activity after
     * the process was killed and when the task is reopened from Recents. That text was
     * imported, or saved as pending, the first time, so importing it again duplicates it.
     */
    static boolean isNewDelivery(boolean restored, int flags) {
        return !restored && (flags & FLAG_LAUNCHED_FROM_HISTORY) == 0;
    }

    static String validate(String action, String type, CharSequence value, boolean internal) {
        boolean allowed = internal
            ? ACTION.equals(action)
            : "android.intent.action.PROCESS_TEXT".equals(action)
                || "android.intent.action.SEND".equals(action);
        if (!allowed || !"text/plain".equals(type) || value == null || value.length() > 65536) return null;
        String text = value.toString();
        return text.trim().isEmpty() ? null : text;
    }
}
