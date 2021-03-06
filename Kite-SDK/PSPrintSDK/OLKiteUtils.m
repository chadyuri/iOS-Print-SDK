//
//  Modified MIT License
//
//  Copyright (c) 2010-2017 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "OLKiteUtils.h"
#import "OLKitePrintSDK.h"
#import "OLProductHomeViewController.h"
#import "OLPaymentViewController.h"
#import "OLKiteABTesting.h"
#import "OLCheckoutViewController.h"
#import "OLKiteViewController.h"
#import "OLUserSession.h"
#import "OLPayPalWrapper.h"
#import "OLStripeWrapper.h"
#import "OLFacebookSDKWrapper.h"

@import Contacts;
@import PassKit;

@interface OLKitePrintSDK (Private)
+ (NSString *)appleMerchantID;
+ (NSString *)instagramRedirectURI;
+ (NSString *)instagramSecret;
+ (NSString *)instagramClientID;
@end

@interface OLKiteViewController (Private)
@property (strong, nonatomic) NSMutableArray *customImageProviders;
@end

@implementation OLKiteUtils

+ (NSBundle *)kiteLocalizationBundle{
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:[OLKiteViewController class]] pathForResource:@"OLKiteLocalizationResources" ofType:@"bundle"]];
}

+ (NSBundle *)kiteResourcesBundle{
#ifdef COCOAPODS
    return [NSBundle bundleWithPath:[[NSBundle bundleForClass:[OLKiteViewController class]] pathForResource:@"OLKiteResources" ofType:@"bundle"]];
#else
    return [NSBundle bundleForClass:[OLKiteViewController class]];
#endif
}

+ (NSString *)userEmail:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [OLUserSession currentSession].kiteVc;
    return kiteVC.userEmail;
}

+ (NSString *)userPhone:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [OLUserSession currentSession].kiteVc;
    return kiteVC.userPhone;
}

+ (BOOL)instagramEnabled{
    if (YES){ //Check what needs to be checked in terms of installation
        return [OLKitePrintSDK instagramSecret] && ![[OLKitePrintSDK instagramSecret] isEqualToString:@""] && [OLKitePrintSDK instagramClientID] && ![[OLKitePrintSDK instagramClientID] isEqualToString:@""] && [OLKitePrintSDK instagramRedirectURI] && ![[OLKitePrintSDK instagramRedirectURI] isEqualToString:@""];
    }
    
    return NO;
}

+ (BOOL)qrCodeUploadEnabled {
    return [OLUserSession currentSession].kiteVc.qrCodeUploadEnabled;
}

+ (BOOL)facebookEnabled{
    return [OLFacebookSDKWrapper isFacebookAvailable];
}

+ (BOOL)recentsAvailable{
    return [OLUserSession currentSession].appAssets.count == 0 && [OLUserSession currentSession].recentPhotos.count == 0;
}

+ (NSInteger)numberOfProvidersAvailable{
    NSInteger providers = 0;
    if ([self cameraRollEnabled]){
        providers++;
    }
    if ([self instagramEnabled]){
        providers++;
    }
    if ([self facebookEnabled]){
        providers++;
    }
    if ([self qrCodeUploadEnabled]){
        providers++;
    }
    if ([self recentsAvailable]){
        providers++;
    }
    providers += [OLUserSession currentSession].kiteVc.customImageProviders.count;
    
    return providers;
}

+ (BOOL)imageProvidersAvailable{
    if ([OLUserSession currentSession].kiteVc.disallowUserToAddMorePhotos){
        return NO;
    }
    
    return [self numberOfProvidersAvailable] > 0;
}

+ (BOOL)cameraRollEnabled{
    if ([OLUserSession currentSession].kiteVc.disableCameraRoll){
        return NO;
    }
    
    return YES;
}

+(BOOL)isApplePayAvailable{
    if (![OLStripeWrapper isStripeAvailable] || ![OLKitePrintSDK appleMerchantID] || [[OLKitePrintSDK appleMerchantID] isEqualToString:@""]){
        return NO;
    }
    
    //Disable Apple Pay on iOS 8 because we need the Contacts framework. There's in issue in Xcode 8.0 that doesn't include some old symbols in PassKit that crashes iOS 9 apps built with frameworks on launch. Did Not test that they crash iOS 8, but disabled to be safe.
    if (![CNContact class]){
        return NO;
    }
    return [PKPaymentAuthorizationViewController class] && [PKPaymentAuthorizationViewController canMakePaymentsUsingNetworks:[self supportedPKPaymentNetworks]];
}

