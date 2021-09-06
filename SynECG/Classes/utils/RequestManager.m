//
//  RequestManager.m
//  libSynECG
//
//  Created by LiangXiaobin on 16/6/29.
//  Copyright © 2016年 LiangXiaobin. All rights reserved.
//

#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGLibSingleton.h"

@implementation RequestManager

+ (instancetype)sharedInstance
{
    static RequestManager * sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[RequestManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _manager = [AFHTTPSessionManager manager];
        AFSecurityPolicy *securityPolicy = [AFSecurityPolicy defaultPolicy];
        securityPolicy.allowInvalidCertificates = YES;
        securityPolicy.validatesDomainName = NO;
        
        _manager.securityPolicy = securityPolicy;
        [_manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        _manager.requestSerializer = [AFJSONRequestSerializer serializer];
        _manager.requestSerializer.timeoutInterval = 10;
        
        AFHTTPResponseSerializer * responseSerializer = [AFHTTPResponseSerializer serializer];
        responseSerializer.acceptableContentTypes = nil;
        _manager.responseSerializer = responseSerializer;
    }
    return self;
}


-(void)handleFailBlock:(CommonBlockCompletion)failBlock
                 error:(NSError *)error
      publishIfNoBlock:(int)errorCode
               message:(id)msg
{
    @autoreleasepool {
        
        if (failBlock)
        {
            //把非服务器错误转成错误消息格式
            if (errorCode != 10001) {
                
                NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                [dic setObject:[NSNumber numberWithInt:911] forKey:@"status"];
                [dic setObject:[NSNumber numberWithInteger:911] forKey:@"errorCode"];
                [dic setObject:msg forKey:@"errorMessage"];
                [dic setObject:msg forKey:@"message"];
                [result setObject:dic forKey:@"result"];
                
                failBlock(result);
                return;
            }
            
            failBlock(msg);
            return;
        }

    }
}

//处理请求完成
-(void)handleCallback:(id)response
         onCompletion:(CommonBlockCompletion)completionBlock
               onFail:(CommonBlockCompletion)failBlock
{
    @autoreleasepool {
        
        if (!completionBlock) return;
        
        //解析JSON
        NSError *error;
        NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:response
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&error];
        if (error) {
            completionBlock(nil);
        }
        
        if (jsonData && [jsonData[@"result"][@"status"] integerValue] == 1) {
            
            completionBlock(jsonData);
            return ;
        }else
        {
            
            [self handleFailBlock:failBlock
                            error:nil
                 publishIfNoBlock:10001
                          message:jsonData];
            return;
        }

    }
  }

- (void)postParameters:(NSDictionary *)params Url:(NSString *)url sucessful:(CommonBlockCompletion)success failure:(CommonBlockCompletion)failure;
{
  
        if ([RequestManager isNetworkReachable] == NO) {
            
             dispatch_async(dispatch_get_main_queue(), ^{
            
                NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                [dic setObject:[NSNumber numberWithInteger:111] forKey:@"status"];
                [dic setObject:[NSNumber numberWithInteger:111] forKey:@"errorCode"];
                [dic setObject:@"网络连接中断" forKey:@"errorMessage"];
                [dic setObject:@"网络连接中断" forKey:@"message"];
                [result setObject:dic forKey:@"result"];
                failure(result);
                return;
             });
            
        }
        NSString *all_url = [NSString stringWithFormat:@"%@",url];
        if ([url hasPrefix:@"http"] || [url hasPrefix:@"https"]) {
            
        }
        else
        {
            all_url = [NSString stringWithFormat:@"%@%@",[SynECGLibSingleton sharedInstance].baseurl,url];
        }
    
    
  
        [self.manager.requestSerializer setValue:[SynECGLibSingleton sharedInstance].token forHTTPHeaderField:@"Authorization"];

    
    
        
         BlockWeakSelf(self);
        [self.manager POST:all_url parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            //响应处理
             [weakSelf handleCallback:responseObject onCompletion:success onFail:failure];
        
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            //错误处理
            [weakSelf handleFailBlock:failure error:error publishIfNoBlock:-1 message:error.localizedDescription];
        
        }];

}

