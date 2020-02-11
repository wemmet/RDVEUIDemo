//
//  RDEditTextViewController.m
//  RDVEUISDK
//
//  Created by wuxiaoxia on 2018/12/20.
//  Copyright © 2018年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDEditTextViewController.h"
#import "RDNavigationViewController.h"
#import "RDATMHud.h"
#import "UIImageView+RDWebCache.h"
#import "RDFileDownloader.h"
#import "RDZipArchive.h"
#import "RDSectorProgressView.h"

#define kFontTitleImageViewTag   10000
#define kCAPTIONTYPECHILDTAG 3000

@implementation RDTextAnimateInfo



@end

@interface RDEditTextViewController ()<UITextViewDelegate, UIScrollViewDelegate>
{
    RDATMHud            *hud;
    UITextView          *textView;
    UILabel             *placeHolderLabel;
    UIView              *bottomView;
    UILabel             *tipLbl;
    UIButton            *selectFontBtn;
    UIScrollView        *fontScrollView;
    NSMutableArray      *fontList;
    NSDictionary        *fontIconList;
    float                fontSize;
    NSInteger            selectedFontIndex;
}

@end

@implementation RDEditTextViewController

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle{
    return UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [textView resignFirstResponder];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = YES;
    self.view.backgroundColor = SCREEN_BACKGROUND_COLOR;
    hud = [[RDATMHud alloc] init];
    [self.navigationController.view addSubview:hud.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    if(![[NSFileManager defaultManager] fileExistsAtPath:kFontFolder]){
        [[NSFileManager defaultManager] createDirectoryAtPath:kFontFolder withIntermediateDirectories:YES attributes:nil error:nil];
    }
    [RDHelpClass customFontWithPath:_templateFontPath fontName:nil];
    fontSize = 20;
    
    textView = [[UITextView alloc] initWithFrame:CGRectMake(10, 0, kWIDTH - 20, kWIDTH)];
    textView.backgroundColor = [UIColor clearColor];
    textView.text = _textContent;
    textView.font = [UIFont fontWithName:_selectedFontName size:fontSize];
    textView.textColor = [UIColor whiteColor];
    textView.delegate = self;
    [self.view addSubview:textView];
    [textView becomeFirstResponder];
    
    placeHolderLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 1.5, textView.bounds.size.width - 20, 60)];
    placeHolderLabel.text = RDLocalizedString(@"[分:秒.毫秒(开始时间),分:秒.毫秒(结束时间)]文字内容", nil);
    placeHolderLabel.numberOfLines = 0;
    placeHolderLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.7];
    placeHolderLabel.font = [UIFont systemFontOfSize:fontSize];
    if (textView.text.length > 0) {
        placeHolderLabel.hidden = YES;
    }
    [textView addSubview:placeHolderLabel];
    
    bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kHEIGHT - 88, kWIDTH, 88)];
    bottomView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:bottomView];
    
    tipLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, kWIDTH, 44)];
    tipLbl.textColor = UIColorFromRGB(0x888888);
    tipLbl.textAlignment = NSTextAlignmentCenter;
    tipLbl.font = [UIFont systemFontOfSize:15.0];
    [bottomView addSubview:tipLbl];
    [self refreshLineNum:_textContent];
    
    UIView *btnView = [[UIView alloc] initWithFrame:CGRectMake(0, 44, kWIDTH, 44)];
    btnView.backgroundColor = [UIColorFromRGB(NV_Color) colorWithAlphaComponent:(iPhone4s ? 0.6 : 1.0)];
    [bottomView addSubview:btnView];
    
    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelBtn.frame = CGRectMake(0, 2, 40, 40);
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消默认_"] forState:UIControlStateNormal];
    [cancelBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步取消点击_"] forState:UIControlStateHighlighted];
    cancelBtn.tag = 1;
    [cancelBtn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [btnView addSubview:cancelBtn];
    
    selectFontBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    selectFontBtn.frame = CGRectMake((kWIDTH - 100)/2.0, 0, 100, 44);
    [selectFontBtn setTitle:RDLocalizedString(@"选择字体", nil) forState:UIControlStateNormal];
    [selectFontBtn setTitle:RDLocalizedString(@"选择字体", nil) forState:UIControlStateSelected];
    [selectFontBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [selectFontBtn setTitleColor:Main_Color forState:UIControlStateSelected];
    selectFontBtn.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [selectFontBtn addTarget:self action:@selector(selectFontBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    [btnView addSubview:selectFontBtn];
    
    UIButton *finishBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    finishBtn.frame = CGRectMake(kWIDTH - 40, 2, 40, 40);
    [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成默认_"] forState:UIControlStateNormal];
    [finishBtn setImage:[RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"] forState:UIControlStateHighlighted];
    finishBtn.tag = 2;
    [finishBtn addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [btnView addSubview:finishBtn];
    
    [self getFontList];
}

- (void)initFontScrollView {
    fontScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, bottomView.frame.origin.y - 100 + 44, kWIDTH, 100)];
    fontScrollView.backgroundColor = UIColorFromRGB(0x27262c);
    fontScrollView.layer.borderWidth = 1.0;
    fontScrollView.layer.borderColor = UIColorFromRGB(0x888888).CGColor;
    fontScrollView.showsHorizontalScrollIndicator = NO;
    fontScrollView.contentSize = CGSizeMake(0, (50 * fontList.count + 10));
    fontScrollView.hidden = YES;
    [self.view addSubview:fontScrollView];
    
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length>0 ? YES : NO;
    BOOL suc = NO;
    for (int k = 0; k<fontList.count; k++) {
        NSDictionary *itemDic = [fontList objectAtIndex:k];
        if (k == 0) {
            if ([[itemDic objectForKey:@"font"] isEqualToString:_selectedFontName]) {
                selectedFontIndex = 0;
            }
        }else {
            NSString *fontfile;
            if(hasNew){
                fontfile = [[[itemDic objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension];
            }else{
                fontfile = [itemDic objectForKey:@"name"];
            }
            NSString *netFontName = [itemDic objectForKey:@"fontname"];
            if(fontfile.length > 0){
                NSString *fontPath = [RDHelpClass pathForURL_font_WEBP:fontfile extStr:@"ttf" isNetMaterial:hasNew];
                if(hasNew){
                    NSString *n = [[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent];
                    NSString *f = [RDHelpClass pathInCacheDirectory:[NSString stringWithFormat:@"SubtitleEffect/Font/%@",n]];
                    __block NSString *fn;
                    [ [[NSFileManager defaultManager] contentsOfDirectoryAtPath:f error:nil] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if([[[obj pathExtension] lowercaseString] isEqualToString:@"ttf"]){
                            fn = obj;
                        }else{
                            NSString * ipath = [NSString stringWithFormat:@"%@/%@/%@",kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],obj];
                            [[NSFileManager defaultManager] removeItemAtPath:ipath error:nil];
                        }
                    }];
                    fontPath = [NSString stringWithFormat:@"%@/%@/%@",kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],fn];
                }
                NSString *fontName = [RDHelpClass customFontWithPath:fontPath fontName:netFontName];
                if ([fontName isEqualToString:_selectedFontName]) {
                    selectedFontIndex = k;
                }
            }
        }
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn addTarget:self action:@selector(touchesFontListViewChild:) forControlEvents:UIControlEventTouchUpInside];
        btn.backgroundColor = [UIColor clearColor];
        btn.frame = CGRectMake(0, k* 50 + 5, fontScrollView.frame.size.width, 50);
        btn.layer.cornerRadius = 0.0;
        btn.layer.masksToBounds = YES;
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:CGRectMake(10, 0, 106,btn.frame.size.height)];
        imageV.backgroundColor = [UIColor clearColor];
        imageV.contentMode = UIViewContentModeScaleAspectFit;
        imageV.frame = CGRectMake(10, 0, 145, btn.frame.size.height);
        imageV.backgroundColor = [UIColor clearColor];
        NSString *fileName = hasNew ? [[[itemDic objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension] : [itemDic objectForKey:@"name"];
        NSString *path = kFontIconPath;
        if(hasNew){
            [imageV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
        }else{
            if (k == selectedFontIndex) {
                path = [NSString stringWithFormat:@"%@/%@/selected",kFontFolder,fileName];
                NSString *imagePath;
                imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_@3x.png",fileName]];
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                if (image) {
                    imageV.image = image;
                }else{
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_@2x.png",fileName]];
                    image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        imageV.image = image;
                    }
                }
            }else {
                NSString *imagePath;
                imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@3x.png",fileName]];
                UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                if (image) {
                    imageV.image = image;
                }else{
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@2x.png",fileName]];
                    image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        imageV.image = image;
                    }
                }
            }
        }
        imageV.tag = kFontTitleImageViewTag;
        imageV.layer.masksToBounds = YES;
        
        if(k==0){
            NSString *title = [itemDic objectForKey:@"title"];
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, 0, 145, btn.frame.size.height)];
            label.text = title;
            label.tag = 3;
            label.textAlignment = NSTextAlignmentLeft;
            if (selectedFontIndex == 0) {
                label.textColor = Main_Color;
            }else {
                label.textColor = UIColorFromRGB(0xbdbdbd);
            }
            label.font = [UIFont systemFontOfSize:16.0];
            [btn addSubview:label];
        }else{
            
            NSString *timeunix = [NSString stringWithFormat:@"%d",[(hasNew ? itemDic[@"updatetime"] : itemDic[@"timeunix"]) integerValue]];
            
            fontList = [NSMutableArray arrayWithContentsOfFile:kFontPlistPath];
            
            NSString *configPath = kFontCheckPlistPath;
            NSMutableDictionary *configDic = [[NSMutableDictionary alloc] initWithContentsOfFile:configPath];
            BOOL check = [timeunix isEqualToString:[configDic objectForKey:fileName]] ? YES : NO;
            
            NSString *path = [RDHelpClass pathForURL_font_WEBP:fileName extStr:@"ttf" isNetMaterial:hasNew];
            
            if(![[NSFileManager defaultManager] fileExistsAtPath:path] || !check){
                NSError *error;
                if([[NSFileManager defaultManager] fileExistsAtPath:path]){
                    [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
                    NSLog(@"error:%@",error);
                }
            }
            suc = [RDHelpClass hasCachedFont_WEBP:hasNew ? [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[itemDic[@"file"] lastPathComponent]] : fileName extStr:@"ttf" isNetMaterial:hasNew];
        }
        
        {
            UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
            UIImageView *markV = [[UIImageView alloc] initWithFrame:CGRectMake(btn.frame.size.width - 35, (btn.frame.size.height-accessory.size.height)/2, accessory.size.width, accessory.size.height)];
            markV.backgroundColor = [UIColor clearColor];
            imageV.layer.masksToBounds = YES;
            markV.tag = 4000;
            [markV setImage:accessory];
            [btn addSubview:markV];
            if(!suc && k != 0){
                markV.hidden = NO;
            }else{
                markV.hidden = YES;
            }
            if(k == 0){
                markV.hidden = YES;
            }
        }
        
        if(hasNew){
            UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"];
            UIImageView *markV = [[UIImageView alloc] initWithFrame:CGRectMake(btn.frame.size.width - accessory.size.width, (btn.frame.size.height-accessory.size.height)/2, accessory.size.width, accessory.size.height)];
            markV.backgroundColor = [UIColor clearColor];
            markV.tag = 50000;
            [markV setImage:accessory];
            [btn addSubview:markV];
            if (k == selectedFontIndex) {
                markV.hidden = NO;
            }else {
                markV.hidden = YES;
            }
        }
        [btn setImageEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        btn.tag = k+kCAPTIONTYPECHILDTAG;
        UIView *span = [[UIView alloc] initWithFrame:CGRectMake(0, btn.frame.size.height-1, btn.frame.size.width, 1)];
        span.backgroundColor = UIColorFromRGB(NV_Color);
        [btn addSubview:imageV];
        [btn addSubview:span];
        
        [fontScrollView addSubview:btn];
    }
}

- (void)getFontList {
    fontList = [NSMutableArray arrayWithContentsOfFile:kFontPlistPath];
    
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length>0;
    __block BOOL create = NO;
    if(!hasNew){
        fontIconList = [NSDictionary dictionaryWithContentsOfFile:kFontIconPlistPath];
        
        if(fontList && fontIconList){
            create = YES;
            [self initFontScrollView];
        }
    }else if (fontList){
        create = YES;
        [self initFontScrollView];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableDictionary *params  = [[NSMutableDictionary alloc] init];
        __block NSDictionary *fontListDic;
        NSString *fontUrl = @"";
        if(hasNew){
            fontUrl = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL;
            fontListDic = [RDHelpClass getNetworkMaterialWithType:kFontType
                                                           appkey:((RDNavigationViewController *)self.navigationController).appKey
                                                          urlPath:fontUrl];
        }else{
            [params setObject:@"1" forKey:@"os"];
            fontUrl = getFontTypeUrl;
            fontListDic = [RDHelpClass updateInfomation:params andUploadUrl:fontUrl];
        }
        NSMutableDictionary *fontdic=[[NSMutableDictionary alloc] initWithCapacity:1];
        
        [fontdic setObject:@"默认模板字体" forKey:@"title"];
        [fontdic setObject:@"morenziti" forKey:@"code"];
        [fontdic setObject:@"" forKey:@"icon"];
        [fontdic setObject:_templateFontName forKey:@"font"];
        
        BOOL resultInteger = hasNew ? [fontListDic[@"code"] intValue] == 0 : [fontListDic[@"code"] intValue] == 200;
        if (!resultInteger){
            fontListDic = nil;
            if (!fontList) {//20161108 bug4320
                fontList = [[NSMutableArray alloc] initWithObjects:fontdic, nil];
            }
        }else{
            if([fontListDic[@"data"] isKindOfClass:[NSMutableArray class]]){
                fontList = [fontListDic[@"data"] mutableCopy];
                [fontList insertObject:fontdic atIndex:0];
                
                BOOL suc = [fontList writeToFile:kFontPlistPath atomically:YES];
                if(!suc){
                    NSLog(@"写文件失败");
                }
                if (!hasNew && (!fontIconList || (fontIconList && [[[fontListDic objectForKey:@"icon"] objectForKey:@"timeunix"] longValue] > [[fontIconList objectForKey:@"timeunix"] longValue]))) {
                    NSFileManager *manager = [[NSFileManager alloc] init];
                    NSError *error;
                    NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[fontIconList objectForKey:@"name"]];
                    if([manager fileExistsAtPath:path]){
                        [manager removeItemAtPath:path error:&error];
                    }
                    create = NO;
                    fontIconList = [fontListDic objectForKey:@"icon"];
                    suc = [fontIconList writeToFile:kFontIconPlistPath atomically:YES];
                    if(!suc){
                        NSLog(@"写文件失败");
                    }
                    if (!create) {
                        [self DownloadThumbnailFile:[fontIconList objectForKey:@"caption"] andUnzipToPath:@"SubtitleEffect/Font" andCellcaptionTypeCount:1];
                    }
                }else if(!create){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self initFontScrollView];                        
                    });
                }
            }
        }
    });
}

