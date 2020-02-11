//
//  RDZipArchive.h
//  
//
//  Created by aish on 08-9-11.
//  acsolu@gmail.com
//  Copyright 2008  Inc. All rights reserved.
//
// History: 
//    09-11-2008 version 1.0    release
//    10-18-2009 version 1.1    support password protected zip files
//    10-21-2009 version 1.2    fix date bug

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#include "minizip/RDzip.h"
#include "minizip/RDunzip.h"


@protocol RDZipArchiveDelegate <NSObject>
@optional
-(void) ErrorMessage:(NSString*) msg;
-(BOOL) OverWriteOperation:(NSString*) file;

@end
typedef void(^ProgressBlock) (float progress);

@interface RDZipArchive : NSObject {
@private
	rdZipFile		_zipFile;
	unzFile		_unzFile;
//    UILabel     *_progressLabel;
    NSTimer     *_progressTimer;
	NSString*   _password;
	id			_delegate;
}
@property (nonatomic, assign) NSInteger fileIndex;
@property (nonatomic, assign) NSInteger fileCounts;
@property (nonatomic, strong) ProgressBlock progressBlock;
@property (nonatomic, assign) id delegate;

-(BOOL) RDCreateZipFile2:(NSString*) zipFile;
-(BOOL) RDCreateZipFile2:(NSString*) zipFile Password:(NSString*) password;
-(BOOL) RDAddFileToZip:(NSString*) file newname:(NSString*) newname;
-(BOOL) RDCloseZipFile2;

-(BOOL) RDUnzipOpenFile:(NSString*) zipFile;
-(BOOL) RDUnzipOpenFile:(NSString*) zipFile Password:(NSString*) password;
-(BOOL) RDUnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite completionProgress:(void (^)(float progress))completionProgress;
-(BOOL) RDUnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite;
-(BOOL) RDUnzipCloseFile;
@end
