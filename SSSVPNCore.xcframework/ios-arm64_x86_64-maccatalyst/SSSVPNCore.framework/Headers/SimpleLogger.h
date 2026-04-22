#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, LogLevel) {
    LogLevelDebug,
    LogLevelInfo,
    LogLevelWarning,
    LogLevelError
};

@interface SimpleLogger : NSObject

+ (instancetype)sharedLogger;
- (void)configureLogDirectory:(NSString *)directory;
- (void)logWithLevel:(LogLevel)level category:(NSString *)category message:(NSString *)message;
- (void)clearLogs;
- (NSURL *)openLogsFolder;

@end

NS_ASSUME_NONNULL_END
