#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TNSettings : NSObject

+ (TNSettings *)shared;
@property (nonatomic, strong, nullable) NSDate *startTime;

@end

NS_ASSUME_NONNULL_END
