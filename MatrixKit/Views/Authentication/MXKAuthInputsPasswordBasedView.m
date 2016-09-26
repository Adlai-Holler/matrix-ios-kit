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

#import "MXKAuthInputsPasswordBasedView.h"

#import "NSBundle+MatrixKit.h"

@implementation MXKAuthInputsPasswordBasedView

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([MXKAuthInputsPasswordBasedView class])
                          bundle:[NSBundle bundleForClass:[MXKAuthInputsPasswordBasedView class]]];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _userLoginTextField.placeholder = [NSBundle mxk_localizedStringForKey:@"login_user_id_placeholder"];
    _passWordTextField.placeholder = [NSBundle mxk_localizedStringForKey:@"login_password_placeholder"];
    _emailTextField.placeholder = [NSString stringWithFormat:@"%@ (%@)", [NSBundle mxk_localizedStringForKey:@"login_email_placeholder"], [NSBundle mxk_localizedStringForKey:@"login_optional_field"]];
    _emailInfoLabel.text = [NSBundle mxk_localizedStringForKey:@"login_email_info"];
    
    _displayNameTextField.placeholder = [NSBundle mxk_localizedStringForKey:@"login_display_name_placeholder"];
}

#pragma mark -

- (BOOL)setAuthSession:(MXAuthenticationSession *)authSession withAuthType:(MXKAuthenticationType)authType;
{
    if (type == MXKAuthenticationTypeLogin || type == MXKAuthenticationTypeRegister)
    {
        // Validate first the provided session
        MXAuthenticationSession *validSession = [self validateAuthenticationSession:authSession];
        
        if ([super setAuthSession:validSession withAuthType:authType])
        {
            if (type == MXKAuthenticationTypeLogin)
            {
                self.passWordTextField.returnKeyType = UIReturnKeyDone;
                self.emailTextField.hidden = YES;
                self.emailInfoLabel.hidden = YES;
                self.displayNameTextField.hidden = YES;
                
                self.viewHeightConstraint.constant = self.displayNameTextField.frame.origin.y;
            }
            else
            {
                self.passWordTextField.returnKeyType = UIReturnKeyNext;
                self.emailTextField.hidden = NO;
                self.emailInfoLabel.hidden = NO;
                self.displayNameTextField.hidden = NO;
                
                self.viewHeightConstraint.constant = 179;
            }
            
            return YES;
        }
    }
    
    return NO;
}

- (NSString*)validateParameters
{
    NSString *errorMsg = [super validateParameters];
    
    if (!errorMsg)
    {
        // Check user login and pass fields
        if (!self.areAllRequiredFieldsSet)
        {
            errorMsg = [NSBundle mxk_localizedStringForKey:@"login_invalid_param"];
        }
    }
    
    return errorMsg;
}

- (void)prepareParameters:(void (^)(NSDictionary *parameters))callback
{
    if (callback)
    {
        // Sanity check on required fields
        if (!self.areAllRequiredFieldsSet)
        {
            callback(nil);
            return;
        }
        
        // Retrieve the user login and check whether it is an email or a username.
        NSString *user = self.userLoginTextField.text;
        user = [user stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        BOOL isEmailAddress = [MXTools isEmailAddress:user];
        
        NSDictionary *parameters;
        
        if (isEmailAddress)
        {
            parameters = @{
                           @"type": kMXLoginFlowTypePassword,
                           @"medium": @"email",
                           @"address": user,
                           @"password": self.passWordTextField.text
                           };
        }
        else
        {
            parameters = @{
                           @"type": kMXLoginFlowTypePassword,
                           @"user": user,
                           @"password": self.passWordTextField.text
                           };
        }
        
        callback(parameters);
    }
}

- (BOOL)areAllRequiredFieldsSet
{
    BOOL ret = [super areAllRequiredFieldsSet];
    
    // Check user login and pass fields
    ret = (ret && self.userLoginTextField.text.length && self.passWordTextField.text.length);
    
    return ret;
}

- (void)dismissKeyboard
{
    [self.userLoginTextField resignFirstResponder];
    [self.passWordTextField resignFirstResponder];
    [self.emailTextField resignFirstResponder];
    [self.displayNameTextField resignFirstResponder];
    
    [super dismissKeyboard];
}

- (NSString*)userId
{
    return self.userLoginTextField.text;
}

- (NSString*)password
{
    return self.passWordTextField.text;
}

#pragma mark UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField.returnKeyType == UIReturnKeyDone)
    {
        // "Done" key has been pressed
        [textField resignFirstResponder];
        
        // Launch authentication now
        [self.delegate authInputsViewDidPressDoneKey:self];
    }
    else
    {
        //"Next" key has been pressed
        if (textField == self.userLoginTextField)
        {
            [self.passWordTextField becomeFirstResponder];
        }
        else if (textField == self.passWordTextField)
        {
            [self.displayNameTextField becomeFirstResponder];
        }
        else if (textField == self.displayNameTextField)
        {
            [self.emailTextField becomeFirstResponder];
        }
    }
    
    return YES;
}

#pragma mark -

- (MXAuthenticationSession*)validateAuthenticationSession:(MXAuthenticationSession*)authSession
{
    // Check whether at least one of the listed flow is supported.
    BOOL isSupported = NO;
    
    for (MXLoginFlow *loginFlow in authSession.flows)
    {
        // Check whether flow type is defined
        if ([loginFlow.type isEqualToString:kMXLoginFlowTypePassword])
        {
            isSupported = YES;
            break;
        }
        else if (loginFlow.stages.count == 1 && [loginFlow.stages.firstObject isEqualToString:kMXLoginFlowTypePassword])
        {
            isSupported = YES;
            break;
        }
    }
    
    if (isSupported)
    {
        if (authSession.flows.count == 1)
        {
            // Return the original session.
            return authSession;
        }
        else
        {
            // Keep only the supported flow.
            MXAuthenticationSession *updatedAuthSession = [[MXAuthenticationSession alloc] init];
            updatedAuthSession.session = authSession.session;
            updatedAuthSession.params = authSession.params;
            updatedAuthSession.flows = @[[MXLoginFlow modelFromJSON:@{@"stages":@[kMXLoginFlowTypePassword]}]];
            return updatedAuthSession;
        }
    }
    
    return nil;
}

@end
