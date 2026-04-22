#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSError (Helper)

+ (NSError *)errorWithCode:(NSInteger)code description:(NSString *)description;

@end

NS_ASSUME_NONNULL_END
