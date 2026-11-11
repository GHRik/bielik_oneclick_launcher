package bielik.ai.bielik_oneclick_launcher;

import java.io.ByteArrayInputStream;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

public final class SharedTextFileTest {
    public static void main(String[] args) throws Exception {
        expectText("Zażółć\ngęślą jaźń", "Zażółć\ngęślą jaźń".getBytes(StandardCharsets.UTF_8));
        expectText("Z BOM", new byte[] {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF, 'Z', ' ', 'B', 'O', 'M'});
        expectText("tab\tand\r\nline", "tab\tand\r\nline".getBytes(StandardCharsets.UTF_8));
        expectText("x".repeat(SharedTextFile.MAX_BYTES), filled(SharedTextFile.MAX_BYTES));

        expectFailure(SharedTextFile.Failure.TOO_LARGE, filled(SharedTextFile.MAX_BYTES + 1));
        expectFailure(SharedTextFile.Failure.NOT_TEXT, "Zażółć".getBytes(Charset.forName("windows-1250")));
        expectFailure(SharedTextFile.Failure.NOT_TEXT, new byte[] {'P', 'K', 3, 4, 20, 0});
        expectFailure(SharedTextFile.Failure.NOT_TEXT, "A\u0000B".getBytes(StandardCharsets.UTF_8));
        expectFailure(SharedTextFile.Failure.EMPTY, new byte[0]);
        expectFailure(SharedTextFile.Failure.EMPTY, " \n\t ".getBytes(StandardCharsets.UTF_8));
        expectFailure(SharedTextFile.Failure.EMPTY, new byte[] {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF});

        expectRead(10, 10);
        expectRead(SharedTextFile.MAX_BYTES, SharedTextFile.MAX_BYTES);
        expectRead(SharedTextFile.MAX_BYTES + 1, SharedTextFile.MAX_BYTES + 1);
        expectRead(SharedTextFile.MAX_BYTES + 1, 5 * 1024 * 1024);
        System.out.println("SharedTextFile: 15 scenarios passed.");
    }

    private static byte[] filled(int length) {
        byte[] bytes = new byte[length];
        Arrays.fill(bytes, (byte) 'x');
        return bytes;
    }

    private static void expectText(String expected, byte[] bytes) throws Exception {
        if (!expected.equals(SharedTextFile.decode(bytes))) throw new AssertionError(
            "Unexpected shared file text");
    }

    private static void expectFailure(SharedTextFile.Failure expected, byte[] bytes) {
        try {
            SharedTextFile.decode(bytes);
        } catch (SharedTextFile.Rejected rejected) {
            if (rejected.failure == expected) return;
            throw new AssertionError("Expected " + expected + " but got " + rejected.failure);
        }
        throw new AssertionError("Expected " + expected + " but the file was accepted");
    }

    private static void expectRead(int expectedLength, int available) throws Exception {
        int read = SharedTextFile.read(new ByteArrayInputStream(filled(available))).length;
        if (read != expectedLength) throw new AssertionError(
            "Expected to read " + expectedLength + " bytes but read " + read);
    }
}
