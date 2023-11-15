
#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface VisualizerManager : NSObject {
    vDSP_Length _log2n;
    COMPLEX_SPLIT _complexData;
    FFTSetup _fftSetup;
    float *_outputBins;
    float *_window;
    float *_samples;
    float *_rollingMaxBinValues;
    float *_rollingLoudnessValues;
    int *_beatDetectionBuffer;
    float *_zeroBuf;
    int *_samplesPerOutputBin;
}

@property(assign, nonatomic) NSInteger numVisualizersActive;
@property(assign, nonatomic) NSInteger sampleCount;
@property(assign, nonatomic) BOOL hasFFTSetup;
@property(assign, nonatomic) NSInteger numOutputBins;
@property(assign, nonatomic) float overallMaxBinValue;
@property(assign, nonatomic) float minLoudnessThreshold;
@property(assign, nonatomic) NSInteger numRollingMaxBinValues;
@property(assign, nonatomic) NSInteger numRollingLoudnessValues;
@property(assign, nonatomic) NSInteger nextRollingMaxBinValueIndex;
@property(assign, nonatomic) NSInteger nextRollingLoudnessValueIndex;
@property(assign, nonatomic) NSInteger numBeatDetectionBufferValues;
@property(assign, nonatomic) NSInteger nextBeatDetectionIndex;
@property(assign, nonatomic) NSInteger processCount;
@property(assign, nonatomic) BOOL hasRecentlyDetectedBeat;
@property(assign, nonatomic) float sampleRate;
@property(assign, nonatomic) NSInteger test;
@property(assign, nonatomic) BOOL testEnabled;

+ (void)load;
+ (instancetype)sharedInstance;

- (void)initFFT;
- (void)processAudioBuffers:(AudioBufferList *)bufferList numberFrames:(NSInteger)numFrames;
- (float)valueForBin:(NSInteger)arg1;
- (float)maxBinValue;
- (float)rollingMaxBinValue;
- (float)averageRollingLoudnessValue;
- (float)calculateBPM;
- (BOOL)isAnyVisualizerActive;
- (void)handleLibraryPrefsUpdate:(NSNotification *)arg1;

@end