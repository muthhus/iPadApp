//
//  engine.m
//  mobePlaceIPad
//
//  Created by Ana Ruelas on 7/8/11.
//  Copyright 2011 Massachusetts Institute of Technology. All rights reserved.
//

#import "engine.h"


@implementation engine


#import "engine.h"
#import "conference.h"
#import "conferenceList.h"
#import "levelSlot.h"
#import "detailSlot.h"
#import "slotFactory.h"
#import "constants.h"
#import "commController.h"
#import "conventionClientAppDelegate.h"
#import "zipArchive.h"

#import <CommonCrypto/CommonDigest.h>


@synthesize conferences;
@synthesize	levelViewController;
@synthesize	detailViewController;
@synthesize	slotFactory;
@synthesize currentConference;
@synthesize conferenceNavController;
@synthesize	foundValidConferenceList;
@synthesize currentXMLNode;
@synthesize textInProgress;
@synthesize xmlNodeStack;
@synthesize resourcePrefix;
@synthesize resourcesLocallyCached;
@synthesize commController;
@synthesize toFileFullPath;
@synthesize downLoadConferenceID;
@synthesize insertingConference;
@synthesize parsingCopyList;

#pragma mark NSXMLParser delegate Methods
#pragma mark Conference Retrieval Support
#pragma mark - View lifecycle



- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



/*
 100614	NALEX	PVEngine is a singleton.
 */

+ (id) sharedPVEngine
{
    static PVEngine *shared = nil;
	
    if ( !shared )
        shared = [[self alloc] init];
	
    return shared;
	
}


- (id) init
{
	if((self = [super init]) != nil)
	{
		conferences					= [[PVConferenceList alloc] init];
		textInProgress				= [[NSMutableString alloc] init];
		resourcePrefix				= [[NSMutableString alloc] init];
		foundValidConferenceList	= NO;
		resourcesLocallyCached		= NO;
		parsingCopyList				= NO;
	}
	
	return( self );
	
}


- (void) dealloc
{
	[self saveState];
	
    [conferences release];
	[conferenceNavController release];
	[textInProgress release];
	[resourcePrefix release];
	
    [super dealloc];
}
	

-(void) start
{
	NSLog(@"PVEngine:start");
	
	//----------------------------------------------//	
	
	[self loadConferenceListFromFile];				//	Standard file name in Documents folder
	
	//----------------------------------------------//	
	//----------------------------------------------//	
	//----------------------------------------------//	
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(pushSlot:)
												 name:kNotificationPushSlot
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(popSlot:)
												 name:kNotificationPopSlot
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(getAConference:)
												 name:kNotificationGetConference
											   object:nil];
	
	//----------------------------------------------//	
	
}
	

-(void)loadConferenceListFromFile
{
	//----------------------------------------------//	Load conference list file ( if any )
	
	NSArray			*arrayPaths		= NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
	NSString		*docDir			= [arrayPaths objectAtIndex:0];
	NSString		*fileName		= [docDir stringByAppendingPathComponent:kConferenceListFileName];
	NSURL			*theURL			= [[NSURL alloc] initFileURLWithPath:fileName];
	NSData			*conferenceList = [NSData dataWithContentsOfURL:theURL];
	
	[conferenceList retain];
	
	[self loadConferenceListWithData:conferenceList];
	
	[theURL release];
	[conferenceList release];
	
	//----------------------------------------------//	user preferences
	
	[self restoreState];
	
	//----------------------------------------------//	Set to conference based on restored-state
    
    /* 110124 old stuff....
     
     if( [[conferences slots] count] > 0 )
     {
     currentLevel = [[conferences slots] objectAtIndex:0];
     
     [levelViewController changeLevel:currentLevel];
     levelViewController.title = [currentLevel.attributes objectForKey:kXMLShortTitle];
     }
     */
	
}

//****************************************************************************************************	
//	110119	NALEX	We've retrieved conference list from PlaceView's server. Now we need to parse it
//					and do something with it - like display it.

