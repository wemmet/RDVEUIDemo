//
//  RDThumbImageView.m
//  RDVEUISDK
//
//  Created by emmet on 15/8/17.
//  Copyright (c) 2015年 emmet. All rights reserved.
//

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)


#import "RDThumbImageView.h"


//#import "RDThumbImageView+Shadow.h"

#define DRAG_THRESHOLD 10
#define kValidDirections [NSArray arrayWithObjects: @"top", @"bottom", @"left", @"right",nil]


float distanceBetweenPoints(CGPoint a, CGPoint b);
@interface RDThumbImageView (){
    UIImageView *_backImageView;
}
@property (strong, nonatomic)UIImageView    *fileTypeView;
@property (strong, nonatomic)UIView         *durationBackView;
@end
@implementation RDThumbImageView

@synthesize delegate;
@synthesize imageName;
@synthesize home;
@synthesize touchLocation;

- (instancetype)initWithSize:(CGSize )t_size{
    self = [super init];
    if(self){
        _isEdit = false;
        _backImageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, t_size.width - 10, t_size.height - 10)];
        _backImageView.backgroundColor = [UIColor clearColor];
        [self addSubview:_backImageView];
        _thumbIconView = [[UIImageView alloc] initWithFrame:CGRectMake(8 + (t_size.width-t_size.height)/2.0, 8, t_size.height - 16, t_size.height - 16)];
        _thumbIconView.backgroundColor = [UIColor clearColor];
        _thumbIconView.layer.cornerRadius = 1;
        _thumbIconView.layer.masksToBounds = YES;
        _coverView = [[UIImageView alloc] initWithFrame:_thumbIconView.bounds];
        
        _coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
        
        UIImage *idBackImage = [RDHelpClass imageWithContentOfFile:@"jianji/剪辑_序号默认_"];
        _thumbIdlabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, idBackImage.size.width, idBackImage.size.height)];
        _thumbIdlabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];//[UIColor colorWithPatternImage:idBackImage];
        _thumbIdlabel.textColor = [UIColor colorWithWhite:1 alpha:1.0];
        _thumbIdlabel.font = [UIFont systemFontOfSize:12];
        _thumbIdlabel.adjustsFontSizeToFitWidth = YES;
        _thumbIdlabel.textAlignment = NSTextAlignmentCenter;
        _thumbIdlabel.layer.cornerRadius = 3;
        _thumbIdlabel.layer.masksToBounds = YES;
            
        _customTextPhotoFile = nil;
        
        self.clipSliderTimeRange = kCMTimeRangeZero;
//        self.speed = 1;
//        self.speedIndex = 2;
//        self.speedTimeRange = kCMTimeRangeZero;
//        self.movePointsAndcurrentTimes = nil;
//        self.clipRectScale = 0;
//        self.clipPrivatValue = 0;
//        self.clipRect = CGRectZero;
        [self setUserInteractionEnabled:YES];
        
        [self setExclusiveTouch:YES];  // block other touches while dragging a thumb view
        
        _durationBackView = [[UIView alloc] initWithFrame:CGRectMake(0, _thumbIconView.frame.size.height - 20, _thumbIconView.frame.size.width, 20)];
        _durationBackView.backgroundColor = [UIColor clearColor];
        [self insertColorGradient];
        
        _thumbDurationlabel = [[UILabel alloc] initWithFrame:CGRectMake(12, (_durationBackView.frame.size.height - 10)/2.0, _durationBackView.frame.size.width - 19, 10)];
        _thumbDurationlabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
        _thumbDurationlabel.textColor = [UIColor colorWithWhite:1 alpha:1.0];
        _thumbDurationlabel.font = [UIFont systemFontOfSize:kWIDTH>320 ? 11 : 9];
        _thumbDurationlabel.textAlignment = NSTextAlignmentRight;
        _thumbDurationlabel.layer.cornerRadius = 1;
        _thumbDurationlabel.layer.masksToBounds = YES;;
        _thumbDurationlabel.shadowOffset = CGSizeMake(1, 1);
        _thumbDurationlabel.shadowColor = [UIColor blackColor];
        
        _fileTypeView = [[UIImageView alloc] initWithFrame:CGRectMake(4, (_durationBackView.frame.size.height - 8)/2.0, 11, 8)];
        _fileTypeView.backgroundColor = [UIColor clearColor];
        
        _thumbDeletedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_删除素材_"];
        image = [image imageWithTintColor];
        _thumbDeletedBtn.frame = CGRectMake(t_size.width - image.size.width, 0, image.size.width, image.size.height);
        dispatch_async(dispatch_get_main_queue(), ^{
            [_thumbDeletedBtn setImage:image forState:UIControlStateNormal];
        });
        _thumbDeletedBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        _thumbDeletedBtn.layer.cornerRadius = image.size.width/2.0;
        _thumbDeletedBtn.layer.masksToBounds = YES;;
        [_thumbDeletedBtn addTarget:self action:@selector(deletedThumbFile) forControlEvents:UIControlEventTouchUpInside];
        //[self addSubview:_thumbFileTypelabel];
        
