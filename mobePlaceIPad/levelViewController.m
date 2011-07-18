//
//  levelViewController.m
//  mobePlaceIPad
//
//  Created by Ana Ruelas on 7/8/11.
//  Copyright 2011 Massachusetts Institute of Technology. All rights reserved.
//


/*	Implements a "Level" of a conference. Basically - a table view with a fairly detailed custom table cell.
	Each cell will include numerous specific adornments, most importantly: "chicklets" which indicate to the user
	if the slot ( level or detail ) has been visited before, has notes, or follow-up, etc. Also will include a track
	or session background color or badge of some sort. Along with anything else that might pop up
*/
 
 
#import "levelViewController.h"
#import "levelSlot.h"
#import "constants.h"
#import	"engine.h"
#import "conference.h"


@implementation levelViewController


@synthesize detailViewController;
@synthesize pvLevelCell;
@synthesize currentLevel;
@synthesize	backgroundImageView;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark Table view methods	

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	//	NSLog(@"PVLevelViewController:numberOfSectionsInTableView");
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{   // customize the number of rows in the table view
	if( currentLevel )
	{
		return( [currentLevel.slots count] );
	}
	else
		return(1);								//	returns one "blank" row.
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{   // customize the appearance of table view cells
	PVSlot *aSlot = [currentLevel.slots objectAtIndex:indexPath.row];
	
	static NSString *MyIdentifier = @"pvLevelCell";
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
    if (cell == nil)
	{
        [[NSBundle mainBundle] loadNibNamed:@"PVLevelCell" owner:self options:nil];
        cell = pvLevelCell;
		//        self.pvLevelCell = nil;
    }
	
	//----------------------------------------------//	Get info from the slot
	
    UILabel		*label;
	NSString	*aString;
	
	//	PVSlot *aSlot = [currentLevel.slots objectAtIndex:indexPath.row];
	
    label = (UILabel *)[cell viewWithTag:42];
	//    label.text = [NSString stringWithFormat:@"%d", indexPath.row];
	if( aSlot && ( [aSlot.attributes objectForKey:kXMLShortTitle] != nil ) )
	{
		label.text = [NSString stringWithString:[aSlot.attributes objectForKey:kXMLShortTitle]];
		
		label = (UILabel *)[cell viewWithTag:3];
		
		aString = [aSlot.attributes objectForKey:kXMLShortDescription];
		if( !aString )
			aString = [aSlot.attributes objectForKey:kXMLDescription];
		
		if( aString )
			label.text = [NSString stringWithString:aString];
		else
			label.text = @"";
	}
	
	//----------------------------------------------//	background
	
	UIImage *rowBackground;
	UIImage *selectionBackground;
	NSInteger sectionRows = [tableView numberOfRowsInSection:[indexPath section]];
	
	if (indexPath.row == 0 && indexPath.row == sectionRows - 1)
	{
		rowBackground = [UIImage imageNamed:@"topAndBottomRow.png"];
		selectionBackground = [UIImage imageNamed:@"topAndBottomRowSelected.png"];
	}
	else if (indexPath.row == 0)
	{
		rowBackground = [UIImage imageNamed:@"topRow.png"];
		selectionBackground = [UIImage imageNamed:@"topRowSelected.png"];
	}
	else if (indexPath.row == sectionRows - 1)
	{
		rowBackground = [UIImage imageNamed:@"bottomRow.png"];
		selectionBackground = [UIImage imageNamed:@"bottomRowSelected.png"];
	}
	else
	{
		rowBackground = [UIImage imageNamed:@"middleRow.png"];
		selectionBackground = [UIImage imageNamed:@"middleRowSelected.png"];
	}
	
	UIImageView *background = (UIImageView *)[cell viewWithTag:1];
	
	background.image = rowBackground;
	
	//	UIImageView *background = (UIImageView *)[cell viewWithTag:0];
	
	//	((UIImageView *)cell.backgroundView).image = rowBackground;
	//	((UIImageView *)cell.selectedBackgroundView).image = selectionBackground;
	
	//----------------------------------------------//	Slot Icon
	
	
	id	anObject = [aSlot.attributes objectForKey:kXMLGenericIconURL];
	
	if( anObject )
	{
		UIImageView *anImageView = (UIImageView *)[cell viewWithTag:49];
		
		aString = [NSString stringWithString:anObject];
		
		//	was 110131:	UIImage *anImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:aString]]];
		
		UIImage *anImage	= [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL fileURLWithPath:aString]]];
		CGRect	frame		= [anImageView frame];
		CGSize aSize		= { frame.size.width, frame.size.height };
		
		anImage = [anImage imageByScalingProportionallyToSize:aSize];
		
		if( anImage && anImageView )
		{
			anImageView.image = anImage;
		}
	}
	
	//----------------------------------------------//	Other attributes...
	
	
	/*
	 aString = [aSlot.attributes objectForKey:kXMLAttributeBackgroundColor];
	 if( aString )
	 {
	 //		view.backgroundColor = [UIColor yellowColor];
	 
	 label = (UILabel *)[cell viewWithTag:53];
	 label.textColor = [UIColor redColor];
	 label = (UILabel *)[cell viewWithTag:54];
	 label.textColor = [UIColor redColor];
	 
	 
	 }
	 
	 */
	
	//----------------------------------------------//	Debug...
	
    label = (UILabel *)[cell viewWithTag:18];
	
	if( [aSlot.attributes count] && ( [aSlot.attributes objectForKey:kXMLConferenceID] != nil ) )
	{
		if( label != nil )
			label.text = [NSString stringWithString:[aSlot.attributes objectForKey:kXMLConferenceID]];
		
		if( [(PVConference *)aSlot isDownloaded] )
		{
			if( label != nil )
				label.text = [NSString stringWithString:@"YES"];
            
			UIButton *aButton = (UIButton *)[cell viewWithTag:99];
			if( aButton != nil )
			{
				UIImage *btnImage;
				CGRect	frame		= [aButton frame];
				CGSize	aSize		= { frame.size.width, frame.size.height };
				
				btnImage = [UIImage imageNamed:@"softwareUpdate-256.png"];
				btnImage = [btnImage imageByScalingProportionallyToSize:aSize];
				
				[aButton setImage:btnImage forState:UIControlStateNormal];
				[aButton setImage:btnImage forState:UIControlStateHighlighted];
				[aButton setTitle:[NSString stringWithString:[aSlot.attributes objectForKey:kXMLConferenceID]] forState:UIControlStateNormal];
			}
			
		}
		else 
		{
			UIImageView *anImage = (UIImageView *)[cell viewWithTag:4];
			if( anImage != nil )
				anImage.hidden = YES;
			anImage = (UIImageView *)[cell viewWithTag:49];
			if( anImage != nil )
				anImage.hidden = YES;
			
			UIButton *aButton = (UIButton *)[cell viewWithTag:99];
			if( aButton != nil )
			{
				[aButton setTitle:[NSString stringWithString:[aSlot.attributes objectForKey:kXMLConferenceID]] forState:UIControlStateNormal];
			}
			
		}
	}
	else 
	{
		UIButton *aButton = (UIButton *)[cell viewWithTag:99];
		if( aButton != nil )
			aButton.hidden = YES;
	}
	
	
	
    return cell;
	
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
    /* Navigation logic may go here, create and push another view controller. 
       Navigation logic may go here. Create and push another view controller.
	   AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	   [self.navigationController pushViewController:anotherViewController];
	   [anotherViewController release];
	*/
     
	if( indexPath.section == 0 )
	{
		PVSlot *aSlot = [currentLevel.slots objectAtIndex:indexPath.row];
		
		if( aSlot )
			[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPushSlot object:aSlot];
	}
	else
	{
		PVSlot *aSlot = [currentLevel.slots objectAtIndex:indexPath.row + 1];
		
		if( aSlot )
			[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationPushSlot object:aSlot];
	}
}


