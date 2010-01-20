#import "BTLGetError.h"
#import <sys/errno.h>

int BTLGetError()
{
#ifdef WIN32
	return WSAGetLastError();
#else
	return errno;
#endif
}
