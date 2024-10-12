//
//  VelocityTracker.m
//  WidgetSpinner
//
//  Created by Grishka on 10.10.2024.
//  Copyright © 2024 Grishka. All rights reserved.
//

#import "VelocityTracker.h"
#include <math.h>
#include <stdint.h>

// Ported from https://cs.android.com/androidx/platform/frameworks/support/+/androidx-main:transition/transition/src/main/java/androidx/transition/VelocityTracker1D.java

#define HISTORY_SIZE 20
#define ASSUME_POINTER_MOVE_STOPPED_MILLIS 40
#define HORIZON_MILLIS 100

@implementation VelocityTracker{
	int index;
	int64_t timeSamples[HISTORY_SIZE];
	float dataSamples[HISTORY_SIZE];
}

- (instancetype)init{
	self = [super init];
	if (self) {
		[self resetTracking];
	}
	return self;
}

-(void)resetTracking{
	for(int i=0;i<HISTORY_SIZE;i++){
		timeSamples[i]=INT64_MIN;
		dataSamples[i]=0;
	}
}

-(void)addDataPoint:(float)data atTime:(NSTimeInterval)time{
	index=(index+1)%HISTORY_SIZE;
	timeSamples[index]=(int64_t)(time*1000);
	dataSamples[index]=data;
}

float kineticEnergyToVelocity(float kineticEnergy) {
	float sign=kineticEnergy>0 ? 1 : -1;
	return (sign * sqrtf(2 * fabs(kineticEnergy)));
}

-(float)calculateVelocity{
	int sampleCount = 0;
	int index = self->index;

	if (index == 0 && timeSamples[index] == INT64_MIN) {
		return 0; // We haven't received any data
	}

	// The sample at index is our newest sample.  If it is null, we have no samples so return.
	int64_t newestTime = timeSamples[index];

	int64_t previousTime = newestTime;

	// Starting with the most recent sample, iterate backwards while
	// the samples represent continuous motion.
	do {
		int64_t sampleTime = timeSamples[index];
		if (sampleTime == INT64_MIN) {
			break; // no point here
		}
		float age = newestTime - sampleTime;
		float delta = llabs(sampleTime - previousTime);
		previousTime = sampleTime;

		if (age > HORIZON_MILLIS || delta > ASSUME_POINTER_MOVE_STOPPED_MILLIS) {
			break;
		}

		index = (index == 0 ? HISTORY_SIZE : index) - 1;
		sampleCount++;
	} while (sampleCount < HISTORY_SIZE);

	if (sampleCount < 2) {
		return 0; // Not enough data to have a velocity
	}

	if (sampleCount == 2) {
		// Simple diff in time
		int prevIndex = self->index == 0 ? HISTORY_SIZE - 1 : self->index - 1;
		float timeDiff = timeSamples[self->index] - timeSamples[prevIndex];
		if (timeDiff == 0) {
			return 0;
		}
		float dataDiff = dataSamples[self->index] - dataSamples[prevIndex];
		return dataDiff / timeDiff * 1000;
	}

	float work = 0;
	int startIndex = (self->index - sampleCount + HISTORY_SIZE + 1) % HISTORY_SIZE;
	int endIndex = (self->index + 1 + HISTORY_SIZE) % HISTORY_SIZE;
	previousTime = timeSamples[startIndex];
	float previousData = dataSamples[startIndex];
	for (int i = (startIndex + 1) % HISTORY_SIZE; i != endIndex; i = (i + 1) % HISTORY_SIZE) {
		long time = timeSamples[i];
		long timeDelta = time - previousTime;
		if (timeDelta == 0) {
			continue;
		}
		float data = dataSamples[i];
		float vPrev = kineticEnergyToVelocity(work);
		float dataPointsDelta = data - previousData;

		float vCurr = dataPointsDelta / timeDelta;
		work += (vCurr - vPrev) * fabs(vCurr);
		if (i == startIndex + 1) {
			work = (work * 0.5f);
		}
		previousTime = time;
		previousData = data;
	}
	return kineticEnergyToVelocity(work) * 1000;
}

@end
