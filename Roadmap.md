# Eloqui – Comprehensive Technical Architecture & Product Roadmap

Eloqui is an enterprise-grade, **100% offline**, privacy-first AI English speaking, IELTS, TOEFL, PTE, and Duolingo English Test (DET) coach for Android 8.0+ (API 26–35).

---

## 🏗️ 1. Complete System Architecture

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           Flutter UI (Material 3)                               │
│     [HomeScreen] [ConversationScreen] [IeltsScreen] [ToeflScreen] [PteScreen]     │
└──────────────────────────────────────┬──────────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────────┐
│                   State Management & Services Layer                             │
│  • Riverpod State Notifiers  • Settings & Power Profiles (Eco/Balanced/Perf)   │
│  • AISessionManager          • BatterySaverNotifier                              │
└───────────────────┬─────────────────────────────────────────┬───────────────────┘
                    │                                         │
┌───────────────────▼───────────────────────┐ ┌───────────────▼───────────────────┐
│      Dart Compute Isolate Engine          │ │         AI Sandbox & Recovery     │
│  • Instant 60-Rule Grammar Matcher        │ │  • Worker Isolate Execution       │
│  • Hybrid Rule + LLM Refinement           │ │  • 25-Second Timeout Safeguard    │
└───────────────────┬───────────────────────┘ └───────────────┬───────────────────┘
                    │                                         │
┌───────────────────▼─────────────────────────────────────────▼───────────────────┐
│                    SequentialModelPipeline (RAM Safeguard)                       │
│  • Whisper STT (Load -> Transcribe -> Destroy Context)                           │
│  • Llama.cpp LLM (Load -> Generate -> Release Heap)                              │
│  • Piper TTS (Load -> Synthesize PCM -> Destroy Context)                         │
└──────────────────────────────────────┬──────────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────────┐
│              Native C++ Engine & Dynamic FFI Bridge (NDK)                        │
│             `libeloqui_native.so` compiled via CMake 3.22                        │
│   • llama.cpp FFI   • whisper.cpp FFI   • piper_tts FFI   • Native Destructors    │
└──────────────────────────────────────┬──────────────────────────────────────────┘
                                       │
┌──────────────────────────────────────▼──────────────────────────────────────────┐
│                         Persistence & Database Layer                            │
│  • SQLite DbHelper (15 Versioned Tables)  • Local File Storage (crash_logs.txt)  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

---

## 🧠 2. Deep Technical Innovations

### 🛡️ SequentialModelPipeline (RAM Cliff Mitigation)
On 4GB and 6GB Android devices, running Llama LLM (1.8 GB heap) and Whisper STT (600 MB heap) concurrently with Android OS overhead exceeds memory limits, triggering the Low Memory Killer (LMK).
- **Solution**: Hot-swapping pipeline. Whisper loads $\rightarrow$ transcribes speech $\rightarrow$ executes native C++ destructor (`freeWhisperContext()`) $\rightarrow$ Llama loads $\rightarrow$ streams response $\rightarrow$ releases heap $\rightarrow$ Piper TTS synthesizes PCM audio.

### ⚡ Isolate Rule Engine + Hybrid Refinement
- **Rule Engine**: Runs 60+ grammar pattern checks inside a non-blocking background Dart isolate via `compute(_runRuleEngine, text)`, returning zero-jank feedback in <15ms.
- **Hybrid Mode**: When LLM is loaded, secondary deep grammar refinement evaluates subtle nuance and style.

### 🛡️ Worker Isolate AISandbox
- AI inference runs isolated from the UI main thread.
- If native C++ code panics or times out (>25 seconds), `AISandbox` intercepts the error, kills only the worker isolate, re-initializes `libeloqui_native.so`, and preserves user UI state seamlessly.

### 🔐 Multi-Tier Security Verification
- **SHA-256 Checksum**: Verifies file integrity after offline download/sideload.
- **RSA Digital Signatures**: `ModelBundleManifest.digitalSignatureRsa` verifies official Eloqui cryptographic signatures before mounting model weights.

---

## 🗄️ 3. Persistence Schema (15 SQLite Tables)

