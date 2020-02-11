//
//  RDExtractAudioViewController.h
//  RDVEUISDK
//
//  Created by apple on 2019/7/15.
//  Copyright © 2019 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDKConfigure.h"

@interface RDExtractAudioViewController : UIViewController

@property (nonatomic,assign) bool   isExtract;

@property (nonatomic, strong) RDFile *file;

@property (nonatomic,assign)AVFileType type;
@property (nonatomic,assign)int        samplerate;

@property (nonatomic, copy) NSString *outputPath;

@property (nonatomic, assign) CGSize exportSize;

@property (nonatomic,copy) void (^finishAction)( NSString *outputPath, CMTimeRange videoTimeRange );

@property (nonatomic,copy) void (^cancelAction)( );
@end
