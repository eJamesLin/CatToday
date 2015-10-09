//
//  CatTodayTimelineVC.m
//  CatToday
//
//  Created by cjlin on 2015/8/22.
//  Copyright (c) 2015年 HackUC. All rights reserved.
//

#import "CatTodayTimelineVC.h"
#import "CatCollectionViewCell.h"
#import "Constants.h"
#import "PFObject+CatToday.h"
#import "UIColor+CatToday.h"
#import "Constants.h"
#import "MenuImage.h"
#import "AppDelegate.h"
//#import "Azure.h"

//pods
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "AFNetworking.h"
#import "Masonry.h"

static NSString *cellIdentifier = @"cellIdentifier";

@interface CatTodayTimelineVC ()
@property (nonatomic, strong) UILabel *networkView;
//@property (nonatomic, strong) Azure *azure;
@end

@implementation CatTodayTimelineVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	[self.collectionView registerClass:[CatCollectionViewCell class]
			forCellWithReuseIdentifier:cellIdentifier];

	[self uiSetting];

	// network status
	[self createNetworkStatusFrame];
	[self networkStatusMonitoring];

	//[self createNewCat];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(jumpToPhoto)
												 name:NSNotify_ObjectID
											   object:nil];
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSNotify_ObjectID
												  object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self jumpToPhoto];
}

- (void)uiSetting
{
	self.collectionView.backgroundColor = [UIColor mainPageBackground];
	self.paginationEnabled = NO;
	self.pullToRefreshEnabled = NO;
	((UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout).scrollDirection = UICollectionViewScrollDirectionHorizontal;
	if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}

	if ([self respondsToSelector:@selector(extendedLayoutIncludesOpaqueBars)]) {
		self.extendedLayoutIncludesOpaqueBars = NO;
	}

	if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) {
		self.automaticallyAdjustsScrollViewInsets = NO;
	}
}

- (void)createNewCat
{
	PFObject *cat = [PFObject objectWithClassName:CAT_CLASS];
	[cat setObject:@"kitty" forKey:CAT_CLASS_KEY_NAME];

	UIImage *catPhoto = [UIImage imageNamed:@"catDemo"];
	NSData *data = UIImagePNGRepresentation(catPhoto);
	[cat setObject:[PFFile fileWithData:data] forKey:CAT_CLASS_KEY_PHOTO];
	[cat saveInBackground];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDelegateFlowLayout
// comment and move to collectionViewLayout using itemSize
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
	CGSize size = CGSizeMake(self.collectionView.bounds.size.width, self.collectionView.bounds.size.height);
	return size;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
	return MainPage_Item_Spacing;
}

