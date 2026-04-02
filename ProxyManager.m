//
//  ProxyManager.m
//
//  Created by LEI on 2/23/16.
//  Copyright © 2016 TouchingApp. All rights reserved.
//

#import "ProxyManager.h"
#import <ShadowPath/ShadowPath.h>
#import <netinet/in.h>
#import "Profile.h"
//#include <ssrNative/ssrNative.h>
#import "CommUtils.h"
//#import <overtls/overtls.h>
#import "OverTlsWrapper.h"
//#import <overtls.h>
//#import <CocoaLumberjack/CocoaLumberjack.h>
//static DDLogLevel ddLogLevel = DDLogLevelWarning;

@interface ProxyManager () {
    ProxyCompletion _shadowsocksCompletion;
    
    BOOL _httpProxyRunning;
    ProxyCompletion _httpCompletion;
}
- (void)onHttpProxyCallback: (int)fd;
- (void)onShadowsocksCallback:(int)port;
@end

int sock_port (int fd) {
    struct sockaddr_in sin;
    socklen_t len = sizeof(sin);
    if (getsockname(fd, (struct sockaddr *)&sin, &len) < 0) {
        NSLog(@"getsock_port(%d) error: %s",
              fd, strerror (errno));
        return 0;
    }else{
        return ntohs(sin.sin_port);
    }
}


void shadowsocks_handler(int port, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    [provider onShadowsocksCallback:port];
}

void info_callback(int dump_level, const char *info, void *p) {
    
}




@implementation ProxyManager {
    int _socksProxyPort;
    BOOL _isOverTLS;
}

+ (ProxyManager *)sharedManager {
    static dispatch_once_t onceToken;
    static ProxyManager *manager;
    dispatch_once(&onceToken, ^{
        manager = [ProxyManager new];
    });
    return manager;
}

# pragma mark - Shadowsocks

- (void) startShadowsocks:(NSURL*)proxyConfUrl completion:(ProxyCompletion)completion {
    _shadowsocksCompletion = [completion copy];
    [NSThread detachNewThreadSelector:@selector(_startShadowsocks:) toTarget:self withObject:proxyConfUrl];
}

- (void)_startShadowsocks:(NSURL*)proxyConfUrl {
    NSString *confContent = [NSString stringWithContentsOfURL:proxyConfUrl encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[confContent dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments error:nil];
    Profile *profile = [[Profile alloc] initWithJSONDictionary:json];
    profile.listenPort = 0;

    _isOverTLS = profile.isOverTLS;

    NSURL *file = [[AppProfile sharedUrl] URLByAppendingPathComponent:@"overtls.json"];
    NSError *error;
    NSData *data = [Profile JsonDataFromDictionary:[profile OverTlsJsonDictionary]];
    [data writeToURL:file options:NSDataWritingAtomic error:&error];
    if (error) {
        if (_shadowsocksCompletion) {
            _shadowsocksCompletion(0, error);
        }
    }
    NSString *path = [file path];

    [OverTlsWrapper startWithConfig:path handler:shadowsocks_handler context:(__bridge void*)self];
    

}

- (void)stopShadowsocks {
    [OverTlsWrapper shutdown];
}

- (void) onShadowsocksCallback:(int)port {
    NSError *error;
    if (port > 0) {
        _socksProxyPort = port;
    } else {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
    }
    if (_shadowsocksCompletion) {
        _shadowsocksCompletion(_socksProxyPort, error);
    }
}

# pragma mark - Http Proxy

- (void) startHttpProxyServer:(NSURL*)httpProxyConfUrl completion:(ProxyCompletion)completion {
    _httpCompletion = [completion copy];
    NSAssert(httpProxyConfUrl, @"httpProxyConfUrl must have a valid value!");
    [NSThread detachNewThreadSelector:@selector(_startHttpProxyServer:) toTarget:self withObject:httpProxyConfUrl];
}

void http_proxy_handler(int fd, void *udata) {
    ProxyManager *provider = (__bridge ProxyManager *)udata;
    [provider onHttpProxyCallback:fd];
}

- (void)_startHttpProxyServer: (NSURL *)confURL {
    struct forward_spec *proxy = NULL;
    if (_socksProxyPort > 0) {
        proxy = calloc(1, sizeof(*proxy));
        proxy->type = SOCKS_5;
        proxy->gateway_host = "127.0.0.1";
        proxy->gateway_port = _socksProxyPort;
    }
    shadowpath_main(strdup([[confURL path] UTF8String]), proxy, http_proxy_handler, (__bridge void *)self);
}

- (void)onHttpProxyCallback:(int)fd {
    NSError *error;
    int httpProxyPort = 0;
    if (fd > 0) {
        httpProxyPort = sock_port(fd);
        _httpProxyRunning = YES;
    }else {
        error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:100 userInfo:@{NSLocalizedDescriptionKey: @"Fail to start http proxy"}];
    }
    if (_httpCompletion) {
        _httpCompletion(httpProxyPort, error);
    }
}

- (void)stopHttpProxy {
//    polipoExit();
//    _httpProxyRunning = NO;
}

@end

