// Taken from https://github.com/jusax23/flutter_stockfish_plugin

#ifndef _STREAM_FIX_H_
#define _STREAM_FIX_H_
#include <iostream>
#include <sstream>

template <typename T>
inline std::string stringify(const T& input) {
    std::ostringstream output;
    output << input;
    return output.str();
}

class FakeStream {
   private:
    std::ostream* out = nullptr;
    std::istream* in = nullptr;
   public:
    FakeStream(std::ostream& os) : out(&os) {}
    FakeStream(std::istream& is) : in(&is) {}
    FakeStream() {}

    template <typename T>
    FakeStream& operator<<(const T& val) {
        if (out) {
            *out << val;
        }
        return *this;
    };
    template <typename T>
    FakeStream& operator>>(T& val) {
        if (in) {
            *in >> val;
        }
        return *this;
    };

    bool try_get_line(std::string& val);

    void close();
    void reopen();
    bool is_closed();

    std::streambuf* rdbuf();
    std::streambuf* rdbuf(std::streambuf* __sb);
};

namespace std {
bool getline(FakeStream& is, std::string& str);
}  // namespace std

extern FakeStream fakeout;
extern FakeStream fakein;
extern FakeStream fakeerr;
extern std::string fakeendl;

#endif