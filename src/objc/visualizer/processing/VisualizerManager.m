
#import "VisualizerManager.h"
#import "../../managers/managers.h"
#import "../../utilities/utilities.h"

static VisualizerManager *sharedVisualizerManager;
static void createSharedVisualizerManager(void *p) {
    sharedVisualizerManager = [VisualizerManager new];
}

@implementation VisualizerManager

// initialize the shared instance without obtaining a reference
+ (void)load {
    [self sharedInstance];
}

// create a singleton instance
+ (instancetype)sharedInstance {

    static dispatch_once_t onceToken;
    dispatch_once_f(&onceToken, nil, &createSharedVisualizerManager);

	return sharedVisualizerManager;
}

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        MeloManager *meloManager = [MeloManager sharedInstance];

        _sampleCount = 4096;
        _hasFFTSetup = NO;
        // _numOutputBins = 16;
        _numOutputBins = [meloManager prefsIntForKey:@"visualizerNumBars"];

        _outputBins = calloc(_numOutputBins, sizeof(float));
        _samplesPerOutputBin = calloc(_numOutputBins, sizeof(int));
        _overallMaxBinValue = 0;

        _nextRollingMaxBinValueIndex = 0;
        _numRollingMaxBinValues = 12 * 5; // covers approximately n seconds where = (12 * n)
        _rollingMaxBinValues = calloc(_numRollingMaxBinValues, sizeof(float));

        _nextRollingLoudnessValueIndex = 0;
        _numRollingLoudnessValues = 12 * 2; // covers approximately n seconds where = (12 * n)
        _rollingLoudnessValues = calloc(_numRollingLoudnessValues, sizeof(float));

        _nextBeatDetectionIndex = 0;
        _numBeatDetectionBufferValues = 12 * 10;
        _beatDetectionBuffer = calloc(_numBeatDetectionBufferValues, sizeof(int));

        _minLoudnessThreshold = 1;

        _processCount = 0;
        _testEnabled = NO;

        _numVisualizersActive = 0;
        _hasRecentlyDetectedBeat = NO;

        _sampleRate = 48000;

        [self initFFT];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleLibraryPrefsUpdate:) name:@"MELO_NOTIFICATION_PREFS_UPDATED_LIBRARY" object:meloManager];
    }

    return self;
}

// initialize variables used in the FFT calculation
- (void)initFFT {

    @synchronized(self) {

        // destroy previous setup if it exists
        if (_hasFFTSetup) {
            vDSP_destroy_fftsetup(_fftSetup);
            free(_complexData.realp);
            free(_complexData.imagp);
            free(_window);
            free(_samples);
            free(_zeroBuf);

            _hasFFTSetup = YES;
        }

        // setup the length
        _log2n = log2f(_sampleCount);

        // calculate the weights array. This is a one-off operation.
        _fftSetup = vDSP_create_fftsetup(_log2n, FFT_RADIX2);

        // define complex buffer
        _complexData.realp = (float *)calloc(_sampleCount, sizeof(float));
        _complexData.imagp = (float *)calloc(_sampleCount, sizeof(float));

        // define and setup hamming window buffer
        _window = (float *)malloc(_sampleCount * sizeof(float));
        vDSP_hamm_window(_window, _sampleCount, 0);

        // setup sample buffer
        _samples = (float *)calloc(_sampleCount, sizeof(float));

        _zeroBuf = (float *)calloc(_sampleCount, sizeof(float));
    }
}

// update the visualizer related settings if change detected
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1 {

    MeloManager *meloManager = [MeloManager sharedInstance];
    NSInteger newNumOutputBins = [meloManager prefsIntForKey:@"visualizerNumBars"];
    
    @synchronized(self) {

        if (_numOutputBins != newNumOutputBins) {    
            _numOutputBins = newNumOutputBins;
            free(_outputBins);
            free(_samplesPerOutputBin);
            _outputBins = calloc(_numOutputBins, sizeof(float));
            _samplesPerOutputBin = calloc(_numOutputBins, sizeof(int));
            _overallMaxBinValue = 0;
        }
    }
}

