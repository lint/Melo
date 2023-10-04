
#import "Logger.h"
#import "../managers/managers.h"

static Logger *sharedLogger;
static void createSharedLogger(void *p) {
    sharedLogger = [Logger new];
}

@implementation Logger

// loads the object if you don't need to use it right away
+ (void)load {
    [self sharedInstance];
}

// create a singleton instance
+ (instancetype)sharedInstance {
	// static Logger* sharedInstance = nil;
	// static dispatch_once_t onceToken;
	// dispatch_once(&onceToken, ^{
	// 	sharedInstance = [Logger new];
	// });
	// return sharedInstance;

    static dispatch_once_t onceToken;
    dispatch_once_f(&onceToken, nil, &createSharedLogger);

	return sharedLogger;
}

// default initializer
- (instancetype)init {

    if ((self = [super init])) {

        // _enabled = [[MeloManager sharedInstance] prefsBoolForKey:@"loggingEnabled"];
        NSDictionary *prefs = [[NSDictionary alloc] initWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/com.lint.melo.prefs.plist"];
        id enabledVal = [prefs objectForKey:@"loggingEnabled"];

        if (enabledVal) {
            _enabled = [enabledVal boolValue];
        } else {
            _enabled = NO;
        }

        if (!_enabled) {
            return self;
        }

        // store files in the app's Application Support directory since it is sandboxed
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
        _logFileDir = [paths firstObject];

        // use the current date and time as the file name
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];

        NSString *dateString = [formatter stringFromDate:[NSDate date]];
        _logFilePath = [NSString stringWithFormat:@"%@/%@_log.txt", _logFileDir, dateString];
        // _logFilePath = [NSString stringWithFormat:@"%@/log.txt", _logFileDir];

        // lock object to provide synchronous writes to the log file
        // _lock = [NSObject new];

        // try to read the log file's contents if it already exists
        NSError *error = nil;
        _contents = [NSString stringWithContentsOfFile:_logFilePath encoding:NSUTF8StringEncoding error:&error];

        if (error) {
            _contents = @"";
        }
    }

    return self;
}

// append a given string to the log file
- (void)logString:(NSString *)arg1 {

    if (!_enabled) {
        return;
    }

    arg1 = [arg1 copy];

    @synchronized(self) {

        NSError *error = nil;

        // NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        // [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss(SSS)"];

        // NSString *dateString = [formatter stringFromDate:[NSDate date]];

        // NSString *newContents = [NSString stringWithFormat:@"%@[%@] %@\n", _contents, dateString, arg1];
        // NSString *newContents = [NSString stringWithFormat:@"%@[log] %@\n", _contents, arg1];
        NSString *newContents = [[[_contents stringByAppendingString:@"[log] "] stringByAppendingString:arg1] stringByAppendingString:@"\n"];
        _contents = newContents;
        [_contents writeToFile:_logFilePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    }
}

// intermediate method to directly take string format arguments
- (void)logStringWithFormat:(NSString *)arg1, ... {

    if (!_enabled) {
        return;
    }

    arg1 = [arg1 copy];

    va_list va;
    va_start(va, arg1);    
    NSString *formattedStr = [[NSString alloc] initWithFormat:arg1 arguments:va];
    va_end(va);

    [self logString:formattedStr];
}

// append a given string to the log file
+ (void)logString:(NSString *)arg1 {
    [[Logger sharedInstance] logString:arg1];
}

// intermediate method to directly take string format arguments
+ (void)logStringWithFormat:(NSString *)arg1, ... {
    
    va_list va;
    va_start(va, arg1);    
    NSString *formattedStr = [[NSString alloc] initWithFormat:arg1 arguments:va];
    va_end(va);

    [[Logger sharedInstance] logString:formattedStr];
}

@end