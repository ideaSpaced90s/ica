#ifndef _STREAM_FIX_H_
#define _STREAM_FIX_H_

#include <iostream>
#include <streambuf>
#include <mutex>
#include <queue>
#include <string>
#include <condition_variable>
#include <android/log.h>

class QueueStreamBuf : public std::streambuf {
public:
    QueueStreamBuf(bool is_input) : is_input_(is_input), closed_(false) {}

    void close() {
        std::lock_guard<std::mutex> lock(mutex_);
        closed_ = true;
        cv_.notify_all();
    }

    void reopen() {
        std::lock_guard<std::mutex> lock(mutex_);
        closed_ = false;
    }

    bool is_closed() {
        std::lock_guard<std::mutex> lock(mutex_);
        return closed_;
    }

    void write_string(const std::string& str) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (closed_) return;
        __android_log_print(ANDROID_LOG_INFO, "ARASAN_NATIVE", "QueueStreamBuf::write_string: %s", str.c_str());
        for (char c : str) {
            queue_.push(c);
        }
        cv_.notify_all();
    }

    bool try_get_line(std::string& line) {
        std::lock_guard<std::mutex> lock(mutex_);
        if (queue_.empty()) return false;
        line.clear();
        while (!queue_.empty()) {
            char c = queue_.front();
            queue_.pop();
            if (c == '\n') break;
            line.push_back(c);
        }
        __android_log_print(ANDROID_LOG_INFO, "ARASAN_NATIVE", "QueueStreamBuf::try_get_line: %s", line.c_str());
        return true;
    }

protected:
    virtual int_type overflow(int_type c) override {
        if (c != EOF) {
            std::lock_guard<std::mutex> lock(mutex_);
            if (!closed_) {
                queue_.push(static_cast<char>(c));
                cv_.notify_all();
            }
        }
        return c;
    }

    virtual std::streamsize xsputn(const char* s, std::streamsize n) override {
        std::lock_guard<std::mutex> lock(mutex_);
        if (closed_) return 0;
        __android_log_print(ANDROID_LOG_INFO, "ARASAN_NATIVE", "QueueStreamBuf::xsputn: %.*s", (int)n, s);
        for (std::streamsize i = 0; i < n; ++i) {
            queue_.push(s[i]);
        }
        cv_.notify_all();
        return n;
    }

    virtual int_type underflow() override {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_.wait(lock, [this]() { return !queue_.empty() || closed_; });
        if (queue_.empty()) return EOF;
        return queue_.front();
    }

    virtual int_type uflow() override {
        std::unique_lock<std::mutex> lock(mutex_);
        cv_.wait(lock, [this]() { return !queue_.empty() || closed_; });
        if (queue_.empty()) return EOF;
        char c = queue_.front();
        queue_.pop();
        return c;
    }

private:
    std::queue<char> queue_;
    std::mutex mutex_;
    std::condition_variable cv_;
    bool is_input_;
    bool closed_;
};

// FakeStream wrapper interface to maintain compatibility with arasan_chess_engine.cpp
class FakeStream {
public:
    FakeStream(QueueStreamBuf* buf) : buf_(buf) {}

    bool try_get_line(std::string& val) {
        return buf_->try_get_line(val);
    }

    void close() {
        buf_->close();
    }

    void reopen() {
        buf_->reopen();
    }

    bool is_closed() {
        return buf_->is_closed();
    }

    // Input writing (e.g. from Dart stdin)
    FakeStream& operator<<(const std::string& val) {
        buf_->write_string(val);
        return *this;
    }

private:
    QueueStreamBuf* buf_;
};

extern FakeStream fakeout;
extern FakeStream fakein;
extern FakeStream fakeerr;
extern std::string fakeendl;

#endif
