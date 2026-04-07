#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TunnelError : NSObject

+ (NSError *)errorWithMessage:(nullable NSString *)message;

@end

NS_ASSUME_NONNULL_END
