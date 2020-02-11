//
//  CustomSizeLayout.m
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCustomSizeLayout.h"


@interface RDCustomRect()

@end

@implementation RDCustomRect

+(RDCustomRect *) InitRDCustomRect:(CGRect) rect
{
    RDCustomRect * customRect = [[RDCustomRect alloc] init];
    customRect.rect = rect;
    return  customRect;
}

@end

@interface RDCustomSizeLayout ()
/** attrs的数组 */
@property(nonatomic,strong)NSMutableArray * attrsArr;
@end
@implementation RDCustomSizeLayout

- (id)init
{
    if (self = [super init]) {
        self.scrollDirection = UICollectionViewScrollDirectionVertical;
        self.minimumInteritemSpacing = 3;
        self.minimumLineSpacing = 3;
    }
    
    return self;
}

-(NSMutableArray *)attrsArr
{
    if(!_attrsArr){
        _attrsArr=[[NSMutableArray alloc] init];
    }
    return _attrsArr;
}

-(void)prepareLayout
{
    [super prepareLayout];
    [self.attrsArr removeAllObjects];
    NSInteger count =[self.collectionView   numberOfItemsInSection:0];
    for (int i=0; i<count; i++) {
        NSIndexPath *  indexPath =[NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes * attrs=[self layoutAttributesForItemAtIndexPath:indexPath];
        [self.attrsArr addObject:attrs];
    }
}

-(NSArray<UICollectionViewLayoutAttributes *> *)layoutAttributesForElementsInRect:(CGRect)rect
{
    return self.attrsArr;
}

#pragma mark ---- 返回CollectionView的内容大小
-(CGSize)collectionViewContentSize
{
    return CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height);
}

