//
//  PacketTunnelProvider.m
//  PacketTunnel
//
//  Created by yuanyizhou on 2026/4/3.
//

#import "PacketTunnelProvider.h"

@implementation PacketTunnelProvider

- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    [super startTunnelWithOptions:options completionHandler:completionHandler];
}

- (void)stopTunnelWithReason:(NEProviderStopReason)reason completionHandler:(void (^)(void))completionHandler {
    [super stopTunnelWithReason:reason completionHandler:completionHandler];
}

- (void)handleAppMessage:(NSData *)messageData completionHandler:(void (^)(NSData *))completionHandler {
    [super handleAppMessage:messageData completionHandler:completionHandler];
}

- (void)sleepWithCompletionHandler:(void (^)(void))completionHandler {
    [super sleepWithCompletionHandler:completionHandler];
}

- (void)wake {
    [super wake];
}

@end
