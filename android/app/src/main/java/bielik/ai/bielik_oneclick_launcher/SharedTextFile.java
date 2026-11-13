package bielik.ai.bielik_oneclick_launcher;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.charset.CharacterCodingException;
import java.nio.charset.CodingErrorAction;
import java.nio.charset.StandardCharsets;

/**
 * Turns a file shared to Ask Bielik into draft text. The rules match TXT attachments:
 * UTF-8 (a byte order mark is accepted), at most 64 KiB, no binary content, not empty.
 */
final class SharedTextFile {
    static final int MAX_BYTES = 64 * 1024;

    enum Failure { TOO_LARGE, NOT_TEXT, EMPTY }

    static final class Rejected extends Exception {
        private static final long serialVersionUID = 1L;
        final Failure failure;

        Rejected(Failure failure) {
            this.failure = failure;
        }
    }

    /** Reads at most one byte more than the limit, so a large file is never loaded whole. */
    static byte[] read(InputStream input) throws IOException {
        ByteArrayOutputStream bytes = new ByteArrayOutputStream();
        byte[] buffer = new byte[8192];
        int count;
        while (bytes.size() <= MAX_BYTES && (count = input.read(buffer)) != -1) {
            bytes.write(buffer, 0, Math.min(count, MAX_BYTES + 1 - bytes.size()));
        }
        return bytes.toByteArray();
    }

    static String decode(byte[] bytes) throws Rejected {
        if (bytes.length > MAX_BYTES) throw new Rejected(Failure.TOO_LARGE);
        String text;
        try {
            text = StandardCharsets.UTF_8.newDecoder()
                .onMalformedInput(CodingErrorAction.REPORT)
                .onUnmappableCharacter(CodingErrorAction.REPORT)
                .decode(ByteBuffer.wrap(bytes))
                .toString();
        } catch (CharacterCodingException error) {
            throw new Rejected(Failure.NOT_TEXT);
        }
        if (text.startsWith("﻿")) text = text.substring(1);
        for (int i = 0; i < text.length(); i++) {
            char c = text.charAt(i);
            if (c < 0x20 && c != '\t' && c != '\n' && c != '\r') throw new Rejected(Failure.NOT_TEXT);
        }
        if (text.trim().isEmpty()) throw new Rejected(Failure.EMPTY);
        return text;
    }
}
