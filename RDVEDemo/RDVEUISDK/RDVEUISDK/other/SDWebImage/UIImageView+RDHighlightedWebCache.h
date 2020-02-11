/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import <UIKit/UIKit.h>
#import "RDSDWebImageCompat.h"
#import "RDSDWebImageManager.h"

/**
 * Integrates SDWebImage async downloading and caching of remote images with UIImageView for highlighted state.
 */
@interface UIImageView (RDHighlightedWebCache)

/**
 * Set the imageView `highlightedImage` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url The url for the image.
 */
- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url;

/**
 * Set the imageView `highlightedImage` with an `url` and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url     The url for the image.
 * @param options The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 */
- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options;

/**
 * Set the imageView `highlightedImage` with an `url`.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Set the imageView `highlightedImage` with an `url` and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Set the imageView `highlightedImage` with an `url` and custom options.
 *
 * The download is asynchronous and cached.
 *
 * @param url            The url for the image.
 * @param options        The options to use when downloading the image. @see SDWebImageOptions for the possible values.
 * @param progressBlock  A block called while image is downloading
 * @param completedBlock A block called when operation has been completed. This block has no return value
 *                       and takes the requested UIImage as first parameter. In case of error the image parameter
 *                       is nil and the second parameter may contain an NSError. The third parameter is a Boolean
 *                       indicating if the image was retrived from the local cache or from the network.
 *                       The forth parameter is the original image url.
 */
- (void)rd_sd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageCompletionBlock)completedBlock;

/**
 * Cancel the current download
 */
- (void)rd_sd_cancelCurrentHighlightedImageLoad;

@end


@interface UIImageView (HighlightedWebCacheDeprecated)

- (void)rd_setHighlightedImageWithURL:(NSURL *)url __deprecated_msg("Method deprecated. Use `sd_setHighlightedImageWithURL:`");
//- (void)rd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options __deprecated_msg("Method deprecated. Use `sd_setHighlightedImageWithURL:options:`");
- (void)rd_setHighlightedImageWithURL:(NSURL *)url completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setHighlightedImageWithURL:completed:`");
- (void)rd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setHighlightedImageWithURL:options:completed:`");
- (void)rd_setHighlightedImageWithURL:(NSURL *)url options:(RDSDWebImageOptions)options progress:(RDSDWebImageDownloaderProgressBlock)progressBlock completed:(RDSDWebImageCompletedBlock)completedBlock __deprecated_msg("Method deprecated. Use `sd_setHighlightedImageWithURL:options:progress:completed:`");

- (void)rd_cancelCurrentHighlightedImageLoad __deprecated_msg("Use `sd_cancelCurrentHighlightedImageLoad`");

@end
