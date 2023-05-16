#include <cstdarg>
#include <cstddef>
#include <cstdint>
#include <cstdlib>
#include <ostream>
#include <new>



extern "C" {

void tor_hello();

bool tor_start(const char *conf_path);

} // extern "C"
