//
//  ObjectTracker.h
//  Test_KCF_iPhone
//
//  Created by Tuan on 06/12/2018.
//  Copyright © 2018 Next Aeon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface KCFTrackerWrapper : NSObject

- (id) init;
- (void) setROI: (UIImage *) image roi: (CGRect) roi;
- (CGRect) update: (UIImage *) image;

@end
