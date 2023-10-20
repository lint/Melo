
#import "VisualizerManager.h"


@implementation VisualizerManager

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        _sampleCount = 4096;
        _hasFFTSetup = NO;
        _numOutputBins = 16;

        _outputData = calloc(_numOutputBins, sizeof(float));
        _overallMaxBinValue = 0;

        _nextRecentOutputIndex = 0;
        _numRecentMaxesTracked = 10;
        _recentOutputMaxes = calloc(_numRecentMaxesTracked, sizeof(float));

        [self initFFT];
    }

    return self;
}

// initialize variables used in the FFT calculation
- (void)initFFT {

    @synchronized(self) {

        // destroy previous setup if it exists
        if (_hasFFTSetup) {
            vDSP_destroy_fftsetup(_fftSetup);
            free(_complexInput.realp);
            free(_complexInput.imagp);

            _hasFFTSetup = YES;
        }

        // setup the length
        _log2n = log2f(_sampleCount);

        // calculate the weights array. This is a one-off operation.
        _fftSetup = vDSP_create_fftsetup(_log2n, FFT_RADIX2);

        // define complex buffer
        NSInteger arrayByteSize = _sampleCount * sizeof(float);
        _complexInput.realp = (float *)malloc(arrayByteSize);
        _complexInput.imagp = (float *)malloc(arrayByteSize);
    }
}

// process samples given by MPCAudioSpectrumAnalyzer
- (void)processAudioBuffers:(AudioBufferList *)bufferList numberFrames:(NSInteger)numFrames {

    @synchronized(self) {

        // TODO: when would this not be the case?
        if (bufferList->mNumberBuffers != 2) {
            return;
        }

        // check if the sample bytes can be processed as floats
        NSUInteger dataUnitByteSize = bufferList->mBuffers[0].mDataByteSize / numFrames;
        if (dataUnitByteSize != sizeof(float)) {
            return;
        }

        // update sample count if need be
        if (numFrames != _sampleCount) {
            _sampleCount = numFrames;
            [self initFFT];
        }

        // copy samples to complex buffer
        NSInteger arrayByteSize = _sampleCount * sizeof(float);
        memcpy(_complexInput.realp, (float *)bufferList->mBuffers[0].mData, arrayByteSize);
        memcpy(_complexInput.imagp, (float *)bufferList->mBuffers[1].mData, arrayByteSize);

        // perform a forward FFT using fftSetup and A: results are returned in A
        vDSP_fft_zrip(_fftSetup, &_complexInput, 1, _log2n, FFT_FORWARD);

        NSInteger samplesPerBin = floor(_sampleCount / (_numOutputBins));

        for (NSInteger i = 0; i < _numOutputBins; i++) {
            
            // calculate the average magnitude of every sample in the bin
            float sum = 0;
            for (NSInteger j = 0; j < samplesPerBin; j++) {
                float real = _complexInput.realp[i];
                float imag = _complexInput.imagp[i];
                float magnitude = sqrtf(real * real + imag * imag);
                sum += magnitude;
            }

            sum /= samplesPerBin;
            _outputData[i] = sum;

            // check for the max overall bin value
            if (sum > _overallMaxBinValue) {
                _overallMaxBinValue = sum;
            }
        }

        // update rolling max bin values
        float maxBinValue = [self maxBinValue];
        _recentOutputMaxes[_nextRecentOutputIndex] = maxBinValue;
        _nextRecentOutputIndex = (_nextRecentOutputIndex + 1) % _numRecentMaxesTracked;
    }
}

// get the value of a given bin
- (float)valueForBin:(NSInteger)arg1 {
    return _outputData ? _outputData[arg1] : 0;
}

// get the max value for the current bins
- (float)maxBinValue {

    float max = 0;

    for (NSInteger i = 0; i < _numOutputBins; i++) {
        float val = _outputData[i];

        if (val > max) {
            max = val;
        }
    } 

    return max;
}

// get the max value of all bins over the previous 10 analyses
- (float)rollingMaxBinValue {

    float max = 0;

    for (NSInteger i = 0; i < _numRecentMaxesTracked; i++) {
        float val = _recentOutputMaxes[i];

        if (val > max) {
            max = val;
        }
    } 

    return max;
}

@end