-(void) loadConferenceListWithData:(NSData *)theData
{
	NSLog( @"[PVEngine loadConferenceListWithData:]" );
	
	//----------------------------------------------//	Remove any existing stuff
	
	while( [[conferences slots] count] )
		[[conferences slots] removeObjectAtIndex:0];
	
	//----------------------------------------------//	Open in parser
	
	NSXMLParser *aParser = [[NSXMLParser alloc] initWithData: theData];
	
	//----------------------------------------------//	Configure parser and set up
	
	currentXMLNode = nil;
	xmlNodeStack = [[NSMutableArray alloc] init];
	insertingConference = nil;						//	we're not inserting a conference into an existing list ( like expanding )
	
	[aParser setDelegate:self];						// Set this controller as the delegate
	[aParser setShouldProcessNamespaces:NO];
	[aParser setShouldReportNamespacePrefixes:NO];
	[aParser setShouldResolveExternalEntities:NO];
	
	[aParser parse];								// this starts the SAX parsing and calls the delegate methods
	[aParser release];
	
	
	for( int i = 0;i < [[conferences slots] count]; i++ )
	{
		NSDictionary *attributes = [[[conferences slots] objectAtIndex:i] attributes];
		
		NSLog( @"Conference %d attributes:%@", i+1, attributes );
		NSLog( @"=======================");
	}
	
	if( [[conferences slots] count] > 0 )
	{
		currentLevel = conferences;
		
		[levelViewController changeLevel:currentLevel];
		levelViewController.title = [currentLevel.attributes objectForKey:kXMLShortTitle];
	}	
	
}
	

-(void) handleNotification:(NSNotification *)theNotification
{
	NSLog(@"PVEngine:handleNotification");
}



- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)theString
{	
    if( self.textInProgress )
	{
        [textInProgress appendString:theString];
    }
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	[self.textInProgress setString:@""];
	
	if( [elementName isEqualToString:kXMLConferenceList] )
	{
		foundValidConferenceList = YES;
		
		//		PVConferenceList	*aList = [[PVConferenceList alloc] init];
		//		[xmlNodeStack insertObject:aList atIndex:0];
		self.currentXMLNode		= conferences;
		self.currentConference	= conferences;
	}
    else if( [elementName isEqualToString:kXMLConference])
	{
		if( self.insertingConference == nil )
		{
			PVConference	*aConference = [[PVConference alloc] init];
			[xmlNodeStack insertObject:aConference atIndex:0];
			[[currentXMLNode slots] addObject:aConference];
			self.currentXMLNode = aConference;
		}
		else
		{
			[xmlNodeStack insertObject:insertingConference atIndex:0];
			self.currentXMLNode = insertingConference;
		}
    }
	else if( [elementName isEqualToString:kXMLLevel])
	{
		PVLevelSlot	*aLevel = [[PVLevelSlot alloc] init];
		[xmlNodeStack insertObject:aLevel atIndex:0];
		[[currentXMLNode slots] addObject:aLevel];
		self.currentXMLNode = aLevel;
	}
	else if( [elementName isEqualToString:kXMLDetail])
	{
		PVDetailSlot	*aDetail = [[PVDetailSlot alloc] init];
		[xmlNodeStack insertObject:aDetail atIndex:0];
		[[currentXMLNode slots] addObject:aDetail];
		self.currentXMLNode = (PVLevelSlot *)aDetail;
	}
	else if( [elementName isEqualToString:kXMLDetailAttributeList] )	//	110302	These go in current detail
	{
		self.parsingCopyList = YES;
	}
	
}


//****************************************************************************************************	
//	100621	NALEX	Inserts parsed object into appropriate place. NOTE: only levels and details and chicklets
//					are declared as nodes. All other objects are merely attributes of those classes.


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	
	if( [elementName isEqualToString:kXMLConferenceList] )
	{
		//		[self.xmlNodeStack removeObjectAtIndex:0];	//	no nested conference lists
		self.currentXMLNode = nil;
	}
	else if( [elementName isEqualToString:kXMLLevel] || [elementName isEqualToString:kXMLDetail] )
	{
		[self.xmlNodeStack removeObjectAtIndex:0];
		self.currentXMLNode = [self.xmlNodeStack objectAtIndex:0];	//	this node was added to parent when created.
	}
	else if( [elementName isEqualToString:kXMLConference] )
	{
		[self.xmlNodeStack removeObjectAtIndex:0];
		self.currentXMLNode = conferences;		
	}
	else if( [elementName isEqualToString:kXMLDetailAttributeList] )
	{
		self.parsingCopyList = NO;
	}
	//----------------------------------------------//	Generic Attribute 
	else if( ![elementName isEqualToString:kXMLConferenceList] )
	{
		NSString *aString = [NSString stringWithString:self.textInProgress];
		
        //		NSLog( @"=-=-=-=->>%@", aString );
		
		aString = [self modifyURL:aString];
		
		if( self.parsingCopyList )
		{
			PVDetailSlot	*aDetail = (PVDetailSlot *)self.currentXMLNode;
			
			[aDetail.copyList setObject:aString forKey:elementName];
		}
		else 
		{
			[[self.currentXMLNode attributes] setObject:aString forKey:elementName];
			
			if( [elementName isEqualToString:kXMLConferenceID] && (self.currentXMLNode.slotKind == kSlotKindConference ) )
			{
				((PVConference *)(self.currentXMLNode)).uniqueID = [[NSString alloc] initWithString:aString];
				[(PVConference *)self.currentXMLNode calculateResourcePrefix];
			}
		}
	}
	
}
	

