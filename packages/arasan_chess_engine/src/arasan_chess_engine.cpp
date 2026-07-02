#include "arasan_chess_engine.h"
#include "fixes/fixes.h"
#include <string>
#include <android/log.h>

#define BUFFER_SIZE 1024

// Declaration of Arasan's main entry point (defined in arasanx.cpp)
int main(int argc, char **argv);

char buffer[BUFFER_SIZE + 1];
char errBuffer[BUFFER_SIZE + 1];

FFI_PLUGIN_EXPORT int arasan_main() {
  __android_log_print(ANDROID_LOG_INFO, "ARASAN_NATIVE", "arasan_main: starting main thread");
  fakeout.reopen();
  fakein.reopen();

  int argc = 1;
  char *argv[] = {(char *)"arasan"};
  int exitCode = main(argc, argv);

  __android_log_print(ANDROID_LOG_INFO, "ARASAN_NATIVE", "arasan_main: main thread exited with code %d", exitCode);

#if _WIN32
  Sleep(100);
#else
  usleep(100000); // 100ms sleep
#endif

  fakeout.close();
  fakein.close();

  return exitCode;
}

FFI_PLUGIN_EXPORT ssize_t arasan_stdin_write(char *data) {
  __android_log_print(ANDROID_LOG_INFO, "ARASAN_NATIVE", "arasan_stdin_write: %s", data);
  std::string val(data);
  fakein << val << fakeendl;
  return val.length();
}

FFI_PLUGIN_EXPORT char* arasan_stdout_read() {
  std::string outputLine;
  if (fakeout.try_get_line(outputLine)) {
    outputLine += "\n"; // Append the newline back so Dart isolate can split and dispatch it!
    size_t len = outputLine.length();
    size_t i;
    for (i = 0; i < len && i < BUFFER_SIZE; i++) {
      buffer[i] = outputLine[i];
    }
    buffer[i] = 0;
    return buffer;
  }
  return nullptr; // No data available
}

FFI_PLUGIN_EXPORT char* arasan_stderr_read() {
  std::string errorLine;
  if (fakeerr.try_get_line(errorLine)) {
    errorLine += "\n"; // Append the newline back so Dart isolate can split and dispatch it!
    size_t len = errorLine.length();
    size_t i;
    for (i = 0; i < len && i < BUFFER_SIZE; i++) {
      errBuffer[i] = errorLine[i];
    }
    errBuffer[i] = 0;
    return errBuffer;
  }
  return nullptr; // No data available
}