// process samples given by MPCAudioSpectrumAnalyzer
- (void)processAudioBuffers:(AudioBufferList *)bufferList numberFrames:(NSInteger)numFrames {

    @synchronized(self) {
        
        // do not process audio if visualizer is not active
        if (![self isAnyVisualizerActive]) {
            return;
        }

        // TODO: when would this not be the case?
        // if (bufferList->mNumberBuffers != 2) {
        //     [Logger logStringWithFormat:@"PROCESS AUDIO BUFFERS mNumberBuffers: %ld", bufferList->mNumberBuffers];
        //     // return;
        // }

        // check if the sample bytes can be processed as floats
        NSUInteger dataUnitByteSize = bufferList->mBuffers[0].mDataByteSize / numFrames;
        if (dataUnitByteSize != sizeof(float)) {
            return;
        }

        _processCount++;

        // update sample count if need be
        if (numFrames != _sampleCount) {
            _sampleCount = numFrames;
            [self initFFT];
        }

        // average all channels 
        NSInteger numChannels = bufferList->mNumberBuffers;
        memset(_samples, 0, _sampleCount * sizeof(float));

        for (NSInteger i = 0; i < numChannels; i++) {
            
            float *channelData = (float *)bufferList->mBuffers[i].mData;
            
            for (NSInteger j = 0; j < _sampleCount; j++) {
                _samples[j] += channelData[j];
            }
        }

        for (NSInteger i = 0; i < _sampleCount; i++) {
            _samples[i] /= numChannels;
        }

        // float *leftChannelData = (float *)bufferList->mBuffers[0].mData;
        // float *rightChannelData = (float *)bufferList->mBuffers[1].mData;

        // // combine both channels into one sample buffer
        // for (NSInteger i = 0; i < _sampleCount; i++) {
        //     _samples[i] = (leftChannelData[i] + rightChannelData[i]) / 2;
        // }

        // apply the hamming window function
        // vDSP_vmul(_complexData.realp, 1, _window, 1, _complexData.realp, 1, _sampleCount);
        // vDSP_vmul(_complexData.imagp, 1, _window, 1, _complexData.imagp, 1, _sampleCount);
        // vDSP_vmul(_samples, 1, _window, 1, _samples, 1, _sampleCount);

        // copy samples to complex buffer
        NSInteger arrayByteSize = _sampleCount * sizeof(float);
        // memcpy(_complexData.realp, (float *)bufferList->mBuffers[1].mData, arrayByteSize);
        // memcpy(_complexData.imagp, (float *)bufferList->mBuffers[1].mData, arrayByteSize);
        memcpy(_complexData.realp, _samples, arrayByteSize);
        memcpy(_complexData.imagp, _zeroBuf, arrayByteSize);
        // vDSP_ctoz((COMPLEX*)_samples, 2, &_complexData, 1, _sampleCount/2);

        // perform a forward FFT inplace on _complexData
        // vDSP_fft_zrip(_fftSetup, &_complexData, 1, _log2n, FFT_FORWARD);
        vDSP_fft_zip(_fftSetup, &_complexData, 1, _log2n, FFT_FORWARD);

        // zero out the DC component (average of all values)
        // _complexData.realp[0] = 0.0f;
        // _complexData.imagp[0] = 0.0f;

        // define lower and upper bounds for frequncies to view
        NSInteger targetLowFreq = 20;
        NSInteger targetHighFreq = 20000;

        // calculate the output data index that contains the target frequencies
        NSInteger lowFreqIndex = floor(targetLowFreq / (_sampleRate / 2) * (_sampleCount / 2));
        NSInteger highFreqIndex = floor(targetHighFreq / (_sampleRate / 2) * (_sampleCount / 2));

        NSInteger numTargetedResults = highFreqIndex - lowFreqIndex + 1;
        _test = numTargetedResults;

        float rmsVal = 0;

        // reset values for output bins
        memset(_outputBins, 0, _numOutputBins * sizeof(float));
        memset(_samplesPerOutputBin, 0, _numOutputBins * sizeof(int));

        // iterate over the targeted samples
        for (NSInteger i = 0; i < numTargetedResults; i++) {

            NSInteger dataIndex = lowFreqIndex + i;
            NSInteger binIndex = floor((float)i / numTargetedResults * _numOutputBins);


            float real = _complexData.realp[dataIndex];
            float imag = _complexData.imagp[dataIndex];
            float magnitude = sqrtf(real * real + imag * imag);
            rmsVal += magnitude * magnitude;
            magnitude = log2f(magnitude);
            // magnitude = fabsf(magnitude);
            // magnitude /= _sample;
            if (_testEnabled) {
            [Logger logStringWithFormat:@"dataIndex: %ld, binIndex: %ld, magnitude: %lf", dataIndex, binIndex, magnitude];
            }

            _outputBins[binIndex] += magnitude;
            _samplesPerOutputBin[binIndex]++;
        }

        // calculate the average over all samples in the bin
        for (NSInteger i = 0; i < _numOutputBins; i++) {
            if (_testEnabled) {

                [Logger logStringWithFormat:@"i: %ld, _outputBin: %lf, _samplesPerBin: %ld, after div: %lf", 
                    i, _outputBins[i],_samplesPerOutputBin[i], _outputBins[i] / _samplesPerOutputBin[i]];
            }
            _outputBins[i] /= _samplesPerOutputBin[i];

            //             // check for the max overall bin value
            // if (sum > _overallMaxBinValue) {
            //     _overallMaxBinValue = sum;
            // }
        }

        // NSInteger numUsableResults = floor((20000 / (_sampleRate / 2)) * (_sampleCount / 2));
        // _test = numUsableResults;
        // NSInteger numUsableResults = floor(_sampleCount / 2);
        // NSInteger samplesPerBin = floor(numUsableResults / _numOutputBins); // TODO: need a better way of filtering the higher frequencies
        // float rmsVal = 0;

        // for (NSInteger i = 0; i < _numOutputBins; i++) {
            
        //     // calculate the average magnitude of every sample in the bin
        //     float sum = 0;
        //     for (NSInteger j = 0; j < samplesPerBin; j++) {
        //         float real = _complexData.realp[i * samplesPerBin + j];
        //         float imag = _complexData.imagp[i * samplesPerBin + j];
        //         float magnitude = sqrtf(real * real + imag * imag);
        //         rmsVal += magnitude * magnitude;
        //         magnitude = logf(magnitude);
        //         sum += magnitude;
        //     }

        //     sum /= samplesPerBin;
        //     _outputBins[i] = sum;

        //     // check for the max overall bin value
        //     if (sum > _overallMaxBinValue) {
        //         _overallMaxBinValue = sum;
        //     }
        // }
        // _outputBins[0] = 0;

        // update rolling max bin values
        float maxBinValue = [self maxBinValue];
        _rollingMaxBinValues[_nextRollingMaxBinValueIndex] = maxBinValue;
        _nextRollingMaxBinValueIndex = (_nextRollingMaxBinValueIndex + 1) % _numRollingMaxBinValues;

        // calculate the RMS value (approximating loudness)
        rmsVal = sqrtf(rmsVal / _sampleCount);


        float averageLoudness = [self averageRollingLoudnessValue];
        [Logger logStringWithFormat:@"currLoudness: %lf, avgLoudness: %lf", rmsVal, averageLoudness];
        float threshold = MAX(_minLoudnessThreshold, averageLoudness * 1.5);
        int beatOccurred = rmsVal >= threshold;

        if (beatOccurred) {
            _hasRecentlyDetectedBeat = YES;
        }

        _beatDetectionBuffer[_nextBeatDetectionIndex] = beatOccurred;
        _nextBeatDetectionIndex = (_nextBeatDetectionIndex + 1) % _numBeatDetectionBufferValues;

        _rollingLoudnessValues[_nextRollingLoudnessValueIndex] = rmsVal;
        _nextRollingLoudnessValueIndex = (_nextRollingLoudnessValueIndex + 1) % _numRollingLoudnessValues;
    }
}

