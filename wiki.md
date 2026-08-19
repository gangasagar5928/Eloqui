# Eloqui Technical Wiki & Architecture Reference

> **Version:** 1.0.0 Production | **Framework:** Flutter 3.22+ / Dart 3.x / C++ FFI | **Target:** Android (ARM64-v8a / x86_64)
>
> This wiki is the comprehensive engineering guide for Eloqui, an on-device, zero-latency, private AI English and IELTS/PTE/TOEFL speaking coach.

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Native C++ FFI Engine & Memory Isolation](#2-native-c-ffi-engine--memory-isolation)
3. [Sequential AI Lifecycle Pipeline](#3-sequential-ai-lifecycle-pipeline)
4. [IELTS / PTE / TOEFL / DET Evaluation Engine](#4-ielts--pte--toefl--det-evaluation-engine)
5. [Core Services & Providers](#5-core-services--providers)
6. [Offline Database & Data Schemas](#6-offline-database--data-schemas)
7. [UI & Feature Modules](#7-ui--feature-modules)
8. [Hardware Adaptation & Battery Optimization](#8-hardware-adaptation--battery-optimization)
9. [Automated Verification & CI/CD](#9-automated-verification--cicd)

---

## 1. High-Level Architecture

Eloqui runs fully on-device without cloud API dependencies. The architecture is structured in four decoupled tiers:

```
┌────────────────────────────────────────────────────────────┐
│                       UI / Features                        │
│   IELTS (Part 1/2/3) │ PTE │ TOEFL │ DET │ Practice Hub    │
│   Analytics │ Vocabulary │ Daily Plan │ Diagnostics Shell  │
├────────────────────────────────────────────────────────────┤
│                    Application State & Core                │
│   SettingsProvider │ BatterySaverProvider │ AdaptivePlanner│
├────────────────────────────────────────────────────────────┤
│                  Core Services / Evaluator                 │
│   IeltsEvaluator │ GrammarService │ NativeResourceManager  │
├────────────────────────────────────────────────────────────┤
│               Native C++ FFI Inference Engine              │
│   Whisper.cpp (STT) ─► Llama.cpp (LLM) ─► Piper (TTS)     │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Native C++ FFI Engine & Memory Isolation

To avoid the *"Multi-Model RAM Cliff"* on mid-range Android devices (4GB-6GB RAM), Eloqui uses `NativeFfiBridge` and `NativeResourceManager`:

- **Deterministic Memory Reclamation:**
  1. `stt_init()` loads Whisper Tiny/Base GGUF into memory (~200MB).
  2. Microphone buffer processes PCM 16kHz audio.
  3. Transcribed text passes to Dart; `stt_free()` immediately releases audio buffers.
  4. `llm_init()` allocates Llama 3.2 1B / Qwen 2.5 1.5B 4-bit quantized model (~1.1GB).
  5. Evaluator generates scores, grammar corrections, and feedback tokens.
  6. `llm_free_context()` purges KV-cache buffers before TTS initialization.
  7. `tts_init()` loads Piper ONNX voice model (~65MB) to synthesize streaming waveform.

---

## 3. Sequential AI Lifecycle Pipeline

```
[Audio Input (16kHz PCM)]
           │
           ▼
┌───────────────────────┐
│ Whisper STT (200MB)   │  ──► Transcribes user audio to raw string
└───────────────────────┘
           │ (Reclaims STT context)
           ▼
┌───────────────────────┐
│ Llama.cpp 1.5B (1.1GB)│  ──► Assesses Lexical Resource, Fluency,
└───────────────────────┘      Coherence, Grammatical Range & Accuracy
           │ (Flushes KV cache)
           ▼
┌───────────────────────┐
│ Piper Neural TTS (65MB│  ──► Speaks native pronunciation feedback
└───────────────────────┘
```

---

## 4. IELTS / PTE / TOEFL / DET Evaluation Engine

`IeltsEvaluator` computes authentic band scores (0.0 to 9.0) using rubric metrics:
- **Fluency and Coherence (FC):** Measures words-per-minute (WPM), hesitation pause ratios, and discourse marker usage.
- **Lexical Resource (LR):** Evaluates CEFR level distribution (A1-C2), idiom variety, and academic vocabulary density.
- **Grammatical Range and Accuracy (GRA):** Parses complex clause structures, tense consistency, and subject-verb agreements.
- **Pronunciation (PR):** Analyzes phoneme alignment and stress patterns.

---

## 5. Core Services & Providers

- `AiEngine` / `AiSessionManager`: Coordinates async execution, token streaming, and cancellation tokens.
- `ContentPackManager`: Manages localized IELTS cue cards, PTE templates, and TOEFL independent speaking topics.
- `DownloadManager`: Handles resumable SHA256-verified GGUF/ONNX model downloads.
- `DiagnosticsService`: Collects frame rate, memory footprint, thermal throttling, and inference latency benchmarks.

---

## 6. Offline Database & Data Schemas

Local persistence is managed by `DbHelper` (`sqflite`):
- `conversations`: Stores prompt histories, audio waveforms, and token transcripts.
- `ielts_scores`: Detailed evaluation logs, radar breakdown metrics, and feedback.
- `vocabulary_words`: Spaced-repetition (SM-2 algorithm) vocabulary tracker with mastery ratings.

---

## 7. UI & Feature Modules

- `IeltsScreen`: Comprehensive simulator with Part 1 (Introduction), Part 2 (Cue Card with 1-min preparation timer), and Part 3 (Two-way Discussion).
- `PteScreen` & `ToeflScreen`: Format-specific testing modes with countdown beeps.
- `PracticeHub`: Targeted drill modules for pronunciation, connector words, and idioms.
- `PrivacyDashboardScreen`: Visual audit demonstrating 0 bytes transmitted over external networks.

---

## 8. Hardware Adaptation & Battery Optimization

- `BatterySaverProvider`: Reduces LLM context window from 2048 to 1024 tokens and disables background pre-warming when battery is below 20%.
- `DeviceHardwareService`: Probes CPU cores, NEON support, and OpenCL/Vulkan GPU availability to select optimal GGML thread counts.

---

## 9. Automated Verification & CI/CD

The repository includes test suites and GitHub Actions CI in `.github/workflows/ci.yml`:
- Static code analysis (`flutter analyze`).
- Unit and widget test suite (`flutter test`).
- Native ABI linkage checks and APK build verification.