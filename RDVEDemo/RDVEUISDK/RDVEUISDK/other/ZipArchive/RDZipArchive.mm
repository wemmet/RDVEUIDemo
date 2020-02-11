//
//  RDZipArchive.mm
//  
//
//  Created by aish on 08-9-11.
//  acsolu@gmail.com
//  Copyright 2008  Inc. All rights reserved.
//

#import "RDZipArchive.h"
#import "zlib.h"
#import "zconf.h"
#import "UIImage+RDWebP.h"

@interface RDZipArchive (Private)
-(void) OutputErrorMessage:(NSString*) msg;
-(BOOL) OverWrite:(NSString*) file;
-(NSDate*) Date1980;

@end



@implementation RDZipArchive
@synthesize delegate = _delegate;

-(id) init
{
	if( self=[super init] )
	{
		_zipFile = NULL ;
	}
	return self;
}

-(void) dealloc
{
	[self RDCloseZipFile2];
    [_progressBlock release];
    
    _delegate = nil;
	[super dealloc];
}

-(BOOL) RDCreateZipFile2:(NSString*) zipFile
{
	_zipFile = rdZipOpen( (const char*)[zipFile UTF8String], 0 );
	if( !_zipFile ) 
		return NO;
	return YES;
}

-(BOOL) RDCreateZipFile2:(NSString*) zipFile Password:(NSString*) password
{
	_password = password;
	return [self RDCreateZipFile2:zipFile];
}

-(BOOL) RDAddFileToZip:(NSString*) file newname:(NSString*) newname;
{
	if( !_zipFile )
		return NO;
//	tm_zip filetime;
	time_t current;
	time( &current );
	
	zip_fileinfo zipInfo = {0};
//	zipInfo.dosDate = (unsigned long) current;
	
    NSError* error = nil;
    
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:file error:&error];
	if( attr )
	{
		NSDate* fileDate = (NSDate*)[attr objectForKey:NSFileModificationDate];
		if( fileDate )
		{
			// some application does use dosDate, but tmz_date instead
		//	zipInfo.dosDate = [fileDate timeIntervalSinceDate:[self Date1980] ];
			NSCalendar* currCalendar = [NSCalendar currentCalendar];
            uint flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay |
            NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond ;
            
			NSDateComponents* dc = [currCalendar components:flags fromDate:fileDate];
			zipInfo.tmz_date.tm_sec = (int)[dc second];
			zipInfo.tmz_date.tm_min = (int)[dc minute];
			zipInfo.tmz_date.tm_hour = (int)[dc hour];
			zipInfo.tmz_date.tm_mday = (int)[dc day];
			zipInfo.tmz_date.tm_mon = (int)[dc month] - 1;
			zipInfo.tmz_date.tm_year = (int)[dc year];
		}
	}
	
	int ret ;
	NSData* data = nil;
	if( [_password length] == 0 )
	{
		ret = rdZipOpenNewFileInZip( _zipFile,
								  (const char*) [newname UTF8String],
								  &zipInfo,
								  NULL,0,
								  NULL,0,
								  NULL,//comment
								  Z_DEFLATED,
								  Z_DEFAULT_COMPRESSION );
	}
	else
	{
		data = [ NSData dataWithContentsOfFile:file];
		uLong crcValue = crc32( 0L,NULL, 0L );
		crcValue = crc32( crcValue, (const Bytef*)[data bytes], (int)[data length] );
		ret = rdZipOpenNewFileInZip3( _zipFile,
								  (const char*) [newname UTF8String],
								  &zipInfo,
								  NULL,0,
								  NULL,0,
								  NULL,//comment
								  Z_DEFLATED,
								  Z_DEFAULT_COMPRESSION,
								  0,
								  15,
								  8,
								  Z_DEFAULT_STRATEGY,
								  [_password cStringUsingEncoding:NSASCIIStringEncoding],
								  crcValue );
	}
	if( ret!=Z_OK )
	{
		return NO;
	}
	if( data==nil )
	{
		data = [ NSData dataWithContentsOfFile:file];
	}
	unsigned int dataLen = (int)[data length];
	ret = rdZipWriteInFileInZip( _zipFile, (const void*)[data bytes], dataLen);
	if( ret!=Z_OK )
	{
		return NO;
	}
	ret = rdZipCloseFileInZip( _zipFile );
	if( ret!=Z_OK )
		return NO;
	return YES;
}

