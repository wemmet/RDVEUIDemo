//
//  RDFilterChooserViewCell.m
//  RDVEUISDK
//
//  Created by 周晓林 on 16/4/8.
//
//


#import "RDFilterChooserViewCell.h"
#import "RDHelpClass.h"
//#import <RDGPUImage.h>
#import "UIImageView+RDWebCache.h"
@interface RDFilterChooserViewCell () {
    UIImageView *view1;
    RDFilter * group;
//    RDGPUImagePicture *stillImageSource;
}

@end

@implementation RDFilterChooserViewCell



- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        
        view1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 56, 56)];
        view1.center = CGPointMake(40, 30);
        view1.layer.masksToBounds = YES;
        view1.layer.cornerRadius = 28;
       
        
        _circleView = [[CircleView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        _circleView.center = CGPointMake(40, 30);
        _circleView.backgroundColor = [UIColor clearColor];
        _circleView.progressBackgroundColor = [UIColor clearColor];
        _circleView.progressColor = Main_Color;
        [self addSubview:_circleView];

        
        [self addSubview:view1];
        [self addSubview:self.titleLabel];
    }
    return self;
}
- (void) setImage:(NSString*)item name:(NSString *)name
{
    
    UIImage* inputImage;
    if ([item hasPrefix:@"http"]) {
        
        NSString* imgPath = [RDHelpClass getFaceUFilePathString:name type:@"png"];
        inputImage = [UIImage imageWithContentsOfFile:imgPath];

        
        if (!inputImage) {
            NSURL* url = [NSURL URLWithString:item];
            NSURLRequest* request = [NSURLRequest requestWithURL:url];
            NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
            NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                NSString* imgPath = [RDHelpClass getFaceUFilePathString:name type:@"png"];
                NSData* data = UIImagePNGRepresentation([UIImage imageWithData:[NSData dataWithContentsOfURL:location]]);
                
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [view1 setImage:[UIImage imageWithData:data]];

                });

                NSFileManager* fileManager = [NSFileManager defaultManager];
                if (![fileManager fileExistsAtPath:imgPath]) {
                    [data writeToFile:imgPath atomically:YES];
                }
                
                
            }];
            [task resume];
        }else{
            [view1 setImage:inputImage];

        }
        
       
    }else{
        inputImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"VideoRecord.bundle/faceunity/%@.png",item]]];
        if (inputImage) {
            [view1 setImage:inputImage];
        }else{
            view1.backgroundColor = [UIColor grayColor];
        }
    }
    
    //view1.layer.borderColor = [UIColor colorWithRed:40.0/255.0 green:202.0/255.0 blue:217.0/255.0 alpha:1.0].CGColor;

    
}
- (void)setFilter:(RDFilter *)filter {
    if(filter.netCover.length>0){
        [view1 rd_sd_setImageWithURL:[NSURL URLWithString:filter.netCover]];
    }else{
        NSString *path = [RDHelpClass pathInCacheDirectory:@"filterImage"];
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
            [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *photoPath = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"image%@.jpg",filter.name]];
        UIImage* image;
        if([[NSFileManager defaultManager] fileExistsAtPath:photoPath]){
            image = [UIImage imageWithContentsOfFile:photoPath];
        }else{
            NSString* bundlePath = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:@"VideoRecord.bundle/Contents/Resources/原图.png"];
            image = [UIImage imageWithContentsOfFile:bundlePath];
        }
        [view1 setImage:image];
    }
    _titleLabel.text = RDLocalizedString(filter.name, nil);

    
    //group = filter;
    view1.layer.borderColor = [UIColor colorWithRed:40.0/255.0 green:202.0/255.0 blue:217.0/255.0 alpha:1.0].CGColor;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 62, view1.bounds.size.width, 20)];
        titleLabel.textAlignment = NSTextAlignmentCenter;
        titleLabel.textColor = [UIColor grayColor];
        titleLabel.font = [UIFont systemFontOfSize:12];
        titleLabel.adjustsFontSizeToFitWidth = YES;
        _titleLabel = titleLabel;
    }
    return _titleLabel;
}

- (UIImageView *)backgroudView{
    if (!_backgroudView) {
        UIImageView* imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        imageView.center = CGPointMake(40, 30);
        
        _backgroudView = imageView;
    }
    return _backgroudView;
}
- (RDFilter *)getFilter {
    
    return group;
    
}

- (void)setState:(UIControlState)state value:(float )value
{
    
    switch (state) {
        case UIControlStateNormal: {
            [_titleLabel setTextColor:[UIColor whiteColor]];
            [_circleView setPercent:value];
        }
            break;
        case UIControlStateSelected:{
            [_titleLabel setTextColor:Main_Color];
            [_circleView setPercent:value];
        }
            break;
        default:
            break;
    }
    
}

@end
