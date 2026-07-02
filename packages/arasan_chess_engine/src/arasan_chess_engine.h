#if _WIN32
#include <windows.h>
#include <stddef.h>
typedef ptrdiff_t ssize_t; 
#else
#include <sys/types.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

extern "C" {

#if defined(_WIN32)
    #define API_EXPORT
#else
    #define API_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

// Arasan main loop.
API_EXPORT FFI_PLUGIN_EXPORT int arasan_main();

// Writing to Arasan STDIN.
API_EXPORT FFI_PLUGIN_EXPORT ssize_t arasan_stdin_write(char *data);

// Reading Arasan STDOUT.
API_EXPORT FFI_PLUGIN_EXPORT char * arasan_stdout_read();

// Reading Arasan STDERR.
API_EXPORT FFI_PLUGIN_EXPORT char * arasan_stderr_read();

}
