#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

const char *tor_last_error_message(void);

TorClient<TokioNativeTlsRuntime> *tor_start(uint16_t socks_port,
                                            const char *state_dir,
                                            const char *cache_dir);

bool tor_bootstrap(TorClient<TokioNativeTlsRuntime> *client);

void tor_hello(void);
