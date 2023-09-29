d :: DPDKInfo( NB_SOCKET_MBUF 655350 )

define($length 990, $rate 1)

elementclass Numberise { $magic |
    input -> Strip(14) -> check :: MarkIPHeader -> nPacket :: NumberPacket(42) -> StoreData(40, $magic) -> ResetIPChecksum -> Unstrip(14) -> output
}

elementclass Generator { $NUM, $srcmac, $dstmac, $srcip, $dstip, $th |
    fastudp :: FastUDPFlows(RATE 0, LIMIT -1, LENGTH $length, SRCETH $srcmac, DSTETH $dstmac, SRCIP $srcip, DSTIP $dstip, FLOWS 128, FLOWSIZE 32, SEQUENTIAL true)
        -> MarkMACHeader
        -> EnsureDPDKBuffer
        -> Numberise($NUM)
        -> rated :: RatedUnqueue($rate, BURST 32)
        -> IPFilter(drop udp dst port 4791, allow all)
        -> sndavg :: AverageCounter(IGNORE 0)
        -> output;

    StaticThreadSched(rated $th, fastudp $th);
}

elementclass Receiver {
    input
        -> outOfOrder :: FlowOrdering(OFFSET 56, NET_ORDER false, CAPACITY 6000000, SAMPLE 5000)
        -> Unstrip(14)
        -> lat :: EtherLatency(N 100002048, SAMPLE 10)
        -> avg :: AverageCounterMP(IGNORE 0)
        -> recircs :: Classifier(4/0000, 4/0001, 4/0002, 4/0003, 4/0004, 4/0005, 4/0006, 4/0007, 4/0008, 4/0009, 4/000a, 4/000b, -)
    
    recircs[0] -> count0 :: CounterMP() -> lat0 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[1] -> count1 :: CounterMP() -> lat1 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[2] -> count2 :: CounterMP() -> lat2 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[3] -> count3 :: CounterMP() -> lat3 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[4] -> count4 :: CounterMP() -> lat4 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[5] -> count5 :: CounterMP() -> lat5 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[6] -> count6 :: CounterMP() -> lat6 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[7] -> count7 :: CounterMP() -> lat7 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[8] -> count8 :: CounterMP() -> lat8 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[9] -> count9 :: CounterMP() -> lat9 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[10] -> count10 :: CounterMP() -> lat10 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[11] -> count11 :: CounterMP() -> lat11 :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
    recircs[12] -> countOther :: CounterMP() -> latOther :: EtherLatency(N 100002048, SAMPLE 10) -> Discard;
}

