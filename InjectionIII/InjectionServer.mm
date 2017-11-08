//
//  InjectionServer.m
//  InjectionIII
//
//  Created by John Holdsworth on 06/11/2017.
//  Copyright © 2017 John Holdsworth. All rights reserved.
//

#import "InjectionServer.h"
#import "SignerService.h"
#import "AppDelegate.h"
#import "FileWatcher.h"
#import "Xcode.h"

@implementation InjectionServer {
    FileWatcher *fileWatcher;
}

- (void)runInBackground {
    XcodeApplication *xcode = (XcodeApplication *)[SBApplication
           applicationWithBundleIdentifier:@"com.apple.dt.Xcode"];
    XcodeWorkspaceDocument *workspace = [xcode activeWorkspaceDocument];
    NSString *projectRoot = workspace.file.path.stringByDeletingLastPathComponent;
    NSLog(@"Connection with project root: %@", projectRoot);

    // tell client app the infered project being watched
    [self writeString:projectRoot];

    [appDelegate setMenuIcon:@"InjectionOK"];

    // start up  afile watcher to write changed filenames to client app
    fileWatcher = [[FileWatcher alloc] initWithRoot:projectRoot plugin:^(NSArray *changed) {
        if (appDelegate.enableWatcher.state) {
            for (NSString *swiftSource in changed)
                [self writeString:swiftSource];
        }
    }];

    // read requests to codesign from client app
    while (NSString *dylib = [self readString])
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL response = FALSE;
            if ([dylib hasPrefix:@"SIGN "])
                response = [SignerService codesignDylib:[dylib substringFromIndex:5]];
//            if ([dylib hasPrefix:@"ERROR "])
//                [[NSAlert alertWithMessageText:@"Injection Error"
//                                 defaultButton:@"OK" alternateButton:nil otherButton:nil
//                     informativeTextWithFormat:@"%@",
//                  [dylib substringFromIndex:@"ERROR ".length]] runModal];
            [appDelegate setMenuIcon:response ? @"InjectionOK" : @"InjectionError"];
            [self writeString:response ? @"SIGNED 1" : @"SIGNED 0"];
        });
    fileWatcher = nil;

    [appDelegate setMenuIcon:@"InjectionOK"];
}

@end