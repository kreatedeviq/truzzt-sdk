#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(Niv2fa, NSObject)
RCT_EXTERN_METHOD(requestPermissions:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getSimPhones:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(openVerify:(NSDictionary *)opts resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
@end
