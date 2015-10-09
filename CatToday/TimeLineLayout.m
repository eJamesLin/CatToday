//
//  MenuCollectionViewLayout.m
//  MENU
//
//  Created by cjlin on 2015/3/17.
//
//

#import "TimeLineLayout.h"
#import "WhiteDecorationCell.h"
#import "Constants.h"

@interface TimeLineLayout ()
@property (nonatomic, strong) NSDictionary *decorationRects;
@end

@implementation TimeLineLayout

- (id)init
{
	if (!(self = [super init])) return nil;

	//self.itemSize = CGSizeMake(CGRectGetWidth([[UIScreen mainScreen] bounds]), 364.0f);
	//self.sectionInset = UIEdgeInsetsMake((iPhone5 ? 60 : 60), 2, 100, 2);
	//self.minimumInteritemSpacing = 10.0f;
	//self.minimumLineSpacing = 2.0f;
	self.scrollDirection = UICollectionViewScrollDirectionHorizontal;
	self.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0);
	self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;

	[self registerClass:WhiteDecorationCell.class forDecorationViewOfKind:[WhiteDecorationCell kind]];

	return self;
}

- (void)awakeFromNib
{
	self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast;
	[self registerClass:WhiteDecorationCell.class forDecorationViewOfKind:[WhiteDecorationCell kind]];
}

- (BOOL)shouldInvalidateLayoutForBoundsChange:(CGRect)oldBounds
{
	return YES;
}

- (CGPoint)targetContentOffsetForProposedContentOffset:(CGPoint)proposedContentOffset withScrollingVelocity:(CGPoint)velocity
{
	CGFloat offsetAdjustment = MAXFLOAT;
	CGFloat horizontalCenter = proposedContentOffset.x + (CGRectGetWidth(self.collectionView.bounds) / 2.0);

	CGRect targetRect = CGRectMake(proposedContentOffset.x, 0.0, self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
	NSArray* array = [self layoutAttributesForElementsInRect:targetRect];

	for (UICollectionViewLayoutAttributes* layoutAttributes in array) {
//		if (layoutAttributes.representedElementCategory != UICollectionElementCategoryCell)
//			continue; // skip headers

		CGFloat itemHorizontalCenter = layoutAttributes.center.x;
		if (ABS(itemHorizontalCenter - horizontalCenter) < ABS(offsetAdjustment)) {
			offsetAdjustment = itemHorizontalCenter - horizontalCenter;

			//layoutAttributes.alpha = 0;
		}
	}
	return CGPointMake(proposedContentOffset.x + offsetAdjustment, proposedContentOffset.y);
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect
{
	NSArray *attributesInRect = [super layoutAttributesForElementsInRect:rect];

	NSMutableArray *mArray = [attributesInRect mutableCopy];
	[self.decorationRects enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
		if (CGRectIntersectsRect([obj CGRectValue], rect)) {
			UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForDecorationViewOfKind:[WhiteDecorationCell kind] withIndexPath:key];
			attributes.frame = [obj CGRectValue];
			attributes.zIndex = -1;
			[mArray addObject:attributes];
		}
	}];
	attributesInRect = mArray;

	return attributesInRect;
}

- (void)prepareLayout
{
	// call super so flow layout can do all the math for cells, headers, and footers
	[super prepareLayout];

	NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
	NSInteger sectionCount = [self.collectionView numberOfSections];
	for (NSInteger section = 0; section < sectionCount; section++)
	{
		NSInteger itemCount = [self.collectionView numberOfItemsInSection:section];
		for (NSInteger row = 0; row < itemCount; row++)
		{
			CGSize size = CGSizeMake(self.collectionView.frame.size.width, self.collectionView.frame.size.height);
			CGRect rect = CGRectMake(row*(size.width+MainPage_Item_Spacing), 0, size.width, size.height);
			dictionary[[NSIndexPath indexPathForItem:row inSection:section]] = [NSValue valueWithCGRect:rect];
		}
	}

	self.decorationRects = [NSDictionary dictionaryWithDictionary:dictionary];
}

@end
