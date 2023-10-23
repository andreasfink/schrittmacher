//
//  SchrittmacherMetrics.m
//  schrittmacher
//
//  Created by Andreas Fink on 28.06.21.
//  Copyright © 2021 Andreas Fink. All rights reserved.
//

#import "SchrittmacherMetrics.h"

@implementation SchrittmacherMetrics

-(SchrittmacherMetrics *)initWithPrometheus:(UMPrometheus *)prom
{
    self = [super init];
    if(self)
    {
        _prometheus = prom;
        _metricReceivedUNK = [[UMPrometheusMetric alloc]init];
        _metricReceivedUNK.metricName       = @"rx_unk";
        _metricReceivedUNK.help             = @"Total number of received UNK packets";
        _metricReceivedUNK.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedHOTT = [[UMPrometheusMetric alloc]init];
        _metricReceivedHOTT.metricName       = @"rx_hott";
        _metricReceivedHOTT.help             = @"Total number of received HOTT packets";
        _metricReceivedHOTT.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedSTBY = [[UMPrometheusMetric alloc]init];
        _metricReceivedSTBY.metricName       = @"rx_sby";
        _metricReceivedSTBY.help             = @"Total number of received SBY packets";
        _metricReceivedSTBY.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedTREQ = [[UMPrometheusMetric alloc]init];
        _metricReceivedTREQ.metricName       = @"rx_treq";
        _metricReceivedTREQ.help             = @"Total number of received TREQ packets";
        _metricReceivedTREQ.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedTCNF = [[UMPrometheusMetric alloc]init];
        _metricReceivedTCNF.metricName       = @"rx_tcnf";
        _metricReceivedTCNF.help             = @"Total number of received TCNF packets";
        _metricReceivedTCNF.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedTREJ = [[UMPrometheusMetric alloc]init];
        _metricReceivedTREJ.metricName       = @"rx_trej";
        _metricReceivedTREJ.help             = @"Total number of received TREJ packets";
        _metricReceivedTREJ.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedFAIL = [[UMPrometheusMetric alloc]init];
        _metricReceivedFAIL.metricName       = @"rx_fail";
        _metricReceivedFAIL.help             = @"Total number of received FAIL packets";
        _metricReceivedFAIL.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedFOVR = [[UMPrometheusMetric alloc]init];
        _metricReceivedFOVR.metricName       = @"rx_fovr";
        _metricReceivedFOVR.help             = @"Total number of received FOVR packets";
        _metricReceivedFOVR.metricType       = UMPrometheusMetricType_counter;

        _metricReceived2HOT = [[UMPrometheusMetric alloc]init];
        _metricReceived2HOT.metricName       = @"rx_2sby";
        _metricReceived2HOT.help             = @"Total number of received 2HOT packets";
        _metricReceived2HOT.metricType       = UMPrometheusMetricType_counter;

        _metricReceived2SBY = [[UMPrometheusMetric alloc]init];
        _metricReceived2SBY.metricName       = @"rx_2sby";
        _metricReceived2SBY.help             = @"Total number of received 2SBY packets";
        _metricReceived2SBY.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedLHOT = [[UMPrometheusMetric alloc]init];
        _metricReceivedLHOT.metricName       = @"rx_lhot";
        _metricReceivedLHOT.help             = @"Total number of received LHOT packets";
        _metricReceivedLHOT.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedLSBY = [[UMPrometheusMetric alloc]init];
        _metricReceivedLSBY.metricName       = @"rx_lsby";
        _metricReceivedLSBY.help             = @"Total number of received LSBY packets";
        _metricReceivedLSBY.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedLUNK = [[UMPrometheusMetric alloc]init];
        _metricReceivedLUNK.metricName       = @"rx_lunk";
        _metricReceivedLUNK.help             = @"Total number of received LUNK packets";
        _metricReceivedLUNK.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedLFAI = [[UMPrometheusMetric alloc]init];
        _metricReceivedLFAI.metricName       = @"rx_lfai";
        _metricReceivedLFAI.help             = @"Total number of received LFAI packets";
        _metricReceivedLFAI.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedL2HT = [[UMPrometheusMetric alloc]init];
        _metricReceivedL2HT.metricName       = @"rx_l2ht";
        _metricReceivedL2HT.help             = @"Total number of received L2HT packets";
        _metricReceivedL2HT.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedL2SB = [[UMPrometheusMetric alloc]init];
        _metricReceivedL2SB.metricName       = @"rx_l2sb";
        _metricReceivedL2SB.help             = @"Total number of received L2SB packets";
        _metricReceivedL2SB.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedLRFO = [[UMPrometheusMetric alloc]init];
        _metricReceivedLRFO.metricName       = @"rx_lrfo";
        _metricReceivedLRFO.help             = @"Total number received LRFO packets";
        _metricReceivedLRFO.metricType       = UMPrometheusMetricType_counter;

        _metricReceivedLRTO = [[UMPrometheusMetric alloc]init];
        _metricReceivedLRTO.metricName       = @"rx_ltto";
        _metricReceivedLRTO.help             = @"Total number of received LRTO packets";
        _metricReceivedLRTO.metricType       = UMPrometheusMetricType_counter;
        
        
        _metricSentUNK = [[UMPrometheusMetric alloc]init];
        _metricSentUNK.metricName       = @"tx_unk";
        _metricSentUNK.help             = @"Total number of sent UNK packets";
        _metricSentUNK.metricType       = UMPrometheusMetricType_counter;

        _metricSentHOTT = [[UMPrometheusMetric alloc]init];
        _metricSentHOTT.metricName       = @"tx_hott";
        _metricSentHOTT.help             = @"Total number of sent HOTT packets";
        _metricSentHOTT.metricType       = UMPrometheusMetricType_counter;

        _metricSentSTBY = [[UMPrometheusMetric alloc]init];
        _metricSentSTBY.metricName       = @"tx_sby";
        _metricSentSTBY.help             = @"Total number of sent SBY packets";
        _metricSentSTBY.metricType       = UMPrometheusMetricType_counter;

        _metricSentTREQ = [[UMPrometheusMetric alloc]init];
        _metricSentTREQ.metricName       = @"tx_treq";
        _metricSentTREQ.help             = @"Total number of sent TREQ packets";
        _metricSentTREQ.metricType       = UMPrometheusMetricType_counter;

        _metricSentTCNF = [[UMPrometheusMetric alloc]init];
        _metricSentTCNF.metricName       = @"tx_tcnf";
        _metricSentTCNF.help             = @"Total number of sent TCNF packets";
        _metricSentTCNF.metricType       = UMPrometheusMetricType_counter;

        _metricSentTREJ = [[UMPrometheusMetric alloc]init];
        _metricSentTREJ.metricName       = @"tx_trej";
        _metricSentTREJ.help             = @"Total number of sent TREJ packets";
        _metricSentTREJ.metricType       = UMPrometheusMetricType_counter;

        _metricSentFAIL = [[UMPrometheusMetric alloc]init];
        _metricSentFAIL.metricName       = @"tx_fail";
        _metricSentFAIL.help             = @"Total number of sent FAIL packets";
        _metricSentFAIL.metricType       = UMPrometheusMetricType_counter;

        _metricSentFOVR = [[UMPrometheusMetric alloc]init];
        _metricSentFOVR.metricName       = @"tx_fovr";
        _metricSentFOVR.help             = @"Total number of sent FOVR packets";
        _metricSentFOVR.metricType       = UMPrometheusMetricType_counter;

        _metricSent2HOT = [[UMPrometheusMetric alloc]init];
        _metricSent2HOT.metricName       = @"tx_2sby";
        _metricSent2HOT.help             = @"Total number of sent 2HOT packets";
        _metricSent2HOT.metricType       = UMPrometheusMetricType_counter;

        _metricSent2SBY = [[UMPrometheusMetric alloc]init];
        _metricSent2SBY.metricName       = @"tx_2sby";
        _metricSent2SBY.help             = @"Total number of sent 2SBY packets";
        _metricSent2SBY.metricType       = UMPrometheusMetricType_counter;

        _metricsStartActionRequested            = [[UMPrometheusMetric alloc]init];
        _metricsStartActionRequested.metricName = @"start_action";
        _metricsStartActionRequested.help       = @"Total count of start action requests";
        _metricsStartActionRequested.metricType = UMPrometheusMetricType_counter;
        
        _metricsStopActionRequested             = [[UMPrometheusMetric alloc]init];
        _metricsStopActionRequested.metricName  = @"stop_action";
        _metricsStopActionRequested.help        = @"Total count of stop action requests";
        _metricsStopActionRequested.metricType  = UMPrometheusMetricType_counter;

    }
    return self;
}