//        [self addSubview:_thumbDeletedBtn];
        _thumbFileTypelabel.text = @"";
        _thumbDurationlabel.text = @"";
        
        _thumbFileTypelabel.alpha = 0;
        _thumbIconView.contentMode = UIViewContentModeScaleAspectFill;
        _backImageView.layer.masksToBounds = YES;
        _thumbIconView.layer.masksToBounds = YES;
        _backImageView.layer.cornerRadius = 3;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0.0;
        
         dispatch_async(dispatch_get_main_queue(), ^{
             [self addSubview:_thumbIconView];
             
             [_thumbIconView addSubview:_coverView];
             
             [self addSubview:_thumbIdlabel];
             
             [_durationBackView addSubview:_thumbDurationlabel];
             
             [_durationBackView addSubview:_fileTypeView];

             [_thumbIconView addSubview:_durationBackView];
             
             [self addSubview:_thumbDeletedBtn];
             
             
         });
    }
    
    return self;
}

-(void)setIsAlbum:(BOOL)isAlbum
{
    if( isAlbum )
    {
        UIImage * image = [RDHelpClass imageWithContentOfFile:@"album/相册_删除"];
        image = [image imageWithTintColor];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_thumbDeletedBtn setImage:image forState:UIControlStateNormal];
        });
        _thumbDurationlabel.font = [UIFont systemFontOfSize:kWIDTH>320 ? 9 : 7];
        
        _thumbIconView.layer.cornerRadius = 5.0;
        _thumbIconView.layer.masksToBounds = YES;
        
        _thumbIdlabel.hidden = YES;
        _fileTypeView.hidden = YES;
    }
    _isAlbum = isAlbum;
}

- (void)setCustomTextPhotoFile:(CustomTextPhotoFile *)customTextPhotoFile{
    _customTextPhotoFile = customTextPhotoFile;
    
    if([[_contentFile.contentURL.path lastPathComponent] rangeOfString:@"cachedContentTextPhotoImage"].location != NSNotFound && _contentFile.contentURL.path.length>0){
        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图文字_"];
    }
}

- (void) insertColorGradient {//渐变的背景
    
    UIColor *colorOne = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.0];
    UIColor *colorTwo = [UIColor colorWithRed:0.0/255.0 green:0.0/255.0 blue:0.0/255.0 alpha:0.6];
    
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor,nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
    headerLayer.colors = colors;
    headerLayer.frame = CGRectMake(0, 0, _durationBackView.frame.size.width, _durationBackView.frame.size.height);
    headerLayer.startPoint = CGPointMake(0, 0);
    headerLayer.endPoint = CGPointMake(0, 1);
    [_durationBackView.layer insertSublayer:headerLayer above:0];
    
}

- (void)longLongGestureWithEvent{
    if(delegate){
        if([delegate respondsToSelector:@selector(thumbImageViewWaslongLongTap:)]){
            [delegate thumbImageViewWaslongLongTap:self];
        }
    }
    
}

