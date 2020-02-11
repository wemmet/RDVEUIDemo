//
//  RDConnectBtn.m
//  RDVEUISDK
//
//  Created by emmet on 2017/6/28.
//  Copyright © 2017年 com.rd. All rights reserved.
//

#import "RDConnectBtn.h"
#import "RDAutoScrollLabel.h"

@interface RDConnectBtn(){
    UIImageView *iconView;
    UIImageView *transitionImageView;
    RDAutoScrollLabel     *transitionTitleLabel;
}
@end

@implementation RDConnectBtn

- (instancetype)initWithFrame:(CGRect)frame{

    if(self = [super initWithFrame:frame]){
        iconView = [UIImageView new];
        iconView.frame = CGRectMake(0, 0,  frame.size.width, frame.size.height);
        iconView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_加号默认_"];
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        transitionImageView = [UIImageView new];
        transitionImageView.frame = CGRectMake((frame.size.width - 34)/2.0, (frame.size.height - 14)/2.0, 34, 14);
        
        transitionTitleLabel = [RDAutoScrollLabel new];
        transitionTitleLabel.frame = CGRectMake(0, 0, transitionImageView.frame.size.width, transitionImageView.frame.size.height);
        transitionTitleLabel.textColor = [UIColor blackColor];
        transitionTitleLabel.font = [UIFont systemFontOfSize:9];
        transitionTitleLabel.textAlignment = NSTextAlignmentCenter;
        
        
        
        [transitionImageView addSubview:transitionTitleLabel];
       // [self addSubview:iconView];
        [self addSubview:transitionImageView];
    }
    return self;
}

- (void)setFileIndex:(NSInteger)fileIndex {
    _fileIndex = fileIndex;
    self.tag = 20000+fileIndex;
}

- (void)setSelected:(BOOL)selected{
    if(selected){
       // iconView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_加号选中_"];
        transitionImageView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_加号选中转场提示1k_"];
    }else{
       // iconView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_加号默认_"];
        transitionImageView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_加号默认转场提示1k_"];
    }
}

- (void)setTransitionTypeName:(NSString *)transitionTypeName {
    dispatch_async(dispatch_get_main_queue(), ^{
        iconView.frame = CGRectMake((self.frame.size.width - (self.frame.size.height - 14))/2.0, 0,  self.frame.size.height - 14,self.frame.size.height - 14);
        
        _transitionTypeName = transitionTypeName;
        transitionImageView.image = [RDHelpClass imageWithContentOfFile:@"/jianji/剪辑_加号默认转场提示1k_"];
    });
}

- (void)setTransitionTitle:(NSString *)transitionTitle{
    dispatch_async(dispatch_get_main_queue(), ^{
        _transitionTitle = transitionTitle;
        transitionTitleLabel.text = _transitionTitle;
    });
}

@end