- (void)setSubname1:(NSString *)a value:(NSString *)b
{
    [_metricReceivedUNK setSubname1:a value:b];
    [_metricReceivedHOTT setSubname1:a value:b];
    [_metricReceivedSTBY setSubname1:a value:b];
    [_metricReceivedTREQ setSubname1:a value:b];
    [_metricReceivedTCNF setSubname1:a value:b];
    [_metricReceivedTREJ setSubname1:a value:b];
    [_metricReceivedFAIL setSubname1:a value:b];
    [_metricReceivedFOVR setSubname1:a value:b];
    [_metricReceived2HOT setSubname1:a value:b];
    [_metricReceived2SBY setSubname1:a value:b];
    [_metricReceivedLHOT setSubname1:a value:b];
    [_metricReceivedLSBY setSubname1:a value:b];
    [_metricReceivedLUNK setSubname1:a value:b];
    [_metricReceivedLFAI setSubname1:a value:b];
    [_metricReceivedL2HT setSubname1:a value:b];
    [_metricReceivedL2SB setSubname1:a value:b];
    [_metricReceivedLRFO setSubname1:a value:b];
    [_metricReceivedLRTO setSubname1:a value:b];

    [_metricSentUNK setSubname1:a value:b];
    [_metricSentHOTT setSubname1:a value:b];
    [_metricSentSTBY setSubname1:a value:b];
    [_metricSentTREQ setSubname1:a value:b];
    [_metricSentTCNF setSubname1:a value:b];
    [_metricSentTREJ setSubname1:a value:b];
    [_metricSentFAIL setSubname1:a value:b];
    [_metricSentFOVR setSubname1:a value:b];
    [_metricSent2HOT setSubname1:a value:b];
    [_metricSent2SBY setSubname1:a value:b];
    
    [_metricsStartActionRequested setSubname1:a value:b];
    [_metricsStopActionRequested setSubname1:a value:b];
}

