# Speech to text

Tap the microphone beside Send to dictate into the current message draft. Tap again to stop. Review or edit the text, then press Send yourself. No audio message is saved.

Speech recognition uses the device's system service through speech_to_text. Availability, language support, network use and silence timeouts depend on the service and device. Offline recognition is not guaranteed; the Bielik model itself still runs locally. The service uses the device's default recognition language.

Microphone permission is requested only after tapping the microphone. If access is denied, regular typing stays available. Enable microphone access in system app settings before retrying if the system no longer offers the permission dialog.

## Platform boundary

SpeechRecognitionRepository is the platform-independent contract. PlatformSpeechRecognitionRepository adapts speech_to_text. The presentation controller updates a draft without invoking the LLM.

The project currently includes Android only. When adding an iOS target, add NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription to Runner/Info.plist with user-facing explanations. The same speech adapter supports iOS; Siri integration is a separate future App Intents feature.

## Verification

Unit tests live beside the adapter and controller in ut directories and run through test/ut_test.dart. Widget tests cover microphone interaction in the chat. Device checks should cover permission denial, recognition in the desired language, silence timeout, interruption, and manual sending.
