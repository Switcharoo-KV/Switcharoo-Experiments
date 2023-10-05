d :: DPDKInfo(200000)

define($bout 32)
define($INsrcmac b8:83:03:6f:43:11)
define($RAW_INsrcmac b883036f4311)
define($INdstmac 00:00:00:00:00:00)
define($RAW_INdstmac 000000000000)

define($ignore 0)
define($replay_count 100)
define($quick true)
define($txverbose 99)
define($rxverbose 99)

elementclass MyNull { [0-7] => [0-7]; };

fdIN0 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-1, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);
fdIN1 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-2, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);
fdIN2 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-3, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);
fdIN3 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-4, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);
fdIN4 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-5, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);
fdIN5 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-6, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);
fdIN6 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-7, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);
fdIN7 :: FromDump(/mnt/traces/caida-18/caida18-32x.forcedudp.pcap-8, STOP true, TIMING 1, TIMING_FNT "100", END_AFTER 0, ACTIVE true, BURST 1);

tdIN :: ToDPDKDevice(0, BLOCKING true, BURST $bout, VERBOSE $txverbose, IQUEUE $bout, NDESC 0, TCO 0)

elementclass Numberise { $magic |
    input -> Strip(14) -> check :: MarkIPHeader -> nPacket :: NumberPacket(42) -> StoreData(40, $magic) -> ResetIPChecksum -> Unstrip(14) -> output
}

elementclass Generator { $magic |
    input
    -> MarkMACHeader
    -> EnsureDPDKBuffer
    -> doethRewrite :: { input[0] -> active::Switch(OUTPUT 0)[0] -> rwIN :: EtherRewrite($INsrcmac, $INdstmac) -> [0]output; active[1] -> [0]output }
    -> Pad
    -> Numberise($magic)
    -> sndavg :: AverageCounter(IGNORE 0)
    -> output;
}

