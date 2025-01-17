/*
 * This source file was modified from sample Syphon Examples
 * Software written by Jared Bruni https://github.com/lostjared
 
 This software is dedicated to all the people that experience mental illness.
 
 Website: http://lostsidedead.com
 YouTube: http://youtube.com/LostSideDead
 Instagram: http://instagram.com/lostsidedead
 Twitter: http://twitter.com/jaredbruni
 Facebook: http://facebook.com/LostSideDead0x
 
 You can use this program free of charge and redistrubute it online as long
 as you do not charge anything for this program. This program is meant to be
 100% free.
 
 BSD 2-Clause License
 
 Copyright (c) 2020, Jared Bruni
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 */
#import <Cocoa/Cocoa.h>
#import <Syphon/Syphon.h>
#import "AC_Renderer.h"
#import "AC_ImageView.h"
#import "SimpleImageView.h"


@interface AC_AppDelegate : NSObject <NSApplicationDelegate, NSUserNotificationCenterDelegate,NSWindowDelegate> {
    NSWindow *window;
    AC_ImageView *glView;
    SyphonServer *syServer;
    AC_Renderer *renderer;
    NSTimer *lameRenderingTimer;
    NSUInteger FPS;
    NSTimeInterval fpsStart;
    NSUInteger fpsCount;
    GCController *game_controller;
    IBOutlet NSBox *the_box;
    IBOutlet NSTextField *the_box_text;
    
}

@property (assign) IBOutlet SimpleImageView *view;
@property (readwrite, retain) NSArray *selectedServerDescriptions;
@property (readonly) NSString *status; // "frameWidth x frameHeight : FPS" or "--" if no
@property (readwrite, assign) NSUInteger FPS;
@property (readwrite, assign) NSUInteger frameWidth;
@property (readwrite, assign) NSUInteger frameHeight;
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet AC_ImageView* glView;
@property (retain) NSNotificationCenter *center;
@property (assign) IBOutlet SimpleImageView *image_view;


- (IBAction) open:(id)sender;
- (IBAction) listen_for:(id)sender;
@end
