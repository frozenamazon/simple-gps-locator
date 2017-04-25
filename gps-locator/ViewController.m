//
//  ViewController.m
//  gps-locator
//
//  Created by Lisa Lau on 20/04/2017.
//  Copyright © 2017 Lisa Lau. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "CLLocation+Strings.h"

double const kTimeout = 100;

@interface ViewController ()
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (nonatomic, strong) CLLocation *bestEffortAtLocation;
@property (weak, nonatomic) IBOutlet UITextField *coordX;
@property (weak, nonatomic) IBOutlet UITextField *coordY;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    _errorLabel.text = @"";
}

- (void) viewDidAppear:(BOOL)animated {
    if (![CLLocationManager locationServicesEnabled]) {
        // location services is disabled, alert user
        UIAlertController *servicesDisabledAlert = [UIAlertController
                                                    alertControllerWithTitle:NSLocalizedString(@"DisabledTitle", @"DisabledTitle")
                                                    message:NSLocalizedString(@"DisabledMessage", @"DisabledMessage")
                                                    preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* OkButton = [UIAlertAction
                                   actionWithTitle: NSLocalizedString(@"OKButtonTitle", @"OKButtonTitle")
                                   style: UIAlertActionStyleDefault
                                   handler: nil];
        
        [servicesDisabledAlert addAction: OkButton];
        [self presentViewController:servicesDisabledAlert animated:YES completion:nil];
    }
}

- (IBAction)onFetchCoordinatesClick:(id)sender {
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    [self.locationManager startUpdatingLocation];
    
    [self performSelector:@selector(stopUpdatingLocationWithMessage:)
               withObject:@"Timed Out"
               afterDelay:kTimeout];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    // test the age of the location measurement to determine if the measurement is cached
    // in most cases you will not want to rely on cached measurements
    //
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) {
        return;
    }
    
    // test that the horizontal accuracy does not indicate an invalid measurement
    if (newLocation.horizontalAccuracy < 0) {
        return;
    }
    
    // test the measurement to see if it is more accurate than the previous measurement
    if (self.bestEffortAtLocation == nil || self.bestEffortAtLocation.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // store the location as the "best effort"
        _bestEffortAtLocation = newLocation;
        
        // test the measurement to see if it meets the desired accuracy
        //
        // IMPORTANT!!! kCLLocationAccuracyBest should not be used for comparison with location coordinate or altitidue
        // accuracy because it is a negative value. Instead, compare against some predetermined "real" measure of
        // acceptable accuracy, or depend on the timeout to stop updating. This sample depends on the timeout.
        //
        if (newLocation.horizontalAccuracy <= self.locationManager.desiredAccuracy) {
            // we have a measurement that meets our requirements, so we can stop updating the location
            //
            // IMPORTANT!!! Minimize power usage by stopping the location manager as soon as possible.
            //
            [self stopUpdatingLocationWithMessage:NSLocalizedString(@"Acquired Location", @"Acquired Location")];
            [self setCoordinates];
            // we can also cancel our previous performSelector:withObject:afterDelay: - it's no longer necessary
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocationWithMessage:) object:nil];
        }
    }
    
    
    
}

- (void)setCoordinates {
    _coordX.text= self.bestEffortAtLocation.localizedCoordinateString;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // The location "unknown" error simply means the manager is currently unable to get the location.
    // We can ignore this error for the scenario of getting a single location fix, because we already have a
    // timeout that will stop the location manager to save power.
    //
    if ([error code] != kCLErrorLocationUnknown) {
        //Handle error if failed to get location
        [self stopUpdatingLocationWithMessage:NSLocalizedString(@"Error", @"Error")];
    }
}

- (void)stopUpdatingLocationWithMessage:(NSString *)state {
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    _errorLabel.text = state;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
