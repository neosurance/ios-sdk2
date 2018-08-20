#import "NSRControllerWebView.h"
#import "NSR.h"

@implementation NSRControllerWebView

-(void)loadView {
	[super loadView];
	
	self.webConfiguration = [WKWebViewConfiguration new];
	[self.webConfiguration.userContentController addScriptMessageHandler:self name:@"app"];
	
	int sh = [UIApplication sharedApplication].statusBarFrame.size.height;
	CGSize size = self.view.frame.size;
	self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0,sh, size.width, size.height-sh) configuration:self.webConfiguration];
	self.webView.navigationDelegate = self;
	self.webView.backgroundColor = self.view.backgroundColor;
	self.webView.scrollView.showsVerticalScrollIndicator = NO;
	self.webView.scrollView.showsHorizontalScrollIndicator = NO;
	self.webView.scrollView.bounces = NO;
	if (@available(iOS 11.0, *)) {
		self.webView.scrollView.insetsLayoutMarginsFromSafeArea = NO;
		self.webView.scrollView.contentInsetAdjustmentBehavior= UIScrollViewContentInsetAdjustmentNever;
	}
	[self.webView loadRequest:[[NSURLRequest alloc] initWithURL:self.url]];
	[self.view addSubview: self.webView];
}

-(void)viewDidLoad {
	[super viewDidLoad];
	[self performSelector:@selector(checkBody) withObject:nil afterDelay:5];
}

-(void)navigate:(NSString*) url {
	[self.webView loadRequest:[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]]];
}

-(void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
	NSDictionary *body = (NSDictionary*)message.body;
	NSR* nsr = [NSR sharedInstance];
	if(body[@"log"] != nil) {
		NSLog(@"%@",body[@"log"]);
	}
	if(body[@"event"] != nil && body[@"payload"] != nil) {
		[nsr sendEvent:body[@"event"] payload:body[@"payload"]];
	}
	if(body[@"action"] != nil) {
		[nsr sendAction:body[@"action"] policyCode:body[@"code"] details:body[@"details"]];
	}
	if(body[@"what"] != nil) {
		if([@"init" compare:body[@"what"]] == NSOrderedSame && body[@"callBack"] != nil) {
			[nsr authorize:^(BOOL authorized) {
				NSMutableDictionary* message = [[NSMutableDictionary alloc] init];
				[message setObject:[nsr getSettings][@"base_url"] forKey:@"api"];
				[message setObject:[nsr getToken] forKey:@"token"];
				[message setObject:[nsr getLang] forKey:@"lang"];
				[message setObject:[nsr uuid] forKey:@"deviceUid"];
				[self eval:[NSString stringWithFormat:@"%@(%@)",body[@"callBack"], [nsr dictToJson:message]]];
			}];
		}
		if([@"close" compare:body[@"what"]] == NSOrderedSame) {
			[self close];
		}
		if([@"photo" compare:body[@"what"]] == NSOrderedSame && body[@"callBack"] != nil) {
			[self takePhoto:body[@"callBack"]];
		}
		if([@"location" compare:body[@"what"]] == NSOrderedSame && body[@"callBack"] != nil) {
			[self getLocation:body[@"callBack"]];
		}
		if([@"user" compare:body[@"what"]] == NSOrderedSame && body[@"callBack"] != nil) {
			[self eval:[NSString stringWithFormat:@"%@(%@)", body[@"callBack"], [nsr dictToJson:[[nsr getUser] toDict:YES]]]];
		}
		if([@"showApp" compare:body[@"what"]] == NSOrderedSame) {
			[nsr showApp:body[@"params"]];
		}
		if([@"showUrl" compare:body[@"what"]] == NSOrderedSame && body[@"url"] != nil) {
			[nsr showUrl:body[@"url"] params:body[@"params"]];
		}
		if([@"callApi" compare:body[@"what"]] == NSOrderedSame && body[@"callBack"] != nil) {
			[nsr authorize:^(BOOL authorized) {
				if(!authorized){
					NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
					[result setObject:@"error" forKey:@"status"];
					[result setObject:@"not authorized" forKey:@"message"];
					[self eval:[NSString stringWithFormat:@"%@(%@)", body[@"callBack"], [nsr dictToJson:result]]];
					return;
				}
				NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];
				[headers setObject:[nsr getToken] forKey:@"ns_token"];
				[headers setObject:[nsr getLang] forKey:@"ns_lang"];
				[nsr.securityDelegate secureRequest:body[@"endpoint"] payload:body[@"payload"] headers:headers completionHandler:^(NSDictionary *responseObject, NSError *error) {
					if(error == nil) {
						[self eval:[NSString stringWithFormat:@"%@(%@)", body[@"callBack"], [nsr dictToJson:responseObject]]];
					} else {
						NSMutableDictionary* result = [[NSMutableDictionary alloc] init];
						[result setObject:@"error" forKey:@"status"];
						[result setObject:[NSString stringWithFormat:@"%@", error] forKey:@"message"];
						[self eval:[NSString stringWithFormat:@"%@(%@)", body[@"callBack"], [nsr dictToJson:result]]];
					}
				}];
			}];
		}
		if(nsr.workflowDelegate != nil && [@"executeLogin" compare:body[@"what"]] == NSOrderedSame && body[@"callBack"] != nil) {
			[self eval:[NSString stringWithFormat:@"%@(%@)", body[@"callBack"], [nsr.workflowDelegate executeLogin:self.webView.URL.absoluteString]?@"true":@"false"]];
		}
		if(nsr.workflowDelegate != nil && [@"executePayment" compare:body[@"what"]] == NSOrderedSame && body[@"payment"] != nil) {
			NSDictionary* paymentInfo = [nsr.workflowDelegate executePayment:body[@"payment"] url:self.webView.URL.absoluteString];
			if(body[@"callBack"] != nil) {
				[self eval:[NSString stringWithFormat:@"%@(%@)", body[@"callBack"], paymentInfo != nil?[nsr dictToJson:paymentInfo]:@""]];
			}
		}
	}
}

