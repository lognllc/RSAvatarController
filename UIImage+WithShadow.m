
#import "UIImage+WithShadow.h"

@implementation UIImage (WithShadow)

- (UIImage *)operateOn:(void (^)(CGContextRef context, CGRect rect))block
{
	CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
	CGSize size = CGSizeMake(self.size.width * self.scale, self.size.height * self.scale);
	CGRect rect = CGRectMake(0, 0, size.width, size.height);
	CGContextRef context = CGBitmapContextCreate(NULL, size.width, size.height, CGImageGetBitsPerComponent(self.CGImage), 0, colourSpace, (CGBitmapInfo) kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colourSpace);
	
	block(context, rect);
	
	CGImageRef cgImage = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:[UIScreen mainScreen].scale orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
	return image;
}

- (UIImage*)maskWithMask:(UIImage *)maskImage
{
	CGImageRef maskRef = maskImage.CGImage; 
	
	CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
										CGImageGetHeight(maskRef),
										CGImageGetBitsPerComponent(maskRef),
										CGImageGetBitsPerPixel(maskRef),
										CGImageGetBytesPerRow(maskRef),
										CGImageGetDataProvider(maskRef), NULL, false);
	
	CGImageRef masked = CGImageCreateWithMask(self.CGImage, mask);
	CGImageRelease(mask);
	UIImage *image = [UIImage imageWithCGImage:masked];
	CGImageRelease(masked);
	return image;
}

- (UIImage *)clippingMask:(CGColorRef)clippingMask
{
	return [self operateOn:^(CGContextRef context, CGRect rect) {
		CGImageRef image = self.CGImage;
		CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(image),
											CGImageGetHeight(image),
											CGImageGetBitsPerComponent(image),
											CGImageGetBitsPerPixel(image),
											CGImageGetBytesPerRow(image),
											CGImageGetDataProvider(image), NULL, YES);
		CGContextClipToMask(context, rect, mask);
		CGImageRelease(mask);
		CGContextSetFillColorWithColor(context, clippingMask);
		CGContextFillRect(context, rect);
	}];
}

- (UIImage *)wrap:(UIImage *)newImage
{
	return [self operateOn:^(CGContextRef context, CGRect rect) {
		CGImageRef image = self.CGImage;
		CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(image),
											CGImageGetHeight(image),
											CGImageGetBitsPerComponent(image),
											CGImageGetBitsPerPixel(image),
											CGImageGetBytesPerRow(image),
											CGImageGetDataProvider(image), NULL, false);
		CGContextClipToMask(context, rect, mask);
		CGImageRelease(mask);
		CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
		CGContextFillRect(context, rect);
		CGFloat myRatio = rect.size.width / rect.size.height;
		CGSize newSize = newImage.size;
		CGFloat newRatio = newSize.width / newSize.height;
		CGFloat insetY = 0, insetX = 0;
		if (newRatio > myRatio) {
			insetY = (rect.size.height - rect.size.width / newRatio) / 2;
		} else {
			insetX = (rect.size.width - rect.size.height * newRatio) / 2;
		}
		CGRect newRect = CGRectInset(rect, insetX, insetY);
		CGContextDrawImage(context, newRect, newImage.CGImage);
		CGContextSetBlendMode(context, kCGBlendModeNormal);
		CGContextDrawImage(context, rect, image);
	}];
}

- (UIImage *)blendMode:(CGBlendMode)blendMode image:(CGImageRef)image
{
	return [self operateOn:^(CGContextRef context, CGRect rect) {
		CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(image),
											CGImageGetHeight(image),
											CGImageGetBitsPerComponent(image),
											CGImageGetBitsPerPixel(image),
											CGImageGetBytesPerRow(image),
											CGImageGetDataProvider(image), NULL, false);
		CGContextClipToMask(context, rect, mask);
		CGImageRelease(mask);
		CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
		CGContextFillRect(context, rect);
		
		
		CGContextDrawImage(context, rect, self.CGImage);
		CGContextSetBlendMode(context, blendMode);
		CGContextDrawImage(context, rect, image);
	}];
}

- (UIImage *)resizedImageFitSize:(CGSize)frameSize edgeInsets:(UIEdgeInsets)insets
{
	CGSize imageSize = self.size;
	CGFloat ratio = 1;
	CGFloat targetHeight = imageSize.height, targetWidth = imageSize.width;
	if (self.imageOrientation != UIImageOrientationUp && self.imageOrientation != UIImageOrientationDown) {
		CGFloat i = targetHeight;
		targetHeight = targetWidth;
		targetWidth = i;
	}
	CGFloat height = frameSize.height, width = frameSize.width;
	height += insets.top + insets.bottom;
	width += insets.left + insets.right;
	
	CGFloat frameRatio = width / height;
	CGFloat imageRatio = targetWidth / targetHeight;
	if (imageRatio < frameRatio) {
		width = height * imageRatio;
	}
	ratio = width / targetHeight;
	return [self resizedImage:ratio edgeInsets:insets];
}

