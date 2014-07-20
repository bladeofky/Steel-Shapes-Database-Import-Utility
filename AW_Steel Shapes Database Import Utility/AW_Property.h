//
//  AW_Property.h
//  AW_Steel Shapes Database Import Utility
//
//  Created by Alan Wang on 5/11/14.
//  Copyright (c) 2014 Alan Wang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class AW_Shape, AW_PropertyDescription;

@interface AW_Property : NSManagedObject

@property (nonatomic, strong) NSDecimalNumber *imp_value;
@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) AW_Shape *shape;
@property (nonatomic, strong) AW_PropertyDescription *propertyDescription;

@end
