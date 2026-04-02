
#import "PacketTunnelProvider.h"
#import "ProxyManager.h"
#import "TunnelInterface.h"
#import "TunnelError.h"
#import "dns.h"
#import "CommUtils.h"
#import <sys/syslog.h>
#import <ShadowPath/ShadowPath.h>
#import <sys/socket.h>
#import <arpa/inet.h>
@import MMWormhole;
@import CocoaAsyncSocket;
#import "Profile.h"
#import "serverConnectivity.h"
#import "SingBox/Mobile.objc.h"
#import "SimpleLogger.h"


#define REQUEST_CACHED @"requestsCached"    // Indicate that recent requests need update

#if DEBUG
#define WAIT_TIME      20000
#else
#define WAIT_TIME      2
#endif

@interface PacketTunnelProvider () <GCDAsyncSocketDelegate> {
    MMWormhole *_wormhole;
    GCDAsyncSocket *_statusSocket;
    GCDAsyncSocket *_statusClientSocket;
    BOOL _didSetupHockeyApp;
    BOOL _isObservingDefaultPath;
    NWPath *_lastPath;
    void (^_pendingStartCompletion)(NSError *);
    void (^_pendingStopCompletion)(void);
}
/// 定时器
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger currentTime;
@end


@implementation PacketTunnelProvider {
    NSInteger _httpProxyPort;
    NSInteger _socksProxyPort;
}


- (void)beginCountDown
{
    self.currentTime -= 1;
    if (self.currentTime < 0) {
        [[SimpleLogger sharedLogger] logWithLevel:LogLevelInfo category:@"beginCountDown" message:@"VIP时间已用完"];
        [self stop];
    }
}


- (NSTimer *)timer {
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(beginCountDown) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}


- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    [self openLog];
    [self updateUserDefaults];
    [[SimpleLogger sharedLogger] logWithLevel:LogLevelInfo category:@"NE" message:@"starting potatso tunnel..."];
    
    NSError *error = [[TunnelInterface sharedInterface] setupWithPacketTunnelFlow:self.packetFlow];
    if (error) {
        completionHandler(error);
        return;
    }
    
    NSString *confContent = [NSString stringWithContentsOfURL:[AppProfile sharedProxyConfUrl] encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *json = [confContent jsonDictionary];
    
    
    NSInteger current = [self currentTimeStamp];
    NSInteger vipTime = [json[@"time"] integerValue];
    
    self.currentTime = vipTime - current;
    if (self.currentTime <= 0) {
        /// 时间校验, 如果超过15分, 不连接
        [[SimpleLogger sharedLogger] logWithLevel:LogLevelWarning category:@"NE" message:@"VIP时间不够"];
        completionHandler([NSError errorWithDomain:@"SSSVPN" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"server address or port error"}]);
        return;
    }
    
    
    
    Profile *profile = [[Profile alloc] initWithJSONDictionary:json];
    
    if (profile.server.length==0 || profile.serverPort==0) {
        [[SimpleLogger sharedLogger] logWithLevel:LogLevelError category:@"NE" message:@"server address or port error"];
        completionHandler([NSError errorWithDomain:@"SSSVPN" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"server address or port error"}]);
        return;
    }
    
    if (serverConnectivity(profile.server.UTF8String, (int)profile.serverPort, 10000) != 0){
        [[SimpleLogger sharedLogger] logWithLevel:LogLevelError category:@"NE" message:@"serverConnectivity"];
        completionHandler([NSError errorWithDomain:@"SSSVPN" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"serverConnectivity"}]);
        return;
    }

    _pendingStartCompletion = completionHandler;
    [self saveFile];
    NSError *proxyError = [self startAllProxyServers];
    if (proxyError) {
        [self finishStartWithError:proxyError];
        return;
    }
    [self startPacketForwarders];
    [self setupWormhole];
}

- (void)updateUserDefaults {
    [[AppProfile sharedUserDefaults] removeObjectForKey:REQUEST_CACHED];
    [[AppProfile sharedUserDefaults] synchronize];
    [[Settings shared] setStartTime:[NSDate date]];
}