- (NSString *)testString {

    NSMutableString *str = [NSMutableString stringWithCapacity:_sampleCount];

    for (NSInteger i = 0; i < _sampleCount; i++) {
        [str appendFormat:@"%.3f\n", _samples[i]];
    }

    return str;
}

// get the value of a given bin
- (float)valueForBin:(NSInteger)arg1 {
    return _outputBins && _numOutputBins > arg1 ? MAX(_outputBins[arg1], 0) : 0; // TODO: keep this max here?
}

// get the max value for the current bins
- (float)maxBinValue {

    float max = 0;

    for (NSInteger i = 0; i < _numOutputBins; i++) {
        float val = _outputBins[i];

        if (val > max) {
            max = val;
        }
    } 

    return max;
}

// get the max value of all bins over the previous few analyses
- (float)rollingMaxBinValue {

    float max = 0;

    for (NSInteger i = 0; i < _numRollingMaxBinValues; i++) {
        float val = _rollingMaxBinValues[i];

        if (val > max) {
            max = val;
        }
    } 

    return max;
}

// get the average rolling loudness value
- (float)averageRollingLoudnessValue {

    float sum = 0;

    for (NSInteger i = 0; i < _numRollingLoudnessValues; i++) {
        sum += _rollingLoudnessValues[i];
    } 

    return sum / _numRollingLoudnessValues;
}

- (float)calculateBPM {

    // NSInteger lastBeatIndex = 0;
    NSInteger currDistance = 0;
    NSInteger numBeats = 0;
    NSInteger distanceSum = 0;

    @synchronized(self) {


    for (NSInteger i = 0; i < _numBeatDetectionBufferValues; i++) {
        unsigned char beatOccurred = _beatDetectionBuffer[i];

        if (beatOccurred) {
            // lastBeatIndex = i;
            distanceSum += currDistance;
            currDistance = 0;
            numBeats++;
        } else {
            currDistance++;
        }
    }
    }

    float avgDistance = distanceSum / numBeats;
    return avgDistance * (_sampleCount / _sampleRate) * 60;
}

- (BOOL)isAnyVisualizerActive {
    return _numVisualizersActive > 0;
}

@end