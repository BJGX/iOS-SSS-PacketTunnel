#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CommResourceLocator : NSObject

+ (NSBundle *)resourceBundle;
+ (nullable NSString *)pathForResource:(NSString *)name ofType:(nullable NSString *)ext;
+ (nullable NSURL *)URLForResource:(NSString *)name withExtension:(nullable NSString *)ext;

@end

NS_ASSUME_NONNULL_END