- (void)registerMetrics
{
    [_prometheus addObject:_metricReceivedUNK forKey:_metricReceivedUNK.key];
    [_prometheus addObject:_metricReceivedHOTT forKey:_metricReceivedHOTT.key];
    [_prometheus addObject:_metricReceivedSTBY forKey:_metricReceivedSTBY.key];
    [_prometheus addObject:_metricReceivedTREQ forKey:_metricReceivedTREQ.key];
    [_prometheus addObject:_metricReceivedTCNF forKey:_metricReceivedTCNF.key];
    [_prometheus addObject:_metricReceivedTREJ forKey:_metricReceivedTREJ.key];
    [_prometheus addObject:_metricReceivedFAIL forKey:_metricReceivedFAIL.key];
    [_prometheus addObject:_metricReceivedFOVR forKey:_metricReceivedFOVR.key];
    [_prometheus addObject:_metricReceived2HOT forKey:_metricReceived2HOT.key];
    [_prometheus addObject:_metricReceived2SBY forKey:_metricReceived2SBY.key];
    [_prometheus addObject:_metricReceivedLUNK forKey:_metricReceivedLUNK.key];
    [_prometheus addObject:_metricReceivedLFAI forKey:_metricReceivedLFAI.key];
    [_prometheus addObject:_metricReceivedLHOT forKey:_metricReceivedLHOT.key];
    [_prometheus addObject:_metricReceivedLSBY forKey:_metricReceivedLSBY.key];
    [_prometheus addObject:_metricReceivedL2HT forKey:_metricReceivedL2HT.key];
    [_prometheus addObject:_metricReceivedL2SB forKey:_metricReceivedL2SB.key];
    [_prometheus addObject:_metricReceivedLRFO forKey:_metricReceivedLRFO.key];
    [_prometheus addObject:_metricReceivedLRTO forKey:_metricReceivedLRTO.key];
    
    [_prometheus addObject:_metricSentUNK forKey:_metricSentUNK.key];
    [_prometheus addObject:_metricSentHOTT forKey:_metricSentHOTT.key];
    [_prometheus addObject:_metricSentSTBY forKey:_metricSentSTBY.key];
    [_prometheus addObject:_metricSentTREQ forKey:_metricSentTREQ.key];
    [_prometheus addObject:_metricSentTCNF forKey:_metricSentTCNF.key];
    [_prometheus addObject:_metricSentTREJ forKey:_metricSentTREJ.key];
    [_prometheus addObject:_metricSentFAIL forKey:_metricSentFAIL.key];
    [_prometheus addObject:_metricSentFOVR forKey:_metricSentFOVR.key];
    [_prometheus addObject:_metricSent2HOT forKey:_metricSent2HOT.key];
    [_prometheus addObject:_metricSent2SBY forKey:_metricSent2SBY.key];

    [_prometheus addObject:_metricsStartActionRequested forKey:_metricsStartActionRequested.key];
    [_prometheus addObject:_metricsStopActionRequested forKey:_metricsStopActionRequested.key];

}

