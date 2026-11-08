/*
 * padbridge - HID dance pad -> keyboard bridge for OutFox on macOS.
 *
 * Why this exists: OutFox's macOS input layer enumerates this pad
 * (0x0079:0x0011 "USB Gamepad") but receives no button events. A user-level
 * IOHIDManager does receive them, and CGEventPost from an SSH session reaches
 * the game. This bridge reads the pad and posts arrow/function keys, bypassing
 * OutFox's joystick handling entirely.
 *
 * Button map (verified on the OSTENT mat, bcdDevice 0x0106):
 *   usage 1 = Up, 2 = Down, 3 = Left, 4 = Right
 *   usage 8 = Enter (Start)
 *   usage 9 = Escape (Back)
 *   usage 10 = Enter (Start)
 *   all other usages are intentionally INERT.
 *
 * Never map to F1-F5 or other system keys: on macOS F3/F4 open
 * Mission Control/Launchpad, which is what was throwing players out of
 * the game. Unused pad buttons must do nothing.
 *
 * Build:
 *   clang -framework IOKit -framework CoreFoundation \
 *         -framework ApplicationServices -o padbridge padbridge.c
 */
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/hid/IOHIDManager.h>
#include <ApplicationServices/ApplicationServices.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static const CGKeyCode kmap[15] = {
    0,    /* 0  unused */
    126,  /* 1  Up */
    125,  /* 2  Down */
    123,  /* 3  Left */
    124,  /* 4  Right */
    0,    /* 5  inert */
    0,    /* 6  inert */
    0,    /* 7  inert */
    36,   /* 8  Enter (Start) */
    0,    /* 9  inert (was Escape/Back -> ejected players from the app) */
    36,   /* 10 Enter (Start) */
    0,    /* 11 inert */
    0,    /* 12 inert */
    0,    /* 13 inert */
    0     /* 14 inert */
};

static void removal_cb(void *ctx, IOReturn res, void *sender, IOHIDDeviceRef device)
{
    printf("padbridge device removed; exiting so launchd can reopen it\n");
    fflush(stdout);
    exit(0);
}

static void value_cb(void *ctx, IOReturn res, void *sender, IOHIDValueRef value)
{
    IOHIDElementRef el = IOHIDValueGetElement(value);
    if (IOHIDElementGetUsagePage(el) != 0x09) {
        return;
    }
    uint32_t usage = IOHIDElementGetUsage(el);
    CFIndex down = IOHIDValueGetIntegerValue(value);
    printf("usage=%u value=%ld key=%u\n", usage, (long)down,
           usage < 15 ? kmap[usage] : 0);
    fflush(stdout);

    if (usage < 15) {
        CGKeyCode key = kmap[usage];
        if (key) {
            /* Start (usages 8/10) must be a TAP, not a held key. If Enter stays
             * held while the 1P/2P screen transitions, the song screen sees the
             * still-held Start and launches immediately ("autostart"), so the
             * player never gets to pick a difficulty. Posting a short down+up
             * gives the game a clean tap; release events are ignored. Arrows
             * stay true held inputs (needed for gameplay). */
            if (usage == 8 || usage == 10) {
                if (down) {
                    CGEventRef d = CGEventCreateKeyboardEvent(NULL, key, true);
                    CGEventPost(kCGHIDEventTap, d);
                    CFRelease(d);
                    usleep(40000); /* 40 ms tap */
                    CGEventRef u = CGEventCreateKeyboardEvent(NULL, key, false);
                    CGEventPost(kCGHIDEventTap, u);
                    CFRelease(u);
                }
                return;
            }
            CGEventRef event = CGEventCreateKeyboardEvent(NULL, key, down != 0);
            CGEventPost(kCGHIDEventTap, event);
            CFRelease(event);
        }
    }
}

int main(void)
{
    IOHIDManagerRef manager =
        IOHIDManagerCreate(kCFAllocatorDefault, kIOHIDOptionsTypeNone);

    int vendor = 0x0079;
    int product = 0x0011;
    CFNumberRef vendor_ref =
        CFNumberCreate(NULL, kCFNumberIntType, &vendor);
    CFNumberRef product_ref =
        CFNumberCreate(NULL, kCFNumberIntType, &product);

    CFMutableDictionaryRef match = CFDictionaryCreateMutable(
        NULL, 0, &kCFTypeDictionaryKeyCallBacks,
        &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(match, CFSTR(kIOHIDVendorIDKey), vendor_ref);
    CFDictionarySetValue(match, CFSTR(kIOHIDProductIDKey), product_ref);

    IOHIDManagerSetDeviceMatching(manager, match);
    IOHIDManagerRegisterDeviceRemovalCallback(manager, removal_cb, NULL);
    IOHIDManagerRegisterInputValueCallback(manager, value_cb, NULL);
    IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetCurrent(),
                                    kCFRunLoopDefaultMode);

    IOReturn rc = IOHIDManagerOpen(manager, kIOHIDOptionsTypeNone);
    printf("padbridge open=0x%x uid=%d\n", rc, (int)getuid());
    fflush(stdout);

    CFRunLoopRun();
    return 0;
}