- (UIImage *)resizedImageFitSize:(CGSize)frameSize
{
	return [self resizedImageFitSize:frameSize edgeInsets:UIEdgeInsetsZero];
}

- (UIImage *)resizedImage:(CGFloat)ratio
{
	return [self resizedImage:ratio edgeInsets:UIEdgeInsetsZero];
}

- (UIImage *)resizedImage:(CGFloat)ratio edgeInsets:(UIEdgeInsets)insets
{
	CGFloat scale = [UIScreen mainScreen].scale;
	UIImage* sourceImage = self; 
	
	CGImageRef imageRef = [sourceImage CGImage];
	CGColorSpaceRef colorSpaceInfo = CGColorSpaceCreateDeviceRGB();
	
	CGFloat targetWidth = (sourceImage.size.width * ratio) * scale;
	CGFloat targetHeight = (sourceImage.size.height * ratio) * scale;
//	NSLog(@"%f x %f", targetWidth, targetHeight);
	CGFloat width = targetWidth, height = targetHeight;
	if (sourceImage.imageOrientation != UIImageOrientationUp && sourceImage.imageOrientation != UIImageOrientationDown) {
		CGFloat i = targetHeight;
		targetHeight = targetWidth;
		targetWidth = i;
		width -= (insets.left + insets.right) * scale;
		height -= (insets.top + insets.bottom) * scale;
	} else {
		height -= (insets.left + insets.right) * scale;
		width -= (insets.top + insets.bottom) * scale;
	}
	
	CGContextRef bitmap = CGBitmapContextCreate(NULL, width, height, CGImageGetBitsPerComponent(imageRef), 0, colorSpaceInfo, (CGBitmapInfo) kCGImageAlphaPremultipliedFirst);
	CGColorSpaceRelease(colorSpaceInfo);
	
	CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
	
	if (sourceImage.imageOrientation == UIImageOrientationLeft) {
		CGContextRotateCTM (bitmap, M_PI / 2);
		CGContextTranslateCTM (bitmap, 0 - insets.top * scale, -targetHeight + insets.right * scale);
	} else if (sourceImage.imageOrientation == UIImageOrientationRight) {
		CGContextRotateCTM (bitmap, -M_PI / 2);
		//bottom, left
		CGContextTranslateCTM (bitmap, - targetWidth + insets.bottom * scale, -insets.left * scale);
	} else if (sourceImage.imageOrientation == UIImageOrientationUp) {
		CGContextTranslateCTM (bitmap, -insets.top * scale, -insets.right * scale);
	} else if (sourceImage.imageOrientation == UIImageOrientationDown) {
		CGContextTranslateCTM (bitmap, targetWidth - insets.bottom * scale, targetHeight - insets.left * scale);
		CGContextRotateCTM (bitmap, -M_PI);
	}
	
	CGContextDrawImage(bitmap, CGRectMake(0, 0, targetWidth, targetHeight), imageRef);
	CGImageRef ref = CGBitmapContextCreateImage(bitmap);
	UIImage *image = [UIImage imageWithCGImage:ref scale:scale orientation:UIImageOrientationUp];

	CGContextRelease(bitmap);
	CGImageRelease(ref);
	
	return image; 
}

- (UIImage *)blendMode:(CGBlendMode)blendMode color:(CGColorRef)color reverse:(BOOL)reverse
{
	return [self operateOn:^(CGContextRef context, CGRect rect) {
		CGContextClipToMask(context, rect, self.CGImage);
		CGContextDrawImage(context, rect, self.CGImage);
		CGContextSetBlendMode(context, blendMode);
		CGContextSetFillColorWithColor(context, color);
		CGContextFillRect(context, rect);
		if (reverse) {
			CGContextSetBlendMode(context, kCGBlendModeDifference);
			CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
			CGContextFillRect(context, rect);
		}
	}];
}

- (UIImage *)blendMode:(CGBlendMode)blendMode color:(CGColorRef)color
{
	return [self blendMode:blendMode color:color reverse:NO];
}

- (UIImage *)addShadowSize:(CGSize)shadowSize shadowBlur:(CGFloat)blur shadowColor:(CGColorRef)shadowColor
{
	return [self operateOn:^(CGContextRef context, CGRect rect) {
		CGContextSetShadowWithColor(context, shadowSize, blur, shadowColor);
		CGContextDrawImage(context, rect, self.CGImage);
	}];
}

- (UIImage *)addShadowSize:(CGSize)shadowSize shadowBlur:(CGFloat)blur shadowColor:(CGColorRef)shadowColor clippingMask:(CGColorRef)clippingMask
{
	return [self operateOn:^(CGContextRef context, CGRect rect) {
		CGContextSetShadowWithColor(context, shadowSize, blur, shadowColor);
		CGContextDrawImage(context, rect, self.CGImage);
		if (clippingMask) {
			CGContextClipToMask(context, rect, self.CGImage);
			CGContextSetFillColorWithColor(context, clippingMask);
			CGContextFillRect(context, rect);
		}	
	}];
}

@end
