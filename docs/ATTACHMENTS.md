# TXT attachments

Use the plus button in the chat composer to select one .txt file. Its name and size appear above the input. Remove it with the close button, or press Send to submit it with your question. Sending a file without a typed question is supported. Picking a file never invokes inference.

The first implementation accepts UTF-8 text, including UTF-8 with BOM, up to 64 KiB. Empty files, binary content, other extensions and invalid UTF-8 are rejected. Legacy encodings such as Windows-1250 and UTF-16 need conversion to UTF-8 first.

Pending attachments are saved with their conversation draft. Sent attachment contents are stored in SQLite together with the message, independently of the original file. The chat displays the question and a clickable file tile; the model receives the full text. Tap a pending or sent attachment to open a read-only, scrollable text view with selection support. The view uses stored content, so the original file is not required. Removing an attachment never deletes the original file.

The 64 KiB import limit is not a guarantee that the text fits the selected model context. Attachment text is included in token counting. A latest input that exceeds the available context produces an error instead of silently truncating the file. Existing history trimming still applies to older turns; this feature does not implement document retrieval or chunking.

## Structure

- domain/models/text_attachment.dart: attachment content and typed import failures.
- domain/repositories/attachment_repository.dart: picker/import contract.
- data/datasources/txt_attachment_decoder.dart: UTF-8 validation and byte limit.
- data/repositories_impl/local_attachment_repository.dart: Flutter file_selector adapter using system file selection.
- data/datasources/local/text_attachment_codec.dart: SQLite serialization.
- presentation/controllers/chat_workspace.dart: per-conversation import and submission.
- presentation/widgets/chat/attachment_preview.dart: clickable file tile.
- presentation/pages/text_attachment_page.dart: read-only text viewer.

Future document formats should add separate text extractors behind the import boundary. Parsing belongs in data; prompt preparation and context budgeting stay shared.

No broad storage permission is added. The picker supports Android and has implementations for iOS and desktop; only the current Android target is built here. Schema version 4 also supports upgrading installations that used the separate version-3 conversation-ordering branch.

## Checks

Run flutter test and flutter analyze. Component tests cover selection, cancellation, removal, attachment-only sending, failed sends and conversation isolation. SQLite tests cover draft/message persistence and upgrades from versions 2 and 3. Native picker interaction and model quality require manual device testing.
