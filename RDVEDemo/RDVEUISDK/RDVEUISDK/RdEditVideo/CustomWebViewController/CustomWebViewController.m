//
//  CustomWebViewController.m
//  RDVEUISDK
//
//  Created by 王全洪 on 2018/11/15.
//  Copyright © 2018 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "CustomWebViewController.h"
#import <WebKit/WebKit.h>
#import "RDATMHud.h"
#import "RDMBProgressHUD.h"
@interface CustomWebViewController ()<UINavigationControllerDelegate,WKUIDelegate,WKNavigationDelegate,WKScriptMessageHandler,UIScrollViewDelegate,RDMBProgressHUDDelegate>

@property (nonatomic, strong) UIButton      *backBtn;
@property (nonatomic, strong) WKWebView     *webView;
@property (nonatomic,strong)RDATMHud        *hud;
@property (nonatomic,strong)RDMBProgressHUD *progressHUD;
@end

@implementation CustomWebViewController

- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return  UIStatusBarStyleDefault;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    self.navigationController.navigationBarHidden = NO;
    [self.navigationController setNavigationBarHidden:NO];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    self.navigationController.navigationBar.shadowImage = [[UIImage alloc]init];
    UIImage *theImage = [RDHelpClass rdImageWithColor:UIColorFromRGB(0x141414) cornerRadius:0.0];
    [self.navigationController.navigationBar setBackgroundImage:theImage forBarMetrics:UIBarMetricsDefault];
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    attributes[NSFontAttributeName] = [UIFont boldSystemFontOfSize: 20];
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    self.navigationController.navigationBar.titleTextAttributes = attributes;
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.backBtn];
    self.title = self.linkTitle;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.view addSubview:self.webView];
    [self loadExamplePage];
}

- (void)loadExamplePage{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSString *postUrl = _linkUrl;
        NSLog(@"postUrl=%@",postUrl);
        //=====
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:postUrl]];
        [request setHTTPMethod:@"GET"];
        [request setTimeoutInterval:10];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self.webView loadRequest:request];
        });
    });
}

- (UIButton *)backBtn{
    if(!_backBtn){
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _backBtn.frame = CGRectMake(0, 0, 44, 44);
         [_backBtn setImage:[RDHelpClass imageWithContentOfPath:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:@"/jianji/剪辑_返回默认_@3x" Type:@"png"]] forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (void)backAction{
    [self.navigationController popViewControllerAnimated:YES];
}

- (RDATMHud *)hud{
    if(!_hud){
        _hud = [[RDATMHud alloc] initWithDelegate:self];
        [self.view addSubview:_hud.view];
    }
    [self.view bringSubviewToFront:_hud.view];
    return _hud;
}

- (RDMBProgressHUD *)progressHUD{
    if(!_progressHUD){
        //圆形进度条
        
        _progressHUD = [[RDMBProgressHUD alloc] initWithView:self.navigationController.view];
        [_progressHUD setBackgroundColor:[UIColorFromRGB(0x000000) colorWithAlphaComponent:0.5]];
        [self.navigationController.view addSubview:_progressHUD];
        _progressHUD.removeFromSuperViewOnHide = YES;
        _progressHUD.mode = RDMBProgressHUDModeIndeterminate;//MBProgressHUDModeAnnularDeterminate;
        _progressHUD.animationType = RDMBProgressHUDAnimationZoom;
        _progressHUD.labelText = RDLocalizedString(@"加载中,请稍候...", nil);
        _progressHUD.delegate = self;
        
    }
    return _progressHUD;
}

- (WKWebView *)webView{
    if(!_webView){
        WKWebViewConfiguration *wkConfig = [[WKWebViewConfiguration alloc] init];
        wkConfig.userContentController = [[WKUserContentController alloc] init];
        CGRect frame = CGRectMake(0, 0, kWIDTH, kHEIGHT);
        _webView = [[WKWebView alloc] initWithFrame:frame configuration:wkConfig];
        _webView.backgroundColor = [UIColor clearColor];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        _webView.scrollView.showsVerticalScrollIndicator = NO;
        _webView.scrollView.showsHorizontalScrollIndicator = NO;
        _webView.scrollView.delegate = self;
        _webView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        if (@available(iOS 11.0, *)) {
            _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            _webView.scrollView.insetsLayoutMarginsFromSafeArea = YES;
        }else{
            //WKWebView加载web页面，隐藏导航栏，全屏显示,顶部出现20px的空白的解决办法
            self.edgesForExtendedLayout = UIRectEdgeNone;
        }
        //WKUserContentController *userCC = wkConfig.userContentController;
        //JS调用OC 添加处理脚本
        //[userCC addScriptMessageHandler:self name:@"label"];
    }
    return _webView;
}

#pragma mark-
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    [self.progressHUD show:YES];
}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    [self.progressHUD hide:NO];
}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self.progressHUD hide:NO];
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    [self.progressHUD hide:NO];
}

#pragma mark-
-(WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures

{
    
    NSLog(@"createWebViewWithConfiguration");
    
    if (!navigationAction.targetFrame.isMainFrame) {
        
        //[webView loadRequest:navigationAction.request];
        NSURLRequest *request = navigationAction.request;
        
        NSString *url = [NSString stringWithFormat:@"%@",request.URL];
        //NSInteger buttonNumber = navigationAction.buttonNumber;
        NSLog(@"url:%@",url);
    }
    
    return nil;
    
}
// 界面弹出警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(void (^)(void))completionHandler{
    
}
// 界面弹出确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
    
}
// 界面弹出输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler{
    
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    //AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    
    NSLog(@"%@",NSStringFromSelector(_cmd));
    NSLog(@"%@",message.body);
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    
}

- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_AVAILABLE(ios(10.0)){
    
}

- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * _Nullable URLs))completionHandler API_AVAILABLE(macosx(10.12)){
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
