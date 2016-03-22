#include "SwipyFoldersPrefs.h"

@implementation SwipyFoldersPrefs

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"SwipyFoldersPrefs" target:self] retain];
	}

	return _specifiers;
}

-(void)respring {
	system("killall -9 SpringBoard");
}

- (void)github {
    NSURL *githubURL = [NSURL URLWithString:@"https://github.com/megacookie/SwipyFolders"];
    [[UIApplication sharedApplication] openURL:githubURL];
}

- (void)contact {
	NSURL *url = [NSURL URLWithString:@"mailto:mail@jessevandervelden.nl?subject=SwipyFolders"];
	[[UIApplication sharedApplication] openURL:url];
}

- (void)paypal {
	NSURL *url = [NSURL URLWithString:@"https://paypal.me/JessevanderVelden"];
	[[UIApplication sharedApplication] openURL:url];
}


@end