- (void)parserDidEndDocument:(NSXMLParser *)parser
{
	
	
}
	
//****************************************************************************************************	
//	100624	NALEX	Insert new slot here. Goes into a stack, so that back-trail can be kept.
//	110131			Modified to handle loading conference data on-the-fly

-(void)pushSlot:(NSNotification *)notification
{
	PVSlot	*aSlot = [notification object];
	
	switch( aSlot.slotKind )
	{
		case kSlotKindConference:
		{
			PVConference *aConference = (PVConference *)aSlot;
			
			if( aConference.isDownloaded && ( [aConference.slots count] == 0 ) )		//	if there are no slots - then we haven't expanded / inserted the conference, yet
			{
				[self insertConferenceXMLIntoList:aConference.uniqueID];			//	so, let's expand it, but not go anywhere - just yet.
				break;
			}
			// NO BREAK IS INTENTIONAL!
		}
		case kSlotKindLevel:
		{
			PVLevelViewController *newLevel = [[PVLevelViewController alloc] initWithNibName:@"PVLevelViewController" bundle:nil];
			
			newLevel.currentLevel = (PVLevelSlot *)aSlot;
			newLevel.title = [aSlot.attributes objectForKey:kXMLShortTitle];
			[conferenceNavController pushViewController:newLevel animated:YES];
			[newLevel release];
			
			UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStylePlain target:self action:@selector(navButtonHit:)];          
			conferenceNavController.navigationItem.rightBarButtonItem = anotherButton;
			[anotherButton release];
			
			//====================================================
			
			break;
		}
		case kSlotKindDetail:
		{
			PVDetailViewController *newDetail = [[PVDetailViewController alloc] initWithNibName:@"PVDetailViewController" bundle:nil];
			
			newDetail.currentDetail = (PVDetailSlot *)aSlot;
			newDetail.title = [aSlot.attributes objectForKey:kXMLShortTitle];
			[conferenceNavController pushViewController:newDetail animated:YES];
			[newDetail release];
			break;
		}
		default:
		{
			break;
		}
	}
	
	
}

//****************************************************************************************************	
//	100624	NALEX	Insert new slot here. Goes into a stack, so that back-trail can be kept.

-(void)popSlot:(NSNotification *)notification
{
	
}

//****************************************************************************************************	
//	100628	NALEX	Test for navigation view right button stuff

-(void)navButtonHit:(id)sender
{
	
}
	
//	100718	NALEX
//	110118	NALEX	Load in conferences - if any

-(void) restoreState
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	id		anObject;
	
	anObject = [defaults objectForKey:kUserDefaultsResourcePrefix];
	if( anObject )
		resourcePrefix			=	[NSString stringWithString:anObject];
	
	anObject = [defaults objectForKey:kUserDefaultsLocalCache];
	if( anObject )
		resourcesLocallyCached	=	[anObject boolValue];
	
}	

-(void) saveState
{
	//	NSLog( @"saveState...scrollAmount = %d", scrollAmount );
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	[defaults setObject:self.resourcePrefix  forKey:kUserDefaultsResourcePrefix];
	[defaults setObject:[NSNumber numberWithBool:resourcesLocallyCached]  forKey:kUserDefaultsLocalCache];	
	[defaults synchronize];	
}

//****************************************************************************************************	
//	100718	NALEX	Takes stuff like "$URL_ROOT" and replaces it with online or cached references, 
//					including file:/// or http://
//	110228	NALEX	Modified to merely replace $URL_ROOT, and not do it within context of path components. 
//					this was done so that hrefs inside of detail pages would work.