- (UITableViewCellAccessoryType)tableView:(UITableView *)tv accessoryTypeForRowWithIndexPath:(NSIndexPath *)indexPath
{
	PVSlot *aSlot = [currentLevel.slots objectAtIndex:indexPath.row];
	
	if( aSlot.slotKind == kSlotKindDetail )
		return UITableViewCellAccessoryDetailDisclosureButton;
	else if( aSlot.slotKind == kSlotKindLevel )
		return UITableViewCellAccessoryDisclosureIndicator;
	else if( aSlot.slotKind == kSlotKindConference )
	{
		if( [(PVConference *)aSlot isDownloaded] )
			return UITableViewCellAccessoryDisclosureIndicator;		//	only display if conference is already downloaded.
	}
	else
		return( UITableViewCellAccessoryNone );
	
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{   // Override to support conditional editing of the table view
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{   // override to support conditional rearranging of the table view
    // Return NO if you do not want the item to be re-orderable.
    return NO;
}


-(void)changeLevel:(PVLevelSlot *)newLevel
{   // 100624 NALEX Swaps in a new level, and forces the table to reload
	NSLog(@"PVLevelViewController:changeLevel");
	
	currentLevel = newLevel;
	
	[[self view] reloadData];
}


-(IBAction)downloadConference:(id)sender
{   // 110404 NALEX the conference ID was added to the button's text
	UIButton *aButton = (UIButton *)sender;
	NSString *aTitle;
	
	if( [aButton currentTitle] != nil )
	{
		aTitle = [NSString stringWithString:aButton.currentTitle];
		[aTitle retain];
		[[NSNotificationCenter defaultCenter] postNotificationName:kNotificationGetConference object:aTitle];
		[aTitle autorelease];
	}		
	else 
	{
		UIAlertView *emptyConferenceIDAlert = [[UIAlertView alloc] 
                                               initWithTitle:@"Error" 
                                               message:@"Unknown Conference ID!"
                                               delegate:self cancelButtonTitle:nil
                                               otherButtonTitles:@"OK", nil];
		[emptyConferenceIDAlert show];
	}
}


@end



/*
 code that Neil wrote, will try to figure out what it does later
 */

@implementation UIImage (Extras)

- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize {
	
	UIImage *sourceImage = self;
	UIImage *newImage = nil;
	
	CGSize imageSize = sourceImage.size;
	CGFloat width = imageSize.width;
	CGFloat height = imageSize.height;
	
	CGFloat targetWidth = targetSize.width;
	CGFloat targetHeight = targetSize.height;
	
	CGFloat scaleFactor = 0.0;
	CGFloat scaledWidth = targetWidth;
	CGFloat scaledHeight = targetHeight;
	
	CGPoint thumbnailPoint = CGPointMake(0.0,0.0);
	
	if (CGSizeEqualToSize(imageSize, targetSize) == NO) {
		
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
		
        if (widthFactor < heightFactor) 
			scaleFactor = widthFactor;
        else
			scaleFactor = heightFactor;
		
        scaledWidth  = width * scaleFactor;
        scaledHeight = height * scaleFactor;
		
        // center the image
		
        if (widthFactor < heightFactor) {
			thumbnailPoint.y = (targetHeight - scaledHeight) * 0.5; 
        } else if (widthFactor > heightFactor) {
			thumbnailPoint.x = (targetWidth - scaledWidth) * 0.5;
        }
	}
	
	
	// this is actually the interesting part:
	
	UIGraphicsBeginImageContext(targetSize);
	
	CGRect thumbnailRect = CGRectZero;
	thumbnailRect.origin = thumbnailPoint;
	thumbnailRect.size.width  = scaledWidth;
	thumbnailRect.size.height = scaledHeight;
	
	[sourceImage drawInRect:thumbnailRect];
	
	newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	if(newImage == nil) NSLog(@"could not scale image");
	
	
	return newImage ;
}
	

@end;