#pragma mark - 下载字体
-(void)DownloadThumbnailFile:(NSString*)fileUrl andUnzipToPath:(NSString *)unzipToPath andCellcaptionTypeCount:(NSInteger)cellcaptionTypeCount
{
    NSURL *url = [NSURL URLWithString:fileUrl];
    unlink([[RDHelpClass pathFontForURL:url] UTF8String]);
    __weak typeof(self) weakSelf= self;
    NSString *cacheFolderPath = [[RDHelpClass pathFontForURL:url] stringByDeletingLastPathComponent];
    
    [RDFileDownloader downloadFileWithURL:fileUrl cachePath:cacheFolderPath httpMethod:GET progress:nil finish:^(NSString *fileCachePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [weakSelf OpenZip:fileCachePath unzipto:[RDHelpClass pathInCacheDirectory:unzipToPath] caption:NO];
            [weakSelf initFontScrollView];
            
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"下载失败");
            [hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [hud show];
            [hud hideAfter:2];
        });
    }];
}

- (void)OpenZip:(NSString*)zipPath  unzipto:(NSString*)_unzipto caption:(BOOL)caption
{
    RDZipArchive* zip = [[RDZipArchive alloc] init];
    if( [zip RDUnzipOpenFile:zipPath] )
    {
        BOOL ret = [zip RDUnzipFileTo:_unzipto overWrite:YES];
        if( NO==ret )
        {
            NSLog(@"error");
        }else{
            unlink([zipPath UTF8String]);
        }
        [zip RDUnzipCloseFile];
    }
}

