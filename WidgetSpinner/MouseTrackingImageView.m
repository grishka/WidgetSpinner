//
//  MouseTrackingImageView.m
//  WidgetSpinner
//
//  Created by Grishka on 10.10.2024.
//  Copyright © 2024 Grishka. All rights reserved.
//

#import "MouseTrackingImageView.h"
#import "VelocityTracker.h"
#import <CoreVideo/CoreVideo.h>
#include <math.h>

typedef NSInteger CGSWindow;
typedef NSInteger CGSConnection;
extern CGSConnection _CGSDefaultConnection();
extern CGError CGSSetWindowTransform(const CGSConnection cid, const CGSWindow wid, CGAffineTransform transform);
extern OSStatus CGSGetWindowBounds(const CGSConnection cid, const CGSWindow wid, CGRect *bounds);

@implementation MouseTrackingImageView{
	CGSConnection conn;
	CGSWindow windowNumber;
	float initialAngle;
	float downAngle;
	float prevAngle;
	float lastSetAngle;
	VelocityTracker *velocityTracker;
	CVDisplayLinkRef displayLink;
	bool animationRunning;
	double animationStartTime;
	double animationPrevTime;
	bool animationStartTimeValid;
	float animationVelocity;
	float animationValue;
}
@synthesize centerImageView;

- (void)awakeFromNib{
	conn=_CGSDefaultConnection();
	initialAngle=0;
	velocityTracker=[VelocityTracker new];
	
	// TODO this doesn't work very well with multiple displays with different refresh rates
	CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
	CVDisplayLinkSetOutputCallback(displayLink, displayLinkOutputCallback, (__bridge void *)self);

	animationRunning=false;
	windowNumber=-1;
}

- (void)dealloc{
	if(animationRunning)
		CVDisplayLinkStop(displayLink);
	CVDisplayLinkRelease(displayLink);
}

- (void)setWindowRotation:(CGFloat)angleRad{
	if(windowNumber==-1){
		windowNumber=[self.window windowNumber];
	}
	lastSetAngle=angleRad;
	CGAffineTransform transform=CGAffineTransformIdentity;
	
	CGRect bounds;
	CGSGetWindowBounds(conn, windowNumber, &bounds);
	CGFloat pivotX=bounds.size.width/2.0;
	CGFloat pivotY=bounds.size.height/2.0;
	transform=CGAffineTransformTranslate(transform, pivotX, pivotY);
	transform=CGAffineTransformRotate(transform, angleRad);
	transform=CGAffineTransformTranslate(transform, -(bounds.origin.x+pivotX), -(bounds.origin.y+pivotY));
	
	CGSSetWindowTransform(conn, windowNumber, transform);
	centerImageView.layer.position=CGPointMake(centerImageView.layer.frame.origin.x+centerImageView.layer.frame.size.width/2.0, centerImageView.layer.frame.origin.y+centerImageView.layer.frame.size.height/2.0);
	centerImageView.layer.anchorPoint=CGPointMake(0.5, 0.5);
	centerImageView.layer.transform=CATransform3DMakeRotation(-angleRad, 0, 0, 1);
	
}

- (float)mouseAngle{
	NSPoint location=[NSEvent mouseLocation];
	NSRect windowFrame=self.window.frame;
	float x=location.x-(windowFrame.origin.x+windowFrame.size.width/2.0f);
	float y=location.y-(windowFrame.origin.y+windowFrame.size.height/2.0f);
	return atan2f(y, x)+M_PI;
}

- (void)mouseDown:(NSEvent *)event{
	downAngle=[self mouseAngle];
	prevAngle=downAngle;
	[velocityTracker resetTracking];
	[velocityTracker addDataPoint:downAngle atTime:event.timestamp];
	if(animationRunning){
		initialAngle=lastSetAngle;
		CVDisplayLinkStop(displayLink);
		animationRunning=false;
	}
}

- (void)mouseDragged:(NSEvent *)event{
	float angle=[self mouseAngle];
	float deltaAngle=angle-prevAngle;
	if(fabs(deltaAngle)>M_PI){
		if(deltaAngle>0)
			deltaAngle-=M_PI*2.0;
		else
			deltaAngle+=M_PI*2.0;
	}
	prevAngle=angle;
	float totalRotation=lastSetAngle+deltaAngle;
	[velocityTracker addDataPoint:totalRotation atTime:event.timestamp];
	[self setWindowRotation:totalRotation];
}

- (void)mouseUp:(NSEvent *)event{
	float angle=[self mouseAngle];
	float deltaAngle=angle-prevAngle;
	float totalRotation=lastSetAngle+deltaAngle;
	[velocityTracker addDataPoint:totalRotation atTime:event.timestamp];
	initialAngle=angle-downAngle+initialAngle;
	initialAngle-=(M_PI*2.0*((int)(initialAngle/(M_PI*2.0))));
	[self setWindowRotation:initialAngle];
	float velocity=[velocityTracker calculateVelocity];
	if(velocity!=0){
		animationVelocity=velocity;
		animationRunning=true;
		animationStartTimeValid=false;
		animationValue=initialAngle;
		CVDisplayLinkStart(displayLink);
	}
}

- (void)updateAnimation:(double)time{
	if(!animationStartTimeValid){
		animationStartTime=time;
		animationPrevTime=time-0.016f;
		animationStartTimeValid=true;
	}
	float deltaT=(float)(time-animationPrevTime);
	float friction=-4.2f*0.2f;
	
	float newVelocity=animationVelocity*expf(deltaT*friction);
	float newValue=animationValue+(newVelocity-animationVelocity)/friction;
	
	[self setWindowRotation:newValue];
	animationValue=newValue;
	animationVelocity=newVelocity;
	animationPrevTime=time;
	if(fabs(animationVelocity)<0.01f){
		animationRunning=false;
		initialAngle=animationValue;
		CVDisplayLinkStop(displayLink);
	}
}

CVReturn displayLinkOutputCallback(CVDisplayLinkRef displayLink, const CVTimeStamp *inNow, const CVTimeStamp *inOutputTime, CVOptionFlags flagsIn, CVOptionFlags *flagsOut, void *displayLinkContext){
	@autoreleasepool {
		double time=(double)inOutputTime->videoTime/inOutputTime->videoTimeScale;
		dispatch_async(dispatch_get_main_queue(), ^{
			MouseTrackingImageView *self=(__bridge MouseTrackingImageView*)displayLinkContext;
			[self updateAnimation:time];
		});
	}
	return kCVReturnSuccess;
}

@end
