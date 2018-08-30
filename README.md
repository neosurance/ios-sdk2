# ![](https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/IOS_logo.svg/32px-IOS_logo.svg.png) iOS - Neosurance SDK (NSR)

- Collects info from device sensors and from the hosting app
- Exchanges info with the AI engines
- Sends the push notification
- Displays a landing page
- Displays the list of the purchased policies

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Installation

NeosuranceSDK(NSR) is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'NSR'
```

## Requirements

1. Inside your **info.plist** be sure to have the following permissions:

	```plist
	<key>NSAppTransportSecurity</key>
	<dict>
	  <key>NSAllowsArbitraryLoads</key>
	  <true/>
	</dict>
	<key>NSCameraUsageDescription</key>
	<string>use camera...</string>
	<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
	<string>Always and when in use...</string>
	<key>NSLocationAlwaysUsageDescription</key>
	<string>Always...</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>When in use...</string>
	<key>NSMotionUsageDescription</key>
	<string>Motion...</string>
	<key>UIBackgroundModes</key>
	<array>
	  <string>fetch</string>
	  <string>location</string>
	  <string>remote-notification</string>
	</array>
	```
2. Add the following audio file <a href="https://github.com/neosurance/ios-sdk2/raw/master/Example/NSR_push.wav" download="NSR_push.waw">NSR_push.waw</a> to your app resource bundles

## Use

1. ### setup
	Earlier in your application startup flow (tipically inside the **application didFinishLaunchingWithOptions** method of your application) call the **setup** method using

	**base_url**: provided by us, used only if no *securityDelegate* is configured  
	**code**: the community code provided by us  
	**secret_key**: the community secret key provided by us  
	**dev_mode** *optional*: [0|1] activate the *developer mode*	
	
	```objc
	NSMutableDictionary* settings = [[NSMutableDictionary alloc] init];
	[settings setObject:@"https://<provided base url>/" forKey:@"base_url"];
	[settings setObject:@"<provided code>" forKey:@"code"];
	[settings setObject:@"<provided secret_key>" forKey:@"secret_key"];
	[[NSR sharedInstance] setup:settings];
	```
2. ### setSecurityDelegate *optional*
	If the communications must be secured using any policy.  
	A **securityDelegate** implementing the following protocol can be configured:
	
	```objc
	@protocol NSRSecurityDelegate <NSObject>
	-(void)secureRequest:(NSString* _Nullable)endpoint payload:(NSDictionary* _Nullable)payload headers:(NSDictionary* _Nullable)headers completionHandler:(void (^)(NSDictionary* responseObject, NSError *error))completionHandler;
	@end
	```
	
	Then use the ***setSecurityDelegate*** method
	
	```objc
	[[NSR sharedInstance] setSecurityDelegate:[[<yourSecurityDelegate> alloc] init];
	```
	
3. ### setWorkFlowDelegate *optional*  
	If the purchase workflow must be interrupted in order to perform user login or to perform payment.  
	A **workflowDelegate** implementing the following interface must be configured:
	
	```objc
	@protocol NSRWorkflowDelegate <NSObject>
	-(BOOL)executeLogin:(NSString*)url;
	-(NSDictionary*)executePayment:(NSDictionary*)payment url:(NSString*)url;
	@end
	```
	
	Then use the ***setWorkflowDelegate*** method

	```objc
	[[NSR sharedInstance] setWorkflowDelegate:[[<yourWorkflowDelegate> alloc] init];
	```
	
	when login or payment is performed you must call the methods **loginExecuted** and **paymentExecuted** to resume the workflow
	
	```objc
	[[NSR sharedInstance] loginExecuted:<theGivenUrl>];
	...
	[[NSR sharedInstance] paymentExecuted:<theGivenUrl>]
	NSR.getInstance(this).paymentExecuted:(<paymentTransactionInfo> url:<theGivenUrl>);
	```
	
4. ### registerUser  
	When the user is recognized by your application, register him in our *SDK* creating an **NSRUser** and using the **registerUser** method.  
	The **NSRUser** has the following fields:
	
	**code**: the user code in your system (can be equals to the email)  
	**email**: the email is the real primary key  
	**firstname** *optional*  
	**lastname** *optional*  
	**mobile** *optional*  
	**fiscalCode** *optional*  
	**gender** *optional*  
	**birthday** *optional*  
	**address** *optional*  
	**zipCode** *optional*  
	**city** *optional*  
	**stateProvince** *optional*  
	**country** *optional*  
	**extra** *optional*: will be shared with us  
	**locals** *optional*: will not be exposed outside the device  

	```objc
	NSRUser* user = [[NSRUser alloc] init];
	user.email = @"jhon.doe@acme.com";
	user.code = @"jhon.doe@acme.com";
	user.firstname = @"Jhon";
	user.lastname = @"Doe";
	[[NSR sharedInstance] registerUser:user];
	```
5. ### forgetUser *optional*
	If you want propagate user logout to the SDK use the **forgetUser** method.  
	Note that without user no tracking will be performed.
	
	```objc
	[[NSR sharedInstance] forgetUser];	
	```
6. ### showApp *optional*
	Is possible to show the list of the purchased policies (*communityApp*) using the **showApp** methods
	
	```objc
	[[NSR sharedInstance] showApp];	
	```
	or
	
	```objc
	NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
	[params setObject:@"profiles" forKey:@"page"];
	[[NSR sharedInstance] showApp:params];	
	```
7. ### showUrl *optional*
	If custom web views are needed the **showUrl** methods can be used
	
	```objc
	[[NSR sharedInstance] showUrl:url];	
	```
	or
	
	```objc
	NSMutableDictionary* params = [[NSMutableDictionary alloc] init];
	[params setObject:@"true" forKey:@"profile"];
	[[NSR sharedInstance] showUrl:url params:params];	
	```
8. ### sendEvent *optional*
	The application can send explicit events to the system with **sendEvent** method
	
	```objc
	NSMutableDictionary* payload = [[NSMutableDictionary alloc] init];
	[payload setObject:latitude forKey:@"latitude"];
	[payload setObject:longitude forKey:@"longitude"];
	[[NSR sharedInstance] sendEvent:@"position" payload:payload];
	```
	
9. ### sendAction *optional*
	The application can send tracing information events to the system with **sendAction** method
	
	```objc          
	[[NSR sendAction] sendAction:@"read" policyCode:@"xxxx123xxxx" details:@"general condition read"];
	```

## Author

info@neosurance.eu

## License

NeosuranceSDK is available under the MIT license. See the LICENSE file for more info.

