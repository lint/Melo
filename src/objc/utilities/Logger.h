
#import <UIKit/UIKit.h>

// utility class to log debug messages to file
@interface Logger : NSObject
@property(strong, nonatomic) NSString *logFileDir;
@property(strong, nonatomic) NSString *logFilePath;
@property(strong, nonatomic) NSObject *lock;
@property(strong, nonatomic) NSString *contents;
@property(assign, nonatomic) BOOL enabled;

+ (void)load;
+ (instancetype)sharedInstance;
- (instancetype)init;

- (void)logString:(NSString *)arg1;
- (void)logStringWithFormat:(NSString *)arg1, ...;

@end