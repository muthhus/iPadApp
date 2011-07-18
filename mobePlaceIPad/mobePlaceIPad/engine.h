//
//  engine.h
//  mobePlaceIPad
//
//  Created by Ana Ruelas on 7/8/11.
//  Copyright 2011 Massachusetts Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import	"levelViewController.h"
#import "detailViewController.h"
#import	"conferenceController.h"

//Constants

#define	kUserDefaultsResourcePrefix		@"ResourcePrefix"
#define kUserDefaultsLocalCache			@"ResourceLocalCache"




//Forwards

@class	slot;
@class	conference;
@class	levelSlot;
@class	slotFactory;
@class	conferenceList;
@class	commController;


@interface engine : NSObject
{
	//	NSMutableArray				*conferences;				//	Contains Conferences & Info
	PVConferenceList			*conferences;
	PVLevelViewController		*levelViewController;
	PVDetailViewController		*detailViewController;
	PVCommController			*commController;
	PVSlotFactory				*slotFactory;
	PVLevelSlot					*currentLevel;
	PVConference				*currentConference;
	PVConferenceNavController	*conferenceNavController;
	BOOL						foundValidConferenceList;
	
	NSMutableArray				*xmlNodeStack;		//	nested nodes "in progress"
	PVLevelSlot					*currentXMLNode;	//	used during XML parsing
	NSMutableString				*textInProgress;	//	ibid
	NSMutableString				*resourcePrefix;	//	100718	starts URL
	BOOL						resourcesLocallyCached;	//	100718
	BOOL						parsingCopyList;	//	110302
	
	NSFileHandle				*fileHandle;			//	downloads TO this file
	NSURLConnection				*currentConnection;	//	used for downloading a specific conference
	NSMutableData				*receivedData;		//	temporary space for currentConnection's received data before writing to fileHandle
	int							bytesCount;			//	part of receiving file's info
	NSString					*toFileFullPath;	//	short cut for unzipping
	NSString					*downLoadConferenceID;
	PVConference				*insertingConference;	//	HACK - if we're inserting conference, then we have to jump through hoops
}

//Properties

@property (nonatomic, retain) conferenceList			*conferences;
@property (nonatomic, retain) levelViewController		*levelViewController;
@property (nonatomic, retain) detailViewController	*detailViewController;
@property (nonatomic, retain) conferenceNavController	*conferenceNavController;
@property (nonatomic, retain) commController			*commController;
@property (nonatomic, retain) slotFactory				*slotFactory;
@property (nonatomic, retain) conference				*currentConference;
@property (nonatomic, readwrite) BOOL					foundValidConferenceList;

@property (nonatomic, retain) NSMutableArray			*xmlNodeStack;
@property (nonatomic, retain) PVLevelSlot				*currentXMLNode;
@property (nonatomic, retain) NSMutableString			*textInProgress;
@property (nonatomic, retain) NSMutableString			*resourcePrefix;
@property (nonatomic, readwrite) BOOL					resourcesLocallyCached;
@property (nonatomic, readwrite) BOOL					parsingCopyList;
@property (nonatomic, retain) NSString					*toFileFullPath;
@property (nonatomic, retain) NSString					*downLoadConferenceID;
@property (nonatomic, retain) PVConference				*insertingConference;

// Methods

+(id)sharedPVEngine;
-(void) start;
-(void) getAConference:(NSNotification *)notification;		//	110118
-(void) loadConferenceListFromFile;							//	110124
-(void) loadConferenceListWithData:(NSData *)theData;
-(void) insertConferenceXMLIntoList:(NSString *)conferenceID;//	110130
-(void) handleNotification:(NSNotification *)theNotification;
-(void) saveState;								//	100718	Conference location
-(void) restoreState;							//	ibid
-(NSString *)modifyURL:(NSString *)rawURL;
- (void)inflateArchive;							//	110127
- (void)inflateComplete;

@end