-(NSString *)modifyURL:(NSString *)rawURL
{
	//	NSLog( @"PVEngine::modifyURL" );
	
	//----------------------------------------------//	Replace URL prefix with another online...
	
	
#if	THIS_WORKED
	
	NSArray		*pathComponents = [rawURL pathComponents];
	
	if( [pathComponents count] > 0 )
	{
		NSString	*aString = [pathComponents objectAtIndex:0];
		
		if( aString )
		{
			
			NSLog( @"B4------->%@", aString );
			
			if( [aString compare:@"$URL_ROOT"] == NSOrderedSame )
			{
				NSMutableString *result = [[NSMutableString alloc] initWithString:resourcePrefix];
				for( int i = 1;i < [pathComponents count];i++ )
				{
					[result appendString:@"/"];
					[result appendString:(NSString *)[pathComponents objectAtIndex:i]];
				}
				
				NSLog( @"AFTER------->%@", result );
				
				[result autorelease];
				return( result );
			}
		}
	}
    
	return( rawURL );
	
#endif
	
	return( [rawURL stringByReplacingOccurrencesOfString:@"$URL_ROOT" withString:resourcePrefix] );
	
}

//	110113	NALEX	utility - this takes a string and performs an md5 hash on it.

-(NSString *)md5:(NSString *)str
{
	const char *cStr = [str UTF8String];
	unsigned char result[16];
	CC_MD5( cStr, strlen(cStr), result );
	return [NSString stringWithFormat:
			@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], 
			result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11],
			result[12], result[13], result[14], result[15]
			];	
}


/*
    110124	Downloads a conference based on Id in conference List
*/

-(void) getAConference:(NSNotification *)theNotification
{	
	//----------------------------------------------//	Configure FROM
	
	self.downLoadConferenceID = [theNotification object];
	
	PVConventionClientAppDelegate *aDelegate = [[UIApplication sharedApplication] delegate];
	NSString	*sessionID		= aDelegate.commController.retrievedSessionID;
	NSString	*serverFullPath = [NSString stringWithFormat:@"%@conference?sessionId=%@&conferenceId=%@", kWebServerAddress, sessionID,[theNotification object]];
	NSURL		*serverURL		= [NSURL URLWithString:serverFullPath];
	
	//----------------------------------------------//	Configure TO
	
	NSArray		*arrayPaths		= NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
	NSString	*docDir			= [arrayPaths objectAtIndex:0];
	NSString	*toFileName		= [NSString stringWithFormat:@"conference_%@.zip",[theNotification object] ];
	
	self.toFileFullPath	= [docDir stringByAppendingPathComponent:toFileName];
	[self.toFileFullPath retain];
	
	//----------------------------------------------//	Create File for receiving
	
	NSMutableData *fake = [[NSMutableData alloc] initWithLength:0];
	BOOL result = [[NSFileManager defaultManager] createFileAtPath:toFileFullPath
														  contents:fake 
														attributes:nil];
	[fake release];
	
	if (!result) 
	{
		NSLog( @"Error creating %@", toFileName );
		return;
	}
	
	//----------------------------------------------//	Open File for receiving
	
	fileHandle = [[NSFileHandle fileHandleForWritingAtPath:toFileFullPath] retain];
	bytesCount = 0;
	
	//----------------------------------------------//	Open URL connection
	
	NSURLRequest *request = [NSURLRequest requestWithURL:serverURL
											 cachePolicy:NSURLRequestReloadIgnoringCacheData 
										 timeoutInterval:60.0f];
	
	currentConnection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	receivedData = [[NSMutableData alloc] initWithCapacity:0]; 
	
}
	

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data 
{
	
    bytesCount = bytesCount + [data length];
    [receivedData appendData:data]; 
	
    //If the size is over 10MB, then write the current data object to a file and clear the data
	
    if(receivedData.length > kMaxDataLength)
	{
        [fileHandle truncateFileAtOffset:[fileHandle seekToEndOfFile]]; //setting aFileHandle to write at the end of the file
		
        [fileHandle writeData:receivedData]; //actually write the data
		
        [receivedData release];
        receivedData = nil;
        receivedData = [[NSMutableData data] retain];
    }
	
	//    [progressView setProgress:(float)bytesCount/sizeOfDownload];
	
}


- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    NSLog(@"===================>>>Succeeded! Received %d bytes of data",[receivedData length]);
	
    //  Release and clean some ivars
    //
    [currentConnection release];
    currentConnection = nil;
	
    [fileHandle writeData:receivedData];
    [receivedData release];
    [fileHandle release];
	fileHandle = nil;
	receivedData = nil;
	bytesCount = 0;
	
	//----------------------------------------------//	**unzip resulting file**
	
	[self inflateArchive];
	
}


