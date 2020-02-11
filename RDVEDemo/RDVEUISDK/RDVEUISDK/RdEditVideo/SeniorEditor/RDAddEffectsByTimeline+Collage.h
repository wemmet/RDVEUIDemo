//
//  RDAddEffectsByTimeline+Collage.h
//  RDVEUISDK
//
//  Created by apple on 2019/5/10.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDAddEffectsByTimeline.h"

NS_ASSUME_NONNULL_BEGIN

@interface RDAddEffectsByTimeline (Collage)<UICollectionViewDelegate, UICollectionViewDataSource,UIScrollViewDelegate, UIAlertViewDelegate>


- (void)initAlbumTitleToolbarWithFrame:(CGRect)frame;
- (void)initAlbumViewWithFrame:(CGRect)frame;
- (void)refreshAblumScrollViewViewFrame;

- (void)addCollage:(NSURL *)url thumbImage:(UIImage *)thumbImage;

//完成画中画
- (void)addCollageFinishAction:(UIButton *)sender;

- (void)editCollage;

- (void)savePasterView:(BOOL)isScroll;
- (void)showAlbumView;

- (void)startAddCollage:(CMTimeRange)timeRange
                    collages:(NSMutableArray *)collages;

-(void)editCollage_Features;


-(void)rangeView_initPasterView:( CaptionRangeView * ) rangeView;

-(UIImage *)RangeView_Image:( CaptionRangeView * ) rangeView atCrop:(CGRect) rect;
@end

NS_ASSUME_NONNULL_END