- (void)downloadWithUrl:(NSString *)urlStr sucessful:(CommonBlockCompletion)success failure:(CommonBlockCompletion)failure downloadProgress:(void (^)(NSProgress *downloadProgress))progress;
{
    
    if ([RequestManager isNetworkReachable] == NO) {
        
        NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
        [dic setObject:[NSNumber numberWithInteger:0] forKey:@"status"];
        [dic setObject:@"0" forKey:@"errorCode"];
        [dic setObject:@"网络连接中断" forKey:@"errorMessage"];
        [dic setObject:@"网络连接中断" forKey:@"message"];
        [result setObject:dic forKey:@"result"];
        failure(result);
        return;
    }
    //NSURL
    NSURL *url = [NSURL URLWithString:urlStr];
    //2.NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30.0];
    

    
    NSString *fileName = [urlStr lastPathComponent];
    NSString *tmpDir =  NSTemporaryDirectory();
    NSString *path = [tmpDir stringByAppendingPathComponent:fileName];
    
    AFURLSessionManager *dsession = [[AFURLSessionManager alloc]initWithSessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    
    NSURLSessionDownloadTask *downLoad = [dsession downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        progress(downloadProgress);
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        
        
        return [NSURL fileURLWithPath:path];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if(error)
        {
            failure(error.localizedDescription);
        }
        else
        {
            success([NSURL fileURLWithPath:path]);
        }
        
        
    }];
    
    //4.因为任务默认是挂起状态，需要恢复任务（执行任务）
    [downLoad resume];
    

}

- (void)uploadWithUrl:(NSString *)url parameters:(NSDictionary *)params fileUrl:(NSString *)fileUrl name:(NSString *)name  sucessful:(CommonBlockCompletion)success failure:(CommonBlockCompletion)failure
{
    
    @autoreleasepool {
        
        if ([RequestManager isNetworkReachable] == NO) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSMutableDictionary *result = [[NSMutableDictionary alloc]init];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
                [dic setObject:[NSNumber numberWithInteger:111] forKey:@"status"];
                [dic setObject:[NSNumber numberWithInteger:111]  forKey:@"errorCode"];
                [dic setObject:@"网络连接中断" forKey:@"errorMessage"];
                [dic setObject:@"网络连接中断" forKey:@"message"];
                [result setObject:dic forKey:@"result"];
                failure(result);
                return;
            });
        }
        NSString *all_url = [NSString stringWithFormat:@"%@%@",[SynECGLibSingleton sharedInstance].baseurl,url];
        
        // 2.创建请求
        [self.manager.requestSerializer setValue:[SynECGLibSingleton sharedInstance].token forHTTPHeaderField:@"Authorization"];

        BlockWeakSelf(self);
        
        [self.manager POST:all_url parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            NSURL *fileURL = [NSURL fileURLWithPath:fileUrl];
            [formData appendPartWithFileURL:fileURL name:name error:NULL];
            
        } progress:^(NSProgress * _Nonnull uploadProgress) {
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            //响应处理
          [weakSelf handleCallback:responseObject onCompletion:success onFail:failure];
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            //错误处理
            [weakSelf handleFailBlock:failure error:error publishIfNoBlock:-1 message:error.localizedDescription];
        }];

        
        
        
//        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:all_url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:25.0];
//        if (request == nil) {
//            return;
//        }
//        [request setHTTPMethod:@"POST"];
//        
//        [request  setValue:[NSString stringWithFormat:@"SYNAUTH7 %@",[SynECGLibSingleton sharedInstance].token]  forHTTPHeaderField:@"Authorization"];
//        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
//        
//        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",@"boundary"];
//        
//        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
//        // 3.拼接表单，大小受MAX_FILE_SIZE限制(2MB)  FilePath:要上传的本地文件路径  formName:表单控件名称，应于服务器一致
//        //文件参数
//        NSMutableData *data = [NSMutableData dataWithData:[self getHttpBodyWithFilePath:fileUrl formName:name reName:[fileUrl lastPathComponent] with:params]];
//        
//        request.HTTPBody = data;
//        
//        // 根据需要是否提供，非必须,如果不提供，session会自动计算
//        //    [request setValue:[NSString stringWithFormat:@"%lu",data.length] forHTTPHeaderField:@"Content-Length"];
//        
//        
//        // 4. 使用dataTask
//     NSURLSessionDataTask *task =[session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//            if (error == nil) {
//                [self handleCallback:data onCompletion:success onFail:failure];
//            } else {
//                [self handleFailBlock:failure error:error publishIfNoBlock:-1 message:error.localizedDescription];
//            }
//     }];
//        [task resume];
//        [session finishTasksAndInvalidate];
    }
}

