#ifndef VPNKit_DNS_h
#define VPNKit_DNS_h

#include <Foundation/Foundation.h>

@interface DNSConfig : NSObject

+ (NSArray *)getSystemDnsServers;

@end

#endif