#pragma mark - 按钮事件
- (void)buttonAction:(UIButton *)sender {
    [textView resignFirstResponder];
    if (sender.tag == 2) {
        if (textView.text.length > 0) {
            textView.text = [textView.text stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"];
        }
        if (_delegate && [_delegate respondsToSelector:@selector(editTextFinished:textContent:)]) {
            NSString *newTextContent;
            if ([_textContent isEqualToString:textView.text]) {
                newTextContent = nil;
            }else {
                newTextContent = textView.text;
            }
            [_delegate editTextFinished:_selectedFontName textContent:newTextContent];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)selectFontBtnAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    fontScrollView.hidden = !fontScrollView.hidden;
}

- (void)touchesFontListViewChild:(UIButton *)sender{
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length > 0;
    NSDictionary *itemDic = [fontList objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG];
    NSString *title = [itemDic objectForKey:@"name"];
    UIImageView *image = (UIImageView *)[sender viewWithTag:4000];
    NSString *ff = [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[itemDic[@"file"] lastPathComponent]];
    BOOL suc = [RDHelpClass hasCachedFont_WEBP:hasNew ? ff  : title extStr:@"ttf" isNetMaterial:hasNew];
    
    selectedFontIndex = sender.tag - kCAPTIONTYPECHILDTAG;
    if(selectedFontIndex == 0){
        [self setFont:selectedFontIndex];
    }else if(!suc){
        NSString *url = hasNew ? [fontList objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG][@"file"] : [[fontList objectAtIndex:sender.tag-kCAPTIONTYPECHILDTAG] objectForKey:@"caption"];
        [self downloadfontType_font:url button:image index:selectedFontIndex];
    }else{
        [self setFont:selectedFontIndex];
    }
}

#pragma mark -  下载字体
- (void)downloadfontType_font:(NSString *)url
                       button:(UIImageView *)sender
                        index:(NSUInteger)index
{
    __weak typeof(self) weakSelf = self;
    UIImage *accessory = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
    CGRect rect = CGRectMake((sender.frame.size.width - accessory.size.width)/2, (sender.frame.size.height - accessory.size.height)/2, accessory.size.width, accessory.size.height);
    RDSectorProgressView *ddprogress = [[RDSectorProgressView alloc] initWithFrame:rect];
    ddprogress.progressColor = [UIColor greenColor];
    ddprogress.circleBackgroundColor = [UIColor greenColor];
    [sender addSubview:ddprogress];
    
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL.length > 0;
    NSString *path = @"";
    if(hasNew){
        
        path = [RDHelpClass pathForURL_font_WEBP_down:([[[[fontList objectAtIndex:index][@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[[[[fontList objectAtIndex:index] objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension]]) extStr:@"zip"];
    }else{
        path = [RDHelpClass pathForURL_font_WEBP_down:[[fontList objectAtIndex:index] objectForKey:@"name"] extStr:@"zipp"];
    }
    
    NSString *url_str=[NSString stringWithString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    NSString *cacheFolderPath = [path stringByDeletingLastPathComponent];
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:cacheFolderPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:cacheFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
    [RDFileDownloader downloadFileWithURL:url_str cachePath:cacheFolderPath httpMethod:GET progress:^(NSNumber *numProgress) {
        [ddprogress setProgress:[numProgress floatValue]];
    } finish:^(NSString *fileCachePath) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf OpenZip:fileCachePath unzipto:cacheFolderPath caption:NO];
            
            NSString *openZippath = @"";
            __block NSString *fileTimeKey;
            __block NSString *fileName = [[fontList objectAtIndex:index] objectForKey:@"name"];
            if(hasNew){
                [[[NSFileManager defaultManager] contentsOfDirectoryAtPath:cacheFolderPath error:nil] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if([[[obj pathExtension] lowercaseString] isEqualToString:@"zip"]){
                        [[NSFileManager defaultManager] removeItemAtPath:[cacheFolderPath stringByAppendingPathComponent:obj] error:nil];
                    }
                    if([[[obj pathExtension] lowercaseString] isEqualToString:@"ttf"]){
                        fileName = obj;
                    }
                }];
                fileTimeKey = [cacheFolderPath lastPathComponent];
                openZippath = [kFontFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",[[cacheFolderPath lastPathComponent] stringByAppendingPathComponent:fileName]]];
            }else{
                fileTimeKey = fileName;
                openZippath = [kFontFolder stringByAppendingString:[NSString stringWithFormat:@"/%@",fileName]];
            }
            NSString *time = [NSString stringWithFormat:@"%ld",[(hasNew ? fontList[index][@"updatetime"] : fontList[index][@"timeunix"]) integerValue]];
            
            NSString *path = kFontCheckPlistPath;
            
            if([[NSFileManager defaultManager] fileExistsAtPath:openZippath]){
                NSMutableDictionary *checkConfigDic = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
                if(!checkConfigDic){
                    checkConfigDic = [[NSMutableDictionary alloc] init];
                }
                if(time.length==0 || !time){
                    [checkConfigDic setObject:@"2015-02-03" forKey:fileTimeKey];
                }else{
                    [checkConfigDic setObject:time forKey:fileTimeKey];
                }
                if([checkConfigDic writeToFile:path atomically:YES]){
                    [weakSelf setFont:index];
                }
                sender.hidden = YES;
                sender.alpha = 0;
                [ddprogress removeFromSuperview];
            }else{
                [hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
                [hud show];
                [hud hideAfter:2];
                
                [ddprogress removeFromSuperview];
                sender.hidden = NO;
            }
        });
    } fail:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [hud setCaption:RDLocalizedString(@"下载失败，请检查网络!", nil)];
            [hud show];
            [hud hideAfter:2];
            
            [ddprogress removeFromSuperview];
            sender.hidden = NO;
        });
    }];
}

//根据ID设置字体
- (void)setFont:(NSInteger)index{
    BOOL hasNew = ((RDNavigationViewController *)self.navigationController).editConfiguration.fontResourceURL > 0;
    for (int k = 0; k < fontList.count; k++) {
        UIButton *sender = (UIButton *)[fontScrollView viewWithTag:k + kCAPTIONTYPECHILDTAG];
        if(!sender){
            return;
        }
        NSDictionary *itemDic = [fontList objectAtIndex:sender.tag - kCAPTIONTYPECHILDTAG];
        UIImageView *imagev = (UIImageView *)[sender viewWithTag:4000];
        UIImageView *selectv = (UIImageView *)[sender viewWithTag:50000];
        NSString *title = [[fontList objectAtIndex:sender.tag - kCAPTIONTYPECHILDTAG] objectForKey:@"name"];
        if(k >0 && hasNew){
            title = [[[itemDic objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension];
        }
        UIImageView *titleIV = (UIImageView *)[sender viewWithTag:kFontTitleImageViewTag];
        BOOL isCached = [RDHelpClass hasCachedFont_WEBP: hasNew ? [[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent] stringByAppendingPathComponent:[itemDic[@"file"] lastPathComponent]] :title extStr:@"ttf" isNetMaterial:hasNew];
        if ([titleIV isKindOfClass:[UIImageView class]]) {
            if(isCached && sender.tag - kCAPTIONTYPECHILDTAG == index){
                if(hasNew){
                    [titleIV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
                }else{
                    NSString *path = [NSString stringWithFormat:@"%@/%@/selected",kFontFolder,title];
                    NSString *imagePath;
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_@3x.png",title]];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        titleIV.image = image;
                    }else{
                        imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_s_@2x.png",title]];
                        image = [UIImage imageWithContentsOfFile:imagePath];
                        if (image) {
                            titleIV.image = image;
                        }
                    }
                }
            }else if (sender.tag - kCAPTIONTYPECHILDTAG != 0) {
                if(hasNew){
                    [titleIV rd_sd_setImageWithURL:[NSURL URLWithString:itemDic[@"cover"]]];
                }else{
                    NSString *path = [NSString stringWithFormat:@"%@/%@",kFontFolder,[fontIconList objectForKey:@"name"]];
                    NSString *imagePath;
                    imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@3x.png",title]];
                    UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
                    if (image) {
                        titleIV.image = image;
                    }else{
                        imagePath = [path stringByAppendingString:[NSString stringWithFormat:@"/icon_2_%@_n_@2x.png",title]];
                        image = [UIImage imageWithContentsOfFile:imagePath];
                        if (image) {
                            titleIV.image = image;
                        }
                    }
                }
            }
            UILabel *titleLbl = (UILabel *)[sender viewWithTag:3];
            if ([titleLbl isKindOfClass:[UILabel class]]) {
                if (sender.tag - kCAPTIONTYPECHILDTAG == index) {
                    titleLbl.textColor = Main_Color;
                }else {
                    titleLbl.textColor = UIColorFromRGB(0xbdbdbd);
                }
            }
        }
        if([imagev isKindOfClass:[UIImageView class]]){
            if((sender.tag - kCAPTIONTYPECHILDTAG == index) ||!isCached){
                if(sender.tag - kCAPTIONTYPECHILDTAG == index){
                    imagev.image = [RDHelpClass imageWithContentOfFile:@"jianji/scrollViewChildImage/剪辑_下一步完成点击_"];
                    imagev.hidden = YES;
                    
                }else if(!isCached && sender.tag - kCAPTIONTYPECHILDTAG != 0 ){
                    imagev.image = [RDHelpClass imageWithContentOfFile:@"next_jianji/剪辑-字幕下载_"];
                    imagev.hidden = NO;
                    
                }else{
                    imagev.hidden = YES;
                }
            }else{
                imagev.hidden = YES;
            }
        }
        if([selectv isKindOfClass:[UIImageView class]]){
            if((sender.tag - kCAPTIONTYPECHILDTAG == index) ||!isCached){
                if(sender.tag - kCAPTIONTYPECHILDTAG == index){
                    selectv.hidden = NO;
                }else if(!isCached && sender.tag - kCAPTIONTYPECHILDTAG != 0 ){
                    selectv.hidden = YES;
                }else{
                    selectv.hidden = NO;
                }
            }else{
                selectv.hidden = YES;
            }
        }
        if(k == 0 && index !=0){
            selectv.hidden = YES;
        }
    }
    
    if(index==0){
        _selectedFontName = _templateFontName;
        [self setFontSize:textView.text];
        return;
    }
    NSDictionary *itemDic = [fontList objectAtIndex:index];
    NSString *fontfile;
    if(hasNew){
        fontfile = [[[itemDic objectForKey:@"file"] lastPathComponent] stringByDeletingPathExtension];
    }else{
        fontfile = [itemDic objectForKey:@"name"];
    }
    NSString *netFontName = [itemDic objectForKey:@"fontname"];
    
    if(fontfile.length==0){
        return;
    }
    NSString *path = [RDHelpClass pathForURL_font_WEBP:fontfile extStr:@"ttf" isNetMaterial:hasNew];
    
    if(hasNew){
        NSString *n = [[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent];
        NSString *f = [NSString stringWithFormat:@"%@/%@",kFontFolder,n];
        __block NSString *fn;
        [ [[NSFileManager defaultManager] contentsOfDirectoryAtPath:f error:nil] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if([[[obj pathExtension] lowercaseString] isEqualToString:@"ttf"]){
                fn = obj;
            }else{
                NSString * ipath = [NSString stringWithFormat:@"%@/%@/%@",kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],obj];
                [[NSFileManager defaultManager] removeItemAtPath:ipath error:nil];
            }
        }];
        path = [NSString stringWithFormat:@"%@/%@/%@",kFontFolder,[[itemDic[@"file"] stringByDeletingLastPathComponent] lastPathComponent],fn];
    }
    _selectedFontName = [RDHelpClass customFontWithPath:path fontName:netFontName];
    
    [self setFontSize:textView.text];
}

//设置文本域的字体大小
- (void)setFontSize:(NSString *)string{
    NSMutableArray *arr = [self getStringArr:string];
    if(arr){
        string = [arr lastObject];
    }
    
    float width = [self widthForString:string andHeight:fontSize];
    float size = textView.frame.size.width/width;
    if(size<1){
        if(_selectedFontName){
            textView.font = [UIFont fontWithName:_selectedFontName size:fontSize*size];
        }else{
            textView.font = [UIFont systemFontOfSize:fontSize*size];
        }
    }else{
        if(_selectedFontName){
            textView.font = [UIFont fontWithName:_selectedFontName size:fontSize];
        }else{
            textView.font = [UIFont systemFontOfSize:fontSize];
        }
    }
    [arr removeAllObjects];
    arr = nil;
}

//获取最长的一段
- (NSMutableArray *)getStringArr:(NSString *)string{
    NSMutableArray *arr  = [[string componentsSeparatedByString:@"\n"] mutableCopy];
    
    [arr sortUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        
        CGFloat obj1X = [self widthForString:obj1 andHeight:fontSize];
        CGFloat obj2X = [self widthForString:obj2 andHeight:fontSize];
        
        if (obj1X > obj2X) { // obj1排后面
            return NSOrderedDescending;
        }
        else { // obj1排前面
            return NSOrderedAscending;
        }
    }];
    return arr;
}

#pragma mark- 计算文字的方法
//获取字符串的文字域的宽
- (float)widthForString:(NSString *)value andHeight:(float)height
{
    CGSize sizeToFit = [value boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, height)
                                           options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                        attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:fontSize]}
                                           context:nil].size;
    return sizeToFit.width;
}
//获取字符串的文字域的高
- (float)hightForString:(NSString *)value andWidth:(float)width
{
    CGSize sizeToFit = [value boundingRectWithSize:CGSizeMake(width,CGFLOAT_MAX)
                                           options:NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading
                                        attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:textView.font.pointSize]}
                                           context:nil].size;
    return sizeToFit.height;
}