/// filePath:要上传的文件路径   formName：表单控件名称  reName：上传后文件名
- (NSData *)getHttpBodyWithFilePath:(NSString *)filePath formName:(NSString *)formName reName:(NSString *)reName with:(NSDictionary *)params
{
    NSMutableData *data = [NSMutableData data];
    NSURLResponse *response = [self getLocalFileResponse:filePath];
    // 文件类型：MIMEType  文件的大小：expectedContentLength  文件名字：suggestedFilename
    NSString *fileType = response.MIMEType;
    
    // 如果没有传入上传后文件名称,采用本地文件名!
    if (reName == nil) {
        reName = response.suggestedFilename;
    }
    
    // 表单拼接
    [data appendData:[self yyEncode:@"--boundary\r\n"]];
    // name：表单控件名称  filename：上传文件名
    // name : 指定参数名(必须跟服务器端保持一致)
    // filename : 文件名
    NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=%@; filename=%@\r\n",formName,reName];
    [data appendData:[self yyEncode:disposition]];
    NSString *type = [NSString stringWithFormat:@"Content-Type: %@\r\n",fileType];
    [data appendData:[self yyEncode:type]];
    [data appendData:[self yyEncode:@"\r\n"]];
     //文件内容
    NSData *fileData = [NSData dataWithContentsOfFile:filePath];
    [data appendData:fileData];
    [data appendData:[self yyEncode:@"\r\n"]];
    
    
    /***************普通参数***************/
    [params enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        @autoreleasepool {
         
            // 参数开始的标志
            [data appendData:[self yyEncode:@"--boundary\r\n"]];
            NSString *disposition = [NSString stringWithFormat:@"Content-Disposition: form-data; name=%@\r\n", key];
            [data appendData:[self yyEncode:disposition]];
            
            [data appendData:[self yyEncode:@"\r\n"]];
            [data appendData:[self yyEncode:obj]];
            [data appendData:[self yyEncode:@"\r\n"]];
        }
    }];

    NSMutableString *footerStrM = [NSMutableString stringWithFormat:@"--%@--\r\n",@"boundary"];
    [data appendData:[footerStrM  dataUsingEncoding:NSUTF8StringEncoding]];
    //    NSLog(@"dataStr=%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    return data;
}

/// 获取响应，主要是文件类型和文件名
- (NSURLResponse *)getLocalFileResponse:(NSString *)urlString
{
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
    // 本地文件请求
    NSURL *url = [NSURL fileURLWithPath:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    __block NSURLResponse *localResponse = nil;
    // 使用信号量实现NSURLSession同步请求
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        localResponse = response;
        dispatch_semaphore_signal(semaphore);
    }] resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return  localResponse;
}




/*
 只要请求的地址是HTTPS的, 就会调用这个代理方法
 我们需要在该方法中告诉系统, 是否信任服务器返回的证书
 Challenge: 挑战 质问 (包含了受保护的区域)
 protectionSpace : 受保护区域
 NSURLAuthenticationMethodServerTrust : 证书的类型是 服务器信任
 */
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential *))completionHandler
{
    //    NSLog(@"didReceiveChallenge %@", challenge.protectionSpace);
   // NSLog(@"调用了最外层");
    // 1.判断服务器返回的证书类型, 是否是服务器信任
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        //NSLog(@"调用了里面这一层是服务器信任的证书");
        /*
         NSURLSessionAuthChallengeUseCredential = 0,                     使用证书
         NSURLSessionAuthChallengePerformDefaultHandling = 1,            忽略证书(默认的处理方式)
         NSURLSessionAuthChallengeCancelAuthenticationChallenge = 2,     忽略书证, 并取消这次请求
         NSURLSessionAuthChallengeRejectProtectionSpace = 3,            拒绝当前这一次, 下一次再询问
         */
        //        NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
        
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        completionHandler(NSURLSessionAuthChallengeUseCredential , card);
    }
}

- (NSData *)yyEncode:(id)str
{
    if ([str isKindOfClass:[NSString class]]) {
        
     return [str dataUsingEncoding:NSUTF8StringEncoding];
    }
    else
    {
        return [[str stringValue] dataUsingEncoding:NSUTF8StringEncoding];
    }
    
}

//网络监听
+ (BOOL) isNetworkReachable{
    
    if([AFNetworkReachabilityManager sharedManager].networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable)
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


@end
