//
//  OLKiteUtils.m
//  KitePrintSDK
//
//  Created by Konstadinos Karayannis on 9/30/15.
//  Copyright © 2015 Deon Botha. All rights reserved.
//

#import "OLKiteUtils.h"
#import "OLKitePrintSDK.h"
#import "OLProductHomeViewController.h"
#ifdef OL_KITE_OFFER_APPLE_PAY
#import <Stripe/Stripe+ApplePay.h>
#endif
#import "OLPaymentViewController.h"
#import "OLKiteABTesting.h"
#import "OLCheckoutViewController.h"
#import "OLIntegratedCheckoutViewController.h"

@interface OLKitePrintSDK (Private)

+(NSString *)appleMerchantID;

#ifdef OL_KITE_OFFER_INSTAGRAM
+ (NSString *) instagramRedirectURI;
+ (NSString *) instagramSecret;
+ (NSString *) instagramClientID;
#endif

@end

@implementation OLKiteUtils

+ (NSBundle *)kiteBundle{
    return [NSBundle bundleForClass:[OLKiteViewController class]];
}

+ (NSString *)userEmail:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteVcForViewController:topVC];
    OLProductHomeViewController *homeVC = [self homeViewControllerInNavStack:topVC.navigationController.viewControllers];
    if (kiteVC) {
        return kiteVC.userEmail;
    } else if (homeVC) {
        return homeVC.userEmail;
    }
    
    return nil;
}

+ (NSString *)userPhone:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteVcForViewController:topVC];
    OLProductHomeViewController *homeVC = [self homeViewControllerInNavStack:topVC.navigationController.viewControllers];
    if (kiteVC) {
        return kiteVC.userPhone;
    } else if (homeVC) {
        return homeVC.userPhone;
    }
    
    return nil;
}

+ (BOOL)instagramEnabled{
#ifdef OL_KITE_OFFER_INSTAGRAM
    return [OLKitePrintSDK instagramSecret] && ![[OLKitePrintSDK instagramSecret] isEqualToString:@""] && [OLKitePrintSDK instagramClientID] && ![[OLKitePrintSDK instagramClientID] isEqualToString:@""] && [OLKitePrintSDK instagramRedirectURI] && ![[OLKitePrintSDK instagramRedirectURI] isEqualToString:@""];
#else
    return NO;
#endif
}

+ (BOOL)facebookEnabled{
#ifdef OL_KITE_OFFER_FACEBOOK
    return YES;
#else
    return NO;
#endif
}

+ (id<OLKiteDelegate>)kiteDelegate:(UIViewController *)topVC {
    OLKiteViewController *kiteVC = [self kiteVcForViewController:topVC];
    OLProductHomeViewController *homeVC = [self homeViewControllerInNavStack:topVC.navigationController.viewControllers];
    if (kiteVC) {
        return kiteVC.delegate;
    } else if (homeVC) {
        return homeVC.delegate;
    }
    
    return nil;
}

+ (OLProductHomeViewController *)homeViewControllerInNavStack:(NSArray *)viewControllers {
    for (UIViewController *vc in viewControllers) {
        if ([vc isMemberOfClass:[OLProductHomeViewController class]]) {
            return (OLProductHomeViewController *) vc;
        }
    }
    
    return nil;
}

#ifdef OL_KITE_OFFER_APPLE_PAY
+(BOOL)isApplePayAvailable{
    PKPaymentRequest *request = [Stripe paymentRequestWithMerchantIdentifier:[OLKitePrintSDK appleMerchantID]];
    
    return [Stripe canSubmitPaymentRequest:request];
}
#endif

+ (void)checkoutViewControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(id vc))handler{
    OLPaymentViewController *vc = [[OLPaymentViewController alloc] initWithPrintOrder:printOrder];
    handler(vc);
}

+ (void)shippingControllerForPrintOrder:(OLPrintOrder *)printOrder handler:(void(^)(OLCheckoutViewController *vc))handler{
    OLCheckoutViewController *vc;
    if ([[OLKiteABTesting sharedInstance].checkoutScreenType isEqualToString:@"Classic"]){
        vc = [[OLCheckoutViewController alloc] initWithPrintOrder:printOrder];
    }
    else{
        vc = [[OLIntegratedCheckoutViewController alloc] initWithPrintOrder:printOrder];
    }
    handler(vc);
}

+ (NSString *)reviewViewControllerIdentifierForProduct:(OLProduct *)product photoSelectionScreen:(BOOL)photoSelectionScreen{
    OLTemplateUI templateUI = product.productTemplate.templateUI;
    if (templateUI == kOLTemplateUICase){
        return @"OLCaseViewController";
    }
    else if (templateUI == kOLTemplateUIPostcard){
        return @"OLPostcardViewController";
    }
    else if (templateUI == kOLTemplateUIPoster && product.productTemplate.gridCountX == 1 && product.productTemplate.gridCountY == 1){
        return @"OLSingleImageProductReviewViewController";
    }
    else if (templateUI == kOLTemplateUIPhotobook){
        return @"OLEditPhotobookViewController";
    }
    else if (photoSelectionScreen){
        return @"PhotoSelectionViewController";
    }
    else if (templateUI == kOLTemplateUIPoster){
        return @"OLPosterViewController";
    }
    else if (templateUI == kOLTemplateUIFrame){
        return @"FrameOrderReviewViewController";
    }
    else{
        return @"OrderReviewViewController";
    }
}

+(void)reverseRowsOfPhotosInArray:(NSMutableArray*)array forProduct:(OLProduct *)product{
    NSUInteger photosPerRow = sqrt(product.quantityToFulfillOrder);
    NSUInteger numberOfRows = [array count] / photosPerRow;
    
    NSMutableArray* rows = [[NSMutableArray alloc] initWithCapacity:numberOfRows];
    for (NSUInteger rowNumber = 0; rowNumber < numberOfRows; rowNumber++){
        NSMutableArray* row = [[NSMutableArray alloc] initWithCapacity:photosPerRow];
        for (NSUInteger photoInRow = 0; photoInRow < photosPerRow; photoInRow++){
            [row addObject:array[rowNumber * photosPerRow + photoInRow]];
        }
        [rows addObject:row];
    }
    
    [array removeAllObjects];
    for (NSInteger rowNumber = numberOfRows - 1; rowNumber >= 0; rowNumber--){
        [array addObjectsFromArray:rows[rowNumber]];
    }
}

+ (OLKiteViewController *)kiteVcForViewController:(UIViewController *)theVc{
    UIViewController *vc = theVc.parentViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            return (OLKiteViewController *)vc;
            break;
        }
        else{
            vc = vc.parentViewController;
        }
    }
    vc = theVc.presentingViewController;
    while (vc) {
        if ([vc isKindOfClass:[OLKiteViewController class]]){
            return (OLKiteViewController *)vc;
            break;
        }
        else{
            vc = vc.presentingViewController;
        }
    }
    
    return nil;
}

@end
