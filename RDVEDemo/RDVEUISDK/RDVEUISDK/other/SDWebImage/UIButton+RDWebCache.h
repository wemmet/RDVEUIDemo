/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "RDSDWebImageCompat.h"
#import "RDSDWebImageManager.h"

/**
 * Integrates SDWebImage async downloading and caching of remote images with UIButtonView.
 */
@interface UIButton (RDWebCache)

/**
 * Get the current image URL.
 */
- (NSURL *)rd_sd_currentImageURL;

/**
 * Get the image URL for a control state.
 * 
 * @param state Which state you want to know the URL for. The values are described in UIControlState.
 */
- (NSURL *)rd_sd_imageURLForState:(UIControlState)state;

/**
 * Set the imageView `image` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url   The url for the image.
 * @param state The state that uses the specified title. The values are described in UIControlState.
 */
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state;

/**
 * Set the imageView `image` with an `url` and a placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url         The url for the image.
 * @param state       The state that uses the specified title. The values are described in UIControlState.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @see sd_setImageWithURL:placeholderImage:options:
 */
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url         The url for the image.
 * @param state       The state that uses the specified title. The values are described in UIControlState.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options     The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 */
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options;

/**
 * Set the imageView `image` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param state          The state that uses the specified title. The values are described in UIControlState.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Set the imageView `image` with an `url`, placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param state          The state that uses the specified title. The values are described in UIControlState.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Set the imageView `image` with an `url`, placeholder and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param state          The state that uses the specified title. The values are described in UIControlState.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Set the backgroundImageView `image` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url   The url for the image.
 * @param state The state that uses the specified title. The values are described in UIControlState.
 */
- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state;

/**
 * Set the backgroundImageView `image` with an `url` and a placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url         The url for the image.
 * @param state       The state that uses the specified title. The values are described in UIControlState.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @see sd_setImageWithURL:placeholderImage:options:
 */
- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder;

/**
 * Set the backgroundImageView `image` with an `url`, placeholder and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url         The url for the image.
 * @param state       The state that uses the specified title. The values are described in UIControlState.
 * @param placeholder The image to be set initially, until the image request finishes.
 * @param options     The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 */
- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options;

/**
 * Set the backgroundImageView `image` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param state          The state that uses the specified title. The values are described in UIControlState.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Set the backgroundImageView `image` with an `url`, placeholder.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param state          The state that uses the specified title. The values are described in UIControlState.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
//- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Set the backgroundImageView `image` with an `url`, placeholder and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param placeholder    The image to be set initially, until the image request finishes.
 * @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Cancel the current image download
 */
- (void)rd_sd_cancelImageLoadForState:(UIControlState)state;

/**
 * Cancel the current backgroundImage download
 */
- (void)rd_sd_cancelBackgroundImageLoadForState:(UIControlState)state;

@end


@interface UIButton (RDWebCacheDeprecated)

- (NSURL *)rd_currentImageURL __deprecated_msg("Use `sd_currentImageURL`");
- (NSURL *)rd_imageURLForState:(UIControlState)state __deprecated_msg("Use `sd_imageURLForState:`");

- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:forState:`");
- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:forState:placeholderImage:`");
- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:forState:placeholderImage:options:`");

//- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:forState:completed:`");
- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:forState:placeholderImage:completed:`");
- (void)rd_setImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setImageWithURL:forState:placeholderImage:options:completed:`");

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state __deprecated_msg("Method deprecated. Use `sd_setBackgroundImageWithURL:forState:`");
- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder __deprecated_msg("Method deprecated. Use `sd_setBackgroundImageWithURL:forState:placeholderImage:`");
- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options __deprecated_msg("Method deprecated. Use `sd_setBackgroundImageWithURL:forState:placeholderImage:options:`");

- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setBackgroundImageWithURL:forState:completed:`");
- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setBackgroundImageWithURL:forState:placeholderImage:completed:`");
- (void)rd_setBackgroundImageWithURL:(NSURL *)url forState:(UIControlState)state placeholderImage:(UIImage *)placeholder options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setBackgroundImageWithURL:forState:placeholderImage:options:completed:`");

- (void)rd_cancelCurrentImageLoad __deprecated_msg("Use `sd_cancelImageLoadForState:`");
- (void)rd_cancelBackgroundImageLoadForState:(UIControlState)state __deprecated_msg("Use `sd_cancelBackgroundImageLoadForState:`");

@end
