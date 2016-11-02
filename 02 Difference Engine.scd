/* --- Difference Engine. --- */

(
SynthDef(\differencer, { |inBus, outBus, outBusSmoothed|


    var in, fft, mfcc1, mfcc2, delta;

    // input
    in = InFeedback.ar(inBus);

    // features
    fft = FFT(LocalBuf(2048), in, hop: 0.5);
    mfcc1 = MFCC.kr(fft);
    mfcc2 = Delay1.kr(mfcc1);

    // cosine distance
    delta = ((mfcc1 * mfcc2).sum / (mfcc1.pow(2).abs.sum.sqrt * mfcc2.pow(2).abs.sum.sqrt));

    // invert and scale
    delta = delta.linlin(-1, 1, 3, 0);

    // sample and hold b/c mfcc1 == mfcc2 between hops
    delta = Latch.kr(delta, FFTTrigger(LocalBuf(2048), hop: 0.5));

    // out
    Out.kr(outBus, delta);
    Out.kr(outBusSmoothed, LagUD.kr(delta, 0, 5));

}).add;
);

(
~differenceEngine = {

    var self = ();

    // formatting
    self.channelWidth = 100;
    self.channelHeight = 100;
    self.paddingFromEdge = 10;
    self.paddingBetween = 10;

    // window
    self.win = Window.new('~differenceEngine', Rect(900, 700, 3*(self.channelWidth+self.paddingBetween)+10, 3*(self.channelHeight+self.paddingBetween)+10))
    .front.alwaysOnTop_(true)
    .background_(Color.black)
    .drawFunc_({ Pen.strokeColor_(Color.white).width_(2).strokeRect(self.win.bounds.moveTo(0,0).insetBy(2,2));});

    // init channels
    self.channels = ~inputBusses.numChannels.collect({()});

    // init outBus's (all at once)
    self.outBus = Bus.control(s, ~inputBusses.numChannels);
    self.outBusSmoothed = Bus.control(s, ~inputBusses.numChannels);

    // grid layout
    self.gridLayout = [2,1,0,5,4,3,8,7,6];

    // create channels
    ~inputBusses.numChannels.do({|i|

        // local reference
        var channel = self.channels[i];
        channel.inBus = ~inputBusses.subBus(i);

        self.gridLayout[i].postln;

        // channel container
        channel.container = CompositeView(self.win, Rect(
            (self.gridLayout[i]/3).floor*(self.channelWidth+self.paddingBetween)+self.paddingFromEdge,
            (self.gridLayout[i]%3)*(self.channelHeight+self.paddingBetween)+self.paddingFromEdge,
            self.channelWidth,
            self.channelHeight)).background_(Color.grey);

        // plot
        channel.plot = ();
        channel.plot.view = UserView(self.win, channel.container.bounds.insetBy(1,1)).background_(Color.black);
        channel.plot.val = 0.5;
        channel.plot.valSmoothed = 0.5;
        channel.plot.view.drawFunc_({|view|

            var yPix = 1 - (channel.plot.valSmoothed*5) * view.bounds.height;

            // rect
            Pen.fillColor_(Color.magenta.alpha_(channel.plot.val*5*2)); // *2 for perceptual brightness scaling
            Pen.fillRect(Rect(0, yPix, view.bounds.width, view.bounds.height - yPix));

            // line
            Pen.moveTo(0@yPix);
            Pen.lineTo(view.bounds.width@yPix);
            Pen.strokeColor_(Color.cyan).width_(1).smoothing_(false).stroke();

        });

        // init outBus
        channel.outBus = self.outBus.subBus(i);
        channel.outBusSmoothed = self.outBusSmoothed.subBus(i);

        // launch differencer synth
        channel.differencer = Synth(\differencer, [\inBus, channel.inBus, \outBus, channel.outBus, \outBusSmoothed, channel.outBusSmoothed]);

    });

    // plot animation
    self.updatePlots = {

        self.outBus.get({|vals|

            vals.do({|val, i|

                // if different than current val update plot
                if (val != self.channels[i].plot.val, {

                    // update val
                    self.channels[i].plot.val = val;

                    // refresh
                    {self.channels[i].plot.view.refresh()}.defer;

                });
            });
        });

        self.outBusSmoothed.get({|vals|

            vals.do({|val, i|

                // if different than current val update plot
                if (val != self.channels[i].plot.valSmoothed, {

                    // update val
                    self.channels[i].plot.valSmoothed = val;

                    // refresh
                    {self.channels[i].plot.view.refresh()}.defer;

                });
            });
        });

        // notify dependants
        // self.changed();

    };

    // fork animation routine @30Hz on AppClock
    self.animationRoutine = {loop{self['updatePlots'].value(); 0.033333333333333.yield;}}.fork(AppClock);

    // on close
    self.win.onClose_({
        // remove animation routine
        self.animationRoutine.stop;
        // free channel differencer synths
        self.channels.do({|channel| channel.differencer.free});
        // free outBus and smoothed
        self.outBus.free;
        self.outBusSmoothed.free;
    });

    // return self
    self

});