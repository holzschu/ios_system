#import <Foundation/Foundation.h>

// Stub implementation for display_alert to avoid linker errors.
// This function is declared in ios_system.m but usually implemented by the host app.
// We provide a default implementation that logs to console.
void display_alert(NSString* title, NSString* message) {
    NSLog(@"[IOSSystem Alert] %@: %@", title, message);
}
