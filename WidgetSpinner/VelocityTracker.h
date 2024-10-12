//
//  VelocityTracker.h
//  WidgetSpinner
//
//  Created by Grishka on 10.10.2024.
//  Copyright © 2024 Grishka. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VelocityTracker : NSObject
-(void)resetTracking;
-(void)addDataPoint:(float)data atTime:(NSTimeInterval)time;
-(float)calculateVelocity;
@end

NS_ASSUME_NONNULL_END