- (void)setThumbId:(NSInteger)thumbId{
    _thumbId = thumbId;
    _thumbIdlabel.text = [NSString stringWithFormat:@"%zd",(thumbId+1)];
    self.tag = 10000+_thumbId;
}

- (void)setContentFile:(RDFile *)contentFile{
    _contentFile = contentFile;
    if(_contentFile.fileType == kFILEVIDEO){
        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图视频_"];
    }else if(_contentFile.fileType == kFILEIMAGE){
        if (_contentFile.isGif) {
            _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图GIF_"];
        }else {
            _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图图片_"];
        }
    }else{
        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图文字_"];
    }
    //更新截取分割调速三者共同作用下的时间不对的bug
    if(_contentFile.isReverse){        //CMTimeGetSeconds(_contentFile.reverseDurationTime)>CMTimeGetSeconds(_contentFile.reverseVideoTrimTimeRange.duration) &&
        if(CMTimeGetSeconds(_contentFile.reverseVideoTrimTimeRange.duration) > 0){
            _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.reverseVideoTrimTimeRange.duration) / (float)_contentFile.speed)];
        }else{
            if(CMTimeGetSeconds(_contentFile.reverseDurationTime)>0){
                _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.reverseDurationTime) / (float)_contentFile.speed)];
                
            }else{
                _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.reverseVideoTimeRange.duration) / (float)_contentFile.speed)];
            }
        }
    }else{
        if(_contentFile.fileType == kFILEIMAGE || _contentFile.fileType == kTEXTTITLE){
            if (CMTimeCompare(_contentFile.imageTimeRange.duration, kCMTimeZero) == 1) {
                _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.imageTimeRange.duration) / (float)_contentFile.speed)];
            }else {
                _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.imageDurationTime) / (float)_contentFile.speed)];
            }
        }else{
            if(CMTimeGetSeconds(_contentFile.videoTrimTimeRange.duration) > 0){//CMTimeGetSeconds(_contentFile.videoDurationTime)>CMTimeGetSeconds(_contentFile.videoTrimTimeRange.duration) &&
                _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.videoTrimTimeRange.duration) / (float)_contentFile.speed)];
            }else{
                if(CMTimeGetSeconds(_contentFile.videoDurationTime)>0){
                    _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.videoDurationTime) / (float)_contentFile.speed)];

                }else{
                    _thumbDurationlabel.text = [self timeToStringFormat:ceilf(CMTimeGetSeconds(_contentFile.videoTimeRange.duration) / (float)_contentFile.speed)];
                }                
            }
        }
    }
    _thumbIconView.image = _contentFile.thumbImage;
}

-(NSString*)timeToStringFormat:(float) time
{
    if( _isEdit )
    {
        return [RDHelpClass timeToStringFormat:time];
    }
    else{
        return [RDHelpClass timeToStringFormat_MinSecond:time];
    }
}

//- (void)setType:(FileType)type{
//    _type = type;
//    if(type != kFileImage){
//        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图视频_"];
//        
//    }else{
//        if([[_contentURL.path lastPathComponent] rangeOfString:@"cachedContentTextPhotoImage"].location != NSNotFound && _contentURL.path.length>0){
//            _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图文字_"];
//        }else{
//            _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图图片_"];
//        }
//    }
//}

//- (void)setTotalVideoTime:(Float64)totalVideoTime{
////    NSLog(@"totalVideoTime:%f",totalVideoTime);
//    
//    _totalVideoTime = totalVideoTime;
//    if(totalVideoTime>CMTimeGetSeconds(_clipSliderTimeRange.duration) && CMTimeGetSeconds(_clipSliderTimeRange.duration) > 0){
//        _thumbDurationlabel.text = [RDHelpClass timeToStringFormat:CMTimeGetSeconds(_clipSliderTimeRange.duration) / (float)_speed];
//    }else{
//        _thumbDurationlabel.text = [RDHelpClass timeToStringFormat:totalVideoTime / (float)_speed];
//
//    }
//}


