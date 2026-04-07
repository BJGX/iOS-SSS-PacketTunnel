#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TNAppProfile : NSObject

+ (void)setSharedGroupIdentifier:(nullable NSString *)groupIdentifier;
+ (NSString *)sharedGroupIdentifier;
+ (NSURL *)sharedUrl;
+ (NSUserDefaults *)sharedUserDefaults;

+ (NSURL *)sharedLogUrl;
+ (NSURL *)sharedLogUrl2;

///配置
+ (NSURL *)sharedProxyConfUrl;
///singbox
+ (NSURL *)sharedSingboxConfUrl;


+ (NSURL *)sharedDefaultConfigUrl;

@end

NS_ASSUME_NONNULL_END