-(UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewLayoutAttributes * attrs = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
    NSInteger i = indexPath.item;
    
    
    CGFloat width = self.collectionView.frame.size.width;
    CGFloat height = self.collectionView.frame.size.height;
    
//    float spaceX = 0;    //边框幅度为3.0
//    float spaceY = 0;
//    NSArray<RDCustomRect *> * frame1 = nil;
//    NSArray<RDCustomRect *> * frame2 = nil;
//    NSArray<RDCustomRect *> * frame3 = nil;
//    NSArray<RDCustomRect *> * frame4 = nil;
//    NSArray<RDCustomRect *> * frame5 = nil;
//    NSArray<RDCustomRect *> * frame6 = nil;
//    NSArray<RDCustomRect *> * frame7 = nil;
//    NSArray<RDCustomRect *> * frame8 = nil;
//    NSArray<RDCustomRect *> * frame9 = nil;
//
//    switch (_templateIndex) {
//        case 1:
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0)],
//                      nil];
//            break;
//        case 2:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 0.5 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0 - spaceX, 0.5)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0 - spaceY)],
//
////                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 2.0/3.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0)],
////                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0 - spaceY)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect:CGRectMake(0.5 + spaceX, 0.0, 0.5 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0 + spaceX, 0.5, 1.0 - spaceX, 0.5)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0.0 + spaceY, 0.5, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5, 0.5 + spaceY, 0.5, 0.5 - spaceY)],
//
////                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 1.0/3.0, 1.0, 2.0/3.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 1.0)],
//
////                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.5 + spaceY, 1.0, 0.5 - spaceY)],
//                      nil];
//        }
//            break;
//
//        case 3:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect:CGRectMake(0, 0, 0.5 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 0.5, 1.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0, 2.0/3.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0/3.0 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0/3.0 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0 - spaceX, 1.0/3.0)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect:CGRectMake(0.5 + spaceX, 0, 0.5 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5, 0.0 + spaceY, 0.5 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 1.0/2.0 + spaceY, 2.0/3.0, 1.0/2.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0 + spaceX, 0.0, 1.0/3.0 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0 + spaceX, 0.0, 1.0/3.0 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0 + spaceX, 1.0/3.0, 1.0 - spaceX, 1.0/3.0)],
//                      nil];
//            frame3 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect:CGRectMake(0, 0.5 + spaceY, 1, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5 + spaceX, 0.5 + spaceY, 0.5 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0, 1.0/3.0 + spaceY, 1.0/2.0, 2.0/3.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0 + spaceX, 0.0, 1.0/3.0 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0 + spaceX, 0.0, 1.0/3.0 - spaceX, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0 + spaceX, 2.0/3.0, 1.0 - spaceX, 1.0/3.0)],
//                      nil];
//        }
//            break;
//        case 4:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0/3.0 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0.0, 0.5, 1.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 2.0/3.0 - spaceX, 0.5)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.0, 0.5, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.0, 0.25, 1.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.0, 1.0, 0.25 - spaceY)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0 + spaceX, 0, 1.0/3.0 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5, 0.0 + spaceY, 0.5 - spaceX, 1.0/3.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0 + spaceX, 0.0, 1.0/3.0 - spaceX, 0.5)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5, 0.0 + spaceY, 0.5, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.25, 0.0 + spaceY, 0.25, 1.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.25 + spaceY, 1.0, 0.25 - spaceY)],
//                      nil];
//            frame3 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0, 0.0 + spaceY, 1.0/3.0 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5 + spaceX, 1.0/3.0 + spaceY, 0.5 - spaceX, 1.0/3.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0 + spaceX, 0.5, 1.0/3.0 - spaceX, 0.5)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.5 + spaceY, 0.5, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5, 0.0 + spaceY, 0.25, 1.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.5 + spaceY, 1.0, 0.25 - spaceY)],
//                      nil];
//            frame4 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0 + spaceX, 0.5 + spaceY, 1.0 - spaceX, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5 + spaceX, 2.0/3.0 + spaceY, 0.5 - spaceX, 1.0/3.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0 + spaceX, 0.5, 2.0/3.0 - spaceX, 0.5)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.5, 0.5 + spaceY, 0.5, 0.5 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.75, 0.0 + spaceY, 0.25, 1.0 - spaceY)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0, 0.75 + spaceY, 1.0, 0.25 - spaceY)],
//                      nil];
//        }
//
//            break;
//
//        case 5:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1/3.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1/2.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1*2.0/3.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1/4.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1/5.0, 1)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1, 1/5.0)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1/3.0, 0, 1/3.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1/2.0, 0, 1/2.0, 1/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1*2.0/3.0, 0, 1/3.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1/4.0, 0, 1/2.0, 1)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1/5.0, 0, 1/5.0, 1)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1/5.0, 1, 1/5.0)],
//                      nil];
//            frame3 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1/3.0*2, 0, 1/3.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1/2.0, 1/3.0, 1/2.0, 1/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1/2.0, 1/3.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1*3.0/4.0, 0, 1/4.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1*2.0/5.0, 0, 1/5.0, 1)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1*2.0/5.0, 1, 1/5.0)],
//                      nil];
//            frame4 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1/2.0, 1/2.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1/2.0, 1/2.0, 1/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1/3.0, 1.0/2.0, 1/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1.0/2.0, 1.0/4.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*3.0/5.0, 0, 1.0/5.0, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1.0*3.0/5.0, 1.0, 1.0/5.0)],
//                      nil];
//            frame5 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0, 1.0/2.0, 1.0/2.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0, 1.0*2.0/3.0, 1.0/2.0, 1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0, 1.0/2.0, 1.0/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*3.0/4.0, 1.0/2.0, 1.0/4.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*4.0/5.0, 0, 1.0/5.0, 1.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1.0*4.0/5.0, 1.0, 1.0/5.0)],
//                      nil];
//        }
//            break;
//        case 6:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 0, 1.0/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,0,1.0*2.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,0,2.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,0,1.0/3.0,1.0)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0, 0, 1.0/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,1.0/2.0,1.0*2.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,0,1.0/3.0,1.0/4.0)],
//                      nil];
//            frame3 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0, 0, 1.0/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,1.0/3.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/4.0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0,0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,1.0/4.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0/4.0,1.0/3.0,1.0/4.0)],
//                      nil];
//            frame4 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0, 1.0/2.0, 1.0/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0/3.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*3.0/4.0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0,1.0/4.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,1.0/2.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0*2.0/4.0,1.0/3.0,1.0/4.0)],
//                      nil];
//            frame5 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0, 1.0/2.0, 1.0/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,1.0*2.0/3.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,1.0/3.0,1.0/2.0,1.0*2.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0,1.0*2.0/4.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,1.0*3.0/4.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0*3.0/4.0,1.0/3.0,1.0/4.0)],
//                      nil];
//            frame6 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0, 1.0/2.0, 1.0/3.0, 1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0*2.0/3.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0/3.0,1.0/2.0,1.0*2.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0,1.0*3.0/4.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0/2.0,1.0*2.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0,0,1.0/3.0,1.0)],
//                      nil];
//        }
//            break;
//    case 7:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,0,1.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,2.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/2.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0,1.0/2.0,1.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,0.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/3.0,2.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,0.0,1.0/2.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame3 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,2.0/3.0,2.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0/2.0,1.0/2.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,2.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame4 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0,1.0/4.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,0.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/2.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0.0,1.0/2.0,1.0)],
//                      nil];
//            frame5 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0*2.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,1.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/3.0,1.0/3.0,2.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,1.0/4.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,1.0/2.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame6 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0,0,1.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0*2.0/3.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0/3.0,1.0/3.0,2.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,1.0/2.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame7 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0*2.0/3.0,1.0/2.0,1.0/3.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0*2.0/3.0,1.0/2.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,1.0/3.0,1.0/3.0,2.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,3.0/4.0,1.0/3.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,2.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//        }
//            break;
//        case 8:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,3.0/4.0,3.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/4.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame3 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/4.0,0.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,2.0/4.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,0.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,2.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame4 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,3.0/4.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,2.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0/4.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0.0,1.0/2.0,1.0/2.0)],
//                      nil];
//            frame5 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/2.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,0.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/2.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,1.0/2.0,1.0/2.0,1.0/2.0)],
//                      nil];
//            frame6 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,1.0/2.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0/4.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,2.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,3.0/4.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame7 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/4.0,1.0/2.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0/2.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,1.0/2.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//            frame8 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/2.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/2.0,3.0/4.0,1.0/2.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/4.0,3.0/4.0,3.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/2.0,1.0/4.0,1.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,2.0/3.0,1.0/4.0,1.0/3.0)],
//                      nil];
//        }
//            break;
//        case 9:
//        {
//            frame1 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,3.0/4.0,3.0/4.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,0.0,1.0/4.0,1.0/4.0)],
//                      nil];
//            frame2 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,0.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,3.0/4.0/2.0,3.0/4.0,3.0/4.0/2.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/4.0,1.0/4.0,1.0/4.0)],
//                      nil];
//            frame3 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,0.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,2.0/4.0,1.0/4.0,1.0/4.0)],
//                      nil];
//            frame4 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      nil];
//            frame5 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,1.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,2.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,0.0,1.0/2.0,1.0)],
//                      nil];
//            frame6 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,1.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,2.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,0.0,1.0/4.0,1.0/4.0)],
//                      nil];
//            frame7 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,2.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,1.0/4.0,1.0/4.0,1.0/4.0)],
//                      nil];
//            frame8 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/3.0,2.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,1.0/4.0,3.0/4.0/2.0,3.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(1.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,2.0/4.0,1.0/4.0,1.0/4.0)],
//                      nil];
//            frame9 = [NSArray arrayWithObjects:
//                      [RDCustomRect InitRDCustomRect: CGRectMake(2.0/3.0,2.0/3.0,1.0/3.0,1.0/3.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0/2.0,1.0/4.0,3.0/4.0/2.0,3.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(0.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      [RDCustomRect InitRDCustomRect: CGRectMake(3.0/4.0,3.0/4.0,1.0/4.0,1.0/4.0)],
//                      nil];
//        }
//            break;
//        default:
//            break;
//    }
    
    NSMutableArray *  maskDictionary = [RDCustomSizeLayout maskDictionary:[RDHelpClass getResourceFromBundle:@"RDVEUISDK" resourceName:[NSString stringWithFormat:@"/MultiDifferent/Puzzle_Images/mix_%d/%d-%d",_templateIndex, _templateIndex,_templateType] Type:@"json"] ];
    
    float fl = [[maskDictionary[indexPath.row] objectForKey:@"l"]  floatValue];
    float ft  = [[maskDictionary[indexPath.row] objectForKey:@"t"] floatValue];
    
    float fr = [[maskDictionary[indexPath.row] objectForKey:@"r"]  floatValue];
    float fb = [[maskDictionary[indexPath.row] objectForKey:@"b"]  floatValue];
    
    attrs.frame = CGRectMake(fl,ft , fr - fl  , fb - ft );

    
