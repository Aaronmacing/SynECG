#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "BluetoothCommandManager.h"
#import "ECGDecodeManager.h"
#import "SynAlarmOperationModel.h"
#import "LineView.h"
#import "SDBManager.h"
#import "ZYFMDB.h"
#import "JX_GCDTimerManager.h"
#import "libSynECG.h"
#import "lineChartShow.h"
#import "SynECG.h"
#import "SynECGBlueManager.h"
#import "SynWaveformManager.h"
#import "ECGBreathUpload.h"
#import "ECGEnergryManager.h"
#import "ECGErrorCodeUpload.h"
#import "ECGHRManager.h"
#import "ECGRRManager.h"
#import "HADeviceStatusManager.h"
#import "HAEventManager.h"
#import "HeartBeatModel.h"
#import "SportDataManager.h"
#import "SynAlarmUploadManager.h"
#import "SynWaterUploadManager.h"
#import "crypt.h"
#import "ioapi.h"
#import "mztools.h"
#import "unzip.h"
#import "zip.h"
#import "NSString+EnumSynEcg.h"
#import "RequestManager.h"
#import "SynConstant.h"
#import "SynECGLibSingleton.h"
#import "SynECGUtils.h"
#import "ZipArchive.h"
#import "XLBallLoading.h"

FOUNDATION_EXPORT double SynECGVersionNumber;
FOUNDATION_EXPORT const unsigned char SynECGVersionString[];

