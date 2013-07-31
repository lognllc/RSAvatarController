//
//  RSMoveAndScaleController.m
//
//  Created by Rex Sheng on 5/8/12.
//

#import "RSMoveAndScaleController.h"
#import "UIImage+WithShadow.h"

#define PANEL_HEIGHT 96

@interface RSMoveAndScaleView ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UIImageView *imageView;

@end

@implementation RSMoveAndScaleView
{
	CALayer *scrollLayer;
	CGPoint threshold;
	CGFloat minimumScale;
}

- (id)initWithFrame:(CGRect)frame
{
	if (self = [super initWithFrame:frame]) {
		_maximumZoomScale = 3.0;
		_destinationSize = CGSizeMake(320, 320);
		
		CALayer *mask = [CALayer layer];
		mask.frame = frame;
		mask.backgroundColor = (self.maskForegroundColor ?: [UIColor blackColor]).CGColor;
		scrollLayer = [CALayer layer];
		scrollLayer.backgroundColor = [UIColor whiteColor].CGColor;
		[mask addSublayer:scrollLayer];
		self.layer.mask = mask;
		
		UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
		scrollView.showsVerticalScrollIndicator = NO;
		scrollView.showsHorizontalScrollIndicator = NO;
		scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		scrollView.zoomScale = 1.0;
		scrollView.clipsToBounds = NO;
		scrollView.maximumZoomScale = _maximumZoomScale;
		scrollView.scrollEnabled = YES;
		scrollView.alwaysBounceHorizontal = YES;
		scrollView.alwaysBounceVertical = YES;
		[self addSubview:_scrollView = scrollView];
		
		UIImageView *imageView = [[UIImageView alloc] init];
		imageView.contentMode = UIViewContentModeScaleAspectFill;
		[scrollView addSubview:_imageView = imageView];
	}
	return self;
}

- (void)setMaximumZoomScale:(CGFloat)maximumZoomScale
{
	_maximumZoomScale = maximumZoomScale;
	_scrollView.maximumZoomScale = maximumZoomScale;
}

- (void)setMaskForegroundColor:(UIColor *)maskForegroundColor
{
	_maskForegroundColor = maskForegroundColor;
	self.backgroundColor = maskForegroundColor;
	self.layer.mask.backgroundColor = (maskForegroundColor ?: [UIColor blackColor]).CGColor;
}

- (void)adjustView
{
	CGSize size = self.bounds.size;
	CGFloat x = (size.width - _destinationSize.width) / 2;
	CGFloat y = x * 1.5;
	scrollLayer.frame = UIEdgeInsetsInsetRect(CGRectMake(x, y, _destinationSize.width, _destinationSize.height), self.scrollingViewEdgeInsets);
	size = _imageView.frame.size;
	if (size.width > 0 && size.height > 0) {
		CGFloat height = scrollLayer.bounds.size.height, width = scrollLayer.bounds.size.width;
		CGFloat frameRatio = width / height;
		CGFloat imageRatio = size.width / size.height;
		if (imageRatio < frameRatio) {
			width = height * imageRatio;
		}
		CGFloat scale = width / size.height;
		size.width *= scale;
		size.height *= scale;
		threshold = CGPointMake((size.width - _destinationSize.width) / 2, (size.height - _destinationSize.height) / 2);
		_imageView.frame = (CGRect){.size = size, .origin = CGPointMake(-threshold.x + scrollLayer.frame.origin.x, -threshold.y + scrollLayer.frame.origin.y)};
		_scrollView.contentSize = size;
		_scrollView.contentOffset = CGPointZero;
		minimumScale = scale;
		_scrollView.minimumZoomScale = scale;
		_scrollView.maximumZoomScale = MAX(scale, _scrollView.maximumZoomScale);
	}
}

