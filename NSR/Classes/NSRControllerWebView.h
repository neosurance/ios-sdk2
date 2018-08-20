#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <MapKit/MapKit.h>

@interface NSRControllerWebView : UIViewController<WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler,CLLocationManagerDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (strong, nonatomic) WKWebView* webView;
@property (strong, nonatomic) WKWebViewConfiguration* webConfiguration;
@property (strong, nonatomic) NSURL* url;
@property (nonatomic) UIStatusBarStyle barStyle;
@property (nonatomic, strong)CLLocationManager* locationManager;
@property (strong, nonatomic) NSString* locationCallBack;
@property (strong, nonatomic) NSString* photoCallBack;

@end