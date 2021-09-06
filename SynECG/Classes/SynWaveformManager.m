//
//  SynWaveformManager.m
//  SynECG
//
//  Created by LiangXiaobin on 2018/3/14.
//  Copyright © 2018年 LiangXiaobin. All rights reserved.
//

#import "SynWaveformManager.h"

#import "RequestManager.h"
#import "SynECGLibSingleton.h"
#import "SynConstant.h"
#import <UIKit/UIKit.h>
#import "SynECGUtils.h"
#import "ZipArchive.h"
#import "zlib.h"


@interface SynWaveformManager()
@property(nonatomic,copy)NSString *recordId;
@property(nonatomic,copy)NSString *sourcePath;
@property (nonatomic,strong) NSTimer *timer;
@property(nonatomic,strong) NSFileHandle *ecgOutFile;
@property(nonatomic,assign) NSInteger nowPoint;

@end

@implementation SynWaveformManager

+(instancetype)sharedInstance
{
    static SynWaveformManager * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[SynWaveformManager alloc] init];
    });
    return sharedInstance;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *docDir = [paths objectAtIndex:0];
        _sourcePath = [docDir stringByAppendingPathComponent:[NSString stringWithFormat:@"synCache"]];
        _recordId = [[NSString alloc]init];
        
        _timer = [NSTimer  timerWithTimeInterval:0.5 target:self selector:@selector(readAndAnalyticalData) userInfo:nil repeats:YES];
        [ _timer setFireDate:[NSDate distantFuture]];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        
        _nowPoint = 0;
        
        [self deleteECGFilesOutDays:30];
        
    }
    return self;
}


- (void)openFileWithRecordId:(NSString *)recordId;
{
    
    _recordId = recordId;
    NSString *path = [self.sourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",recordId]];
    NSString *path1 = [self.sourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",recordId]];
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:path1])
    {
        if(self.ecgOutFile == nil)
        {
            self.ecgOutFile = [NSFileHandle fileHandleForUpdatingAtPath:path1];
            
        }
        else
        {
            [self.ecgOutFile closeFile];
            self.ecgOutFile = [NSFileHandle fileHandleForUpdatingAtPath:path1];
        }
        _nowPoint = 0;
    }
    else
    {
        if ([fileManager fileExistsAtPath:path])
        {
            
            if(self.ecgOutFile == nil)
            {
                [self uZipArchive];
            }
            else
            {
                [self.ecgOutFile closeFile];
                [self uZipArchive];
            }
            _nowPoint = 0;
        }
        else
        {
            if (_delegate && [_delegate respondsToSelector:@selector(syn_waveformStateChangedTo:)]) {
                [_delegate syn_waveformStateChangedTo:SynWFStateNoFile];
            }
        }
    }
}

