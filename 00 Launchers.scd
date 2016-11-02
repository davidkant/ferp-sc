// activity / difference monitor
~dEngine = ~differenceEngine.value()

// start running analysis engines
~grinder = ~angleGrinder.value()
~eEngine = ~entropyEngine.value()

// plot angle
~grinderPlot = ~angleGrinderPlot.value()
// plot entropy
~ePlot = ~entropyPlot.value()
// piano roll entropy
~eSeq = ~entropySequencer.value(numChannels: 4)

// close engines
~grinder.onClose()
~eEngine.onClose()