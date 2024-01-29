#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct Tor {
  void *client;
  void *proxy;
} Tor;

struct Tor tor_start(uint16_t socks_port, const char *state_dir, const char *cache_dir);

bool tor_client_bootstrap(void *client);

bool tor_proxy_stop(void *proxy);

struct Tor tor_proxy_restart(struct Tor tor, uint16_t port);

void tor_hello(void);

const char *tor_last_error_message(void);

uint64_t tor_get_nofile_limit(void);

uint64_t tor_set_nofile_limit(uint64_t limit);
