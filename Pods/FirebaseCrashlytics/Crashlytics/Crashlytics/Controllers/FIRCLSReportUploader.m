// Copyright 2019 Google
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "Interop/Analytics/Public/FIRAnalyticsInterop.h"

#import "Crashlytics/Crashlytics/Components/FIRCLSApplication.h"
#import "Crashlytics/Crashlytics/Controllers/FIRCLSAnalyticsManager.h"
#import "Crashlytics/Crashlytics/Controllers/FIRCLSManagerData.h"
#import "Crashlytics/Crashlytics/Controllers/FIRCLSReportUploader_Private.h"
#import "Crashlytics/Crashlytics/DataCollection/FIRCLSDataCollectionToken.h"
#import "Crashlytics/Crashlytics/Helpers/FIRCLSDefines.h"
#import "Crashlytics/Crashlytics/Models/FIRCLSFileManager.h"
#import "Crashlytics/Crashlytics/Models/FIRCLSInstallIdentifierModel.h"
#import "Crashlytics/Crashlytics/Models/FIRCLSInternalReport.h"
#import "Crashlytics/Crashlytics/Models/FIRCLSSymbolResolver.h"
#import "Crashlytics/Crashlytics/Models/Record/FIRCLSReportAdapter.h"
#import "Crashlytics/Crashlytics/Operations/Reports/FIRCLSProcessReportOperation.h"

#include "Crashlytics/Crashlytics/Helpers/FIRCLSUtility.h"

#import "Crashlytics/Shared/FIRCLSConstants.h"
#import "Crashlytics/Shared/FIRCLSNetworking/FIRCLSMultipartMimeStreamEncoder.h"
#import "Crashlytics/Shared/FIRCLSNetworking/FIRCLSURLBuilder.h"

#import <GoogleDataTransport/GoogleDataTransport.h>

@interface FIRCLSReportUploader () {
  id<FIRAnalyticsInterop> _analytics;
}

@property(nonatomic, strong) GDTCORTransport *googleTransport;
@property(nonatomic, strong) FIRCLSInstallIdentifierModel *installIDModel;

@property(nonatomic, readonly) NSString *googleAppID;

@end

@implementation FIRCLSReportUploader

- (instancetype)initWithManagerData:(FIRCLSManagerData *)managerData {
  self = [super init];
  if (!self) {
    return nil;
  }

  _operationQueue = managerData.operationQueue;
  _googleAppID = managerData.googleAppID;
  _googleTransport = managerData.googleTransport;
  _installIDModel = managerData.installIDModel;
  _fileManager = managerData.fileManager;
  _analytics = managerData.analytics;

  return self;
}

#pragma mark - Packaging and Submission

/*
 * For a crash report, this is the initial code path for uploading. A report
 * will not repeat this code path after it's happened because this code path
 * will move the report from the "active" folder into "processing" and then
 * "prepared". Once in prepared, the report can be re-uploaded any number of times
 * with uploadPackagedReportAtPath in the case of an upload failure.
 */