- (void)refreshLineNum:(NSString *)str {
    UIFont *font = [UIFont fontWithName:_selectedFontName size:fontSize];
    CGSize size = [str sizeWithAttributes:@{NSFontAttributeName:font}];
    NSInteger lines = (NSInteger)(size.height / font.lineHeight);
    tipLbl.text = [NSString stringWithFormat:RDLocalizedString(@"行数：%d/%d", nil), lines, _lineNum];
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    selectFontBtn.selected = NO;
    fontScrollView.hidden = YES;
    if ([text isEqualToString:@"\n"]) {
        NSString *text = textView.text;
        CGSize size = [text sizeWithAttributes:@{NSFontAttributeName:textView.font}];
        UIFont *font = textView.font;
        NSInteger lines = (NSInteger)(size.height / font.lineHeight);
        if (lines == _lineNum) {
            [hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"提示：最多能输入%d行", nil), _lineNum]];
            [hud show];
            [hud hideAfter:2];
            return NO;
        }
    }
    UITextRange *selectedRange = [textView markedTextRange];
    UITextPosition *pos = [textView positionFromPosition:selectedRange.start offset:0];
    
    //如果有高亮且当前字数开始位置小于最大限制时允许输入
    if (selectedRange && pos) {
#if 1
        return YES;
#else
        NSInteger startOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.start];
        NSInteger endOffset = [textView offsetFromPosition:textView.beginningOfDocument toPosition:selectedRange.end];
        NSRange offsetRange = NSMakeRange(startOffset, endOffset - startOffset);
        
        if (offsetRange.location < _maxNum) {
            return YES;
        }
        else
        {
            return NO;
        }