elementclass MultiThreadGenerator { $port, $outPort, $srcmac, $dstmac, $outSrcmac, $srcip, $dstip |
    tdOUT :: ToDPDKDevice($port, BLOCKING true, VERBOSE 99);

    gen0 :: Generator(\<5701>, $srcmac, $dstmac, $srcip, $dstip, 0/0) -> tdOUT;
    gen1 :: Generator(\<5702>, $srcmac, $dstmac, $srcip, $dstip, 0/1) -> tdOUT;
    gen2 :: Generator(\<5703>, $srcmac, $dstmac, $srcip, $dstip, 0/2) -> tdOUT;
    gen3 :: Generator(\<5704>, $srcmac, $dstmac, $srcip, $dstip, 0/3) -> tdOUT;

    fd :: FromDPDKDevice($outPort, MAXTHREADS 4, MAC $outSrcmac, PROMISC true, FLOW_ISOLATE false, VERBOSE 99)
        -> c0 :: Classifier(12/0806 20/0001,
                            12/0806 20/0002,
                            12/0800,
                            -)[2]
        -> Strip(14)
        -> magic :: Classifier(40/5701,
                            40/5702,
                            40/5703,
                            40/5704,
                            -)

    magic[0] -> rcv0 :: Receiver();
    magic[1] -> rcv1 :: Receiver();
    magic[2] -> rcv2 :: Receiver();
    magic[3] -> rcv3 :: Receiver();
    magic[4] -> Print("WARNING: Unknown magic / untimestamped packet", -1) -> Discard;

    c0[0] -> ARPResponder($srcip $srcmac) -> tdOUT;
    c0[1] -> Discard;
    c0[3] -> Print("WARNING: Non-IP packet !") -> Discard;

    input -> tdOUT;

    sndavg :: HandlerAggregate(ELEMENT gen0/sndavg, ELEMENT gen1/sndavg, ELEMENT gen2/sndavg, ELEMENT gen3/sndavg);
    avg :: HandlerAggregate(ELEMENT rcv0/avg, ELEMENT rcv1/avg, ELEMENT rcv2/avg, ELEMENT rcv3/avg);
    
    count0 :: HandlerAggregate(ELEMENT rcv0/count0, ELEMENT rcv1/count0, ELEMENT rcv2/count0, ELEMENT rcv3/count0);
    count1 :: HandlerAggregate(ELEMENT rcv0/count1, ELEMENT rcv1/count1, ELEMENT rcv2/count1, ELEMENT rcv3/count1);
    count2 :: HandlerAggregate(ELEMENT rcv0/count2, ELEMENT rcv1/count2, ELEMENT rcv2/count2, ELEMENT rcv3/count2);
    count3 :: HandlerAggregate(ELEMENT rcv0/count3, ELEMENT rcv1/count3, ELEMENT rcv2/count3, ELEMENT rcv3/count3);
    count4 :: HandlerAggregate(ELEMENT rcv0/count4, ELEMENT rcv1/count4, ELEMENT rcv2/count4, ELEMENT rcv3/count4);
    count5 :: HandlerAggregate(ELEMENT rcv0/count5, ELEMENT rcv1/count5, ELEMENT rcv2/count5, ELEMENT rcv3/count5);
    count6 :: HandlerAggregate(ELEMENT rcv0/count6, ELEMENT rcv1/count6, ELEMENT rcv2/count6, ELEMENT rcv3/count6);
    count7 :: HandlerAggregate(ELEMENT rcv0/count7, ELEMENT rcv1/count7, ELEMENT rcv2/count7, ELEMENT rcv3/count7);
    count8 :: HandlerAggregate(ELEMENT rcv0/count8, ELEMENT rcv1/count8, ELEMENT rcv2/count8, ELEMENT rcv3/count8);
    count9 :: HandlerAggregate(ELEMENT rcv0/count9, ELEMENT rcv1/count9, ELEMENT rcv2/count9, ELEMENT rcv3/count9);
    count10 :: HandlerAggregate(ELEMENT rcv0/count10, ELEMENT rcv1/count10, ELEMENT rcv2/count10, ELEMENT rcv3/count10);
    count11 :: HandlerAggregate(ELEMENT rcv0/count11, ELEMENT rcv1/count11, ELEMENT rcv2/count11, ELEMENT rcv3/count11);
    countOther :: HandlerAggregate(ELEMENT rcv0/countOther, ELEMENT rcv1/countOther, ELEMENT rcv2/countOther, ELEMENT rcv3/countOther);

    lat :: EtherLatencyAggregate(ELEMENT rcv0/lat, ELEMENT rcv1/lat, ELEMENT rcv2/lat, ELEMENT rcv3/lat);
    lat0 :: EtherLatencyAggregate(ELEMENT rcv0/lat0, ELEMENT rcv1/lat0, ELEMENT rcv2/lat0, ELEMENT rcv3/lat0);
    lat1 :: EtherLatencyAggregate(ELEMENT rcv0/lat1, ELEMENT rcv1/lat1, ELEMENT rcv2/lat1, ELEMENT rcv3/lat1);
    lat2 :: EtherLatencyAggregate(ELEMENT rcv0/lat2, ELEMENT rcv1/lat2, ELEMENT rcv2/lat2, ELEMENT rcv3/lat2);
    lat3 :: EtherLatencyAggregate(ELEMENT rcv0/lat3, ELEMENT rcv1/lat3, ELEMENT rcv2/lat3, ELEMENT rcv3/lat3);
    lat4 :: EtherLatencyAggregate(ELEMENT rcv0/lat4, ELEMENT rcv1/lat4, ELEMENT rcv2/lat4, ELEMENT rcv3/lat4);
    lat5 :: EtherLatencyAggregate(ELEMENT rcv0/lat5, ELEMENT rcv1/lat5, ELEMENT rcv2/lat5, ELEMENT rcv3/lat5);
    lat6 :: EtherLatencyAggregate(ELEMENT rcv0/lat6, ELEMENT rcv1/lat6, ELEMENT rcv2/lat6, ELEMENT rcv3/lat6);
    lat7 :: EtherLatencyAggregate(ELEMENT rcv0/lat7, ELEMENT rcv1/lat7, ELEMENT rcv2/lat7, ELEMENT rcv3/lat7);
    lat8 :: EtherLatencyAggregate(ELEMENT rcv0/lat8, ELEMENT rcv1/lat8, ELEMENT rcv2/lat8, ELEMENT rcv3/lat8);
    lat9 :: EtherLatencyAggregate(ELEMENT rcv0/lat9, ELEMENT rcv1/lat9, ELEMENT rcv2/lat9, ELEMENT rcv3/lat9);
    lat10 :: EtherLatencyAggregate(ELEMENT rcv0/lat10, ELEMENT rcv1/lat10, ELEMENT rcv2/lat10, ELEMENT rcv3/lat10);
    lat11 :: EtherLatencyAggregate(ELEMENT rcv0/lat11, ELEMENT rcv1/lat11, ELEMENT rcv2/lat11, ELEMENT rcv3/lat11);
    latOther :: EtherLatencyAggregate(ELEMENT rcv0/latOther, ELEMENT rcv1/latOther, ELEMENT rcv2/latOther, ELEMENT rcv3/latOther);

    outOfOrder :: HandlerAggregate(ELEMENT rcv0/outOfOrder, ELEMENT rcv1/outOfOrder, ELEMENT rcv2/outOfOrder, ELEMENT rcv3/outOfOrder);
}

