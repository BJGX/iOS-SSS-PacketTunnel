#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const VPNKitServerKey;
FOUNDATION_EXPORT NSString *const VPNKitServerPortKey;
FOUNDATION_EXPORT NSString *const VPNKitRemarksKey;
FOUNDATION_EXPORT NSString *const VPNKitPasswordKey;
FOUNDATION_EXPORT NSString *const VPNKitMethodKey;
FOUNDATION_EXPORT NSString *const VPNKitProtocolKey;
FOUNDATION_EXPORT NSString *const VPNKitProtocolParamKey;
FOUNDATION_EXPORT NSString *const VPNKitObfsKey;
FOUNDATION_EXPORT NSString *const VPNKitObfsParamKey;
FOUNDATION_EXPORT NSString *const VPNKitListenPortKey;
FOUNDATION_EXPORT NSString *const VPNKitOverTLSEnableKey;
FOUNDATION_EXPORT NSString *const VPNKitOverTLSDomainKey;
FOUNDATION_EXPORT NSString *const VPNKitOverTLSPathKey;

@interface Profile : NSObject

- (nullable instancetype)initWithJSONData:(NSData *)data;
- (nullable instancetype)initWithJSONDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)JSONDictionary;
- (NSData *)JSONData;
- (nullable NSMutableDictionary *)OverTlsJsonDictionary;
+ (NSData *)JsonDataFromDictionary:(NSDictionary *)dictionary;

@property (nonatomic, copy) NSString *server;
@property (nonatomic, assign) NSInteger serverPort;
@property (nonatomic, copy) NSString *remarks;
@property (nonatomic, copy) NSString *password;
@property (nonatomic, copy) NSString *method;
@property (nonatomic, copy) NSString *protocol;
@property (nonatomic, copy) NSString *protocolParam;
@property (nonatomic, copy) NSString *obfs;
@property (nonatomic, copy) NSString *obfsParam;
@property (nonatomic, assign) NSInteger listenPort;
@property (nonatomic, assign) BOOL ot_enable;
@property (nonatomic, copy) NSString *ot_domain;
@property (nonatomic, copy) NSString *ot_path;
@property (nonatomic, assign, readonly) BOOL isOverTLS;

@end

NS_ASSUME_NONNULL_END