//    switch (i) {
//        case 0:
//            attrs.frame = frame1[_templateType-1].rect;
//            break;
//        case 1:
//            attrs.frame = frame2[_templateType-1].rect;
//            break;
//        case 2:
//            attrs.frame = frame3[_templateType-1].rect;
//            break;
//        case 3:
//            attrs.frame = frame4[_templateType-1].rect;
//            break;
//        case 4:
//            attrs.frame = frame5[_templateType-1].rect;
//            break;
//        case 5:
//            attrs.frame = frame6[_templateType-1].rect;
//            break;
//        case 6:
//            attrs.frame = frame7[_templateType-1].rect;
//            break;
//        case 7:
//            attrs.frame = frame8[_templateType-1].rect;
//            break;
//        case 8:
//            attrs.frame = frame9[_templateType-1].rect;
//            break;
//        default:
//            break;
//    }
    
//    width -= _templateBorderWidth;
//    height-= _templateBorderWidth;
    
    CGRect rect = attrs.frame;
    attrs.frame = CGRectMake(width * rect.origin.x, height * rect.origin.y, width * rect.size.width, height * rect.size.height);
    
    return attrs;
}

+(id)maskDictionary:(NSString *) path
{
    NSData *jsonData = [[NSData alloc] initWithContentsOfFile:path];
    id  configDic = [RDHelpClass objectForData:jsonData];
    return configDic;
}

@end

