#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Settings : NSObject

+ (Settings *)shared;
@property (nonatomic, strong, nullable) NSDate *startTime;

@end

NS_ASSUME_NONNULL_END