gen0 :: MultiThreadGenerator(0, 0, ae:aa:aa:1b:3c:d6, ae:aa:aa:1b:3c:d6, ae:aa:aa:1b:3c:d6, 10.27.60.214, 10.27.60.214)

adv :: FastUDPFlows(RATE 0, LIMIT -1, LENGTH 60, SRCETH ae:aa:aa:3c:01:65, DSTETH ae:aa:aa:3c:01:65, SRCIP 10.60.1.101, DSTIP 10.60.1.101, FLOWS 1, FLOWSIZE 1, ACTIVE 1)
    -> RatedUnqueue(1)
    -> gen0;

DriverManager(
    print "Waiting 2 seconds before launching generation...",
    wait 2s,
    print "EVENT GEN_BEGIN",
    print "Starting gen...",
    print "Starting timer wait...",
    set starttime $(now),
    wait 10,
    set stoptime $(now),
    print "EVENT GEN_DONE",
    wait 1s,
    print >logs/srv-log.log "SRV-0-RESULT-OUTOFORDER $(gen0/outOfOrder.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT50 $(gen0/lat.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT90 $(gen0/lat.avg perc90) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT95 $(gen0/lat.avg perc95) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT99 $(gen0/lat.avg perc99) us",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_0 $(gen0/count0.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_1 $(gen0/count1.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_2 $(gen0/count2.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_3 $(gen0/count3.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_4 $(gen0/count4.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_5 $(gen0/count5.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_6 $(gen0/count6.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_7 $(gen0/count7.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_8 $(gen0/count8.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_9 $(gen0/count9.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_10 $(gen0/count10.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_11 $(gen0/count11.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_MORE11 $(gen0/countOther.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_0 $(gen0/lat0.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_1 $(gen0/lat1.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_2 $(gen0/lat2.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_3 $(gen0/lat3.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_4 $(gen0/lat4.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_5 $(gen0/lat5.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_6 $(gen0/lat6.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_7 $(gen0/lat7.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_8 $(gen0/lat8.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_9 $(gen0/lat9.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_10 $(gen0/lat10.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_11 $(gen0/lat11.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_MORE11 $(gen0/latOther.avg median) us",
    
    print "SRV-0-RESULT-OUTOFORDER $(gen0/outOfOrder.add count) pkts",
    print "SRV-0-RESULT-LAT50 $(gen0/lat.avg median) us",
    print "SRV-0-RESULT-LAT90 $(gen0/lat.avg perc90) us",
    print "SRV-0-RESULT-LAT95 $(gen0/lat.avg perc95) us",
    print "SRV-0-RESULT-LAT99 $(gen0/lat.avg perc99) us",
    print "SRV-0-RESULT-RECIRC_0 $(gen0/count0.add count)",
    print "SRV-0-RESULT-RECIRC_1 $(gen0/count1.add count)",
    print "SRV-0-RESULT-RECIRC_2 $(gen0/count2.add count)",
    print "SRV-0-RESULT-RECIRC_3 $(gen0/count3.add count)",
    print "SRV-0-RESULT-RECIRC_4 $(gen0/count4.add count)",
    print "SRV-0-RESULT-RECIRC_5 $(gen0/count5.add count)",
    print "SRV-0-RESULT-RECIRC_6 $(gen0/count6.add count)",
    print "SRV-0-RESULT-RECIRC_7 $(gen0/count7.add count)",
    print "SRV-0-RESULT-RECIRC_8 $(gen0/count8.add count)",
    print "SRV-0-RESULT-RECIRC_9 $(gen0/count9.add count)",
    print "SRV-0-RESULT-RECIRC_10 $(gen0/count10.add count)",
    print "SRV-0-RESULT-RECIRC_11 $(gen0/count11.add count)",
    print "SRV-0-RESULT-RECIRC_MORE11 $(gen0/countOther.add count)",
    print "SRV-0-RESULT-LAT_0 $(gen0/lat0.avg median) us",
    print "SRV-0-RESULT-LAT_1 $(gen0/lat1.avg median) us",
    print "SRV-0-RESULT-LAT_2 $(gen0/lat2.avg median) us",
    print "SRV-0-RESULT-LAT_3 $(gen0/lat3.avg median) us",
    print "SRV-0-RESULT-LAT_4 $(gen0/lat4.avg median) us",
    print "SRV-0-RESULT-LAT_5 $(gen0/lat5.avg median) us",
    print "SRV-0-RESULT-LAT_6 $(gen0/lat6.avg median) us",
    print "SRV-0-RESULT-LAT_7 $(gen0/lat7.avg median) us",
    print "SRV-0-RESULT-LAT_8 $(gen0/lat8.avg median) us",
    print "SRV-0-RESULT-LAT_9 $(gen0/lat9.avg median) us",
    print "SRV-0-RESULT-LAT_10 $(gen0/lat10.avg median) us",
    print "SRV-0-RESULT-LAT_11 $(gen0/lat11.avg median) us",
    print "SRV-0-RESULT-LAT_MORE11 $(gen0/latOther.avg median) us",
   
    print "EVENT GEN_DONE"
)

Script(TYPE ACTIVE,
    goto end $(eq 1 0), 
    set s $(now),
    label loop,
    wait 1s, 
    set n $(now),
    set t $(sub $n $s),
    print "SRV-$t-RESULT-TX $(gen0/sndavg.add rate)pps/$(gen0/sndavg.add link_rate)bps",
    print "SRV-$t-RESULT-RX $(gen0/avg.add rate)pps/$(gen0/avg.add link_rate)bps",
    print "SRV-$t-RESULT-OUTOFORDER $(gen0/outOfOrder.add count) pkts",
    write gen0/sndavg.write reset,
    write gen0/avg.write reset,
    goto loop,
    label end
)