elementclass Receiver {
    input
    -> outOfOrder :: FlowOrdering(OFFSET 42, NET_ORDER false, CAPACITY 6000000, SAMPLE 5000)
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

/* SENDING SIDE */
rr :: MyNull;
fdIN0 -> unqueue0 :: Unqueue() -> [0]rr
fdIN1 -> unqueue1 :: Unqueue() -> [1]rr
fdIN2 -> unqueue2 :: Unqueue() -> [2]rr
fdIN3 -> unqueue3 :: Unqueue() -> [3]rr
fdIN4 -> unqueue4 :: Unqueue() -> [4]rr
fdIN5 -> unqueue5 :: Unqueue() -> [5]rr
fdIN6 -> unqueue6 :: Unqueue() -> [6]rr
fdIN7 -> unqueue7 :: Unqueue() -> [7]rr

rr[0] -> gen0 :: Generator(\<5700>) -> tdIN; StaticThreadSched(fdIN0 0/1, unqueue0 0/1)
rr[1] -> gen1 :: Generator(\<5701>) -> tdIN; StaticThreadSched(fdIN1 0/2, unqueue1 0/2)
rr[2] -> gen2 :: Generator(\<5702>) -> tdIN; StaticThreadSched(fdIN2 0/3, unqueue2 0/3)
rr[3] -> gen3 :: Generator(\<5703>) -> tdIN; StaticThreadSched(fdIN3 0/4, unqueue3 0/4)
rr[4] -> gen4 :: Generator(\<5704>) -> tdIN; StaticThreadSched(fdIN4 0/5, unqueue4 0/5)
rr[5] -> gen5 :: Generator(\<5705>) -> tdIN; StaticThreadSched(fdIN5 0/6, unqueue5 0/6)
rr[6] -> gen6 :: Generator(\<5706>) -> tdIN; StaticThreadSched(fdIN6 0/7, unqueue6 0/7)
rr[7] -> gen7 :: Generator(\<5707>) -> tdIN; StaticThreadSched(fdIN7 0/8, unqueue7 0/8)

sndavg :: HandlerAggregate(ELEMENT gen0/sndavg, ELEMENT gen1/sndavg, ELEMENT gen2/sndavg, ELEMENT gen3/sndavg, ELEMENT gen4/sndavg, ELEMENT gen5/sndavg, ELEMENT gen6/sndavg,ELEMENT gen7/sndavg);

/* RECEIVING SIDE */
fd :: FromDPDKDevice(0, VERBOSE $rxverbose, MAC $INsrcmac, PROMISC true, PAUSE none, NDESC 0, MAXTHREADS 8, NUMA false)
    -> c0 :: Classifier(12/0806 20/0001,
                        12/0806 20/0002,
                        12/0800,
                        -)[2]
    -> Strip(14)
    -> magic :: Classifier(
        40/5700,
        40/5701,
		40/5702,
		40/5703,
		40/5704,
		40/5705,
		40/5706,
		40/5707,
        -
    )

magic[0] -> rcv0 :: Receiver();
magic[1] -> rcv1 :: Receiver();
magic[2] -> rcv2 :: Receiver();
magic[3] -> rcv3 :: Receiver();
magic[4] -> rcv4 :: Receiver();
magic[5] -> rcv5 :: Receiver();
magic[6] -> rcv6 :: Receiver();
magic[7] -> rcv7 :: Receiver();
magic[8] -> Print("WARNING: Unknown magic / untimestamped packet", -1) -> Discard;

c0[3] -> Print("WARNING: Non-IP packet !") -> Discard;

c0[0] -> Discard;

c0[1] -> Discard;

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

ig :: Script(TYPE ACTIVE,
    set s $(now),
    set lastcount 0,
    set lastbytes 0,
    set lastbytessent 0,
    set lastsent 0,
    set lastdrop 0,
    set last $s,
    set indexB 0,
    set indexC 0,
    set indexD 0,
    label loop,
    wait 1s,
    set n $(now),
    set t $(sub $n $s),
    set elapsed $(sub $n $last),
    set last $n,
    set count $(avg.add count),
    set sent $(sndavg.add count),
    set bytessent $(sndavg.add byte_count),
    set bytes $(avg.add byte_count),
    print "IG-$t-RESULT-IGCOUNT $(sub $count $lastcount)",
    print "IG-$t-RESULT-IGSENT $(sub $sent $lastsent)",
    print "IG-$t-RESULT-IGBYTESSENT $(sub $bytessent $lastbytessent)",
    set drop $(sub $sent $count),
    print "IG-$t-RESULT-IGDROPPED $(sub $drop $lastdrop)",
    set lastdrop $drop,
    print "IG-$t-RESULT-IGTHROUGHPUT $(div $(mul $(add $(mul $(sub $count $lastcount) 24) $(sub $bytes $lastbytes)) 8) $elapsed)",
    set lastcount $count,
    set lastsent $sent,
    set lastbytes $bytes,
    set lastbytessent $bytessent,
    goto loop
)

StaticThreadSched(ig 15);

dm :: DriverManager(
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
    print >logs/srv-log.log "SRV-0-RESULT-OUTOFORDER $(outOfOrder.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT50 $(lat.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT90 $(lat.avg perc90) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT95 $(lat.avg perc95) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT99 $(lat.avg perc99) us",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_0 $(count0.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_1 $(count1.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_2 $(count2.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_3 $(count3.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_4 $(count4.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_5 $(count5.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_6 $(count6.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_7 $(count7.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_8 $(count8.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_9 $(count9.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_10 $(count10.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_11 $(count11.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-RECIRC_MORE11 $(countOther.add count) pkts",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_0 $(lat0.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_1 $(lat1.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_2 $(lat2.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_3 $(lat3.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_4 $(lat4.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_5 $(lat5.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_6 $(lat6.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_7 $(lat7.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_8 $(lat8.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_9 $(lat9.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_10 $(lat10.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_11 $(lat11.avg median) us",
    print >>logs/srv-log.log "SRV-0-RESULT-LAT_MORE11 $(latOther.avg median) us",
    
    print "SRV-0-RESULT-OUTOFORDER $(outOfOrder.add count) pkts",
    print "SRV-0-RESULT-LAT50 $(lat.avg median) us",
    print "SRV-0-RESULT-LAT90 $(lat.avg perc90) us",
    print "SRV-0-RESULT-LAT95 $(lat.avg perc95) us",
    print "SRV-0-RESULT-LAT99 $(lat.avg perc99) us",
    print "SRV-0-RESULT-RECIRC_0 $(count0.add count)",
    print "SRV-0-RESULT-RECIRC_1 $(count1.add count)",
    print "SRV-0-RESULT-RECIRC_2 $(count2.add count)",
    print "SRV-0-RESULT-RECIRC_3 $(count3.add count)",
    print "SRV-0-RESULT-RECIRC_4 $(count4.add count)",
    print "SRV-0-RESULT-RECIRC_5 $(count5.add count)",
    print "SRV-0-RESULT-RECIRC_6 $(count6.add count)",
    print "SRV-0-RESULT-RECIRC_7 $(count7.add count)",
    print "SRV-0-RESULT-RECIRC_8 $(count8.add count)",
    print "SRV-0-RESULT-RECIRC_9 $(count9.add count)",
    print "SRV-0-RESULT-RECIRC_10 $(count10.add count)",
    print "SRV-0-RESULT-RECIRC_11 $(count11.add count)",
    print "SRV-0-RESULT-RECIRC_MORE11 $(countOther.add count)",
    print "SRV-0-RESULT-LAT_0 $(lat0.avg median) us",
    print "SRV-0-RESULT-LAT_1 $(lat1.avg median) us",
    print "SRV-0-RESULT-LAT_2 $(lat2.avg median) us",
    print "SRV-0-RESULT-LAT_3 $(lat3.avg median) us",
    print "SRV-0-RESULT-LAT_4 $(lat4.avg median) us",
    print "SRV-0-RESULT-LAT_5 $(lat5.avg median) us",
    print "SRV-0-RESULT-LAT_6 $(lat6.avg median) us",
    print "SRV-0-RESULT-LAT_7 $(lat7.avg median) us",
    print "SRV-0-RESULT-LAT_8 $(lat8.avg median) us",
    print "SRV-0-RESULT-LAT_9 $(lat9.avg median) us",
    print "SRV-0-RESULT-LAT_10 $(lat10.avg median) us",
    print "SRV-0-RESULT-LAT_11 $(lat11.avg median) us",
    print "SRV-0-RESULT-LAT_MORE11 $(latOther.avg median) us",
   
    print "EVENT GEN_DONE"
)

StaticThreadSched(dm 15);

