#include "MacHelp.h"

#include <QFileInfo>

#import <Carbon/Carbon.h>
#import <Cocoa/Cocoa.h>

void PrepareDefcoinNuMacLaunchState()
{
    @autoreleasepool {
        NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"ApplePersistenceIgnoreState"];
        [defaults setBool:NO forKey:@"NSQuitAlwaysKeepsWindows"];
        [defaults setBool:NO forKey:@"NSWindowRestoresWorkspaceAtLaunch"];
        [defaults synchronize];

        NSArray<NSURL*>* libraryURLs = [[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory
                                                                              inDomains:NSUserDomainMask];
        NSURL* libraryURL = [libraryURLs firstObject];
        if (!libraryURL) {
            return;
        }

        NSURL* savedStateURL = [[libraryURL URLByAppendingPathComponent:@"Saved Application State" isDirectory:YES]
            URLByAppendingPathComponent:@"org.defcoincore.DefcoinCoreNu.savedState"
                            isDirectory:YES];
        [[NSFileManager defaultManager] removeItemAtURL:savedStateURL error:nil];

        NSURL* temporarySavedStateURL =
            [NSURL fileURLWithPath:[NSTemporaryDirectory()
                                       stringByAppendingPathComponent:@"org.defcoincore.DefcoinCoreNu.savedState"]
                       isDirectory:YES];
        [[NSFileManager defaultManager] removeItemAtURL:temporarySavedStateURL error:nil];
    }
}

void ActivateDefcoinNuMacApplication()
{
    @autoreleasepool {
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp unhide:nil];
        [NSApp activateIgnoringOtherApps:YES];
    }
}

bool OpenDefcoinNuHelpBook(const QString& page)
{
    @autoreleasepool {
        NSURL* helpBookURL = [[NSBundle mainBundle] URLForResource:@"DefcoinCoreNu" withExtension:@"help"];
        if (helpBookURL) {
            AHRegisterHelpBookWithURL((__bridge CFURLRef)helpBookURL);
        }
        NSBundle* bundle = [NSBundle mainBundle];
        [[NSHelpManager sharedHelpManager] registerBooksInBundle:bundle];
        const QString clean_page =
            QFileInfo(page.trimmed().isEmpty() ? QStringLiteral("index.html") : page.trimmed()).fileName();
        NSString* anchor = clean_page == QStringLiteral("details.html") ? @"details" : @"index";
        NSString* path = clean_page == QStringLiteral("details.html") ? @"details.html" : @"index.html";
        NSString* bookTitle = @"Defcoin Core Nu Help";
        NSString* bookID = @"org.defcoincore.DefcoinCoreNu.help";

        OSStatus status =
            AHGotoPage((__bridge CFStringRef)bookTitle, (__bridge CFStringRef)path, (__bridge CFStringRef)anchor);
        if (status == noErr) {
            return true;
        }

        status = AHLookupAnchor((__bridge CFStringRef)bookTitle, (__bridge CFStringRef)anchor);
        if (status == noErr) {
            return true;
        }

        [[NSHelpManager sharedHelpManager] openHelpAnchor:anchor inBook:bookTitle];

        NSString* escapedAnchor =
            [anchor stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString* escapedBookID =
            [bookID stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString* urlString = [NSString stringWithFormat:@"help:anchor=%@ bookID=%@", escapedAnchor, escapedBookID];
        NSURL* helpURL = [NSURL URLWithString:urlString];
        if (helpURL && [[NSWorkspace sharedWorkspace] openURL:helpURL]) {
            return true;
        }
    }
    return false;
}
