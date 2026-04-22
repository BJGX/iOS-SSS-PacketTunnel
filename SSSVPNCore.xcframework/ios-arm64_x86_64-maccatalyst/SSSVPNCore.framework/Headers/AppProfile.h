#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppProfile : NSObject

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