- (void)limitScrollViewInBounds
{
/*	CGFloat scale = _scrollView.zoomScale;
//	NSLog(@"scale=%f offset=%f, %f", scale, _scrollView.contentOffset.x, _scrollView.contentOffset.y);
	CGPoint offset = _scrollView.contentOffset;
	CGSize size = _scrollView.contentSize;
	CGFloat up = scale / minimumScale;
	//better, but still have problem
	CGPoint t = CGPointMake((size.width * up - _destinationSize.width) / 2, (size.height * up - _destinationSize.height) / 2);
	offset.y = MAX(MIN(offset.y, t.y), -threshold.y);
	offset.x = MAX(MIN(offset.x, t.x), -threshold.x);
	_scrollView.contentOffset = offset;
	_scrollView.contentInset = UIEdgeInsetsMake(-offset.y, -offset.x, 0, 0);*/
	CGSize boundsSize = _scrollView.bounds.size;
    CGRect contentsFrame = _imageView.frame;
	CGSize size = _scrollView.contentSize;
    
    if (contentsFrame.size.width < _destinationSize.width) {
        contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0f;
		size.width = boundsSize.width;

    } else {
        contentsFrame.origin.x = (boundsSize.width - _destinationSize.width) / 2;
		size.width = contentsFrame.size.width + boundsSize.width - _destinationSize.width;
    }
    
    if (contentsFrame.size.height < _destinationSize.height) {
        contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0f;
		size.height = boundsSize.height;
    } else {
        contentsFrame.origin.y = (boundsSize.height - _destinationSize.height) / 2;
		size.height = contentsFrame.size.height + boundsSize.height - _destinationSize.height;
    }
	_scrollView.contentSize = size;
    _imageView.frame = contentsFrame;
}

- (void)setDestinationSize:(CGSize)destinationSize
{
	_destinationSize = destinationSize;
	[self adjustView];
}

- (void)setScrollingViewEdgeInsets:(UIEdgeInsets)scrollingViewEdgeInsets
{
	_scrollingViewEdgeInsets = scrollingViewEdgeInsets;
	[self adjustView];
}

- (void)setImage:(UIImage *)image
{
	if (self.imageView.image != image) {
		self.imageView.image = image;
		CGFloat width = self.bounds.size.width;
		CGFloat height = width / image.size.width  * image.size.height;
		CGSize size = CGSizeMake(width, height);
		_imageView.frame = (CGRect){.size = size};
		[self adjustView];
	}
}

- (UIImage *)croppingImage
{
	CGRect scrollFrame = scrollLayer.frame;
	CALayer *layer = _scrollView.layer;
	UIGraphicsBeginImageContextWithOptions(self.destinationSize, NO, [UIScreen mainScreen].scale);
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGPoint vorigin = layer.visibleRect.origin;
	CGContextTranslateCTM(ctx, -vorigin.x - scrollFrame.origin.x, -vorigin.y - scrollFrame.origin.y);
	[layer renderInContext:ctx];
	UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return snapshot;
}

@end


@implementation RSMoveAndScaleController

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.contentSizeForViewInPopover = CGSizeMake(320, 443);
	CGRect frame = self.overlayView.frame;
	CGSize size = self.view.bounds.size;
	CGFloat bottomHeight = 96;
	if (frame.size.height < size.height) {
		NSUInteger mask = self.overlayView.autoresizingMask;
		if ((mask | UIViewAutoresizingFlexibleTopMargin) == mask) {
			frame.origin.y = size.height - frame.size.height;
			bottomHeight = frame.size.height;
		}
		self.overlayView.frame = frame;
	} else {
		self.overlayView.frame = self.view.bounds;
	}
	[self.view addSubview:self.overlayView];
	RSMoveAndScaleView *clippingView = [[RSMoveAndScaleView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height - bottomHeight)];
	clippingView.scrollView.delegate = self;
	clippingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	clippingView.clipsToBounds = YES;
	if (_maximumZoomScale) clippingView.maximumZoomScale = _maximumZoomScale;
	[self.view addSubview:_clippingView = clippingView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	_clippingView.destinationSize = _destinationSize;
	_clippingView.image = _originImage;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[_clippingView limitScrollViewInBounds];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	if (scrollView == _clippingView.scrollView)
		return _clippingView.imageView;
	return nil;
}

- (void)setMaximumZoomScale:(CGFloat)maximumZoomScale
{
	_maximumZoomScale = maximumZoomScale;
	_clippingView.maximumZoomScale = maximumZoomScale;
}

- (void)setDestinationSize:(CGSize)destinationSize
{
	_destinationSize = destinationSize;
	if (self.isViewLoaded) {
		_clippingView.destinationSize = destinationSize;
	}
}

- (void)cancel
{
	[self.delegate moveAndScaleControllerDidCancel:self];
}

- (void)choose
{
	UIImage *snapshot = [_clippingView croppingImage];
	[self.delegate moveAndScaleController:self didFinishCropping:snapshot];
}

@end
