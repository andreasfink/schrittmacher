//
//  SchrittmacherMetrics.h
//  schrittmacher
//
//  Created by Andreas Fink on 28.06.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>

@interface SchrittmacherMetrics : UMObject
{
    UMPrometheus                  *_prometheus;
    UMPrometheusMetric            *_metricReceivedUNK;
    UMPrometheusMetric            *_metricReceivedHOTT;
    UMPrometheusMetric            *_metricReceivedSTBY;
    UMPrometheusMetric            *_metricReceivedTREQ;
    UMPrometheusMetric            *_metricReceivedTCNF;
    UMPrometheusMetric            *_metricReceivedTREJ;
    UMPrometheusMetric            *_metricReceivedFAIL;
    UMPrometheusMetric            *_metricReceivedFOVR;
    UMPrometheusMetric            *_metricReceived2HOT;
    UMPrometheusMetric            *_metricReceived2SBY;
    UMPrometheusMetric            *_metricReceivedLHOT;
    UMPrometheusMetric            *_metricReceivedLSBY;
    UMPrometheusMetric            *_metricReceivedLUNK;
    UMPrometheusMetric            *_metricReceivedLFAI;
    UMPrometheusMetric            *_metricReceivedL2HT;
    UMPrometheusMetric            *_metricReceivedL2SB;
    UMPrometheusMetric            *_metricReceivedLRFO;
    UMPrometheusMetric            *_metricReceivedLRTO;
    
    UMPrometheusMetric            *_metricSentUNK;
    UMPrometheusMetric            *_metricSentHOTT;
    UMPrometheusMetric            *_metricSentSTBY;
    UMPrometheusMetric            *_metricSentTREQ;
    UMPrometheusMetric            *_metricSentTCNF;
    UMPrometheusMetric            *_metricSentTREJ;
    UMPrometheusMetric            *_metricSentFAIL;
    UMPrometheusMetric            *_metricSentFOVR;
    UMPrometheusMetric            *_metricSent2HOT;
    UMPrometheusMetric            *_metricSent2SBY;
    UMPrometheusMetric            *_metricsStartActionRequested;
    UMPrometheusMetric            *_metricsStopActionRequested;

}

@property(readwrite,strong) UMPrometheusMetric            *metricReceivedUNK;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedHOTT;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedSTBY;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedTREQ;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedTCNF;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedTREJ;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedFAIL;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedFOVR;
@property(readwrite,strong) UMPrometheusMetric            *metricReceived2HOT;
@property(readwrite,strong) UMPrometheusMetric            *metricReceived2SBY;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedLHOT;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedLSBY;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedLUNK;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedLFAI;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedL2HT;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedL2SB;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedLRFO;
@property(readwrite,strong) UMPrometheusMetric            *metricReceivedLRTO;

@property(readwrite,strong) UMPrometheusMetric            *metricSentUNK;
@property(readwrite,strong) UMPrometheusMetric            *metricSentHOTT;
@property(readwrite,strong) UMPrometheusMetric            *metricSentSTBY;
@property(readwrite,strong) UMPrometheusMetric            *metricSentTREQ;
@property(readwrite,strong) UMPrometheusMetric            *metricSentTCNF;
@property(readwrite,strong) UMPrometheusMetric            *metricSentTREJ;
@property(readwrite,strong) UMPrometheusMetric            *metricSentFAIL;
@property(readwrite,strong) UMPrometheusMetric            *metricSentFOVR;
@property(readwrite,strong) UMPrometheusMetric            *metricSent2HOT;
@property(readwrite,strong) UMPrometheusMetric            *metricSent2SBY;
@property(readwrite,strong) UMPrometheusMetric            *metricsStartActionRequested;
@property(readwrite,strong) UMPrometheusMetric            *metricsStopActionRequested;
- (SchrittmacherMetrics *)initWithPrometheus:(UMPrometheus *)prom;
- (void)setSubname1:(NSString *)a value:(NSString *)b;
- (void)registerMetrics;
- (void)unregisterMetrics;

@end
