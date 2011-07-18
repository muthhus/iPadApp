//
//  levelViewController.h
//  mobePlaceIPad
//
//  Created by Ana Ruelas on 7/8/11.
//  Copyright 2011 Massachusetts Institute of Technology. All rights reserved.
//

#import <UIKit/UIKit.h>


@class detailViewController;
@class levelSlot;




@interface PVLevelViewController : UITableViewController
{
	IBOutlet	UITableViewCell			*pvLevelCell;
	IBOutlet UIImageView *backgroundImageview;
	UIImageView				*backgroundImageView;
	detailViewController	*detailViewController;			//	100617	Might not need this, might just send notification to engine?
	levelSlot				*currentLevel;
}


@property(nonatomic,retain)				detailViewController	*detailViewController;
@property(nonatomic,retain)				levelSlot				*currentLevel;
@property(nonatomic, assign) IBOutlet	UITableViewCell			*pvLevelCell;
@property(nonatomic, assign) IBOutlet	UIImageView				*backgroundImageView;


-(IBAction)editChicklets:(id)sender;
-(IBAction)downloadConference:(id)sender;
-(void)changeLevel:(levelSlot *)newLevel;

@end


/*
 Code that Neil wrote
 
 will figure out what it does later
 */

@interface UIImage (Extras)
- (UIImage *)imageByScalingProportionallyToSize:(CGSize)targetSize;
@end;