- (void)unregisterMetrics
{
    [_prometheus removeObjectForKey:_metricReceivedUNK.key];
    [_prometheus removeObjectForKey:_metricReceivedHOTT.key];
    [_prometheus removeObjectForKey:_metricReceivedSTBY.key];
    [_prometheus removeObjectForKey:_metricReceivedTREQ.key];
    [_prometheus removeObjectForKey:_metricReceivedTCNF.key];
    [_prometheus removeObjectForKey:_metricReceivedTREJ.key];
    [_prometheus removeObjectForKey:_metricReceivedFAIL.key];
    [_prometheus removeObjectForKey:_metricReceivedFOVR.key];
    [_prometheus removeObjectForKey:_metricReceived2HOT.key];
    [_prometheus removeObjectForKey:_metricReceived2SBY.key];
    [_prometheus removeObjectForKey:_metricReceivedLHOT.key];
    [_prometheus removeObjectForKey:_metricReceivedLSBY.key];
    [_prometheus removeObjectForKey:_metricReceivedLUNK.key];
    [_prometheus removeObjectForKey:_metricReceivedLFAI.key];
    [_prometheus removeObjectForKey:_metricReceivedL2HT.key];
    [_prometheus removeObjectForKey:_metricReceivedL2SB.key];
    [_prometheus removeObjectForKey:_metricReceivedLRFO.key];
    [_prometheus removeObjectForKey:_metricReceivedLRTO.key];
    
    [_prometheus removeObjectForKey:_metricSentUNK.key];
    [_prometheus removeObjectForKey:_metricSentHOTT.key];
    [_prometheus removeObjectForKey:_metricSentSTBY.key];
    [_prometheus removeObjectForKey:_metricSentTREQ.key];
    [_prometheus removeObjectForKey:_metricSentTCNF.key];
    [_prometheus removeObjectForKey:_metricSentTREJ.key];
    [_prometheus removeObjectForKey:_metricSentFAIL.key];
    [_prometheus removeObjectForKey:_metricSentFOVR.key];
    [_prometheus removeObjectForKey:_metricSent2HOT.key];
    [_prometheus removeObjectForKey:_metricSent2SBY.key];

    [_prometheus removeObjectForKey:_metricsStartActionRequested.key];
    [_prometheus removeObjectForKey:_metricsStopActionRequested.key];
}


@end
