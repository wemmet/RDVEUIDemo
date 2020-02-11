
#import <UIKit/UIKit.h>
@protocol RDPosterEditViewDelegate;
@interface RDPosterEditView : UIView<UIScrollViewDelegate,UIGestureRecognizerDelegate>{
    UITapGestureRecognizer *currentTapGesture;
    float   zoomScale;
    BOOL    canHandPan;
    double  beginHandPanTime;
    CGPoint diffHandPanPoint;
    CGRect  maskRect;
}
@property (nonatomic, strong) UIScrollView  *contentView;
@property (nonatomic, strong) UIBezierPath *realCellArea;
@property (nonatomic, strong) UIImageView   *imageview;
@property (nonatomic, strong) NSMutableArray *realAreas;
//@property (nonatomic, assign) BOOL          reset;
@property (nonatomic, assign) id<RDPosterEditViewDelegate> tapDelegate;
- (void)setImageViewData:(UIImage *)imageData reset:(BOOL)reset;
- (void)zoomOut;
- (void)zoomIn;
@end


@protocol RDPosterEditViewDelegate <NSObject>
@optional
- (void)tapWithEditView:(RDPosterEditView *)sender;

- (void)handpanEditView:(RDPosterEditView *)sender endpointInSuperviewLocation:(CGPoint)point;

- (CGRect)getvideoCrop;
@end
