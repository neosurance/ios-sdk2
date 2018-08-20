#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <MapKit/MapKit.h>
#import <CoreMotion/CoreMotion.h>
#import <UserNotifications/UserNotifications.h>
#import <AFNetworking/AFNetworking.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <sys/utsname.h>
#import "NSRUser.h"

@protocol NSRSecurityDelegate <NSObject>
-(void)secureRequest:(NSString* _Nullable)endpoint payload:(NSDictionary* _Nullable)payload headers:(NSDictionary* _Nullable)headers completionHandler:(void (^)(NSDictionary* responseObject, NSError *error))completionHandler;
@end

@protocol NSRWorkflowDelegate <NSObject>
-(BOOL)executeLogin:(NSString*)url;
-(NSDictionary*)executePayment:(NSDictionary*)payment url:(NSString*)url;
@end

@interface NSR : NSObject<CLLocationManagerDelegate>
@property (nonatomic, strong)CLLocationManager* significantLocationManager;
@property (nonatomic, strong)CMMotionActivityManager* motionActivityManager;
@property (nonatomic, strong)AVAudioPlayer* pushPlayer;
@property (nonatomic, strong) id <NSRSecurityDelegate> securityDelegate;
@property (nonatomic, strong) id <NSRWorkflowDelegate> workflowDelegate;
@property (nonatomic) BOOL stillLocation;

+(id) sharedInstance;
-(void) setup:(NSDictionary*)settings;
-(void) forgetUser;
-(NSString*) version;
-(NSString*) os;
-(void) authorize:(void(^)(BOOL authorized))completionHandler;
-(void) registerUser:(NSRUser*) user;
-(void) showApp;
-(void) showApp:(NSDictionary*)params;
-(void) showUrl:(NSString*)url;
-(void) showUrl:(NSString*)url params:(NSDictionary*)params;
-(void) sendEvent:(NSString*)event payload:(NSDictionary*)payload;
-(void) sendAction:(NSString*)action policyCode:(NSString*)code details:(NSString*)details;
-(BOOL) forwardNotification:(UNNotificationResponse*) response withCompletionHandler:(void(^)(void))completionHandler;

-(NSDictionary*) getSettings;
-(NSString*) getLang;
-(NSDictionary*) getConf;
-(NSDictionary*) getAuth;
-(NSString*) getToken;
-(NSString*) getAppUrl;
-(NSRUser*) getUser;
-(NSString*) uuid;
-(NSString*) dictToJson:(NSDictionary*) dict;
@end