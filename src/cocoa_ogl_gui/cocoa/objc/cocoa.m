/** Copyright (C) 2018,  Gavin J Stark.  All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * @file          cocoa.m
 * @brief         Ocaml stubs for Cocoa
 *
 */

/*a Documentation
 */
/*a Includes
 */
/*i Cocoa */
#include <Cocoa/Cocoa.h>
#include <OpenGL/OpenGL.h>
#include <OpenGL/gl3.h>

/*i Ocaml */
#define CAML_NAME_SPACE 
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#include <caml/memory.h>
#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/custom.h>
#include <caml/intext.h>
#include <caml/threads.h>
#include <caml/bigarray.h>

/*a Types
 */
/*f @interface for window_delegate */
@interface window_delegate : NSObject <NSWindowDelegate>
@end

/*f @interface for app_delegate */
@interface app_delegate : NSObject <NSApplicationDelegate>
@end

/*f @interface for opengl_view*/
@interface opengl_view : NSOpenGLView
{
}
- (void) timer_fired: (NSTimer *) timer;
- (void) drawRect: (NSRect) bounds;
@end

/*t t_reshape_draw enumeration - must match cocoa.m's variant type order */
typedef enum {
ReshapeDraw_Resize,
ReshapeDraw_Draw,
} t_reshape_draw ;

/*t t_app - Application structure, mallocked and t_app * is an OCAML custom object
 */
typedef struct
{
    NSApplication *ns_app;
    app_delegate *app_delegate;
    value app_id;       // Can be any OCAML object
    value create;
    value reshape_draw;
    value handle_key;
    value handle_mouse;
    value destroy;
    int ready;
} t_app;

#define t_app_of_val(v) (*((t_app **) Data_custom_val(v)))

/*t t_window - Window structure, mallocked and t_window * is an OCAML custom object
 */
typedef struct
{
    t_app *app;
    value win_id;
    NSWindow *ns_window;
    window_delegate *window_delegate;
    int width;   // window frame width
    int height;  // window frame height
    int resize_pending; // set if the frame has changed size and OCAML needs to be informed
} t_window;

#define t_window_of_val(v) (*((t_window **) Data_custom_val(v)))

/*a Useful functions */
/*f Option_ and Val_ functions (actually macros...) */
#define Val_none       Val_int(0)
#define Option_is_none(v) ((v)==Val_int(0))
#define Option_is_some(v) ((v)!=Val_int(0))
#define Option_get(v)     Field((v),0)

/*a t_app functions */
/*f app_created - app created, invoke OCAML callback closure if specified */
static void
app_created(t_app *app)
{
    if (Option_is_some(app->create)) {
        caml_callback(Option_get(app->create), app->app_id);
    }
}

/*a t_window functions */
/*f window_resize - tell OCAML a window has been resized, or remember that it needs to be told if the world is not ready */
static void
window_resize(t_window *window, int width, int height)
{
    NSLog(@"window_resize %d %d",width,height);

    if ((window->width==width) && (window->height==height) && (!window->resize_pending)) {
        return;
    }
    window->width = width;
    window->height = height;
    window->resize_pending = 1;

    if (!window->app->ready) return;

    value args [] = {window->app->app_id,
                       window->win_id,
                       Val_int(ReshapeDraw_Resize),
                       Val_int(width),
                       Val_int(height)
                       };
    if (Option_is_some(window->app->reshape_draw)) {
        window->resize_pending = 0;
        caml_callbackN(Option_get(window->app->reshape_draw),5,args);
    }
}

/*f window_draw - tell OCAML to redraw a window - the rectangle may or may not be useful */
static void
window_draw(t_window *window, NSRect rect)
{
    if (!window->app->ready) return;
    value args [] = {window->app->app_id,
                       window->win_id,
                       Val_int(ReshapeDraw_Draw),
                       Val_int(0),Val_int(0)
                       };
    if (Option_is_some(window->app->reshape_draw)) {
        caml_callbackN(Option_get(window->app->reshape_draw),5,args);
    }
    (void) rect;
}

/*a Ocaml custom functions - NYI really
 */
static void finalize_vector(value v)
{
    fprintf(stderr,"\n\n\n******************************************************************************** FINALIZE\n\n\n\n");
    (void) v;
}
static struct custom_operations custom_ops = {
    (char *)"cocoa.app",
    finalize_vector,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default
};

