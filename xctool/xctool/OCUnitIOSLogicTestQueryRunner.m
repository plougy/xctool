//
// Copyright 2013 Facebook
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "OCUnitIOSLogicTestQueryRunner.h"

#import "SimulatorInfo.h"
#import "TaskUtil.h"
#import "XCToolUtil.h"
#import "XcodeBuildSettings.h"

@implementation OCUnitIOSLogicTestQueryRunner

- (NSTask *)createTaskForQuery
{
  NSMutableDictionary *environment = IOSTestEnvironment(_simulatorInfo.buildSettings);
  [environment addEntriesFromDictionary:@{
    @"DYLD_INSERT_LIBRARIES" : [XCToolLibPath() stringByAppendingPathComponent:@"otest-query-lib-ios.dylib"],
    // The test bundle that we want to query from, as loaded by otest-query-lib-ios.dylib.
    @"OtestQueryBundlePath" : [_simulatorInfo productBundlePath],
    @"__CFPREFERENCES_AVOID_DAEMON" : @"YES",
  }];

  return CreateTaskForSimulatorExecutable(
    _simulatorInfo.buildSettings[Xcode_SDK_NAME],
    _simulatorInfo,
    [XCToolLibExecPath() stringByAppendingPathComponent:@"otest-query-ios"],
    @[],
    environment
  );
}

@end
