#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (JSON)

- (nullable NSDictionary *)jsonDictionary;
- (nullable NSArray *)jsonArray;

@end

@interface NSDictionary (JSON)

- (nullable NSData *)jsonData;
- (nullable NSString *)jsonString;

@end

@interface NSArray (JSON)

- (nullable NSData *)jsonData;
- (nullable NSString *)jsonString;

@end

NS_ASSUME_NONNULL_END
