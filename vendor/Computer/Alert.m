#import "Alert.h"

@implementation Alert
@synthesize delegate;
- (void) alert: (NSString *)messageTitle defaultButton:(NSString *)defaultButtonTitle alternateButton:(NSString *)alternateButtonTitle otherButton:(NSString *)otherButtonTitle informativeTextWithFormat:(NSString *)informativeText  window: (NSWindow *)window delegate: (NSResponder *)delegateVal
{
  [self setDelegate: delegateVal];
  alert = [NSAlert alertWithMessageText: messageTitle defaultButton:defaultButtonTitle alternateButton:alternateButtonTitle otherButton:otherButtonTitle informativeTextWithFormat:informativeText];
  [alert beginSheetModalForWindow:nil modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo: nil];

}

- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
  if ([self delegate]) {
    if (returnCode == NSAlertDefaultReturn) {
      [[self delegate] handleAlertSuccessResponse];
    } else if (returnCode == NSAlertAlternateReturn) {
      [[self delegate] handleAlertIgnoreResponse];
    } else {
      [[self delegate] handleAlertOtherResponse];
    }
  }
  return;
}
@end


