#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum OverTlsVerbosity {
  OverTlsVerbosity_Off = 0,
  OverTlsVerbosity_Error,
  OverTlsVerbosity_Warn,
  OverTlsVerbosity_Info,
  OverTlsVerbosity_Debug,
  OverTlsVerbosity_Trace,
} OverTlsVerbosity;

typedef struct OverTlsTrafficStatus {
  uint64_t tx;
  uint64_t rx;
} OverTlsTrafficStatus;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/**
 * # Safety
 *
 * Run the overtls client with config file.
 * The callback function will be called when the client is listening on a port.
 * It should be thread-safe and will be called with the port number and should be called only once.
 *
 */
int over_tls_client_run(const char *config_path,
                        enum OverTlsVerbosity verbosity,
                        void (*callback)(int, void*),
                        void *ctx);

/**
 * # Safety
 *
 * Run the overtls client with SSR URL.
 * Parameters:
 * - `url`: SSR style URL string of the server node, e.g. "ssr://server:port:protocol:method:obfs:password_base64/?params_base64".
 * - `listen_addr`: The address to listen on, in the format of "ip:port".
 * - `verbosity`: The verbosity level of the logger.
 * - `callback`: The callback function to be called when the client is listening on a port.
 *   It should be thread-safe and will be called with the port number and should be called only once.
 * - `ctx`: The context pointer to be passed to the callback function.
 *
 */
int over_tls_client_run_with_ssr_url(const char *url,
                                     const char *listen_addr,
                                     enum OverTlsVerbosity verbosity,
                                     void (*callback)(int, void*),
                                     void *ctx);

/**
 * # Safety
 *
 * Shutdown the client.
 */
int over_tls_client_stop(void);

/**
 * # Safety
 *
 * Create a SSR URL from the config file.
 */
char *overtls_generate_url(const char *cfg_path);

/**
 * # Safety
 *
 * Free the string returned by `overtls_generate_url`.
 */
void overtls_free_string(char *s);

/**
 * # Safety
 *
 * set dump log info callback.
 */
void overtls_set_log_callback(bool set_logger, void (*callback)(enum OverTlsVerbosity,
                                                                const char*,
                                                                void*), void *ctx);

/**
 * # Safety
 *
 * set traffic status callback.
 */
void overtls_set_traffic_status_callback(uint32_t send_interval_secs,
                                         void (*callback)(const struct OverTlsTrafficStatus*, void*),
                                         void *ctx);

#ifdef __cplusplus
}  // extern "C"
#endif  // __cplusplus
