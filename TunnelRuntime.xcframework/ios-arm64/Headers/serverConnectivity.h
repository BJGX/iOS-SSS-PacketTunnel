#ifndef VPNKit_serverConnectivity_h
#define VPNKit_serverConnectivity_h

#include <stdio.h>

int serverConnectivity(const char *host, int port, int timeout_ms);
int convertHostNameToIpString(const char *host, char *ipString, size_t len);

#endif
