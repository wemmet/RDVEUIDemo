//
//  SelectionCollectionViewCell.m
//  RDVEUISDK
//
//  Created by emmet on 16/6/29.
//  Copyright © 2016年 com.rd.emmet. All rights reserved.
//

#import "RD_SelectionCollectionViewCell.h"
#import "RDHelpClass.h"

typedef void(^RD_DeleteBtnAction) (RDFile * file);

@interface RD_SelectionCollectionViewCell()
{
    RD_DeleteBtnAction deleteBtnAction;
}

@end
@implementation RD_SelectionCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];//[RDHelpClass colorWithHexString:@"33333b"];
        
        
        _thumbIconView = [[UIImageView alloc] initWithFrame:CGRectMake(6, 6, frame.size.width - 12, frame.size.height - 12)];
        _thumbIconView.backgroundColor = [UIColor clearColor];
        _thumbIconView.layer.cornerRadius = 3;
        _thumbIconView.layer.masksToBounds = YES;;
        [self addSubview:_thumbIconView];
        
        _coverView = [[UIImageView alloc] initWithFrame:_thumbIconView.bounds];
        _coverView.backgroundColor = [UIColor colorWithRed:227.0/255.0 green:138.0/255.0 blue:67.0/255.0 alpha:0.66];
        _coverView.layer.cornerRadius = 3;
        _coverView.layer.masksToBounds = YES;;
        
        [_thumbIconView addSubview:_coverView];

        UIImage *idBackImage = [RDHelpClass imageWithContentOfFile:@"jianji/剪辑_序号默认_"];
        _thumbIdlabel = [[UILabel alloc] initWithFrame:CGRectMake(7, 7, idBackImage.size.width, idBackImage.size.height)];
        _thumbIdlabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];//[UIColor colorWithPatternImage:idBackImage];
        _thumbIdlabel.textColor = [UIColor colorWithWhite:1 alpha:1.0];
        _thumbIdlabel.font = [UIFont systemFontOfSize:12];
        _thumbIdlabel.textAlignment = NSTextAlignmentCenter;
        _thumbIdlabel.layer.cornerRadius = 2;
        _thumbIdlabel.layer.masksToBounds = YES;
        
        [self addSubview:_thumbIdlabel];
        
        [self setUserInteractionEnabled:YES];
        
        [self setExclusiveTouch:YES];
        
        _durationBackView = [[UIView alloc] initWithFrame:CGRectMake(6, _thumbIconView.frame.origin.y + _thumbIconView.frame.size.height - 20, _thumbIconView.frame.size.width, 20)];
        _durationBackView.backgroundColor = [UIColor clearColor];
        [self insertColorGradient];
        
        _thumbDurationlabel = [[UILabel alloc] initWithFrame:CGRectMake(12, (_durationBackView.frame.size.height - 10)/2.0, _durationBackView.frame.size.width - 12, 10)];
        _thumbDurationlabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.0];
        _thumbDurationlabel.textColor = [UIColor colorWithWhite:1 alpha:1.0];
        if([UIScreen mainScreen].bounds.size.width < [UIScreen mainScreen].bounds.size.height){
            _thumbDurationlabel.font = [UIFont systemFontOfSize:9];
        }else{
            _thumbDurationlabel.font = [UIFont systemFontOfSize:9];
            _thumbDurationlabel.adjustsFontSizeToFitWidth = YES;
        }
        _thumbDurationlabel.textAlignment = NSTextAlignmentRight;
        _thumbDurationlabel.layer.cornerRadius = 1;
        _thumbDurationlabel.layer.masksToBounds = YES;;
        _thumbDurationlabel.shadowOffset = CGSizeMake(1, 1);
        _thumbDurationlabel.shadowColor = [UIColor blackColor];
        
        
        _fileTypeView = [[UIImageView alloc] initWithFrame:CGRectMake(4, (_durationBackView.frame.size.height - 8)/2.0, 11, 8)];
        _fileTypeView.backgroundColor = [UIColor clearColor];
        
        [_durationBackView addSubview:_thumbDurationlabel];
        [_durationBackView addSubview:_fileTypeView];

        [self addSubview:_durationBackView];
        
        _thumbDurationlabel.alpha = 1.0;
        _thumbIconView.contentMode = UIViewContentModeScaleAspectFill;
        _thumbIconView.layer.masksToBounds = YES;
        self.layer.borderColor = [UIColor clearColor].CGColor;
        self.layer.borderWidth = 0.0;
        
        _state = Normal;
       
        _thumbDeletedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_删除素材_"];
        image = [image imageWithTintColor];
        _thumbDeletedBtn.frame = CGRectMake(frame.size.width - image.size.width, 0, image.size.width, image.size.height);
        [_thumbDeletedBtn setImage:image forState:UIControlStateNormal];
        _thumbDeletedBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.0];
        _thumbDeletedBtn.layer.cornerRadius = image.size.width/2.0;
        _thumbDeletedBtn.layer.masksToBounds = YES;;
        [_thumbDeletedBtn addTarget:self action:@selector(deletedThumbFile) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_thumbDeletedBtn];
        [_thumbDeletedBtn setHidden:true];
    }
    return self;
}

#pragma mark- 设置删除按钮
-(void)setDeleteBtn:(bool)isShow deleteAction:(void(^) (RDFile * file)) DeleteBtnAction
{
    [_thumbDeletedBtn setHidden:!isShow];
    deleteBtnAction = DeleteBtnAction;
}

#pragma mark- 删除选中文件
- (void)deletedThumbFile{
    if( deleteBtnAction )
        deleteBtnAction( _thumbfile );
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

- (void)setThumbfile:(RDFile *)thumbfile{
    RDFileType type= thumbfile.fileType;
    _thumbfile = thumbfile;
    if(type != kFILEIMAGE){
        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图视频_"];
    }else if(type == kTEXTTITLE){
        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图文字_"];
    }else if (thumbfile.isGif) {
        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图GIF_"];
    }else {
        _fileTypeView.image = [RDHelpClass imageWithContentOfFile:@"jianji/fenge/剪辑_缩略图图片_"];
    }
}

- (void)setCanAddTouch:(BOOL)canAddTouch{
    _canAddTouch = canAddTouch;
    if(_canAddTouch){
        _coverView.alpha = 0.00;
    }
}

- (UIImage *)resizeImage {
    UIImage * image = [RDHelpClass imageWithContentOfFile:@"delete"];
    return image;
}

- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