-(void)takePhoto:(NSString*)callBack {
	UIImagePickerController *controller = [[UIImagePickerController alloc] init];
	controller.delegate = self;
	controller.sourceType = UIImagePickerControllerSourceTypeCamera;
	controller.allowsEditing = NO;
	[self presentViewController:controller animated:YES completion:^{
		[self setPhotoCallBack:callBack];
	}];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
	if(self.photoCallBack != nil){
		UIImage* image = info[UIImagePickerControllerOriginalImage];
		CGSize newSize = CGSizeMake(512.0f*image.size.width/image.size.height,512.0f);
		UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
		[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
		UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		NSData *imageData = UIImageJPEGRepresentation(newImage, 1.0);
		NSString *base64 = [imageData base64EncodedStringWithOptions:kNilOptions];
		[self eval:[NSString stringWithFormat:@"%@('data:image/png;base64,%@')",self.photoCallBack, base64]];
		[picker dismissViewControllerAnimated:YES completion:^{
			[self setPhotoCallBack:nil];
		}];
	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissViewControllerAnimated:YES completion:^{
		[self setPhotoCallBack:nil];
	}];
}
-(void)getLocation:(NSString*)callBack {
	if([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways){
		if(self.locationManager == nil){
			self.locationManager = [[CLLocationManager alloc] init];
			[self.locationManager setAllowsBackgroundLocationUpdates:YES];
			[self.locationManager setPausesLocationUpdatesAutomatically:NO];
			[self.locationManager setDistanceFilter:kCLDistanceFilterNone];
			[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
			self.locationManager.delegate = self;
			[self.locationManager requestAlwaysAuthorization];
		}
		[self setLocationCallBack:callBack];
		[self.locationManager startUpdatingLocation];
	}
}

-(void)locationManager:(CLLocationManager*)manager didUpdateLocations:(NSArray *)locations {
	if([locations count] > 0){
		NSLog(@"didUpdateToLocation");
		[manager stopUpdatingLocation];
		if(self.locationCallBack != nil){
			CLLocation* loc = [locations lastObject];
			[self eval:[NSString stringWithFormat:@"%@({latitude:%f,longitude:%f})", self.locationCallBack, loc.coordinate.latitude, loc.coordinate.longitude]];
			[self setLocationCallBack:nil];
		}
	}
}

-(void)locationManager:(CLLocationManager*)manager didFailWithError:(NSError *)error {
	NSLog(@"didFailWithError");
}

-(BOOL)shouldAutorotate {
	return NO;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
	return UIInterfaceOrientationPortrait;
}

-(UIStatusBarStyle)preferredStatusBarStyle{
	return self.barStyle;
}

-(void)checkBody {
	[self.webView evaluateJavaScript:@"document.body.className" completionHandler:^(id result, NSError *error) {
		if(![result isEqualToString:@"NSR"]) {
			[self close];
		} else {
			[self performSelector:@selector(checkBody) withObject:nil afterDelay:5];
		}
	}];
}

-(void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
	if(navigationAction.navigationType == WKNavigationTypeLinkActivated) {
		NSString* url = [NSString stringWithFormat:@"%@", navigationAction.request.URL];
		if([url hasSuffix:@".pdf"]) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:NULL];
			decisionHandler(WKNavigationActionPolicyCancel);
		} else {
			decisionHandler(WKNavigationActionPolicyAllow);
		}
	} else {
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

-(void)close {
	NSLog(@"%s", __FUNCTION__);
	[self dismissViewControllerAnimated:YES completion:^(){
		[self.webView stopLoading];
		[self.webView setNavigationDelegate: nil];
		[self.webView removeFromSuperview];
		[self setWebView:nil];
		if(self.locationManager != nil){
			[self.locationManager stopUpdatingLocation];
			[self.locationManager setDelegate:nil];
			[self setLocationManager:nil];
		}
	}];
}

-(void)eval:(NSString*)javascript {
	[self.webView evaluateJavaScript:javascript completionHandler:^(id result, NSError *error) {}];
}
@end
