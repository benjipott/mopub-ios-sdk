#import "GreystripeBannerCustomEvent.h"
#import "GSMobileBannerAdView.h"
#import "GSMediumRectangleAdView.h"
#import "GSLeaderboardAdView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface MPInstanceProvider (GreystripeBanners_Spec)

- (GSBannerAdView *)buildGreystripeBannerAdViewWithDelegate:(id<GSAdDelegate>)delegate GUID:(NSString *)GUID size:(CGSize)size;

@end

SPEC_BEGIN(GreystripeBannerCustomEventSpec)

describe(@"GreystripeBannerCustomEvent", ^{
    __block id<CedarDouble, MPBannerCustomEventDelegate> delegate;
    __block GreystripeBannerCustomEvent *event;
    __block UIViewController *viewController;
    __block FakeGSBannerAdView *banner;

    beforeEach(^{
        delegate = nice_fake_for(@protocol(MPBannerCustomEventDelegate));

        event = [[[GreystripeBannerCustomEvent alloc] init] autorelease];
        event.delegate = delegate;

        viewController = [[[UIViewController alloc] init] autorelease];
        delegate stub_method("viewControllerForPresentingModalView").and_return(viewController);
    });

    it(@"should allow automatic metrics tracking", ^{
        event.enableAutomaticImpressionAndClickTracking should equal(YES);
    });

    it(@"should make the display controller available", ^{
        event.greystripeBannerDisplayViewController should equal(viewController);
    });

    describe(@"the instance provider", ^{
        __block MPInstanceProvider *provider;
        beforeEach(^{
            provider = [[[MPInstanceProvider alloc] init] autorelease];
        });

        describe(@"creating the correct Greystripe banner ad, as a function of size", ^{
            it(@"should build a GSMobileBannerAdView for the MOPUB_BANNER_SIZE", ^{
                [provider buildGreystripeBannerAdViewWithDelegate:event GUID:@"foo" size:MOPUB_BANNER_SIZE] should be_instance_of([GSMobileBannerAdView class]);
            });

            it(@"should build a GSMobileBannerAdView for the MOPUB_MEDIUM_RECT_SIZE", ^{
                [provider buildGreystripeBannerAdViewWithDelegate:event GUID:@"foo" size:MOPUB_MEDIUM_RECT_SIZE] should be_instance_of([GSMediumRectangleAdView class]);
            });

            it(@"should build a GSMobileBannerAdView for the MOPUB_LEADERBOARD_SIZE", ^{
                [provider buildGreystripeBannerAdViewWithDelegate:event GUID:@"foo" size:MOPUB_LEADERBOARD_SIZE] should be_instance_of([GSLeaderboardAdView class]);
            });

            it(@"should return nil for any other size", ^{
                [provider buildGreystripeBannerAdViewWithDelegate:event GUID:@"foo" size:CGSizeMake(123113,12)] should be_nil;
            });
        });
    });

    describe(@"when requesting an ad with a valid size", ^{
        beforeEach(^{
            banner = [[[FakeGSBannerAdView alloc] init] autorelease];
            fakeProvider.fakeGSBannerAdView = banner;
            [event requestAdWithSize:MOPUB_BANNER_SIZE customEventInfo:nil];
        });

        it(@"should tell the ad to fetch and not tell the delegate anything just yet (except to ask it for location)", ^{
            banner.didFetch should equal(YES);
            banner.GUID should equal(@"YOUR_GREYSTRIPE_GUID");
            delegate should have_received(@selector(location));
            delegate.sent_messages.count should equal(1);
        });
    });

    describe(@"when requesting an ad with an invalid size", ^{
        beforeEach(^{
            [event requestAdWithSize:CGSizeMake(1, 2) customEventInfo:nil];
        });

        it(@"should (immediately) tell the delegate that it failed", ^{
            delegate should have_received(@selector(bannerCustomEvent:didFailToLoadAdWithError:)).with(event).and_with(nil);
        });
    });
});

SPEC_END
