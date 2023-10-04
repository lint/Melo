
#ifndef SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#endif

#ifndef MAX
#define MAX(a,b) ( ((a) > (b)) ? (a) : (b) )
#endif

#ifndef MIN
#define MIN(a,b) ( ((a) < (b)) ? (a) : (b) )
#endif
