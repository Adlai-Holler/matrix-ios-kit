/*
 Copyright 2015 OpenMarket Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "MXKRegistrationWebView.h"

// Generic method to make a bridge between JS and the UIWebView
NSString *kMXKJavascriptSendObjectMessage = @"window.matrixRegistration.sendObjectMessage = function(parameters) {   \
var iframe = document.createElement('iframe');                              \
iframe.setAttribute('src', 'js:' + JSON.stringify(parameters));             \
\
document.documentElement.appendChild(iframe);                               \
iframe.parentNode.removeChild(iframe);                                      \
iframe = null;                                                              \
};";

// The function the fallback page calls when the registration is complete
NSString *kMXKJavascriptOnRegistered = @"window.matrixRegistration.onRegistered = function(homeserverUrl, userId, accessToken) {   \
matrixRegistration.sendObjectMessage({  \
'action': 'onRegistered',           \
'homeServer': homeserverUrl,        \
'userId': userId,                   \
'accessToken': accessToken          \
});                                     \
};";

@interface MXKRegistrationWebView ()
{
    // The block called when the registration is successful
    void (^onSuccess)(MXCredentials *);
    
    // Activity indicator
    UIActivityIndicatorView *activityIndicator;
}
@end

@implementation MXKRegistrationWebView

- (void)dealloc
{
    if (activityIndicator)
    {
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }
}

- (void)openFallbackPage:(NSString *)fallbackPage success:(void (^)(MXCredentials *))success
{
    self.delegate = self;
    onSuccess = success;
    
    // Add activity indicator
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.center = self.center;
    [self addSubview:activityIndicator];
    [activityIndicator startAnimating];
    
    [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:fallbackPage]]];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    if (activityIndicator)
    {
        [activityIndicator stopAnimating];
        [activityIndicator removeFromSuperview];
        activityIndicator = nil;
    }
    
    [self stringByEvaluatingJavaScriptFromString:kMXKJavascriptSendObjectMessage];
    [self stringByEvaluatingJavaScriptFromString:kMXKJavascriptOnRegistered];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *urlString = [[request URL] absoluteString];
    
    if ([urlString hasPrefix:@"js:"])
    {
        // Listen only to scheme of the JS-UIWebView bridge
        NSString *jsonString = [[[urlString componentsSeparatedByString:@"js:"] lastObject]  stringByReplacingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *error;
        NSDictionary *parameters = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers
                                                                     error:&error];
        
        if (!error)
        {
            if ([@"onRegistered" isEqualToString:parameters[@"action"]])
            {
                // Translate the JS registration event to MXCredentials
                MXCredentials *credentials = [[MXCredentials alloc] initWithHomeServer:parameters[@"homeServer"] userId:parameters[@"userId"] accessToken:parameters[@"accessToken"]];
                // And inform the client
                onSuccess(credentials);
            }
        }
        return NO;
    }
    return YES;
}

@end
