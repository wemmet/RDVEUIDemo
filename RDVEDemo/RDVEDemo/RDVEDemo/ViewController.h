//
//  ViewController.h
//  RDVEDemo
//
//  Created by wuxiaoxia on 2017/7/15.
//  Copyright © 2017年 北京锐动天地信息技术有限公司. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RDVEUISDK.h"

typedef NS_ENUM(NSInteger, FunctionType){
    FunctionType_RDRecord           = 0,    //录制/拍照
//    FunctionType_DouYinRecord,              //抖音录制
    FunctionType_VideoEdit,                 //视频编辑
    FunctionType_PictureMovie,              //照片电影
    FunctionType_CreativeVideo,             //创意搞怪小视频
    FunctionType_Doge,                      //多格
    FunctionType_ShortVideo,                //短视频
    FunctionType_SelectAlbum,               //相册
    FunctionType_SmallFunctions,            //小功能
    FunctionType_SoundEffect,               //音效处理
    FunctionType_Trapezium,                 //不规则四边形示例 
    FunctionType_Heteromorphic,             //异形示例（mask）
    
    FunctionType_VideoTrim,                 //视频截取
    FunctionType_VideoCompression,          //视频压缩
};

@interface ViewController : UIViewController<UITableViewDelegate,UITableViewDataSource,UITextFieldDelegate,RDVEUISDKDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    //相机设置
    UIView          *_cameraSettingView;
    UIScrollView    *_cameraSettingScrollview;
    //编辑设置
    UIView          *_editSettingView;
    UIScrollView    *_editSettingScrollView;
    //截取设置
    UIView          *_specifyCutSettingView;
    UIScrollView    *_specifyCutsettingScrollView;
    //相册设置
    UIView          *_selectPhotoSettingView;
    UIScrollView    *_photoAlbumSettingScrollView;
    //压缩设置
    UIView          *_compressSettingView;
    AVURLAsset      *_compressAsset;
    
    
    //编辑设置
    NSMutableArray          *_functionList;
    UITableView             *_functionListTable;
    
    //记录每个设置项
    ConfigData                *_rdVEEditSDKConfigData;
    ConfigData                *_rdVETrimSDKConfigData;
    ConfigData                *_rdVECameraSDKConfigData;
    ConfigData                *_rdVESelectAlbumSDKConfigData;
    
    NSString                    *_compressOutputPath;//压缩文件的保存路径
    //记录进入设置之前的状态
    EditConfiguration       *_oldEditConfig;
    CameraConfiguration     *_oldCameraConfig;
    ExportConfiguration     *_oldExportConfig;
    UIInterfaceOrientation  _deviceOrientation;
    
    RDCutVideoReturnType    _cutVideoRetrunType;
    RDCutVideoReturnType    _cutVideoRetrunTypeOld;
}

@end