+ (NSArray<NSString *> *)supportedPKPaymentNetworks {
    NSArray *supportedNetworks = @[PKPaymentNetworkAmex, PKPaymentNetworkMasterCard, PKPaymentNetworkVisa];
    if ((&PKPaymentNetworkDiscover) != NULL) {
        supportedNetworks = [supportedNetworks arrayByAddingObject:PKPaymentNetworkDiscover];
    }
    return supportedNetworks;
}

+ (BOOL)isPayPalAvailable{
    return [OLPayPalWrapper isPayPalAvailable];
}

+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(id vc))handler{
    OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:printOrder];
    handler(vc);
}

+ (void)shippingControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler{
    OLCheckoutViewController *vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    handler(vc);
}

+ (UIFont *)fontWithName:(NSString *)name size:(CGFloat)size{
    UIFont *font = [UIFont fontWithName:name size:size];
    if (!font){
        font = [UIFont systemFontOfSize:size];
    }
    
    return font;
}

+ (NSString *)reviewViewControllerIdentifierForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen{
    OLTemplateUI templateUI = product.productTemplate.templateUI;
    if (templateUI == OLTemplateUICase || templateUI == OLTemplateUIApparel){
        return @"OLCaseViewController";
    }
    else if (templateUI == OLTemplateUIPostcard){
        return @"OLPostcardViewController";
    }
    else if (templateUI == OLTemplateUIPoster && product.productTemplate.gridCountX == 1 && product.productTemplate.gridCountY == 1){
        return @"OLSingleImageProductReviewViewController";
    }
    else if (templateUI == OLTemplateUIPhotobook){
        return @"OLEditPhotobookViewController";
    }
    else if (templateUI == OLTemplateUINonCustomizable){
        return @"OLPaymentViewController";
    }
    else if (templateUI == OLTemplateUIMug){
        return @"OL3DProductViewController";
    }
    else if (photoSelectionScreen){
        return @"OLImagePickerViewController";
    }
    else if (templateUI == OLTemplateUIPoster){
        return @"OLPosterViewController";
    }
    else if (templateUI == OLTemplateUIFrame || templateUI == OLTemplateUICalendar){
        return @"FrameOrderReviewViewController";
    }
    else{
        return @"OrderReviewViewController";
    }
}

+ (BOOL)assetArrayContainsPDF:(NSArray *)array{
    for (OLAsset *asset in array){
        if (![asset isKindOfClass:[OLAsset class]]){
            continue;
        }
        if (asset.mimeType == kOLMimeTypePDF){
            return YES;
        }
    }
    
    return NO;
}

+ (void)registerDefaultsWithURL:(NSURL *)url
                        success:(void (^)(NSDictionary *defaults))success
                        failure:(void (^)(NSError *error))failure{
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    
    NSCachedURLResponse *cachedResponse = [[NSURLCache sharedURLCache] cachedResponseForRequest:request];
    if (cachedResponse.data){
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:request];
    }
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:nil];
    
    NSURLSessionDataTask *downloadTask = [session
                                          dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                              if (error){
                                                  failure(error);
                                              }
                                              else if (!((data && [(NSHTTPURLResponse *)response statusCode] >= 200 && [(NSHTTPURLResponse *)response statusCode] <= 299))){
                                                  failure([NSError errorWithDomain:@"ly.kite.remoteconfig" code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil]);
                                              }
                                              else if (data){
                                                  NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"remote.plist"]];
                                                  [data writeToURL:fileURL atomically:YES];
                                                  NSDictionary *dict = [NSDictionary dictionaryWithContentsOfURL:fileURL];
                                                  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                                  [defaults registerDefaults:dict];
                                                  [defaults synchronize];
                                                  success(dict);
                                              }
                                          }];
    [downloadTask resume];
    [session finishTasksAndInvalidate];
}

@end