-(BOOL) RDCloseZipFile2
{
	_password = nil;
	if( _zipFile==NULL )
		return NO;
	BOOL ret =  rdZipClose( _zipFile,NULL )==Z_OK?YES:NO;
	_zipFile = NULL;
	return ret;
}

-(BOOL) RDUnzipOpenFile:(NSString*) zipFile
{///var/mobile/Containers/Data/Application/C6F58EB3-30E2-4A59-B4FE-4C77F6A5AC9C/Library/Caches/SubtitleEffect/Subtitle/icon.zipp
	_unzFile = rdUnzOpen( (const char*)[zipFile UTF8String] );
	if( _unzFile )
	{
		unz_global_info  globalInfo = {0};
		if( rdUnzGetGlobalInfo(_unzFile, &globalInfo )==UNZ_OK )
		{
			NSLog(@"%@",[NSString stringWithFormat:@"%ld entries in the zip file",globalInfo.number_entry]);
		}
	}
	return _unzFile!=NULL;
}

-(BOOL) RDUnzipOpenFile:(NSString*) zipFile Password:(NSString*) password
{
	_password = password;
    
	return [self RDUnzipOpenFile:zipFile];
}

- (void)changeProgressTime{
    dispatch_async(dispatch_get_main_queue(), ^{
//        NSLog(@"%d",_fileIndex);
        _progressBlock(_fileIndex/((float)_fileCounts*2));//解压时会多一个"__MACOSX"文件夹
    });
}
-(BOOL) RDUnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite completionProgress:(void (^)(float progress))completionProgress
{
    _progressBlock = completionProgress;
    _fileIndex = 0;
    
    BOOL success = YES;
    int ret = rdUnzGoToFirstFile( _unzFile );
    unsigned char		buffer[4096] = {0};
    NSFileManager* fman = [NSFileManager defaultManager];
    if( ret!=UNZ_OK )
    {
        [self OutputErrorMessage:@"Failed"];
    }
    
    do{
        if( [_password length]==0 )
            ret = rdUnzOpenCurrentFile( _unzFile );
        else
            ret = rdUnzOpenCurrentFilePassword( _unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding] );
        if( ret!=UNZ_OK )
        {
            [self OutputErrorMessage:@"Error occurs"];
            success = NO;
            break;
        }
        // reading data and write to file
        int read ;
        unz_file_info	fileInfo ={0};
        ret = rdUnzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
        if( ret!=UNZ_OK )
        {
            [self OutputErrorMessage:@"Error occurs while getting file info"];
            success = NO;
            rdUnzCloseCurrentFile( _unzFile );
            break;
        }
        char* filename = (char*) malloc( fileInfo.size_filename +1 );
        rdUnzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
        filename[fileInfo.size_filename] = '\0';
        
        // check if it contains directory
        NSString * strPath = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
        BOOL isDirectory = NO;
        if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
            isDirectory = YES;
        free( filename );
        if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
        {// contains a path
            strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
        }
        _fileIndex ++;
        NSString* fullPath = [path stringByAppendingPathComponent:strPath];
        
        if( isDirectory )
            [fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
        else
            [fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
        if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
        {
            if( ![self OverWrite:fullPath] )
            {
                rdUnzCloseCurrentFile( _unzFile );
                ret = rdUnzGoToNextFile( _unzFile );
                continue;
            }
        }
        FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
        while( fp )
        {
            read=rdUnzReadCurrentFile(_unzFile, buffer, 4096);
            if( read > 0 )
            {
                fwrite(buffer, read, 1, fp );
            }
            else if( read<0 )
            {
                [self OutputErrorMessage:@"Failed to reading zip file"];
                break;
            }
            else
                break;
        }
        if( fp )
        {
            fclose( fp );
            // set the orignal datetime property
            NSDate* orgDate = nil;
            
            //{{ thanks to brad.eaton for the solution
            NSDateComponents *dc = [[NSDateComponents alloc] init];
            
            dc.second = fileInfo.tmu_date.tm_sec;
            dc.minute = fileInfo.tmu_date.tm_min;
            dc.hour = fileInfo.tmu_date.tm_hour;
            dc.day = fileInfo.tmu_date.tm_mday;
            dc.month = fileInfo.tmu_date.tm_mon+1;
            dc.year = fileInfo.tmu_date.tm_year;
            
            NSCalendar *gregorian = [[NSCalendar alloc]
                                     initWithCalendarIdentifier:NSCalendarIdentifierGregorian];//NSGregorianCalendar
            
            orgDate = [gregorian dateFromComponents:dc] ;
            [dc release];
            [gregorian release];
            //}}
            
            
            NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate]; //[[NSFileManager defaultManager] fileAttributesAtPath:fullPath traverseLink:YES];
            if( attr )
            {
                //		[attr  setValue:orgDate forKey:NSFileCreationDate];
                if( ![[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:fullPath error:nil] )
                {
                    // cann't set attributes 
                    NSLog(@"Failed to set attributes");
                }
                
            }
        }
        if([[[fullPath pathExtension] lowercaseString] isEqualToString:@"webp"] && ![fullPath containsString:@"__MACOSX"]) {
            [self webpToPng:fullPath];
        }
        [self changeProgressTime];
        rdUnzCloseCurrentFile( _unzFile );
        ret = rdUnzGoToNextFile( _unzFile );
    }while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
    
    if(_progressTimer){
        [_progressTimer invalidate];
        _progressTimer = nil;
    }
    return success;
}

-(BOOL) RDUnzipFileTo:(NSString*) path overWrite:(BOOL) overwrite
{
    _fileIndex = 0;
	BOOL success = YES;
	int ret = rdUnzGoToFirstFile( _unzFile );
	unsigned char		buffer[4096] = {0};
	NSFileManager* fman = [NSFileManager defaultManager];
	if( ret!=UNZ_OK )
	{
		[self OutputErrorMessage:@"Failed"];
	}
	
	do{
        @autoreleasepool{
            
            if( [_password length]==0 )
                ret = rdUnzOpenCurrentFile( _unzFile );
            else
                ret = rdUnzOpenCurrentFilePassword( _unzFile, [_password cStringUsingEncoding:NSASCIIStringEncoding] );
            if( ret!=UNZ_OK )
            {
                [self OutputErrorMessage:@"Error occurs"];
                success = NO;
                break;
            }
            // reading data and write to file
            int read ;
            unz_file_info    fileInfo ={0};
            ret = rdUnzGetCurrentFileInfo(_unzFile, &fileInfo, NULL, 0, NULL, 0, NULL, 0);
            if( ret!=UNZ_OK )
            {
                [self OutputErrorMessage:@"Error occurs while getting file info"];
                success = NO;
                rdUnzCloseCurrentFile( _unzFile );
                break;
            }
            char* filename = (char*) malloc( fileInfo.size_filename +1 );
            rdUnzGetCurrentFileInfo(_unzFile, &fileInfo, filename, fileInfo.size_filename + 1, NULL, 0, NULL, 0);
            filename[fileInfo.size_filename] = '\0';
            
            // check if it contains directory
            NSString * strPath = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
            BOOL isDirectory = NO;
            if( filename[fileInfo.size_filename-1]=='/' || filename[fileInfo.size_filename-1]=='\\')
                isDirectory = YES;
            free( filename );
            if( [strPath rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/\\"]].location!=NSNotFound )
            {// contains a path
                strPath = [strPath stringByReplacingOccurrencesOfString:@"\\" withString:@"/"];
            }
            NSString* fullPath = [path stringByAppendingPathComponent:strPath];
            
            if( isDirectory )
                [fman createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];
            else
                [fman createDirectoryAtPath:[fullPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            if( [fman fileExistsAtPath:fullPath] && !isDirectory && !overwrite )
            {
                if( ![self OverWrite:fullPath] )
                {
                    rdUnzCloseCurrentFile( _unzFile );
                    ret = rdUnzGoToNextFile( _unzFile );
                    continue;
                }
            }
            FILE* fp = fopen( (const char*)[fullPath UTF8String], "wb");
            while( fp )
            {
                read=rdUnzReadCurrentFile(_unzFile, buffer, 4096);
                if( read > 0 )
                {
                    fwrite(buffer, read, 1, fp );
                }
                else if( read<0 )
                {
                    [self OutputErrorMessage:@"Failed to reading zip file"];
                    break;
                }
                else
                    break;
            }
            if( fp )
            {
                fclose( fp );
                // set the orignal datetime property
                NSDate* orgDate = nil;
                
                //{{ thanks to brad.eaton for the solution
                NSDateComponents *dc = [[NSDateComponents alloc] init];
                
                dc.second = fileInfo.tmu_date.tm_sec;
                dc.minute = fileInfo.tmu_date.tm_min;
                dc.hour = fileInfo.tmu_date.tm_hour;
                dc.day = fileInfo.tmu_date.tm_mday;
                dc.month = fileInfo.tmu_date.tm_mon+1;
                dc.year = fileInfo.tmu_date.tm_year;
                
                NSCalendar *gregorian = [[NSCalendar alloc]
                                         initWithCalendarIdentifier:NSCalendarIdentifierGregorian];//NSGregorianCalendar
                
                orgDate = [gregorian dateFromComponents:dc] ;
                [dc release];
                [gregorian release];
                //}}
                
                
                NSDictionary* attr = [NSDictionary dictionaryWithObject:orgDate forKey:NSFileModificationDate]; //[[NSFileManager defaultManager] fileAttributesAtPath:fullPath traverseLink:YES];
                if( attr )
                {
                    //        [attr  setValue:orgDate forKey:NSFileCreationDate];
                    if( ![[NSFileManager defaultManager] setAttributes:attr ofItemAtPath:fullPath error:nil] )
                    {
                        // cann't set attributes
                        NSLog(@"Failed to set attributes");
                    }
                    
                }
            }
            if([[[fullPath pathExtension] lowercaseString] isEqualToString:@"webp"] && ![fullPath containsString:@"__MACOSX"]) {
                [self webpToPng:fullPath];
            }
            rdUnzCloseCurrentFile( _unzFile );
            ret = rdUnzGoToNextFile( _unzFile );
            
        }
	}while( ret==UNZ_OK && UNZ_OK!=UNZ_END_OF_LIST_OF_FILE );
	return success;
}

- (void)webpToPng:(NSString *)webpPath {
    @autoreleasepool {
#if 0
        
        NSFileManager* fman = [NSFileManager defaultManager];
        NSError *error = nil;
        [UIImage rd_sd_imageWithWebP:webpPath completionBlock:^(UIImage *result) {
            NSData *pngData;
            @try {
               // pngData =  [UIImage rd_sd_imageToWebP:result quality:100];
                pngData = UIImagePNGRepresentation(result);
            }@catch (NSException *exception) {
                NSLog(@"exception: %@",exception);
            }
            NSError *error;
            if (pngData) {
                if ([pngData writeToFile:[[webpPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"] options:NSAtomicWrite error:&error])
                {
                    [fman removeItemAtPath:webpPath error:&error];
                }else {
                    NSLog(@"%@", error.localizedDescription);
                }
            }else {
                NSLog(@"");
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"webp to png failed");
        }];
        
#else
        NSFileManager* fman = [NSFileManager defaultManager];
        NSError *error = nil;
        UIImage *result = [UIImage rd_sd_imageWithWebP:webpPath error:&error];
         if (error) {
         NSLog(@"%@", error.localizedDescription);
         }else{
             NSData *pngData;
             @try {
                 pngData =  UIImagePNGRepresentation(result);
             }@catch (NSException *exception) {
                     NSLog(@"exception: %@",exception);
             }
             result = nil;
             if (pngData) {
                 if ([pngData writeToFile:[[webpPath stringByDeletingPathExtension] stringByAppendingPathExtension:@"png"] options:NSAtomicWrite error:&error])
                 {
                     [fman removeItemAtPath:webpPath error:&error];
                 }else {
                     NSLog(@"%@", error.localizedDescription);
                 }
             }else {
                 NSLog(@"");
             }
             
        }
#endif
    }
}

- (UIImage*)drawImage:(UIImage *)image{
    float width=0;
    float height;
    height = image.size.height;
    width = image.size.width;
    CGSize size = CGSizeMake(width, height);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    UIGraphicsGetCurrentContext();
    float x=0;
    [image drawInRect:CGRectMake(x,0,width,size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
    
}

-(BOOL) RDUnzipCloseFile
{
	_password = nil;
	if( _unzFile )
		return rdUnzClose( _unzFile )==UNZ_OK;
	return YES;
}

#pragma mark wrapper for delegate
-(void) OutputErrorMessage:(NSString*) msg
{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(ErrorMessage:)] )
            [_delegate ErrorMessage:msg];
    }
    
}

-(BOOL) OverWrite:(NSString*) file
{
    if(_delegate){
        if([_delegate respondsToSelector:@selector(OverWriteOperation:)] )
            return [_delegate OverWriteOperation:file];
    }
    
	return YES;
}

#pragma mark get NSDate object for 1980-01-01
-(NSDate*) Date1980
{
	NSDateComponents *comps = [[NSDateComponents alloc] init];
	[comps setDay:1];
	[comps setMonth:1];
	[comps setYear:1980];
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSCalendarIdentifierGregorian];//NSGregorianCalendar
	NSDate *date = [gregorian dateFromComponents:comps];
	
	[comps release];
	[gregorian release];
	return date;
}


@end


