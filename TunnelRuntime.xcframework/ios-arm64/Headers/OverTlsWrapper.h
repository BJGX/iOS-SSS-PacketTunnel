#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OverTlsWrapper : NSObject

+ (int)startWithConfig:(NSString *)filePath handler:(void (*)(int port, void *ctx))handler context:(void *)ctx;
+ (void)shutdown;

@end

NS_ASSUME_NONNULL_END
