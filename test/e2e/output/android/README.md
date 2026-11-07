# Android E2E output

Run the tests using the [E2E quick start](../../README.md). Each run creates a separate `<run-id>_<suite>` directory here. Generated files are ignored by Git; this guide stays in the repository.

```text
<run-id>_<suite>/
├── report.json
├── devices.json
└── <phase>/
    ├── flutter.log
    ├── device-report.json
    ├── logcat.txt
    └── screenshots/
```

The complete suite has five phases: `download`, `cpu`, `create`, `verify`, and `delete`.

| Artifact | Format | Contents |
| --- | --- | --- |
| `report.json` | JSON | Overall status, device, source revision, phase results, and errors |
| `devices.json` | JSON | Devices discovered by Flutter at startup |
| `flutter.log` | Plain text | Build and test output for the phase |
| `device-report.json` | JSON | Scenario result and measurements returned by the test app |
| `logcat.txt` | Plain text | Android logs filtered by the E2E app UID |
| `screenshots/*.png` | PNG | Screenshot attempted after a scenario failure |

An overall `blocked` result means the tests did not start, for example because no Android device was connected. Building an APK alone does not count as an E2E pass. A build failure or process crash may prevent the device report and screenshot from being collected.

Logs and screenshots can contain test conversations. Use synthetic prompts rather than private data.
