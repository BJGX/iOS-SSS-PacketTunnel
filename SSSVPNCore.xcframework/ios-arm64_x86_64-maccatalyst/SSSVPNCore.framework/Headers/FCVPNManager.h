#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, FCVPNStatus) {
    FCVPNStatusOff = 0,
    FCVPNStatusConnecting,
    FCVPNStatusON,
    FCVPNStatusDisconnecting,
};

FOUNDATION_EXPORT NSString *const FCVPNManagerStatusDidChangeNotification;
FOUNDATION_EXPORT NSString *const FCVPNManagerErrorNotification;
FOUNDATION_EXPORT NSString *const FCVPNManagerErrorKey;

@interface FCVPNManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic, assign) FCVPNStatus vpnStatus;

///日志登记  0 不打印 1 debug模式
@property (nonatomic, assign) NSInteger logLevel;


- (void)setup;
- (void)switchVPN;

- (BOOL)setDefaultConfigWithURL:(NSString *)service_str time:(NSInteger)time proxy:(BOOL)proxy;
- (BOOL)setDefaultConfigWithSingBoxConfig:(NSDictionary *)config time:(NSInteger)time;
- (BOOL)setDefaultConfigWithSingBoxConfigString:(NSString *)configString time:(NSInteger)time;

- (void)switchVPNWithCompletion:(void (^_Nullable)(NSError * _Nullable error))completion;
- (void)stopVPN;
+ (void)stopVPN;
- (void)removeManager;

- (NSDictionary *)TESTParseSingBoxOutboundWithURLString:(NSString *)urlString;

@end

NS_ASSUME_NONNULL_END