| Table | Purpose |
| :--- | :--- |
| `conversations` | Conversation metadata, session mode, message counter, duration |
| `messages` | Timestamped conversation transcripts and roles |
| `sessions` | Session duration, scores, and serialized JSON metadata |
| `pronunciation_results` | Fluency %, WPM, filler word count, pause count, confidence |
| `grammar_mistakes` | Original text, corrected text, rule ID, detailed explanation |
| `vocabulary_cards` | Words, definitions, IPA, CEFR level, SM-2 intervals & ease factor |
| `daily_logs` | Daily speaking seconds, session counts, accuracy trend |
| `ielts_scores` | Fluency, Lexical, Grammar, Pronunciation, Overall Band |
| `settings` | Key-value settings storage (theme, power profile, model path) |
| `user_profile` | Target CEFR level, target IELTS/TOEFL band, daily goal minutes |
| `mistake_history` | Historical mistake tracking for adaptive revision |
| `downloads` | Downloaded model packs, checksums, and RSA validation status |
| `custom_topics` | User-created custom speaking practice topics |
| `weekly_summary` | Aggregate weekly analytics for chart visualization |
| `achievements` | Gamification badges and streak milestone unlock status |

---

## 🗓️ 4. Version Roadmap (v1.0 to v3.0)

### ✅ Phase 1: v1.0 Core Release (Completed)
- [x] 100% Offline AI English Voice Conversations
- [x] IELTS Speaking Coach (Parts 1, 2, and 3) with Band Score Evaluator
- [x] 15 SQLite Tables with SM-2 Spaced Repetition Vocabulary Engine
- [x] C++ Native NDK Bridge (`libeloqui_native.so`) & Dynamic Dart FFI bindings
- [x] `SequentialModelPipeline` RAM Safeguard for low-memory devices
- [x] `AISandbox` Worker Isolate Crash Recovery
- [x] Power Profiles (`Eco`, `Balanced`, `Performance`)
- [x] Hardware Inspector (ARM64, RAM, NEON support check)
- [x] Privacy Dashboard & Developer Diagnostics Screen

### ✅ Phase 2: v1.5 Multi-Exam & Voice Expansion (Completed)
- [x] **TOEFL iBT Speaking Module** (`ToeflScreen`: Tasks 1–3 with 0–30 scale evaluation)
- [x] **PTE Academic Speaking Module** (`PteScreen`: Read Aloud, Repeat Sentence, Describe Image with 10–90 scale evaluation)
- [x] **Duolingo English Test Module** (`DetScreen`: Speak About Image, Read-then-Speak with 10–160 subscores)
- [x] **Voice Pack Manager**: Indian (`en_IN`), British (`en_GB`), American (`en_US`), and Australian (`en_AU`) accent support
- [x] **Downloadable Lesson Hub**: Offline Grammar, IPA, IELTS Band 9, Business, and Technical Interview Packs
- [x] **Home Screen Quick Actions**: Multi-exam navigation grid

### ⏳ Phase 3: v2.0 Multimodal & Custom Content (Q4 2026)
- [ ] **Local Multimodal Picture Description**: Quantized MobileVLM / Qwen-VL Q4 GGUF model for offline image analysis
- [ ] **`lesson_pack.json` Plugin Engine**: Open specification for community-created offline lesson bundles
- [ ] **Custom Lesson & Prompt Creator**: UI for users to author custom AI tutors and custom exam simulations
- [ ] **Vocabulary Import/Export**: CSV/Anki file importer and exporter for custom word decks

### ⏳ Phase 4: v2.5 Advanced Phonetics & Streaming Audio (Q1 2027)
- [ ] **Phoneme-Level Alignment**: Offline Wav2Vec2 alignment generating ARPAbet IPA visual heatmaps for word mispronunciations
- [ ] **Pitch & Intonation Contour**: Praat-style fundamental frequency ($F_0$) pitch tracking visualizer
- [ ] **Low-Latency Streaming Pipeline**: Direct C++ audio buffer streaming reducing end-to-end latency to <300ms

### ⏳ Phase 5: v3.0 Cross-Platform & Enterprise (Q2 2027)
- [ ] **Desktop Builds**: Native Windows, macOS, and Linux builds using existing C++ FFI core
- [ ] **Offline P2P Device Sync**: Local Wi-Fi / Bluetooth peer-to-peer data sync without cloud servers
- [ ] **Institutional Analytics Portal**: CSV/PDF cohort progress reporting for universities and language centers