/*a OpenGL view subclass */
/*f @implementation of opengl_view */
@implementation opengl_view
{
    NSTimer *timer;
    t_window *window;
}

/*f frame_changed - handle a notification for when the view's frame changes */
- (void)frame_changed:(NSNotification *)__unused aNotification
{
    NSLog(@"frameDidChange");
    NSRect window_frame = [window->ns_window frame];
    NSRect content_rect = [window->ns_window contentRectForFrameRect:window_frame];
    window_resize(window, content_rect.size.width, content_rect.size.height);
}

/*f set_window - standard initialization, plus add notification handler for frame size change
 */
- (instancetype)set_window:(t_window *) window_i
{
    [[self superview]setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    window = window_i;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(frame_changed:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:self];
    return self;
}

/*f timer_fired - quick hack to have updates regularly (need the idle timer)
 */
- (void) timer_fired: (NSTimer *) __unused timer
{
	NSLog(@"timer_fired");
    [ self setNeedsDisplay: YES ] ;
}

/*f drawRect - standard method to draw a rectangle */
-(void) drawRect: (NSRect)rect	{

    window_resize(window, window->width, window->height);

	NSLog(@"drawRect %f %f %f %f",CGRectGetMinX(rect), CGRectGetMinY(rect), CGRectGetMaxX(rect), CGRectGetMaxY(rect));

    if (!timer) timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self 
                                                       selector:@selector(timer_fired:) userInfo:nil repeats:YES];

	[[self openGLContext] makeCurrentContext];

    window_draw(window, rect);

    /*b Flush - complete the draw

      If single buffered use glFlush();
      If double buffered use [ [ self openGLContext ] flushBuffer ];
      In the latter case, one may have to:
            GLint swapInt = 1;  [[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
      This makes the buffer copy happy on vertical blanking. Or possibly it makes it work at all. This is unclear.
     */
    glFlush();
}

/*f Implementation complete */
@end

/*a Window delegate
 */
/*f @implementation of window_delegate */
@implementation window_delegate
{
    t_window *window;
}

/*f init_with_id - standard initialization
 */
- (instancetype)init_with_window:(t_window *)window_i
{
    if (self = [super init]) {
        window    = window_i;
    }
    return self;
}

/*f windowDidResize - NSWindowDelegate handler for resizing; actually, not required if the OpenGL view frame handles frame change notifications
 Perhaps this would be better, but it is for a view? framedidchangenotification
- (void)windowDidResize:(NSNotification *)__unused aNotification
{
    NSRect window_frame = [window->ns_window frame];
    NSRect content_rect = [window->ns_window contentRectForFrameRect:window_frame];
    window_resize(window, content_rect.size.width, content_rect.size.height);
}
*/

/*f Implementation complete */
@end

/*a Application delegate
 */
/*f @implementation of app_delegate
 */
@implementation app_delegate
{
    t_app *app;
}

/*f init_with_app - standard initialization
 */
- (instancetype)init_with_app:(t_app *) app_i
{
    if (self = [super init]) {
        app = app_i;
    }
    return self;
}

/*f applicationWillFinishLaunching - invoked just before the application object is initialized */
- (void)applicationWillFinishLaunching:(NSNotification *)__unused notification
{
    app_created(app);
    id toplevel = [NSMenu new]; // normally has app, file, edit, etc
    id app_menu = [[NSMenu new] initWithTitle:@"App"]; // actually title is replaced by application name
    id quit     = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
    [app_menu    addItem:quit ];
    id app_menu_item = [NSMenuItem new];
    [app_menu_item setSubmenu:app_menu];
    [toplevel    addItem:app_menu_item];
    [app->ns_app setMainMenu:toplevel];
    [app->ns_app setActivationPolicy:NSApplicationActivationPolicyRegular]; // make us an app with an icon on the dock
}

/*f applicationDidFinishLaunching - invoked after the application is ready but before it has received its first event */
- (void)applicationDidFinishLaunching:(NSNotification *)__unused notification
{
    // Note that if activateIgnoringOtherApps is PRIOR to this point, the menus do not appear, but their key-bindings do work
    [app->ns_app activateIgnoringOtherApps:YES]; // Kick us off immediately
    app->ready = 1;
}

/*f Implementation complete */
@end

/*a NSApplication OCAML externs
 */
/*f cocoa_ns_application_ns_app - create an application
 */
