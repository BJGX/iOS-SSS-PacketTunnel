#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TunnelResourceLocator : NSObject

+ (NSBundle *)resourceBundle;
+ (nullable NSString *)pathForResource:(NSString *)name ofType:(nullable NSString *)ext;

@end

NS_ASSUME_NONNULL_END