- (void)selectThumb:(BOOL)selected{

    if (selected) {
        
        _backImageView.layer.borderColor = ((UIColor*)Main_Color).CGColor;
        _thumbIdlabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _coverView.backgroundColor = [UIColor colorWithRed:227.0/255.0 green:138.0/255.0 blue:67.0/255.0 alpha:0.66];
//        _coverView.backgroundColor = [Main_Color colorWithAlphaComponent:0.66];
        _backImageView.layer.borderWidth = 0;
        //_thumbFileTypelabel.alpha = 1;
    }else{
        _backImageView.layer.borderColor = UIColorFromRGB(0x888888).CGColor;
        _thumbIdlabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
        _coverView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];

        _backImageView.layer.borderWidth = 0;
        self.deleted = NO;
        //_thumbFileTypelabel.alpha = 0;
    }
    
}

#if 1
- (void) createShadowViewWithRadius:(float)radius Color:(UIColor *)color bordWidth:(float)bordWidth
{
    if(shadowLayer.superlayer){
        [shadowLayer removeFromSuperlayer];
    }
    NSArray *directions = [NSArray arrayWithObjects:@"top", @"bottom", @"left" , @"right" , nil];
    
    shadowLayer = [[CALayer alloc] init];
    CGRect shadowRect = CGRectMake(bordWidth, bordWidth, _thumbIconView.frame.size.width - bordWidth * 2.0, _thumbIconView.bounds.size.height - bordWidth*2.0);
    shadowLayer.frame = shadowRect;
    
    
    shadowLayer.backgroundColor = [UIColor clearColor].CGColor;
    // Ignore duplicate direction
    NSMutableDictionary *directionDict = [[NSMutableDictionary alloc] init];
    for (NSString *direction in directions){
        [directionDict setObject:@"1" forKey:direction];
    }
    
    for (NSString *direction in directionDict) {
        // Ignore invalid direction
        if ([kValidDirections containsObject:direction])
        {
            CAGradientLayer *shadow = [CAGradientLayer layer];
            
            if ([direction isEqualToString:@"top"]) {
                [shadow setStartPoint:CGPointMake(0.5, 0.0)];
                [shadow setEndPoint:CGPointMake(0.5, 1.0)];
                shadow.frame = CGRectMake(0, 0, shadowRect.size.width, radius);
            }
            else if ([direction isEqualToString:@"bottom"])
            {
                [shadow setStartPoint:CGPointMake(0.5, 1.0)];
                [shadow setEndPoint:CGPointMake(0.5, 0.0)];
                shadow.frame = CGRectMake(0, shadowRect.size.height - radius, shadowRect.size.width, radius);
            } else if ([direction isEqualToString:@"left"])
            {
                shadow.frame = CGRectMake(0, 0, radius, shadowRect.size.height);
                [shadow setStartPoint:CGPointMake(0.0, 0.5)];
                [shadow setEndPoint:CGPointMake(1.0, 0.5)];
            } else if ([direction isEqualToString:@"right"])
            {
                shadow.frame = CGRectMake(shadowRect.size.width - radius, 0, radius, shadowRect.size.height);
                [shadow setStartPoint:CGPointMake(1.0, 0.5)];
                [shadow setEndPoint:CGPointMake(0.0, 0.5)];
            }
            
            shadow.colors = [NSArray arrayWithObjects:(id)[color CGColor], (id)[[UIColor clearColor] CGColor], nil];
            [shadowLayer insertSublayer:shadow atIndex:0];
        }
    }
}
#else

#endif