- (void)setupWormhole {
    _wormhole = [[MMWormhole alloc] initWithApplicationGroupIdentifier: [AppProfile sharedGroupIdentifier] optionalDirectory:@"wormhole"];
    __weak typeof(self) weakSelf = self;
    [_wormhole listenForMessageWithIdentifier:@"getTunnelStatus" listener:^(id  _Nullable messageObject) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->_wormhole passMessageObject:@"ok" identifier:@"tunnelStatus"];
    }];
    [_wormhole listenForMessageWithIdentifier:@"stopVPNTunnel" listener:^(id  _Nullable messageObject) {
        [weakSelf stop];
    }];
    [_wormhole listenForMessageWithIdentifier:@"getTunnelConnectionRecords" listener:^(id  _Nullable messageObject) {
        NSMutableArray *records = [NSMutableArray array];
        struct log_client_states *p = log_clients;
        while (p) {
            struct client_state *client = p->csp;
            NSMutableDictionary *d = [NSMutableDictionary dictionary];
            char *url = client->http->url;
            if (url ==  NULL) {
                p = p->next;
                continue;
            }
            d[@"url"] = [NSString stringWithCString:url encoding:NSUTF8StringEncoding];
            d[@"method"] = @(client->http->gpc);
            for (int i=0; i < TIME_STAGE_COUNT; i++) {
                d[[NSString stringWithFormat:@"time%d", i]] = @(client->time_stages[i]);
            }
            d[@"version"] = @(client->http->ver);
            if (client->rule) {
                d[@"rule"] = [NSString stringWithCString:client->rule encoding:NSUTF8StringEncoding];
            }
            d[@"global"] = @(global_mode);
            d[@"routing"] = @(client->routing);
            d[@"forward_stage"] = @(client->current_forward_stage);
            if (client->http->remote_host_ip_addr_str) {
                d[@"ip"] = [NSString stringWithCString:client->http->remote_host_ip_addr_str encoding:NSUTF8StringEncoding];
            }
            d[@"responseCode"] = @(client->http->status);
            [records addObject:d];
            p = p->next;
        }
        NSString *result = [records jsonString];
        [self->_wormhole passMessageObject:result identifier:@"tunnelConnectionRecords"];
    }];
    [self setupStatusSocket];
}

- (void)setupStatusSocket {
    NSError *error;
    _statusSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)];
    [_statusSocket acceptOnInterface:@"127.0.0.1" port:0 error:&error];
    [_statusSocket performBlock:^{
        int port = sock_port(self->_statusSocket.socket4FD);
        [[AppProfile sharedUserDefaults] setObject:@(port) forKey:@"tunnelStatusPort"];
        [[AppProfile sharedUserDefaults] synchronize];
    }];
}

- (NSError *)startAllProxyServers {
    NSError *error = [self startShadowsocks];
    if (error) {
        return error;
    }
//    [self startHttpProxyServer];
    return nil;
}

- (NSError *)syncStartProxy: (NSString *)name completion: (void(^)(dispatch_group_t g, NSError **proxyError))handler {
    dispatch_group_t g = dispatch_group_create();
    __block NSError *proxyError;
    dispatch_group_enter(g);
    handler(g, &proxyError);
    long res = dispatch_group_wait(g, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * WAIT_TIME));
    if (res != 0) {
        proxyError = [TunnelError errorWithMessage:@"timeout"];
    }
    if (proxyError) {
        NSLog(@"start proxy: %@ error: %@", name, [proxyError localizedDescription]);
    }
    return proxyError;
}

- (NSError *)startShadowsocks {
    return [self syncStartProxy: @"shadowsocks" completion:^(dispatch_group_t g, NSError *__autoreleasing *proxyError) {
        [[ProxyManager sharedManager] startShadowsocks:[AppProfile sharedProxyConfUrl] completion:^(int port, NSError *error) {
            self->_socksProxyPort = (NSInteger) port;
            *proxyError = error;
            dispatch_group_leave(g);
        }];
    }];
}

- (NSError *)startHttpProxyServer {
    return [self syncStartProxy: @"http" completion:^(dispatch_group_t g, NSError *__autoreleasing *proxyError) {
        [[ProxyManager sharedManager] startHttpProxyServer:[AppProfile sharedHttpProxyConfUrl] completion:^(int port, NSError *error) {
            self->_httpProxyPort = (NSInteger) port;
            *proxyError = error;
            dispatch_group_leave(g);
        }];
    }];
}

- (void)startPacketForwarders {
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTun2SocksFinished) name:kTun2SocksStoppedNotification object:nil];
    [self applyTunnelSettings:^(NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (error == nil) {
            NSAssert(self->_socksProxyPort > 0, @"_socksProxyPort > 0");
            [strongSelf beginObservingDefaultPathIfNeeded];
            NSError *startError = [strongSelf startOvertls];
            if (startError) {
                error = startError;
            } else {
            [[TunnelInterface sharedInterface] startTun2Socks:10808];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[TunnelInterface sharedInterface] processPackets];
                [self.timer setFireDate:[NSDate distantPast]];
                
            });
            }
        }
        if (error) {
            [strongSelf stop];
        }
        [strongSelf finishStartWithError:error];
    }];
}

