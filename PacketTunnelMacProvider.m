#import "PacketTunnelMacProvider.h"

@implementation PacketTunnelMacProvider
- (void)startTunnelWithOptions:(NSDictionary *)options completionHandler:(void (^)(NSError *))completionHandler {
    NSString *groupId = [TNAppProfile sharedGroupIdentifier];
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
