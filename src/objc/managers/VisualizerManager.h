
#import <UIKit/UIKit.h>
#import <Accelerate/Accelerate.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface VisualizerManager : NSObject {
    vDSP_Length _log2n;
    COMPLEX_SPLIT _complexInput;
    FFTSetup _fftSetup;
    float *_outputData;
    float *_recentOutputMaxes;
}

@property(assign, nonatomic) NSInteger sampleCount;
@property(assign, nonatomic) BOOL hasFFTSetup;
@property(assign, nonatomic) NSInteger numOutputBins;
@property(assign, nonatomic) float overallMaxBinValue;
@property(assign, nonatomic) NSInteger numRecentMaxesTracked;
@property(assign, nonatomic) NSInteger nextRecentOutputIndex;
- (void)initFFT;
- (void)processAudioBuffers:(AudioBufferList *)bufferList numberFrames:(NSInteger)numFrames;
- (float)valueForBin:(NSInteger)arg1;
- (float)maxBinValue;
- (float)rollingMaxBinValue;

@end