- (void) applyTunnelSettings:(void (^)(NSError *error))completionHandler {
    NSString *generalConfContent = [NSString stringWithContentsOfURL:[AppProfile sharedGeneralConfUrl] encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *generalConf = [generalConfContent jsonDictionary];
    NSString *dns = generalConf[@"dns"];
    NEIPv4Settings *ipv4Settings = [[NEIPv4Settings alloc] initWithAddresses:@[@"192.0.2.1"] subnetMasks:@[@"255.255.255.0"]];
    NSArray *dnsServers;
    if (dns.length) {
        dnsServers = [dns componentsSeparatedByString:@","];
        NSLog(@"custom dns servers: %@", dnsServers);
    }else {
        dnsServers = [DNSConfig getSystemDnsServers];
        NSLog(@"system dns servers: %@", dnsServers);
    }

    NEPacketTunnelNetworkSettings *settings = [[NEPacketTunnelNetworkSettings alloc] initWithTunnelRemoteAddress:@"192.0.2.2"];
    settings.IPv4Settings = ipv4Settings;
    settings.MTU = @(TunnelMTU);
    NEProxySettings* proxySettings = [[NEProxySettings alloc] init];
    NSString *proxyServerName = @"127.0.0.1";

    proxySettings.HTTPEnabled = YES;
    proxySettings.HTTPServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:10808];
    proxySettings.HTTPSEnabled = YES;
    proxySettings.HTTPSServer = [[NEProxyServer alloc] initWithAddress:proxyServerName port:10808];
    proxySettings.excludeSimpleHostnames = YES;
    NSString *js = @"function FindProxyForURL(url, host) { return 'SOCKS5 127.0.0.1:10808; SOCKS 127.0.0.1:10808'; }";
    
    proxySettings.proxyAutoConfigurationJavaScript = js;
//    
    
    settings.proxySettings = proxySettings;
    NEDNSSettings *dnsSettings = [[NEDNSSettings alloc] initWithServers:dnsServers];
    dnsSettings.matchDomains = @[@""];
    settings.DNSSettings = dnsSettings;
    [self setTunnelNetworkSettings:settings completionHandler:^(NSError * _Nullable error) {
        if (completionHandler) {
            completionHandler(error);
        }
    }];
}

- (void)openLog {
    NSString *logFilePath = [AppProfile sharedLogUrl2].path;
    [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "w+", stdout);
    freopen([logFilePath cStringUsingEncoding:NSASCIIStringEncoding], "w+", stderr);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"defaultPath"]) {
        if (self.defaultPath.status == NWPathStatusSatisfied && ![self.defaultPath isEqualToPath:_lastPath]) {
            if (!_lastPath) {
                _lastPath = self.defaultPath;
            }else {
                NSLog(@"received network change notifcation");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self applyTunnelSettings:nil];
                });
            }
        }else {
            _lastPath = self.defaultPath;
        }
    }
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler
{
    // Add code here to start the process of stopping the tunnel
    _pendingStopCompletion = completionHandler;
    [self stop];
    
}

- (void)stop {
    NSLog(@"stoping potatso tunnel...");
    [self.timer invalidate];
    self.timer = nil;
    [self endObservingDefaultPathIfNeeded];
    [_statusClientSocket disconnect];
    _statusClientSocket = nil;
    [_statusSocket disconnect];
    _statusSocket = nil;
    [[AppProfile sharedUserDefaults] setObject:@(0) forKey:@"tunnelStatusPort"];
    [[AppProfile sharedUserDefaults] synchronize];
    [[ProxyManager sharedManager] stopShadowsocks];
    [[TunnelInterface sharedInterface] stop];
    MobileStop();
}

- (void)onTun2SocksFinished {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_pendingStopCompletion) {
        _pendingStopCompletion();
        _pendingStopCompletion = nil;
    }
    [self cancelTunnelWithError:nil];
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
    if (completionHandler != nil) {
        completionHandler(nil);
    }
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    NSLog(@"sleeping potatso tunnel...");
    completionHandler();
}

- (void)wake {
    NSLog(@"waking potatso tunnel...");
}

#pragma mark - GCDAsyncSocket Delegate

- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    _statusClientSocket = newSocket;
}


-(NSInteger)currentTimeStamp{
    NSDate* date = [NSDate dateWithTimeIntervalSinceNow:0];//获取当前时间0秒后的时间
    NSInteger time = [date timeIntervalSince1970] * 1000;// *1000 是精确到毫秒，不乘就是精确到秒
    return time / 1000;
}


