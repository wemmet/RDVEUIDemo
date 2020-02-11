//
//  CustomSizeLayout.m
//  RDAVEDemo
//
//  Created by apple on 2017/8/25.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import "RDCustomSizeLayout.h"

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
    switch (_templateIndex) {
        case 1:
            attrs.frame = CGRectMake(0, 0, width, height);
            
            break;
            
        case 2:
            switch (i) {
                case 0:
                    attrs.frame = CGRectMake(0, 0, width, height/2.0);
                    break;
                    
                case 1:
                    attrs.frame = CGRectMake(0, height/2.0, width, height/2.0);
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 3:
            switch (i) {
                case 0:
                    attrs.frame = CGRectMake(0, 0, width/2.0, height/2.0);
                    break;
                    
                case 1:
                    attrs.frame = CGRectMake(width/2.0, 0, width/2.0, height/2.0);
                    break;
                    
                case 2:
                    attrs.frame = CGRectMake(0, height/2.0, width, height/2.0);
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 4:
            switch (i) {
                case 0:
                    attrs.frame = CGRectMake(0, 0, width/2.0, height/2.0);
                    break;
                    
                case 1:
                    attrs.frame = CGRectMake(width/2.0, 0, width/2.0, height/2.0);
                    break;
                    
                case 2:
                    attrs.frame = CGRectMake(0, height/2.0, width/2.0, height/2.0);
                    break;
                    
                case 3:
                    attrs.frame = CGRectMake(width/2.0, height/2.0, width/2.0, height/2.0);
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        case 5:
            switch (i) {
                case 0:
                    attrs.frame = CGRectMake(0, 0, width/3.0, height/2.0);
                    break;
                    
                case 1:
                    attrs.frame = CGRectMake(width/3.0, 0, width/3.0, height);
                    break;
                    
                case 2:
                    attrs.frame = CGRectMake(width/3.0*2, 0, width/3.0, height/2.0);
                    break;
                    
                case 3:
                    attrs.frame = CGRectMake(0, height/2.0, width/3.0, height/2.0);
                    break;
                    
                case 4:
                    attrs.frame = CGRectMake(width/3.0*2, height/2.0, width/3.0, height/2.0);
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 6:
            switch (i) {
                case 0:
                    attrs.frame = CGRectMake(0, 0, width/2.0, height/3.0);
                    break;
                    
                case 1:
                    attrs.frame = CGRectMake(width/2.0, 0, width/2.0, height/3.0);
                    break;
                    
                case 2:
                    attrs.frame = CGRectMake(0, height/3.0, width/2.0, height/3.0);
                    break;
                    
                case 3:
                    attrs.frame = CGRectMake(width/2.0, height/3.0, width/2.0, height/3.0);
                    break;
                    
                case 4:
                    attrs.frame = CGRectMake(0, height/3.0*2, width/2.0, height/3.0);
                    break;
                    
                case 5:
                    attrs.frame = CGRectMake(width/2.0, height/3.0*2, width/2.0, height/3.0);
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 7:
            switch (i) {
                case 0:
                    attrs.frame = CGRectMake(0, 0, width/3.0, height/2.0);
                    break;
                    
                case 1:
                    attrs.frame = CGRectMake(width/3.0, 0, width/3.0, height/2.0);
                    break;
                    
                case 2:
                    attrs.frame = CGRectMake(width/3.0*2, 0, width/3.0, height/2.0);
                    break;
                    
                case 3:
                    attrs.frame = CGRectMake(0, height/2.0, width/4.0, height/2.0);
                    break;
                    
                case 4:
                    attrs.frame = CGRectMake(width/4.0, height/2.0, width/4.0, height/2.0);
                    break;
                    
                case 5:
                    attrs.frame = CGRectMake(width/4.0*2, height/2.0, width/4.0, height/2.0);
                    break;
                    
                case 6:
                    attrs.frame = CGRectMake(width/4.0*3, height/2.0, width/4.0, height/2.0);
                    break;
                    
                default:
                    break;
            }
            break;
            
        case 8:
            switch (i) {
                case 0:
                    attrs.frame = CGRectMake(0, 0, width/4.0, height/2.0);
                    break;
                    
                case 1:
                    attrs.frame = CGRectMake(width/4.0, 0, width/4.0, height/2.0);
                    break;
                    
                case 2:
                    attrs.frame = CGRectMake(width/4.0*2, 0, width/4.0, height/2.0);
                    break;
                    
                case 3:
                    attrs.frame = CGRectMake(width/4.0*3, 0, width/4.0, height/2.0);
                    break;
                    
                case 4:
                    attrs.frame = CGRectMake(0, height/2.0, width/4.0, height/2.0);
                    break;
                    
                case 5:
                    attrs.frame = CGRectMake(width/4.0, height/2.0, width/4.0, height/2.0);
                    break;
                    
                case 6:
                    attrs.frame = CGRectMake(width/4.0*2, height/2.0, width/4.0, height/2.0);
                    break;
                    
                case 7:
                    attrs.frame = CGRectMake(width/4.0*3, height/2.0, width/4.0, height/2.0);
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }

    return attrs;
}

@end