- (void)prepareAndSubmitReport:(FIRCLSInternalReport *)report
           dataCollectionToken:(FIRCLSDataCollectionToken *)dataCollectionToken
                      asUrgent:(BOOL)urgent
                withProcessing:(BOOL)shouldProcess {
  if (![dataCollectionToken isValid]) {
    FIRCLSErrorLog(@"Data collection disabled and report will not be submitted");
    return;
  }

  // This activity is still relevant using GoogleDataTransport because the on-device
  // symbolication operation may be computationally intensive.
  FIRCLSApplicationActivity(
      FIRCLSApplicationActivityDefault, @"Crashlytics Crash Report Processing", ^{
        // Run this only once because it can be run multiple times in succession,
        // and if it's slow it could delay crash upload too much without providing
        // user benefit.
        static dispatch_once_t regenerateOnceToken;
        dispatch_once(&regenerateOnceToken, ^{
          // Check to see if the FID has rotated before we construct the payload
          // so that the payload has an updated value.
          [self.installIDModel regenerateInstallIDIfNeeded];
        });

        // Run on-device symbolication before packaging if we should process
        if (shouldProcess) {
          if (![self.fileManager moveItemAtPath:report.path
                                    toDirectory:self.fileManager.processingPath]) {
            FIRCLSErrorLog(@"Unable to move report for processing");
            return;
          }

          // adjust the report's path, and process it
          [report setPath:[self.fileManager.processingPath
                              stringByAppendingPathComponent:report.directoryName]];

          FIRCLSSymbolResolver *resolver = [[FIRCLSSymbolResolver alloc] init];

          FIRCLSProcessReportOperation *processOperation =
              [[FIRCLSProcessReportOperation alloc] initWithReport:report resolver:resolver];

          [processOperation start];
        }

        // With the new report endpoint, the report is deleted once it is written to GDT
        // Check if the report has a crash file before the report is moved or deleted
        BOOL isCrash = report.isCrash;

        // For the new endpoint, just move the .clsrecords from "processing" -> "prepared".
        // In the old endpoint this was for packaging the report as a multipartmime file,
        // so this can probably be removed for GoogleDataTransport.
        if (![self.fileManager moveItemAtPath:report.path
                                  toDirectory:self.fileManager.preparedPath]) {
          FIRCLSErrorLog(@"Unable to move report to prepared");
          return;
        }

        NSString *packagedPath = [self.fileManager.preparedPath
            stringByAppendingPathComponent:report.path.lastPathComponent];

        FIRCLSInfoLog(@"[Firebase/Crashlytics] Packaged report with id '%@' for submission",
                      report.identifier);

        [self uploadPackagedReportAtPath:packagedPath
                     dataCollectionToken:dataCollectionToken
                                asUrgent:urgent];

        // We don't check for success here for 2 reasons:
        //   1) If we can't upload a crash for whatever reason, but we can upload analytics
        //      it's better for the customer to get accurate Crash Free Users.
        //   2) In the past we did try to check for success, but it was a useless check because
        //      sendDataEvent is async (unless we're sending urgently).
        if (isCrash) {
          [FIRCLSAnalyticsManager logCrashWithTimeStamp:report.crashedOnDate.timeIntervalSince1970
                                            toAnalytics:self->_analytics];
        }
      });

  return;
}

/*
 * This code path can be repeated any number of times for a prepared crash report if
 * the report is failing to upload.
 *
 * Therefore, side effects (like logging to Analytics) should not go in this method or
 * else they will re-trigger when failures happen.
 *
 * When a crash report fails to upload, it will stay in the "prepared" folder. Upon next
 * run of the app, the ReportManager will attempt to re-upload prepared reports using this
 * method.
 */
- (void)uploadPackagedReportAtPath:(NSString *)path
               dataCollectionToken:(FIRCLSDataCollectionToken *)dataCollectionToken
                          asUrgent:(BOOL)urgent {
  FIRCLSDebugLog(@"Submitting report %@", urgent ? @"urgently" : @"async");

  if (![dataCollectionToken isValid]) {
    FIRCLSErrorLog(@"A report upload was requested with an invalid data collection token.");
    return;
  }

  FIRCLSReportAdapter *adapter = [[FIRCLSReportAdapter alloc] initWithPath:path
                                                               googleAppId:self.googleAppID
                                                            installIDModel:self.installIDModel];

  GDTCOREvent *event = [self.googleTransport eventForTransport];
  event.dataObject = adapter;
  event.qosTier = GDTCOREventQoSFast;  // Bypass batching, send immediately

  dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

  [self.googleTransport
      sendDataEvent:event
         onComplete:^(BOOL wasWritten, NSError *error) {
           if (!wasWritten) {
             FIRCLSErrorLog(
                 @"Failed to send crash report due to failure writing GoogleDataTransport event");
             return;
           }

           if (error) {
             FIRCLSErrorLog(@"Failed to send crash report due to GoogleDataTransport error: %@",
                            error.localizedDescription);
             return;
           }

           FIRCLSInfoLog(@"Completed report submission with id: %@", path.lastPathComponent);

           if (urgent) {
             dispatch_semaphore_signal(semaphore);
           }

           [self cleanUpSubmittedReportAtPath:path];
         }];

  if (urgent) {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
  }
}

- (BOOL)cleanUpSubmittedReportAtPath:(NSString *)path {
  if (![[self fileManager] removeItemAtPath:path]) {
    FIRCLSErrorLog(@"Unable to remove packaged submission");
    return NO;
  }

  return YES;
}

@end
