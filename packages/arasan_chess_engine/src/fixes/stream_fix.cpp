#include "stream_fix.h"
#include <android/log.h>

#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, "ARASAN_NATIVE", __VA_ARGS__)

// Global buffers
QueueStreamBuf out_buf(false);
QueueStreamBuf err_buf(false);
QueueStreamBuf in_buf(true);

FakeStream fakeout(&out_buf);
FakeStream fakeerr(&err_buf);
FakeStream fakein(&in_buf);
std::string fakeendl("\n");

struct GlobalStreamRedirector {
    std::streambuf* old_out;
    std::streambuf* old_err;
    std::streambuf* old_in;

    GlobalStreamRedirector() {
        LOGI("GlobalStreamRedirector: starting redirection");
        old_out = std::cout.rdbuf(&out_buf);
        old_err = std::cerr.rdbuf(&err_buf);
        old_in = std::cin.rdbuf(&in_buf);
        LOGI("GlobalStreamRedirector: redirection completed");
    }

    ~GlobalStreamRedirector() {
        LOGI("GlobalStreamRedirector: restoring streams");
        std::cout.rdbuf(old_out);
        std::cerr.rdbuf(old_err);
        std::cin.rdbuf(old_in);
    }
};

// Global instance to trigger redirection immediately on library load
static GlobalStreamRedirector global_redirector;
