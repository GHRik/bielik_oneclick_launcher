# Application architecture

## Layout and dependencies

`lib/main.dart` initializes platform services, selects implementations, and injects dependencies into the application. `lib/src/app.dart` configures the app and passes dependencies to screens. Tests can supply alternative implementations.

```text
lib/
├── main.dart
├── configuration/
│   ├── bielik_models.dart        # Model catalog and download metadata
│   ├── llm_configuration.dart    # Default and per-model LLM profiles
│   ├── system_prompt.dart       # Initial instruction for Bielik
│   └── database_configuration.dart
└── src/
    ├── app.dart
    ├── presentation/            # Pages, widgets, controllers, sidebars, formatters
    ├── domain/                  # Models, repository contracts, business services
    └── data/                    # Data sources and repository implementations
```

| Layer | Responsibility | Allowed dependencies |
| --- | --- | --- |
| Domain | Business rules, models, repository contracts | Pure Dart and domain code; `characters` preserves Unicode title boundaries |
| Presentation | Screens, widgets, and view state | Domain and presentation code |
| Data | Storage, downloads, inference, and platform readings | Domain and data code; Flutter foundation/platform services as needed |
| Application setup | Configuration and dependency injection | Connects the implementations to the app |

Domain, data, and presentation do not import `lib/configuration/`. Configuration enters through dependency injection. Data does not depend on UI packages, and presentation does not import data implementations.

## Configuration

`ConfiguredModelCatalogRepository` receives the catalog from `configuration/bielik_models.dart`. Adding a model requires its display information, GGUF URL, filename, exact size, SHA-256, and resource requirements. The runtime must support the model's architecture.

`configuration/llm_configuration.dart` defines shared defaults and optional entries in `modelLlmConfigurations`, keyed by `ModelFile.name`. Without an override, `llmConfigurationFor` returns the default profile. The initial Bielik instruction is in `configuration/system_prompt.dart`.

The settings screen edits a presentation-layer draft and validates it before saving. `LlmSettingsRepository` separates persisted configuration from the UI. Its SQLite implementation saves the complete CPU/generation profile atomically in `settings`. Startup loads the profile, and a successful save replaces the configuration used on the next chat opening. Before the first save, the per-model file configuration applies.

GPU settings are session-only and disabled at startup.

## Model downloads and resource checks

`ModelFilesRepository` defines downloading, cancellation, readiness, and deletion. `FlutterModelDownloadDataSource` delegates transfers to `flutter_downloader`, which persists tasks and uses WorkManager on Android. The plugin is initialized before the UI starts.

`LocalModelFilesRepository` reads task state, measures file growth for speed and ETA, and verifies the exact size and SHA-256 before renaming a `.part` file to its final name. Closing a screen does not cancel the task. A transfer that ends without a cancellation from the user (lost network, work stopped by Android) is reported as interrupted and its `.part` file stays; the next download enqueues a new task and the plugin continues from the existing file. The plugin keeps that file only for tasks marked resumable, so `FlutterModelDownloadDataSource.keepPartialFile` sets the mark in the plugin's task table right after enqueuing and clears it before a cancellation; if setting it fails, the part is removed and the download starts over, as before. Selecting the model again reconnects to a saved task, including a transfer completed while the app was absent. Verification then runs when the app opens. Files remain in the app's private directory; deleting a model also removes associated download tasks.

`DeviceResourcesRepository` exposes total/available RAM and free storage in bytes. `LocalDeviceResourcesRepository` uses `DeviceResourcesDataSource` over the `bielik/device_resources` platform channel. Android's `DeviceResourcesChannel` reads `ActivityManager.MemoryInfo` and `StatFs` for the model storage directory on a background queue, without extra permissions. Unsupported platforms or errors produce unavailable readings.

`DeviceResourcesController` refreshes on opening, app resume, return from chat, and model download/deletion. Another platform can implement the same contract without changing the view. Displayed GB values use one billion bytes, matching model sizes.

`ModelRequirements.evaluate` owns the RAM/storage decision and `requiresConfirmation` result. Widgets display those results and show confirmation dialogs.

## Chat and inference

`Conversation` is a domain model. `ConversationController` holds the chat library controller, draft input, and view state. `ChatWorkspace` manages conversation selection and lifecycle.

`AssistantMarkdownMessage` renders assistant replies as selectable Markdown in presentation, including streamed updates. User messages remain literal text. Stored messages and LLM context keep the original Markdown source; rendering does not modify the database. Markdown image references are displayed as text rather than fetched from the network.

`ChatService` owns the send operation: derive a title, persist the user message, invoke the LLM, and periodically save the assistant's partial reply as well as its final text. It serializes writes with draft updates and emits `ChatMessageSaved` / `ChatMessageUpdated` events. It does not know Flutter controllers or the chat UI library.

`ChatWorkspace` delegates commands and maps events to the appropriate conversation controller, including after switching conversations. Deleting an active conversation waits for generation to stop. Leaving chat or sending the app to the background stops generation and releases the engine after pending writes finish.

`LlmRepository` defines streamed replies, stopping, and model release. `LocalLlmRepository` opens the locally downloaded GGUF using `llamadart` / `llama.cpp`. The selected model is loaded on the first request and reused while working in chat. A different model file or profile reloads the engine.

`ChatContextPolicy` merges consecutive messages with the same role and selects the newest turns fitting the context budget. The runtime supplies token counts using the actual model chat template. Defaults are a 2048-token context and a 512-token response limit. The complete stored history is preserved.