- (void)inflateArchive
{
	
	NSArray		*arrayPaths		= NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
	NSString	*docDir			= [arrayPaths objectAtIndex:0];
	NSString	*newFolderName	= [NSString stringWithFormat:@"conference_%@", self.downLoadConferenceID];
	NSString	*destFolder		= [docDir stringByAppendingPathComponent:newFolderName];
	
	
	ZipArchive *z = [[ZipArchive alloc] init];
	
	[z UnzipOpenFile:self.toFileFullPath];
	[z UnzipFileTo:destFolder overWrite:YES];
	[z UnzipCloseFile];
	
	
	
	//	Following should be added with real archives to inflate in another thread.
	
	[self inflateComplete];
	
	
	/*
	 NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	 
	 NSString *archivePath = [NSString stringWithString:self.toFileFullPath];
	 [archivePath retain];
	 
	 ZKFileArchive *archive = [ZKFileArchive archiveWithArchivePath:archivePath];
	 [archive setDelegate:self];
	 // I think this is for progress view    [self setArchiveSize:[[[archive centralDirectory] valueForKeyPath:@"@sum.uncompressedSize"] unsignedLongValue]];
	 [archive inflateToDiskUsingResourceFork:NO];
	 
	 // do something with inflated archive. 
	 // zipkit puts all inflated files in the same directory as the archive.
	 
	 [self performSelectorOnMainThread:@selector(inflateComplete) withObject:nil waitUntilDone:NO];
	 
	 [pool drain];
	 
	 */
	
}


- (void)inflateComplete 
{
	
	NSLog( @"inflateComplete" );
	
    // do something after inflate finishes. like hide the progress view and stuff.
	
	[self insertConferenceXMLIntoList:self.downLoadConferenceID];
	
	UIAlertView *successfulLoadConferenceAlert = [[UIAlertView alloc] 
                                                  initWithTitle:@"Success" 
                                                  message:@"Downloaded conference successfully."
                                                  delegate:self cancelButtonTitle:nil
                                                  otherButtonTitles:@"OK", nil];
	[successfulLoadConferenceAlert show];
}


/*
            110130	Designed after user has downloaded a conference and we want to insert the conference info
			into the main hierarchy to give the user access to it. One magic part is that the individual
			xml items will automatically be replaced with the new stuff.
*/
-(void) insertConferenceXMLIntoList:(NSString *)conferenceID


{
	NSLog( @"[PVEngine insertConferenceXMLIntoList:]" );
	
	//----------------------------------------------//	Find path to conference xml file and insert into NSData object.
	
	NSArray		*arrayPaths		= NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES);
	NSString	*path			= [arrayPaths objectAtIndex:0];
	NSString	*folderName		= [NSString stringWithFormat:@"%@%@", kConferencePathPrefix, conferenceID];
	
	path = [path stringByAppendingPathComponent:folderName];
	NSString *fullPath = [path stringByAppendingPathComponent:kConferenceDataFileName];
	
	[fullPath retain];
	
	NSData *conferenceData = [[NSData alloc] initWithContentsOfFile:fullPath];
	
	//----------------------------------------------//	Retrieve ( mostly empty ) existing conference in conference list
	
	PVConference *aConference = [conferences conferenceWithID:conferenceID];
	
	if( aConference == nil )
		return;
	
	[aConference calculateResourcePrefix];
	resourcePrefix = [NSMutableString stringWithString:aConference.resourcePrefix];
	
	//	[conferences removeConferenceWithID:conferenceID];	//	Placeholder will be replaced forthwith...
	
	//----------------------------------------------//	Open in parser
	
	NSXMLParser *aParser = [[NSXMLParser alloc] initWithData: conferenceData];
	
	//----------------------------------------------//	Configure parser and set up
	
	currentXMLNode = conferences;
	xmlNodeStack = [[NSMutableArray alloc] init];
	insertingConference = aConference;				//	we're inserting, so jump through hoops
	
	[aParser setDelegate:self];						// Set this controller as the delegate
	[aParser setShouldProcessNamespaces:NO];
	[aParser setShouldReportNamespacePrefixes:NO];
	[aParser setShouldResolveExternalEntities:NO];
	
	[aParser parse];								// this starts the SAX parsing and calls the delegate methods
	[aParser release];
	
	//	aConference = [conferences conferenceWithID:conferenceID];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPushSlot object:aConference];
	
	//----------------------------------------------//	Clean up
	
	[conferenceData release];
	[fullPath release];
	[xmlNodeStack release];
	
	
}	//	insertConferenceXMLIntoList:


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}


@end