- (void)deletedThumbFile{
    if(delegate){
        if([delegate respondsToSelector:@selector(thumbDeletedThumbFile:)]){
            [delegate thumbDeletedThumbFile:self];
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // store the location of the starting touch so we can decide when we've moved far enough to drag
    touchLocation = [[touches anyObject] locationInView:self];
    self.canMovePostion = NO;
    touchBeginTime = CFAbsoluteTimeGetCurrent();
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(CFAbsoluteTimeGetCurrent()-touchBeginTime<0.6){
        return;
    }
    CGPoint newTouchLocation = [[touches anyObject] locationInView:self];
    if(!self.canMovePostion){
        [self longLongGestureWithEvent];
        self.canMovePostion = YES;
        return;
    }
    if (dragging)
    {
        float deltaX = newTouchLocation.x - touchLocation.x;
        float deltaY = newTouchLocation.y - touchLocation.y;
        [self moveByOffset:CGPointMake(deltaX, deltaY)withEvent:event];
    }
    else if (distanceBetweenPoints(touchLocation, newTouchLocation) > DRAG_THRESHOLD)
    {
        touchLocation = newTouchLocation;
        dragging = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    if (dragging)
    {
        [self goHome];
        dragging = NO;
    }
    else if ([[touches anyObject] tapCount] == 1)
    {
        if(delegate){
            if ([delegate respondsToSelector:@selector(thumbImageViewWasTapped:touchUpTiv:)])
            {
                [delegate thumbImageViewWasTapped:self touchUpTiv:YES];
            }
        }
    }
    if(self.canMovePostion){
        if ([delegate respondsToSelector:@selector(thumbImageViewWaslongLongTapEnd:)])
        {
            [delegate thumbImageViewWaslongLongTapEnd:self];
        }
    }
    if(delegate){
        if ([delegate respondsToSelector:@selector(thumbImageViewStoppedTracking:withEvent:)])
        {
            [delegate thumbImageViewStoppedTracking:self withEvent:event];
        }
    }
    self.canMovePostion = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self goHome];
    dragging = NO;
    if(delegate){
        if ([delegate respondsToSelector:@selector(thumbImageViewStoppedTracking:withEvent:)])
        {
            [delegate thumbImageViewStoppedTracking:self withEvent:event];
        }
    }
}

- (void)goHome
{
    // distance is in pixels
    float distanceFromHome = distanceBetweenPoints([self frame].origin, [self home].origin);
    // duration is in seconds, so each additional pixel adds only 1/1000th of a second.
    float animationDuration = 0.1 + distanceFromHome * 0.001;
    NSLog(@"[self home].x:%lf",[self home].origin.x);
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    [self setFrame:[self home]];
    [UIView commitAnimations];
}

- (void)moveByOffset:(CGPoint)offset withEvent:(UIEvent *)event
{
    CGRect frame = [self frame];
    frame.origin.x += offset.x;
    frame.origin.y += offset.y;
    [self setFrame:frame];
    NSLog(@"deltaX:%f,deltaX：%f",frame.origin.x,frame.origin.y);
    if(delegate){
        if ([delegate respondsToSelector:@selector(thumbImageViewMoved:withEvent:)])
        {
            [delegate thumbImageViewMoved:self  withEvent:event];
        }
    }
}
- (void)dealloc{
    NSLog(@"%s",__func__);
    _thumbIconView.image = nil;
}

- (void)AddtThumbIconViewSide
{
    _thumbIconView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    _coverView.frame = _thumbIconView.frame;
    _backImageView.frame =  _thumbIconView.frame;
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 0.2;
    self.layer.borderColor = UIColorFromRGB(0xffffff).CGColor;
    _durationBackView.hidden = YES;
    _fileTypeView.frame = CGRectMake(5, _thumbIconView.frame.size.height - 5 - _fileTypeView.frame.size.height, _fileTypeView.frame.size.width, _fileTypeView.frame.size.height);
    [_thumbIconView addSubview:_fileTypeView];
    _thumbIdlabel.frame = CGRectMake(5, 5 , _thumbIdlabel.frame.size.width, _thumbIdlabel.frame.size.height);
}
@end

float distanceBetweenPoints(CGPoint a, CGPoint b)
{
    float deltaX = a.x - b.x;
    float deltaY = a.y - b.y;
    NSLog(@"%lf",sqrtf( (deltaX * deltaX) + (deltaY * deltaY) ));
    return sqrtf( (deltaX * deltaX) + (deltaY * deltaY) );
}