-(void)uZipArchive
{
     //创建解压缩对象
     ZipArchive *zip = [[ZipArchive alloc]init];
     //Caches路径
    NSString *cachesPath = NSTemporaryDirectory();
    
    //解压目标路径
     NSString *savePath =[cachesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",self.recordId]];
    
    //zip压缩包的路径
    NSString *path = [self.sourcePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip",self.recordId]];
    
     //解压不带密码压缩包
     [zip UnzipOpenFile:path];
     //解压带密码压缩包
     //[zip UnzipOpenFile:path Password:@"ZipArchive.zip"];
     //解压
     [zip UnzipFileTo:savePath overWrite:YES];
     //关闭解压
     BOOL success = [zip UnzipCloseFile];
    
    if (success == YES) {
        
         self.ecgOutFile = [NSFileHandle fileHandleForUpdatingAtPath:[savePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",self.recordId]]];
        
        if (self.ecgOutFile == nil) {
            
            if (_delegate && [_delegate respondsToSelector:@selector(syn_waveformStateChangedTo:)]) {
                [_delegate syn_waveformStateChangedTo:SynWFStateOpenError];
            }
        }
        else
        {
            
        }
        
        
    }
    else
    {
        [self uZipArchive];
    }
    
    
    
}





- (NSData *)getEcgData:(NSInteger)percent{
    
    if (_ecgOutFile == nil) {
        
        return nil;
    }
    else
    {
        
        [self.ecgOutFile seekToFileOffset:self.nowPoint];
        
        NSData *ecgData = [self.ecgOutFile readDataOfLength:153600];
//        NSArray *array = [self getDataArray:ecgData];
        return ecgData;
    }

}
- (void)closeFile
{
    if (self.ecgOutFile != nil) {
        
        [self.ecgOutFile closeFile];
        self.ecgOutFile = nil;
    }
}

- (NSInteger)getFileLength
{
     if (_ecgOutFile == nil) {
         return 0;
     }
    else
    {
        NSData *data = [_ecgOutFile readDataToEndOfFile];
        
        return data.length;
    }
}


- (void)jumpToPoint:(NSInteger)point;
{
    self.nowPoint = point * 2;
    
    [self readAndAnalyticalData];
}

/**
 *  开启自动
 */
- (void)openAutoPlay
{
    [ _timer setFireDate:[NSDate distantPast]];
}

/**
 *  关闭自动
 */
- (void)closeAutoPlay
{
    [ _timer setFireDate:[NSDate distantFuture]];
}


//读取和解析数据
- (void)readAndAnalyticalData
{
    if (_ecgOutFile == nil) {
        
        if (_delegate && [_delegate respondsToSelector:@selector(syn_waveformStateChangedTo:)]) {
            [_delegate syn_waveformStateChangedTo:SynWFStateOpenError];
        }
        return;
    }
    else
    {
        
        [self.ecgOutFile seekToFileOffset:self.nowPoint];
       
        NSData *ecgData = [self.ecgOutFile readDataOfLength:256 * 0.5];
        self.nowPoint = ecgData.length + self.nowPoint;
        NSArray *array = [self getDataArray:ecgData];
        
        
        if (array.count == 0) {
            
            if (_delegate && [_delegate respondsToSelector:@selector(syn_waveformStateChangedTo:)]) {
                [_delegate syn_waveformStateChangedTo:SynWFStateOver];
            }
        }
        else
        {
            if (_delegate && [_delegate respondsToSelector:@selector(syn_waveformData:)]) {
                [_delegate syn_waveformData:array];
            }
        }
    }
}

- (unsigned long long)getFileSize
{
    unsigned long long size = 0;
    
    // 文件管理者
    NSFileManager *mgr = [NSFileManager defaultManager];
    
    // 是否为文件夹
    BOOL isDirectory = NO;
    
    // 路径是否存在
    BOOL exists = [mgr fileExistsAtPath:self.sourcePath isDirectory:&isDirectory];
    if (!exists) return size;
    
    if (isDirectory) { // 文件夹
        // 获得文件夹的大小  == 获得文件夹中所有文件的总大小
        NSDirectoryEnumerator *enumerator = [mgr enumeratorAtPath:self.sourcePath];
        for (NSString *subpath in enumerator) {
            // 全路径
            NSString *fullSubpath = [self.sourcePath stringByAppendingPathComponent:subpath];
            // 累加文件大小
            size += [mgr attributesOfItemAtPath:fullSubpath error:nil].fileSize;
        }
    } else { // 文件
        size = [mgr attributesOfItemAtPath:self.sourcePath error:nil].fileSize;
    }
    
    return size;
    
}



- (void)deleteECGFilesOutDays:(NSInteger)days
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *myDirectoryEnumerator = [fileManager enumeratorAtPath:self.sourcePath];  //baseSavePath 为文件夹的路径
    NSString *file;
    
    while((file = [myDirectoryEnumerator nextObject]))     //遍历当前目录
    {

        if([[file pathExtension] isEqualToString:@"zip"])  //取得后缀名为.dat的文件名
        {
            
            NSError *error = nil;
            NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:[self.sourcePath stringByAppendingPathComponent:file] error:&error];
            NSDate *fileCreateDate = [fileAttributes objectForKey:NSFileCreationDate];
            NSDate *nowDate = [NSDate date];
            NSTimeInterval delta = [nowDate timeIntervalSinceDate:fileCreateDate];
            
            if (delta >= days * 24 * 60 * 60) {
                
                [self removeFileWith:[self.sourcePath stringByAppendingPathComponent:file]];
            }
        }
    }
}



- (void)deleteECGFiles
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *myDirectoryEnumerator = [fileManager enumeratorAtPath:self.sourcePath];  //baseSavePath 为文件夹的路径
    NSString *file;
    
    while((file = [myDirectoryEnumerator nextObject]))     //遍历当前目录
    {
        if(![[file stringByDeletingPathExtension] isEqualToString:[SynECGLibSingleton sharedInstance].record_id])  //取得后缀名为.dat的文件名
        {
            [self removeFileWith:[self.sourcePath stringByAppendingPathComponent:file]];
        }
    }
}




//删除文件
- (void)removeFileWith:(NSString *)path
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:path]) {
        
        BOOL succeed = [fileManager removeItemAtPath:path error:nil];
        if (!succeed) {
            [self removeFileWith:path];
        }
    }
}


-(NSArray*)getDataArray:(NSData *)data{
    NSMutableArray *array = [NSMutableArray new];
    

    Byte *c = (Byte*)[data bytes];
    for (int i = 0; i<data.length; i+=2) {
        short  a = (((c[i] & 0xff) << 8) | (c[i+1] & 0xff));
        float d = a/2048.f;
        [array addObject:[NSNumber numberWithFloat:d]];
    }
    
    return array;
}

- (int16_t)readShort:(NSData*)data {
    int32_t ch1 = [self read:data];
    int32_t ch2 = [self read1:data];
    if ((ch1 | ch2) < 0){
        @throw [NSException exceptionWithName:@"Exception" reason:@"EOFException" userInfo:nil];
    }
    return (int16_t)((ch1 << 8) + (ch2 << 0));
}

- (int32_t)read:(NSData*)data{
    int8_t v;
    [data getBytes:&v range:NSMakeRange(0,1)];
    return ((int32_t)v & 0x0ff);
}
- (int32_t)read1:(NSData*)data{
    int8_t v;
    [data getBytes:&v range:NSMakeRange(1,1)];
    return ((int32_t)v & 0x0ff);
}

@end