#endif
    }
    
    NSString *comcatstr = [textView.text stringByReplacingCharactersInRange:range withString:text];
#if 1
    if (comcatstr.length == 0) {
        placeHolderLabel.hidden = NO;
    }else{
        placeHolderLabel.hidden = YES;
    }
    return YES;
#else
    NSInteger caninputlen = _maxNum - comcatstr.length;
    if (caninputlen >= 0)
    {
        if (comcatstr.length == 0) {
            placeHolderLabel.hidden = NO;
        }else{
            placeHolderLabel.hidden = YES;
        }
        return YES;
    }
    else
    {
        [hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"提示：字数最多%d个", nil), _maxNum]];
        [hud show];
        [hud hideAfter:2];
        
        NSInteger len = text.length + caninputlen;
        NSRange rg = {0,MAX(len,0)};
        
        if (rg.length > 0)
        {
            NSString *s = @"";
            //判断是否只普通的字符或asc码(对于中文和表情返回NO)
            BOOL asc = [text canBeConvertedToEncoding:NSASCIIStringEncoding];
            if (asc) {
                s = [text substringWithRange:rg];
            }
            else
            {
                __block NSInteger idx = 0;
                __block NSString  *trimString = @"";//截取出的字串
                //使用字符串遍历，这个方法能准确知道每个emoji是占一个unicode还是两个
                [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                                         options:NSStringEnumerationByComposedCharacterSequences
                                      usingBlock: ^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
                                          
                                          if (idx >= rg.length) {
                                              *stop = YES;
                                              return ;
                                          }
                                          
                                          trimString = [trimString stringByAppendingString:substring];
                                          idx++;
                                      }];
                
                s = trimString;
            }
            //rang是指从当前光标处进行替换处理(注意如果执行此句后面返回的是YES会触发didchange事件)
            [textView setText:[textView.text stringByReplacingCharactersInRange:range withString:s]];
            tipLbl.text = [NSString stringWithFormat:RDLocalizedString(@"字数：%d/%d 最多：%d行", nil), textView.text.length, _maxNum, _lineNum];
            if (textView.text.length == 0) {
                placeHolderLabel.hidden = NO;
            }else{
                placeHolderLabel.hidden = YES;
            }
        }
        return NO;
    }
