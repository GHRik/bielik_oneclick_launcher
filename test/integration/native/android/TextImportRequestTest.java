package bielik.ai.bielik_oneclick_launcher;

public final class TextImportRequestTest {
    public static void main(String[] args) {
        expect("Zażółć\nBielik", TextImportRequest.validate(
            "android.intent.action.PROCESS_TEXT", "text/plain", "Zażółć\nBielik", false));
        expect("Shared", TextImportRequest.validate(
            "android.intent.action.SEND", "text/plain", "Shared", false));
        expect(null, TextImportRequest.validate(
            "android.intent.action.VIEW", "text/plain", "Text", false));
        expect(null, TextImportRequest.validate(
            "android.intent.action.SEND", "application/pdf", "Text", false));
        expect(null, TextImportRequest.validate(
            "android.intent.action.SEND", "text/plain", null, false));
        expect(null, TextImportRequest.validate(
            "android.intent.action.SEND", "text/plain", "   ", false));
        expect(null, TextImportRequest.validate(
            "android.intent.action.SEND", "text/plain", "x".repeat(65537), false));
        expect("x".repeat(65536), TextImportRequest.validate(
            "android.intent.action.SEND", "text/plain", "x".repeat(65536), false));
        expect(null, TextImportRequest.validate(
            TextImportRequest.ACTION, "text/plain", "Text", false));
        expect(null, TextImportRequest.validate(
            "android.intent.action.SEND", "text/plain", "Text", true));
        expect("Text", TextImportRequest.validate(
            TextImportRequest.ACTION, "text/plain", "Text", true));
        expectDelivery(true, false, 0);
        expectDelivery(true, false, 0x10000000 | 0x04000000 | 0x20000000);
        expectDelivery(false, true, 0);
        expectDelivery(false, false, TextImportRequest.FLAG_LAUNCHED_FROM_HISTORY);
        expectDelivery(false, false, 0x10000000 | TextImportRequest.FLAG_LAUNCHED_FROM_HISTORY);
        expectDelivery(false, true, TextImportRequest.FLAG_LAUNCHED_FROM_HISTORY);
        System.out.println("TextImportRequest: 17 scenarios passed.");
    }

    private static void expectDelivery(boolean expected, boolean restored, int flags) {
        if (TextImportRequest.isNewDelivery(restored, flags) != expected) throw new AssertionError(
            "Unexpected launch intent delivery result");
    }

    private static void expect(String expected, String actual) {
        if (!java.util.Objects.equals(expected, actual)) throw new AssertionError(
            "Unexpected selection validation result");
    }
}
