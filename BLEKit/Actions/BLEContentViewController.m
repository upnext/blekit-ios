/*
 * Copyright (c) 2014 UP-NEXT. All rights reserved.
 * http://www.up-next.com
 *
 * Marcin Krzyżanowski <marcink@up-next.com>
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "BLEContentViewController.h"

@interface BLEContentViewController ()
@property (strong) BLEContentAction *action;
@property (strong) NSURL *url;
@end

@implementation BLEContentViewController

- (instancetype) initWithURL:(NSURL *)url action:(id <BLEAction>)action
{
    if (self = [self initWithNibName:nil bundle:nil])
    {
        self.url = url;
        self.action = action;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat yPos = self.view.frame.origin.y > 64 ?: 64.0;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, yPos, self.view.frame.size.width, self.view.frame.size.height - yPos)];
    [self.view addSubview:self.webView];
    
    // Toolbar
    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeButton setFrame:CGRectMake(0, 20, self.view.frame.size.width, 44)];
    [closeButton setTitle:NSLocalizedString(@"Close",nil) forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    [self loadURL:self.url];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) loadURL:(NSURL *)url
{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    [self.webView loadRequest:request];
}

- (void) closeButtonClicked:(id)sender
{
    id <BLEContentViewControllerDelegate> delegate = self.delegate;
    if (delegate) {
        [delegate viewController:self didPressCloseButton:sender];
    }
}

@end
