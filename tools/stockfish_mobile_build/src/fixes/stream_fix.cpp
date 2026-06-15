#include "stream_fix.h"

bool FakeStream::try_get_line(std::string& val) {
    return false;
}

void FakeStream::close() {}
void FakeStream::reopen() {}
bool FakeStream::is_closed() { return false; }

std::streambuf* FakeStream::rdbuf() { return nullptr; }
std::streambuf* FakeStream::rdbuf(std::streambuf* buf) { return nullptr; }

bool std::getline(FakeStream& is, std::string& str) {
    if (std::getline(std::cin, str)) {
        return true;
    }
    return false;
}

FakeStream fakeout(std::cout);
FakeStream fakein(std::cin);
FakeStream fakeerr(std::cerr);
std::string fakeendl("\n");