- (NSError *)startOvertls
{
    BOOL isGlobal = [[AppProfile sharedUserDefaults] boolForKey:@"VPNPAC"];
    NSString *name = isGlobal  ? @"config" : @"config-pac";
    NSString *path =
        [[NSBundle mainBundle] pathForResource:name ofType:@"json"];
    NSString *config =
        [NSString stringWithContentsOfFile:path
                                  encoding:NSUTF8StringEncoding
                                     error:nil];
    
    
    config = [config stringByReplacingOccurrencesOfString:@"40000" withString:[NSString stringWithFormat:@"%ld",_socksProxyPort]];
    [[SimpleLogger sharedLogger] logWithLevel:LogLevelInfo category:@"config" message:config];
    
    
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    long ret = MobileStart(config, cachePath);
    
    NSString *errors = MobileGetLastError();
    if (ret != 0) {
        NSLog(@"error= %@", errors);
        NSLog(@"code = %ld", ret);
        [[SimpleLogger sharedLogger] logWithLevel:LogLevelError category:@"singbox" message:[NSString stringWithFormat:@"code = %ld, error = %@", ret, errors]];
        return [NSError errorWithDomain:@"SingBox"
                                   code:ret
                               userInfo:@{NSLocalizedDescriptionKey: errors ?: @"MobileStart failed"}];
   }

    if (![NSProcessInfo processInfo].iOSAppOnMac) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[SimpleLogger sharedLogger] logWithLevel:LogLevelInfo category:@"NE" message:@"成功启动,GC回收内存中"];
            MobileStartGC();
        });
    }

    return nil;
}

- (void)finishStartWithError:(NSError *)error {
    if (_pendingStartCompletion) {
        _pendingStartCompletion(error);
        _pendingStartCompletion = nil;
    }

    if (error) {
        [self cancelTunnelWithError:error];
    }
}

- (void)beginObservingDefaultPathIfNeeded {
    if (_isObservingDefaultPath) {
        return;
    }
    [self addObserver:self forKeyPath:@"defaultPath" options:NSKeyValueObservingOptionInitial context:nil];
    _isObservingDefaultPath = YES;
}

- (void)endObservingDefaultPathIfNeeded {
    if (!_isObservingDefaultPath) {
        return;
    }
    @try {
        [self removeObserver:self forKeyPath:@"defaultPath"];
    } @catch (__unused NSException *exception) {
    }
    _isObservingDefaultPath = NO;
}

- (NSString *)copyFileFromBundle:(NSString *)bundleFileName
             toDownloadDirectory:(NSString *)destinationFileName
                      inDirectory:(NSString *)directory
                        overwrite:(BOOL)overwrite {
    
    // 获取Bundle中的文件路径
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:bundleFileName
                                                           ofType:nil];
    if (!bundlePath) {
        NSLog(@"Bundle中找不到文件: %@", bundleFileName);
        return nil;
    }
    
    // 确定目标文件名
    NSString *targetFileName = destinationFileName ?: bundleFileName;
    
    // 获取目标文件路径
    NSString *saveDirectory = directory;
    NSString *targetFilePath = [saveDirectory stringByAppendingPathComponent:targetFileName];
    
    // 检查目标文件是否已存在
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:targetFilePath];
    
    if (fileExists && !overwrite) {
        NSLog(@"文件已存在且不覆盖: %@", targetFilePath);
        return targetFilePath;
    }
    
    // 复制文件
    NSError *error = nil;
    BOOL success = [[NSFileManager defaultManager] copyItemAtPath:bundlePath
                                                            toPath:targetFilePath
                                                             error:&error];
    
    if (!success) {
        NSLog(@"复制文件失败: %@", error.localizedDescription);
        return nil;
    }
    
    NSLog(@"文件从Bundle复制成功: %@ -> %@", bundleFileName, targetFilePath);
    return targetFilePath;
}

- (void)saveFile
{
    NSString *customDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    [self copyFileFromBundle:@"geoip-cn.srs" toDownloadDirectory:nil inDirectory:customDirectory overwrite:NO];
    [self copyFileFromBundle:@"geosite-cn.srs" toDownloadDirectory:nil inDirectory:customDirectory overwrite:NO];
    [self copyFileFromBundle:@"geosite-geolocation-cn.srs" toDownloadDirectory:nil inDirectory:customDirectory overwrite:NO];
    [self copyFileFromBundle:@"gfw.srs" toDownloadDirectory:nil inDirectory:customDirectory overwrite:NO];
}


@end
