#import <Foundation/Foundation.h>

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	//Xbuild tools is a simply proxy tool to filter out unsupported flags used by xcode for the linker.
	//All flags between -ignoreStart and -ignoreEnd are... ignored...
	
	NSArray* args = [[NSProcessInfo processInfo] arguments];
	NSMutableArray* array = [NSMutableArray array];
	int i, c = [args count];
	BOOL ignoreArgs=FALSE;
	for(i=2;i<c;i++) { //Dont take the xbuildtools arg.
		NSString* nextArg = [args objectAtIndex:i];
		if([nextArg isEqualToString:@"-ignoreStart"]) {
			ignoreArgs = TRUE;
		} 
		
		if([nextArg isEqualToString:@"-ignoreEnd"]) {
			ignoreArgs = FALSE;
		} else if(!ignoreArgs && ![nextArg hasPrefix:@"-Wl,-syslibroot"]) {
			[array addObject:nextArg];
		}
	}
	
	//Create the task adapter to gcc (args:1)
	NSTask* ldtask = [NSTask launchedTaskWithLaunchPath:[args objectAtIndex:1] arguments:array]; 
	[ldtask waitUntilExit];
	
	int termStatus = [ldtask terminationStatus];;
	
    [pool drain];
    return termStatus;
}
