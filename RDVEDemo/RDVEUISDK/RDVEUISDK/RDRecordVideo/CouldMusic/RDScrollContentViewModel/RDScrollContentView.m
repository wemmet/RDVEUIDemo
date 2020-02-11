//
//  RDScrollContentView.m

#import "RDScrollContentView.h"
#import "RDCloudMusicItemViewController.h"
static NSString *kContentCellID = @"kContentCellID";

@interface RDScrollContentView()<UICollectionViewDelegate,UICollectionViewDataSource>

{
    NSMutableArray *_childVcs;
    
    UICollectionView *_collectionView;
    
    UICollectionViewFlowLayout *_flowLayout;
    
    BOOL _isForbidScrollDelegate;

}

@end

@implementation RDScrollContentView

- (void)awakeFromNib{
    [super awakeFromNib];
    _childVcs = [[NSMutableArray alloc] init];
    [self setupUI];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        _childVcs = [[NSMutableArray alloc] init];
        [self setupUI];
    }
    return self;
}

- (void)setupUI{
    
    _flowLayout = [[UICollectionViewFlowLayout alloc] init];
    _flowLayout.itemSize = CGSizeZero;
    _flowLayout.minimumLineSpacing = 0;
    _flowLayout.minimumInteritemSpacing = 0;
    _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_flowLayout];
    _collectionView.scrollsToTop = NO;
    _collectionView.backgroundColor = SCREEN_BACKGROUND_COLOR;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.pagingEnabled = YES;
    _collectionView.bounces = NO;
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kContentCellID];
    [self addSubview:_collectionView];
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGRect collectionviewRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    _collectionView.frame = collectionviewRect;
    _flowLayout.itemSize = collectionviewRect.size;
}

- (void)reloadViewWithChildVcs:(NSArray *)childVcs parentVC:(UIViewController *)parentVC{
    for (UIViewController *childVc in _childVcs) {
        [childVc removeFromParentViewController];
    }
    [_childVcs removeAllObjects];
    [_childVcs addObjectsFromArray:childVcs];
    for (UIViewController *childVc in childVcs) {
        [parentVC addChildViewController:childVc];
    }
    [_collectionView reloadData];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    return _childVcs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kContentCellID forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    UIViewController *childVc = _childVcs[indexPath.row];
    CGRect collectionviewRect = CGRectMake(0, 0, cell.contentView.bounds.size.width, cell.contentView.bounds.size.height);
    childVc.view.frame = collectionviewRect;
    [cell.contentView addSubview:childVc.view];
    return cell;
}

- (void)setCurrentIndex:(NSInteger)currentIndex{
    _isForbidScrollDelegate = YES;
    [_childVcs enumerateObjectsUsingBlock:^(RDCloudMusicItemViewController * obj, NSUInteger idx, BOOL * _Nonnull stop) {

        if(obj.isPlaying){
            [obj stopPlayAudio];
        }
    }];
    [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0] atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    _isForbidScrollDelegate = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if (_isForbidScrollDelegate) {
        return;
    }
    [_childVcs enumerateObjectsUsingBlock:^(RDCloudMusicItemViewController * obj, NSUInteger idx, BOOL * _Nonnull stop) {
      
        if(obj.isPlaying){
            [obj stopPlayAudio];
        }
    }];
    NSInteger endIndex = (_collectionView.contentOffset.x + _collectionView.frame.size.width / 2 )/ _collectionView.frame.size.width;
    if (_scrollBlock) {
        _scrollBlock(endIndex);
    }
}

@end
