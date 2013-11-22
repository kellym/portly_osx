//
//  Alert.h
//  port
//
//  Created by Kelly Martin on 5/5/13.
//  Copyright (c) 2013 Kelly Martin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Alert : NSObject {
  NSResponder *delegate;
  NSAlert *alert;
}

@property(nonatomic, weak) NSResponder *delegate;
- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
- (void) alert: (NSString *)messageTitle defaultButton:(NSString *)defaultButtonTitle alternateButton:(NSString *)alternateButtonTitle otherButton:(NSString *)otherButtonTitle informativeTextWithFormat:(NSString *)informativeText  window: (NSWindow *)window delegate: (NSResponder *)delegate;
@end

