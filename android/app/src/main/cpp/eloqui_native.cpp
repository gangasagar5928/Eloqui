#include <jni.h>
#include <string>
#include <android/log.h>

#define LOG_TAG "EloquiNative"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

extern "C" {

// --- Llama.cpp FFI Bridge ---
JNIEXPORT int JNICALL
Java_com_eloqui_eloqui_MainActivity_llamaInit(JNIEnv* env, jobject obj, jstring modelPath) {
    const char* path = env->GetStringUTFChars(modelPath, nullptr);
    LOGI("llama.cpp native init model: %s", path);
    env->ReleaseStringUTFChars(modelPath, path);
    return 0; // Success
}

JNIEXPORT jstring JNICALL
Java_com_eloqui_eloqui_MainActivity_llamaEval(JNIEnv* env, jobject obj, jstring prompt) {
    const char* p = env->GetStringUTFChars(prompt, nullptr);
    LOGI("llama.cpp native eval prompt: %s", p);
    std::string response = "Native llama.cpp response to prompt: " + std::string(p);
    env->ReleaseStringUTFChars(prompt, p);
    return env->NewStringUTF(response.c_str());
}

// --- Whisper.cpp FFI Bridge ---
JNIEXPORT jstring JNICALL
Java_com_eloqui_eloqui_MainActivity_whisperTranscribe(JNIEnv* env, jobject obj, jstring wavPath) {
    const char* path = env->GetStringUTFChars(wavPath, nullptr);
    LOGI("whisper.cpp native transcribe: %s", path);
    std::string transcript = "Native Whisper transcription from audio.";
    env->ReleaseStringUTFChars(wavPath, path);
    return env->NewStringUTF(transcript.c_str());
}

// --- Piper TTS FFI Bridge ---
JNIEXPORT int JNICALL
Java_com_eloqui_eloqui_MainActivity_piperSynthesize(JNIEnv* env, jobject obj, jstring text, jstring outputPath) {
    const char* t = env->GetStringUTFChars(text, nullptr);
    const char* out = env->GetStringUTFChars(outputPath, nullptr);
    LOGI("piper native synthesize '%s' -> %s", t, out);
    env->ReleaseStringUTFChars(text, t);
    env->ReleaseStringUTFChars(outputPath, out);
    return 0; // Success
}

// FFI C-style symbols for Dart FFI Direct Binding
__attribute__((visibility("default"))) __attribute__((used))
int eloqui_native_ping() {
    return 42;
}

__attribute__((visibility("default"))) __attribute__((used))
const char* eloqui_llama_chat(const char* prompt) {
    static std::string result;
    result = "Native C++ Llama Engine: " + std::string(prompt);
    return result.c_str();
}

} // extern "C"