CAMLprim value
cocoa_ns_application_ns_app(value app_id)
{
    CAMLparam1(app_id);
    NSApplication *ns_app = [NSApplication sharedApplication];

    // Malloc an app, as this lets us keep pointers in to the structure
    // We cannot keep pointers in to an Ocaml value
    t_app *app = (t_app *)malloc(sizeof(t_app));

    value r = caml_alloc_custom(&custom_ops, sizeof(t_app *), 0, 1);
    t_app_of_val(r) = app;

    app->ready = 0;
    app->ns_app = ns_app;
    app->app_id = app_id;
    caml_register_global_root(&(app->app_id));
    app->create       = Val_none;
    app->reshape_draw = Val_none;
    app->handle_key   = Val_none;
    app->handle_mouse = Val_none;
    app->destroy      = Val_none;

    app->app_delegate = [app_delegate alloc];
    [ns_app setDelegate:[(app->app_delegate) init_with_app:app]];
    CAMLreturn(r);
}

/*f cocoa_ns_application_create_window
 */
CAMLprim value cocoa_ns_application_create_window(value app, value win_id, value rect)
{
    CAMLparam3(app, win_id, rect);
    CGFloat x, y, w, h;
    x = Double_val(Field(rect, 0));
    y = Double_val(Field(rect, 1));
    w = Double_val(Field(rect, 2));
    h = Double_val(Field(rect, 3));
      
    // Malloc a window, as this lets us keep pointers in to the structure
    // We cannot keep pointers in to an Ocaml value
    t_window *window = (t_window *)malloc(sizeof(t_window));

    NSWindow *ns_window = [NSWindow alloc];
    window_delegate *win_delegate = [window_delegate alloc];

    value r = caml_alloc_custom(&custom_ops, sizeof(t_window *), 0, 1);
    t_window_of_val(r) = window;

    window->app = t_app_of_val(app);
    window->ns_window = ns_window;
    window->win_id = win_id;
    caml_register_global_root(&(window->win_id));
    window->window_delegate = win_delegate;
    window->width = 0;
    window->height = 0;
    window->resize_pending = 0;

    [ns_window initWithContentRect:NSMakeRect(x, y, w, h)
               styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable)
               backing:NSBackingStoreBuffered
               defer:NO];
    [ns_window setDelegate:[win_delegate init_with_window:window]];

    opengl_view *gl_view = [opengl_view alloc];

    // Select 24bpp latest openGL>3.2 (can be 4.x)
    NSOpenGLPixelFormatAttribute attributes [] = {
        NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)24,
        NSOpenGLPFAOpenGLProfile, NSOpenGLProfileVersion3_2Core,
        (NSOpenGLPixelFormatAttribute)0 // termination
    };

    NSOpenGLPixelFormat *pixel_format = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];

    [[gl_view initWithFrame:ns_window.frame pixelFormat:pixel_format] autorelease];
    [gl_view set_window:window];

    ns_window.contentView = gl_view;
    [ns_window display];   
    [ns_window center];
    [ns_window makeKeyAndOrderFront:nil];
    CAMLreturn(r);
}

/*f cocoa_ns_window_debug - useful for now, debug to check that we have not broken garbage collection */
CAMLprim void
cocoa_ns_window_debug(value win)
{
    CAMLparam1(win);
    t_window *window = t_window_of_val(win);
        NSLog(@"window_debug %p",(void *)window);
        NSLog(@"window_debug %p",(void *)(window->ns_window));
        NSLog(@"window_debug %p",(void *)&(window->ns_window));
    CAMLreturn0;
}

/*f cocoa_ns_application_set_callback - set (a) callback, and keep control of the closure
 */
#define SET_CALLBACK(CB) \
CAMLprim void cocoa_ns_application_set_callback_ ## CB(value app_id, value callback) \
{ CAMLparam2(app_id, callback); t_app*app=t_app_of_val(app_id); app->CB = callback; caml_register_global_root(&(app->CB)); CAMLreturn0; }

SET_CALLBACK(create)
SET_CALLBACK(reshape_draw)
SET_CALLBACK(handle_key)
SET_CALLBACK(handle_mouse)
SET_CALLBACK(destroy)

/*f cocoa_ns_application_run - run a precreated application
 */
CAMLprim void
cocoa_ns_application_run(value app)
{
    CAMLparam1(app);
    t_app *tapp = t_app_of_val(app);
    @autoreleasepool {
        [tapp->ns_app run];
    }
    CAMLreturn0;
}

