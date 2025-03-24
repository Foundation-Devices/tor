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

void tor_client_set_dormant(void *client, bool soft_mode);

void tor_proxy_stop(void *proxy);

/**
 * Get the exit node's identity (e.g., nickname or ID) for the given client.
 */
char *tor_get_exit_node(void *client);

/**
 * Free a C string allocated by this library.
 *
 * Used to free memory allocated by functions like `tor_get_exit_node`.
 */
void tor_free_string(char *s);

void tor_hello(void);

const char *tor_last_error_message(void);

uint64_t tor_get_nofile_limit(void);

uint64_t tor_set_nofile_limit(uint64_t limit);
