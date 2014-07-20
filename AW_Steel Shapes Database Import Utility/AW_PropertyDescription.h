//
//  AW_PropertyDescription.h
//  AW_Steel Shapes Database Import Utility
//
//  Created by Alan Wang on 7/20/14.
//  Copyright (c) 2014 Alan Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface AW_PropertyDescription : NSManagedObject

@property (nonatomic, retain) NSDecimalNumber * defaultOrder;
@property (nonatomic, retain) NSString * group;
@property (nonatomic, retain) NSNumber * imp_displayType;
@property (nonatomic, retain) NSString * imp_units;
@property (nonatomic, retain) NSDecimalNumber * impToMetFactor;
@property (nonatomic, retain) NSString * longDescription;
@property (nonatomic, retain) NSNumber * met_displayType;
@property (nonatomic, retain) NSString * met_units;
@property (nonatomic, retain) NSString * symbol;
@property (nonatomic, retain) NSString * key;
@property (nonatomic, strong) NSSet *shapeFamilies;

@end