### CPU and GPU

`CpuRuntimeAdapter` explicitly selects `ComputeDevice.cpu`, `GpuBackend.cpu`, and zero GPU layers. `GpuInferenceAdapter` separately maps GPU settings to Vulkan/OpenCL and checks the reported backend and offloaded layers before generation.

`ComputeRoutingLlmRepository` keeps separate CPU and GPU engine instances. GPU is created only on explicit selection; switching mode releases the previous model. A GPU error releases its engine and is surfaced without silently retrying on CPU. No global Vulkan environment variables are changed.

Android bundles CPU, Vulkan, and OpenCL backends. The manifest declares the optional vendor OpenCL library. OpenCL GPU inference has been tested on OnePlus 15 and Pixel 8 Pro; it does not work on Samsung Galaxy S24+. Vulkan has not been tested. `LlmRuntimeInfo` reports the active runtime to the view. Hardware GPU statistics are independent of inference routing.

## Statistics

`SamplingStatisticsRepository` extends the statistics contract with asynchronous sampling. `LocalStatisticsRepository` combines `StatisticsDataSource` with domain-level `GenerationMetrics`, retaining at most 61 samples from the last 60 seconds. `PreviewStatisticsRepository` remains available for previews and tests.

`StatisticsController` samples once per second in the foreground, including during generation and before the statistics screen opens. It stops its timer in the background and on disposal. Charts use actual timestamps, show gaps for unavailable readings, and do not invent zero-valued history. Samples are held in memory rather than SQLite.

Android's `DeviceStatisticsReader` runs on the platform channel's background queue. It reads process PSS for app RAM, CPU utilization from process time deltas as a percentage of combined core capacity, battery temperature, and CPU temperature when accessible. A denied CPU temperature reading remains unavailable; battery temperature is not substituted.

`GpuStatisticsReader` adds GPU temperature from `HardwarePropertiesManager` and read-only `GpuSysfsReader` sources: Adreno KGSL counters, GPU/Mali devfreq utilization, and GPU thermal zones. Thermal zone values are converted from millidegrees Celsius. Invalid counters, missing files, or denied access produce unavailable data. Utilization describes the whole GPU, not only the app; clock frequency is not treated as utilization.

Availability depends on device permissions and drivers. References: [HardwarePropertiesManager](https://developer.android.com/reference/android/os/HardwarePropertiesManager), [KGSL counter implementation](https://android.googlesource.com/kernel/msm/+/730cf84987cc34f1f0e53cbdd4153a2227563dc7/drivers/gpu/msm/kgsl_pwrctrl.c), and [Mali devfreq implementation](https://nest-open-source.googlesource.com/manifest_repos/mali-driver/+/268e43036ceb1097d004fa09786438f2319a2a0e/midgard/r13p0/kernel/drivers/gpu/arm/midgard/backend/gpu/mali_kbase_devfreq.c).

`GenerationMetrics` records time to first text from request start, including loading. Token counts and average token speed come from the engine's final usage report; streamed text chunks are not counted as tokens. Interrupted requests without a usage report do not increase the token total.

## SQLite persistence

`AppDatabase` manages the private `bielik.db` file, shared opening, schema creation, migrations, and closing. Schema version 2 includes `conversations`, `messages`, a message index, and `settings`. Messages reference conversations with `ON DELETE CASCADE`. Conversations store drafts of at most `Conversation.maxDraftLength` UTF-16 code units, and the conversation list reads no more than that from each row, so a row always fits in Android's 2 MB cursor window. Timestamps use UTC epoch milliseconds. The v1 → v2 migration preserves existing chats, including databases where the settings table already exists.

`ChatRepository` is the domain contract. `SqliteChatRepository` maps records to domain objects; `SqliteChatDataSource` executes queries. Presentation does not import SQLite.

On startup, `ChatWorkspace` restores conversations, messages, and drafts. An empty database gets an initial conversation. After restart, the most recently created conversation is selected; others remain in the sidebar.

`ChatService` explicitly requests `clearDraft: true` for user messages and `false` for assistant messages. The data source does not infer business rules from authors. Inserting a message, updating the title, and optionally clearing the draft form one transaction. Messages appear after persistence succeeds; SQLite-generated IDs survive app restarts.

Draft changes and chat operations are queued in order. An older send does not clear a newer draft. Read/write failures are exposed in chat, and a failed send leaves the input text available. Deleting a conversation permanently removes its messages; deleting the last conversation creates a new empty one.

### Platform database factory

`configuration/database_configuration.dart` selects a ready-made `DatabaseFactory`: `sqflite` on Android/iOS/macOS and `sqflite_common_ffi` on Windows/Linux. The factory is injected directly into `AppDatabase`, without custom database adapters or a global factory override. Desktop uses the application support directory; the Android database location is preserved.

Switching SQLite drivers does not require new repositories. Replacing SQLite with a different database requires implementations of `ChatRepository` and `LlmSettingsRepository`, plus data migration. Database portability alone does not complete an iOS or desktop port.

## Verification

See [test/README.md](test/README.md) for commands, test levels, and directory conventions.

Architecture tests enforce layer dependencies, allowed domain libraries, and the absence of UI dependencies in data. Unit tests cover individual classes with private fakes; component tests cover collaborators and views; integration tests use temporary SQLite files and fake inference/download backends. Manual [Android E2E tests](test/e2e/README.md) verify real downloads, CPU generation, and persistence across process restarts.
