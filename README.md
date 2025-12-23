# Network Debugger

A Flutter package for debugging network requests and responses made with Dio. This package provides a beautiful, interactive UI to view, search, and inspect all network activity in your app.

## Features

- 📡 **Automatic logging** of all Dio requests and responses
- 🔍 **Search and filter** logs by URL, method, or content
- 📊 **Statistics dashboard** showing total requests, responses, and errors
- 🌳 **JSON tree viewer** with expandable/collapsible nodes
- 📋 **Copy to clipboard** for easy sharing
- 🎨 **Color-coded logs** (blue for requests, green for responses, red for errors)
- 📱 **Beautiful UI** with Material Design
- 🛡️ **Safe with large payloads** – responses are truncated and capped to avoid UI freezes/crashes

## Installation

Add one of the following to your package's `pubspec.yaml` file under `dev_dependencies` (since this is a debugging/QA tool):

### 1. Use the tagged GitHub release (`v1.1.3`)

This uses the **`v1.1.3`** tag:

```yaml
dev_dependencies:
  flutter_qa_debug_tool:
    git:
      url: https://github.com/AhmedHusseinHafez/flutter_qa_debug_tool.git
      ref: v1.1.3
```

### 2. Use a local path (for local development)

```yaml
dev_dependencies:
  flutter_qa_debug_tool:
    path: ../packages/flutter_qa_debug_tool
```

### 3. Use pub.dev (when published)

```yaml
dev_dependencies:
  flutter_qa_debug_tool: ^1.1.3
```

Then run:

```bash
flutter pub get
```

## Usage

### 1. Attach to Dio

Attach the network debugger to your Dio instance:

```dart
import 'package:flutter_qa_debug_tool/network_debugger.dart';
import 'package:dio/dio.dart';

final dio = Dio();
NetworkDebugger.attachToDio(dio);
```

### 2. Open the Logger Screen

You can open the network logger screen from anywhere in your app:

```dart
// From a button
ElevatedButton(
  onPressed: () => NetworkDebugger.open(context),
  child: const Text('View Network Logs'),
)

// Or use the ready-made FAB
Scaffold(
  floatingActionButton: NetworkDebugger.fab(),
  body: YourContent(),
)
```

### 3. Conditional Enablement

You can conditionally enable the debugger based on your environment:

```dart
if (kDebugMode || isQAEnvironment) {
  NetworkDebugger.attachToDio(dio);
}
```

## API Reference

### `NetworkDebugger.attachToDio(Dio dio, {bool enabled = true})`

Attaches the network logger interceptor to a Dio instance.

**Parameters:**
- `dio`: The Dio instance to attach the logger to
- `enabled`: Whether to enable logging (default: `true`)

> **Performance note (since `1.1.0`)**
>
> - The in‑memory log buffer keeps the **newest ~200 entries** and drops older ones automatically.
> - Each entry (request/response/error) is capped to a **maximum number of characters**.
> - Very large payloads are **truncated for on‑screen preview** with a clear `...[truncated]` marker, but you can still use **Copy** to inspect the full raw text that Dio produced.
> - These safeguards are designed to **prevent freezes and crashes** when your backend returns huge JSON or binary blobs.

### `NetworkDebugger.open(BuildContext context)`

Opens the network logger screen.

**Parameters:**
- `context`: BuildContext to use for navigation

### `NetworkDebugger.fab({Key? key})`

Returns a ready-to-use FloatingActionButton that opens the logger screen.

**Parameters:**
- `key`: Optional key for the FAB widget

## Example

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_qa_debug_tool/network_debugger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup Dio with network debugger
    final dio = Dio();
    NetworkDebugger.attachToDio(dio);

    return MaterialApp(
      home: HomeScreen(dio: dio),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Dio dio;

  const HomeScreen({super.key, required this.dio});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => NetworkDebugger.open(context),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Make a network request
            await dio.get('https://api.example.com/data');
          },
          child: const Text('Make Request'),
        ),
      ),
      // Optional: Always-visible FAB for debugging
      floatingActionButton: NetworkDebugger.fab(),
    );
  }
}
```

## License

MIT

