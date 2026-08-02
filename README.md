# 🎙️ Eloqui — On-Device AI English & IELTS Coach

Eloqui is a 100% private, on-device AI English speaking, IELTS prep, and pronunciation coach powered by Flutter, llama.cpp, Whisper STT, and Piper TTS.

![Eloqui Logo](assets/images/app_logo.png)

---

## ✨ Features

- 💬 **Daily AI Conversations**: Real-time speaking practice across 10+ modes (Daily, Job Interview, Travel, Business, Airport, Hospital, Debate, Public Speaking).
- 🎓 **IELTS & Exam Preparation**: Part 1, Part 2 (Cue Cards), and Part 3 full mock exams with zero-speech safeguards and dynamic band scoring.
- 🎯 **TOEFL, PTE & DET Modules**: Complete test practice with official scoring scales (TOEFL 0-30, PTE 10-90, DET 10-160).
- 🎙️ **On-Device Speech & Voice**: Direct microphone recording, Whisper STT transcription, and Piper TTS neural voice output.
- ⚡ **Local LLM Execution**: Supports Qwen 1.8B, Qwen 4B, and Gemma 2B GGUF model bundles downloaded directly from Hugging Face.
- 📊 **Performance Diagnostics & Benchmarks**: Real-time token generation speed (tokens/sec), latency metrics (TTFT, STT, TTS), and RAM memory monitoring.
- 🔒 **100% Privacy**: All AI inference runs locally on your device GPU/CPU. Zero conversation data uploaded to external servers.

---

## 🛠️ Tech Stack & Architecture

- **UI & Logic**: Flutter 3.22+, Dart 3.4+
- **State Management**: Riverpod (`flutter_riverpod`)
- **Routing**: GoRouter
- **Local Storage**: SQLite (`sqflite`), `shared_preferences`
- **Native AI Engine**: C++ FFI via `dart:ffi` dynamic library (`libeloqui_native.so`)
- **Speech-to-Text**: Whisper STT
- **Text-to-Speech**: Piper TTS ONNX
- **Networking**: Dio (`dio`) for model bundle downloads from Hugging Face CDN

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (>=3.3.0)
- Android Studio / Android NDK (for native compilation)

### Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/eloqui.git
cd eloqui

# Get dependencies
flutter pub get

# Run tests
flutter test

# Run application
flutter run
```

### Building Release APK

```bash
flutter build apk --release --split-per-abi
```

Generated APKs will be located under `build/app/outputs/flutter-apk/`:
- `app-arm64-v8a-release.apk` (ARM 64-bit devices)
- `app-x86_64-release.apk` (Emulators / ChromeOS)
- `app-release.apk` (Universal Bundle)

---

## 📑 Documentation

For architecture details, SQLite table schemas, memory safeguards, and future version milestones, view the [Roadmap.md](Roadmap.md) document.

---

## 📜 License

This project is licensed under the MIT License.