#endif
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0) {
        placeHolderLabel.hidden = NO;
    }else{
        placeHolderLabel.hidden = YES;
    }
    UITextRange *selectedRange = [textView markedTextRange];
    UITextPosition *pos = [textView positionFromPosition:selectedRange.start offset:0];
    
    if (selectedRange && pos) {
        return;
    }
    
#if 1
    [self refreshLineNum:textView.text];
#else
    NSString  *nsTextContent = textView.text;
    NSInteger existTextNum = nsTextContent.length;
    if (existTextNum > _maxNum)
    {
        [hud setCaption:[NSString stringWithFormat:RDLocalizedString(@"提示：字数最多%d个", nil), _maxNum]];
        [hud show];
        [hud hideAfter:2];
        
        NSString *s = [nsTextContent substringToIndex:_maxNum];
        [textView setText:s];
    }
    tipLbl.text = [NSString stringWithFormat:RDLocalizedString(@"字数：%d/%d 最多：%d行", nil), textView.text.length, _maxNum, _lineNum];
#endif
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    
    return YES;
}

#pragma mark - UINotification
- (void)keyboardWillShow:(NSNotification *)notification {
    NSValue *value = [[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGSize keyboardSize = [value CGRectValue].size;
    float keyboardHeight = keyboardSize.height;
    if (iPhone_X) {
        textView.frame = CGRectMake(10, 44, kWIDTH - 20, kHEIGHT - 44 - keyboardHeight - 88);
    }else {
        textView.frame = CGRectMake(10, 20, kWIDTH - 20, kHEIGHT - 20 - keyboardHeight - 88);
    }
    bottomView.frame = CGRectMake(0, textView.frame.origin.y + textView.frame.size.height, kWIDTH, 88);
    fontScrollView.frame = CGRectMake(0, bottomView.frame.origin.y - 100 + 44, kWIDTH, 100);
}

- (void)keyboardWillHide:(NSNotification *)notification {
    if (iPhone_X) {
        textView.frame = CGRectMake(10, 44, kWIDTH - 20, kHEIGHT - 44 - 34 - 88);
    }else {
        textView.frame = CGRectMake(10, 20, kWIDTH - 20, kHEIGHT - 20 - 88);
    }
    bottomView.frame = CGRectMake(0, textView.frame.origin.y + textView.frame.size.height, kWIDTH, 88);
    fontScrollView.frame = CGRectMake(0, bottomView.frame.origin.y - 100 + 44, kWIDTH, 100);
}

- (void)appEnterForegroundNotification:(NSNotification *)notification{
    [textView becomeFirstResponder];
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
