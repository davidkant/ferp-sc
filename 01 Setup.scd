/*--|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

 difference monitor for the FERP

 input 9 channels from reaper via soundflower

 AudioIn.ar(15-22) is soundflower 64 inputs 1-9

*/

/* --- Server Options and Hardware I/O Setup. --- */

(
o = Server.local.options;
o.numInputBusChannels = 23;
o.sampleRate = 44100;
s.waitForBoot({"-> Server Started!".postln});
s.meter(24,2);
);

/* --- Audio bus for inputs. --- */

// 9-channel audio input bus
~inputBusses = Bus.audio(s, 9)

// stream soundflower inputs to bus
(
~inputBussesSynth = SynthDef(\inputs, {

    Out.ar(~inputBusses.subBus(0), AudioIn.ar(15));
    Out.ar(~inputBusses.subBus(1), AudioIn.ar(16));
    Out.ar(~inputBusses.subBus(2), AudioIn.ar(17));
    Out.ar(~inputBusses.subBus(3), AudioIn.ar(18));
    Out.ar(~inputBusses.subBus(4), AudioIn.ar(19));
    Out.ar(~inputBusses.subBus(5), AudioIn.ar(20));
    Out.ar(~inputBusses.subBus(6), AudioIn.ar(21));
    Out.ar(~inputBusses.subBus(7), AudioIn.ar(22));
    Out.ar(~inputBusses.subBus(8), AudioIn.ar(23));

}).play;
)

// sanity check
~inputBusses.scope

// free
~inputBussesSynth.free