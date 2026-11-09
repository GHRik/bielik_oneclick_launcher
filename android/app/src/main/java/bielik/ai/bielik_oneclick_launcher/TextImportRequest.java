package bielik.ai.bielik_oneclick_launcher;

final class TextImportRequest {
    static final String ACTION = "bielik.ai.bielik_oneclick_launcher.ASK_BIELIK";

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
