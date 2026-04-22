#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Localize)
- (NSString *)localized;
+ (NSString *)stringLocalizedFormat:(NSString *)format, ...;
+ (NSString *)stringLocalizedPlural:(NSString *)format, ...;
@end

FOUNDATION_EXPORT NSString *const LCLLanguageChangeNotification;

@interface SSSLocalize : NSObject
@property (nonatomic, strong, class, readonly) NSArray<NSString *> *availableLanguages;
@property (nonatomic, strong, class) NSString *currentLanguage;
@property (nonatomic, strong, class, readonly) NSString *defaultLanguage;
+ (void)resetCurrentLanguageToDefault;
+ (NSString *)displayNameForLanguage:(NSString *)language;
@end

NS_ASSUME_NONNULL_END
