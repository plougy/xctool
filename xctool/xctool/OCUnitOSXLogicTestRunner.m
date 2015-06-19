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


#import "OCUnitOSXLogicTestRunner.h"

#import "TaskUtil.h"
#import "TestingFramework.h"
#import "XCToolUtil.h"
#import "XcodeBuildSettings.h"

@implementation OCUnitOSXLogicTestRunner

- (NSMutableDictionary *)environmentOverrides
{
  NSMutableDictionary *environment = OSXTestEnvironment(_buildSettings);
  [environment addEntriesFromDictionary:@{
    @"OBJC_DISABLE_GC" : !_garbageCollection ? @"YES" : @"NO",
  }];
  return environment;
}

- (NSTask *)otestTaskWithTestBundle:(NSString *)testBundlePath
{
  NSTask *task = CreateTaskInSameProcessGroup();

  [task setLaunchPath:[XcodeDeveloperDirPath() stringByAppendingPathComponent:_framework[kTestingFrameworkOSXTestrunnerName]]];

  // When invoking otest directly, the last arg needs to be the the test bundle.
  [task setArguments:[[self testArguments] arrayByAddingObject:testBundlePath]];
  NSMutableDictionary *env = [self environmentOverrides];
  env[@"DYLD_INSERT_LIBRARIES"] = [XCToolLibPath() stringByAppendingPathComponent:@"otest-shim-osx.dylib"];
  [task setEnvironment:[self otestEnvironmentWithOverrides:env]];
  return task;
}

- (void)runTestsAndFeedOutputTo:(void (^)(NSString *))outputLineBlock
                   startupError:(NSString **)startupError
                    otherErrors:(NSString **)otherErrors
{
  NSAssert([_buildSettings[Xcode_SDK_NAME] hasPrefix:@"macosx"], @"Should be a macosx SDK.");

  NSString *testBundlePath = [_simulatorInfo productBundlePath];
  BOOL bundleExists = [[NSFileManager defaultManager] fileExistsAtPath:testBundlePath];

  if (IsRunningUnderTest()) {
    // If we're running under test, pretend the bundle exists even if it doesn't.
    bundleExists = YES;
  }

  if (bundleExists) {
    @autoreleasepool {
      NSTask *task = [self otestTaskWithTestBundle:testBundlePath];
      // For OSX test bundles only, Xcode will chdir to the project's directory.
      NSString *projectDir = _buildSettings[Xcode_PROJECT_DIR];
      if (projectDir) {
        [task setCurrentDirectoryPath:projectDir];
      }

      LaunchTaskAndFeedOuputLinesToBlock(task,
                                         @"running otest/xctest on test bundle",
                                         outputLineBlock);
    }
  } else {
    *startupError = [NSString stringWithFormat:@"Test bundle not found at: %@", testBundlePath];
  }
}

@end
