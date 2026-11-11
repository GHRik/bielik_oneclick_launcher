# Ask Bielik

On Android, select text in an app and choose **Zapytaj Bielika**. Some apps put text actions in the selection menu's overflow. If the host app does not support selection actions, share plain text to **Zapytaj Bielika** instead.

A `.txt` file shared to **Zapytaj Bielika** (for example from a file manager) is read into the draft as text. It follows the [TXT attachment](ATTACHMENTS.md) rules: UTF-8, at most 64 KiB, not empty and not binary. Each rejection has its own message, so a small file is no longer reported as exceeding the text limit.

The launcher opens the first conversation in its list, creates one if necessary, and appends the selection to its draft. It does not send the message or load a model. Press Send when ready. Selecting a conversation or sending a message moves it to the top; the order survives app restarts. Background draft and answer updates do not reorder chats.

Selections are plain text only, with a limit of 65,536 UTF-16 code units. Unsupported, empty, and oversized selections are rejected. Existing drafts are kept.

## Platform boundary

- Android: AskBielikActivity validates PROCESS_TEXT and SEND, reads a shared file from `EXTRA_STREAM` on a background thread (`content:` URIs only, checked by SharedTextFile), then constructs a fresh explicit intent containing only text.
- IncomingTextChannel handles cold starts and onNewIntent, queues events until Dart subscribes, consumes delivered intents, and restores pending native events across recreation.
- PlatformIncomingTextRepository adapts the event channel to IncomingTextRepository.
- HomePage coordinates navigation; ChatWorkspace imports and persists the draft through ChatRepository.

The Dart contract and import behavior do not depend on Android. iOS is not implemented: a future Share Extension and its App Group handoff can supply another IncomingTextRepository. iOS extension navigation and app foregrounding need a separate platform design.

## Local checks

```sh
flutter test test/component/chat/incoming_text_test.dart
flutter test test/ut_test.dart
flutter test test/integration/database
```

Native validation can be checked without a phone:

```sh
javac -encoding UTF-8 -d build/text-import-tests android/app/src/main/java/bielik/ai/bielik_oneclick_launcher/TextImportRequest.java test/integration/native/android/TextImportRequestTest.java
java -cp build/text-import-tests bielik.ai.bielik_oneclick_launcher.TextImportRequestTest
javac -encoding UTF-8 -d build/text-import-tests android/app/src/main/java/bielik/ai/bielik_oneclick_launcher/SharedTextFile.java test/integration/native/android/SharedTextFileTest.java
java -cp build/text-import-tests bielik.ai.bielik_oneclick_launcher.SharedTextFileTest
```

Device acceptance checks: cold-start from selected text, import while a chat is open, repeated imports, preservation of an existing draft, and a restart after saving the imported draft.