- (void)reloadCellOfObject:(PFObject *)object
{
	NSIndexPath *indexPath = [self indexPathForObject:object];
	//NSLog(@"%s %ld", __PRETTY_FUNCTION__, indexPath.item);
	if (indexPath) {
		[self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
	}
	else {
#if DEBUG
		NSLog(@"indexPath not found at %s %@", __PRETTY_FUNCTION__, object.objectId);
#endif
	}
}

- (NSIndexPath *)indexPathForObject:(PFObject *)targetObject {
	for (int i = 0; i < self.objects.count; i++) {
		PFObject *object = [self.objects objectAtIndex:i];
		if ([object isEqualToObject:targetObject]) {
			return [NSIndexPath indexPathForRow:i inSection:0];
		}
	}

	return nil;
}

- (UIImage *)imageByDrawingRectOnImage:(UIImage *)image rectString:(NSString *)rectString
{
	CGRect drawRect = CGRectFromString(rectString);

	// begin a graphics context of sufficient size
	UIGraphicsBeginImageContext(image.size);

	// draw original image into the context
	[image drawAtPoint:CGPointZero];

	// get the context for CoreGraphics
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	// set stroking color and draw circle
	[[UIColor yellowColor] setStroke];
//	drawRect = CGRectInset(drawRect, 30, 30);

//	// make circle rect 5 px from border
//	CGRect circleRect = CGRectMake(0, 0,
//								   image.size.width,
//								   image.size.height);
//	circleRect = CGRectInset(circleRect, 5, 5);

	// draw circle
	CGContextStrokeRect(ctx, drawRect);

	// make image out of bitmap context
	UIImage *retImage = UIGraphicsGetImageFromCurrentImageContext();

	// free the context
	UIGraphicsEndImageContext();

	return retImage;
}

- (PFCollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
	// NSUInteger index = indexPath.item;
	//	NSLog(@"%s %lu %ld", __PRETTY_FUNCTION__, (unsigned long)index, (long)indexPath.row);

	CatCollectionViewCell *cell = (CatCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
	cell.imageView.image = nil;
	cell.faceRect = CGRectZero;
	cell.nameLabel.text = [object getName];
	cell.infoTextView.text = [object getInfo];

	if (object && [object objectForKey:CAT_CLASS_KEY_PHOTO]) {
		cell.imageView.file = [object objectForKey:CAT_CLASS_KEY_PHOTO];

		cell.faceView.frame = CGRectZero;
        /*
		if (![self.azure faceRectForID:object.objectId]) {
			[self.azure setRect:NSStringFromCGRect(CGRectZero) withID:object.objectId];

			[Azure azureFaceAPI:cell.imageView.file.url withBlock:^(NSMutableDictionary *json){
				NSLog(@"%s %@", __PRETTY_FUNCTION__, [json class]);
				if (json && json[@"faceRectangle"]) {
					CGRect rect = CGRectMake([self dic:json ForKey:@"left"],
											 [self dic:json ForKey:@"top"],
											 [self dic:json ForKey:@"width"],
											 [self dic:json ForKey:@"height"]);
					[self.azure setRect:NSStringFromCGRect(rect) withID:object.objectId];
				}
			}];
		}
        */

		// PFQTVC will take care of asynchronously downloading files, but will only load them when the tableview is not moving. If the data is there, let's load it right away.
		if ([cell.imageView.file isDataAvailable]) {
			[cell.imageView loadInBackground:^(UIImage *image, NSError *error) {

//				cell.imageView.file = nil;
//				if (![[self.azure faceRectForID:object.objectId] isEqualToString:NSStringFromCGRect(CGRectZero)]) {
//					cell.imageView.image = [self imageByDrawingRectOnImage:image
//																rectString:[self.azure faceRectForID:object.objectId]];
//				}
				/*
				NSLog(@"%s %f %f", __PRETTY_FUNCTION__, image.size.width, image.size.height);
				NSLog(@"%s %f %f", __PRETTY_FUNCTION__, cell.imageView.frame.size.width, cell.imageView.frame.size.height);

				cell.oriImgSize = image.size;

				CGRect rect = CGRectMake((238.0/600.0)*160, ((79.0+97.0)/600.0)*160, (165.0/600.0)*160, (165.0/600.0)*160);
				UIView *faceView = [[UIView alloc] initWithFrame:rect];
				faceView.backgroundColor = [UIColor testRed];
				cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
				[cell.imageView addSubview:faceView];
//				height = 165;
//				left = 238;
//				top = 79;
//				width = 165;
				 */
			}];
		}
		else {
//			[cell.imageView loadInBackground:^(UIImage *image, NSError *error) {
//				if (!error) {
//					NSLog(@"load file ok: %ld", indexPath.item);
//				}
//				else {
//					NSLog(@"load file fail: %ld %@", indexPath.item, error);
//				}
//			}];
			[[MenuImage sharedManager] loadHelperCellOfObject:object
											   needLoadInView:YES
											   viewController:self];
		}
	}

	return cell;
}

- (CGFloat)dic:(NSDictionary *)dic ForKey:(NSString *)key
{
	if (dic && dic[@"faceRectangle"]) {
		NSString *val = dic[@"faceRectangle"][key];
		return [val doubleValue];
	}
	return 0.0;
}

#pragma mark - jump to photo
- (void)jumpToPhoto
{
	NSString *objectID = [self getAppDelegateObjectID];
	if (objectID) {
		NSIndexPath *indexPath = [self indexPathForObjectID:objectID];
		if (indexPath) {
			[self.collectionView scrollToItemAtIndexPath:indexPath
										atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
												animated:NO];
		}
	}
}

- (NSIndexPath *)indexPathForObjectID:(NSString *)objectID {
	for (int i = 0; i < self.objects.count; i++) {
		PFObject *object = [self.objects objectAtIndex:i];
		if ([object.objectId isEqualToString:objectID]) {
			return [NSIndexPath indexPathForRow:i inSection:0];
		}
	}

	return nil;
}

- (NSString *)getAppDelegateObjectID
{
	return ((AppDelegate *)[[UIApplication sharedApplication] delegate]).objectID;
}

#pragma mark - PFQueryCollectionViewController

- (void)objectsDidLoad:(NSError *)error {
	//NSLog(@"%s %@ %@", __PRETTY_FUNCTION__, NSStringFromClass(self.class), self.objects);
	[super objectsDidLoad:error];

	[self jumpToPhoto];
}

- (PFQuery *)queryForCollection {
	NSLog(@"%s %@", __PRETTY_FUNCTION__, NSStringFromClass(self.class));
	if (![PFUser currentUser]) {
		PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
		[query setLimit:0];
		return query;
	}

	PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
	[query orderByDescending:@"createdAt"];
	[query setCachePolicy:kPFCachePolicyCacheThenNetwork];

	return query;
}

#pragma mark - 
#pragma mark - Network
- (void)createNetworkStatusFrame
{
	[self.view addSubview:self.networkView];
	[self.networkView mas_makeConstraints:^(MASConstraintMaker *make) {
		make.bottom.equalTo(self.view.mas_bottom);
		make.left.equalTo(@0);
		make.right.equalTo(@0);
		make.height.equalTo(@30);
	}];

}

- (UILabel *)networkView
{
	if (!_networkView) {
		_networkView = [[UILabel alloc] init];
		_networkView.text = @"No Internet";
		_networkView.textColor = [UIColor whiteColor];
		_networkView.textAlignment = NSTextAlignmentCenter;
		_networkView.backgroundColor = [UIColor blackColor];
		_networkView.hidden = YES;
		_networkView.alpha = 0.5;
	}
	return _networkView;
}

- (void)networkStatusMonitoring
{
	// -- Start monitoring network reachability (globally available) -- //
	[[AFNetworkReachabilityManager sharedManager] startMonitoring];

	[[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
		NSLog(@"Reachability changed: %s %@ %@", __PRETTY_FUNCTION__, NSStringFromClass(self.class), AFStringFromNetworkReachabilityStatus(status));

		switch (status) {
			case AFNetworkReachabilityStatusReachableViaWWAN:
			case AFNetworkReachabilityStatusReachableViaWiFi:
				// -- Reachable -- //
				NSLog(@"Reachable");
				self.networkView.hidden = YES;
				break;
			case AFNetworkReachabilityStatusNotReachable:
			default:
				// -- Not reachable -- //
				NSLog(@"Not Reachable");
				self.networkView.hidden = NO;
				break;
		}

	}];
}


@end
