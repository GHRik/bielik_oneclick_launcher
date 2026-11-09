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
        System.out.println("TextImportRequest: 11 scenarios passed.");
    }

    private static void expect(String expected, String actual) {
        if (!java.util.Objects.equals(expected, actual)) throw new AssertionError(
            "Unexpected selection validation result");
    }
}
