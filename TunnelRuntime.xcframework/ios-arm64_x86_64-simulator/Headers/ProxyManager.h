#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ProxyCompletion)(int port, NSError * _Nullable error);

FOUNDATION_EXPORT int sock_port(int fd);

@interface ProxyManager : NSObject

+ (ProxyManager *)sharedManager;
- (void)startShadowsocks:(NSURL *)proxyConfUrl completion:(ProxyCompletion)completion;
- (void)stopShadowsocks;

@end

NS_ASSUME_NONNULL_END
