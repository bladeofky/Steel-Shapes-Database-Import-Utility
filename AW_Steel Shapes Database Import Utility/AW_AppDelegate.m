//
//  AW_AppDelegate.m
//  AW_Steel Shapes Database Import Utility
//
//  Created by Alan Wang on 5/11/14.
//  Copyright (c) 2014 Alan Wang. All rights reserved.
//

#import "AW_AppDelegate.h"
#import "AW_Database.h"
#import "AW_ShapeFamily.h"
#import "AW_Shape.h"
#import "AW_Property.h"

@implementation AW_AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // --------------- DATABASE IMPORT UTILITY ---------------------
    NSString *filePath;
    
    [self.managedObjectContext setUndoManager:nil];
    
    // IMPORT DATABASE OBJECTS
    filePath = [[NSBundle mainBundle] pathForResource:@"Database" ofType:@"txt"];
    [self processTextFile:filePath forManagedObjectWithName:@"AW_Database"];
    
    // IMPORT SHAPE FAMILY OBJECTS
    filePath = [[NSBundle mainBundle] pathForResource:@"Shape Family" ofType:@"txt"];
    [self processTextFile:filePath forManagedObjectWithName:@"AW_ShapeFamily"];
    
    // IMPORT SHAPE OBJECTS
    filePath = [[NSBundle mainBundle] pathForResource:@"Shapes" ofType:@"txt"];
    [self processTextFile:filePath forManagedObjectWithName:@"AW_Shape"];
    
    
    // --------------------------------------------------------------
    
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    return YES;
}

#pragma mark - Processor methods

- (void) processTextFile:(NSString *)filePath
forManagedObjectWithName:(NSString *) nameOfObject
{
    // INITIALIZE VARIABLES
    NSString *fileText;     // stores full contents of file
    NSArray *lines;         // stores each line of the file
    NSString *headerLine;   // stores the header (first line) of the file
    NSString *line;         // stores the current line being read
    
    // IMPORT OBJECTS
    
    if (!filePath) {
        [NSException raise:@"File not found" format:[NSString stringWithFormat:@"File not found %@", filePath]];
    }
    
    // Read in text
    fileText = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    lines = [fileText componentsSeparatedByString:@"\n"];
    
    // Read in header
    headerLine = lines[0];
    
    // Process entries
    for (int row = 1; row < [lines count]; row++) {
        
        line = lines[row];
        
        if ([line isEqualToString:@""]) {
            // Skip blank lines
            NSLog(@"Found blank line. Skipping...");
            continue;
        }
        
        // Process the current entry
        if ([nameOfObject isEqualToString:@"AW_Database"]) {
            [self processDatabaseEntry:line withHeader:headerLine];
        }
        else if ([nameOfObject isEqualToString:@"AW_ShapeFamily"]) {
            [self processShapeFamilyEntry:line withHeader:headerLine];
        }
        else if ([nameOfObject isEqualToString:@"AW_Shape"]) {
            [self processShapeEntry:line withHeader:headerLine];
        }
        else {
            [NSException raise:@"Unrecognized managed object class" format:@"Unrecognized managed object class"];
        }

    } //end for
    
    //Test fetch
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:nameOfObject inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *error;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"Error performing test fetch");
    }
    
    NSLog(@"%i %@ objects", [fetchedObjects count], nameOfObject);
}

- (void) processDatabaseEntry:(NSString *)line withHeader: (NSString *)headerLine
{
    NSArray *attributeNames = [headerLine componentsSeparatedByString:@"\t"];
    NSArray *fields = [line componentsSeparatedByString:@"\t"];
    
    // Create the object
    AW_Database *entry = [NSEntityDescription insertNewObjectForEntityForName:@"AW_Database" inManagedObjectContext:self.managedObjectContext];
    NSDictionary *entityAttributes = [[entry entity] attributesByName];
    
    // Set attributes
    for (int col = 0; col < [attributeNames count]; col++) {
        
        NSString *attributeName = attributeNames[col];
        
        // Sanitize attributeName
        attributeName = [attributeName stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
        
        NSAttributeDescription *attribute = [entityAttributes objectForKey:attributeName];
        NSString *attributeClass = [attribute attributeValueClassName];
        NSString *value = fields[col];
        
        // Skip blank field
        if ([value isEqualToString:@""]) {
            continue;
        }
        
        // Add field to entry
        if ([attributeClass isEqualToString:@"NSNumber"]) {
            [entry setValue:[NSNumber numberWithInt:[value intValue]] forKey:attributeName];
        }
        else if ([attributeClass isEqualToString:@"NSDecimalNumber"]) {
            [entry setValue:[[NSDecimalNumber alloc] initWithString:value] forKey:attributeName];
        }
        else if ([attributeClass isEqualToString:@"NSString"]) {
            [entry setValue:value forKey:attributeName];
        }
        else {
            // This is the transformable type. Special processing is required.
            if ([attributeName isEqualToString:@"backgroundColor"] || [attributeName isEqualToString:@"textColor"]) {
                // This is a UIColor attribute for the AW_Database entity
                UIColor *color;
                
                if ([value isEqualToString:@"Red"]) {
                    color = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1.0];
                }
                else if ([value isEqualToString:@"Gold"]) {
                    color = [UIColor colorWithRed:1 green:1 blue:0 alpha:1.0];
                } // end else if
                
                // UIColor is NSCoding compliant. NSKeyedUnarchiveFromDataTransformerName is used by default.
                [entry setValue:color forKeyPath:attributeName];
                
#warning TO-DO: Transform UIColor to NSData and add it to the managed object
            } //end if
        } //end else
        
    } //end for
    
    //NSLog(@"Created object: %@", entry);
    
    // Save the managed object context
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error while saving %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
        exit(1);
    }
    
}

- (void) processShapeFamilyEntry:(NSString *)line withHeader: (NSString *)headerLine
{
    NSArray *attributeNames = [headerLine componentsSeparatedByString:@"\t"];
    NSArray *fields = [line componentsSeparatedByString:@"\t"];
    
    // Create the object
    AW_ShapeFamily *entry = [NSEntityDescription insertNewObjectForEntityForName:@"AW_ShapeFamily" inManagedObjectContext:self.managedObjectContext];
    NSDictionary *entityAttributes = [[entry entity] attributesByName];
    
    // Get database
    NSString *databaseKey = fields[0];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AW_Database" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key MATCHES %@", databaseKey];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [NSException raise:@"Fetch error" format:@"Error trying to fetch AW_Databse object"];
    }
    
    AW_Database *database = fetchedObjects[0];
    entry.database = database;
    
    // Set attributes
    for (int col = 1; col < [attributeNames count]; col++) {
        
        NSString *attributeName = attributeNames[col];
        attributeName = [attributeName stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];   // Sanitize attributeName
        
        NSAttributeDescription *attribute = [entityAttributes objectForKey:attributeName];
        NSString *attributeClass = [attribute attributeValueClassName];
        NSString *value = fields[col];
        
        // Skip blank field
        if ([value isEqualToString:@""]) {
            continue;
        }
        
        // Add field to entry
        if ([attributeClass isEqualToString:@"NSNumber"]) {
            [entry setValue:[NSNumber numberWithInt:[value intValue]] forKey:attributeName];
        }
        else if ([attributeClass isEqualToString:@"NSDecimalNumber"]) {
            [entry setValue:[[NSDecimalNumber alloc] initWithString:value] forKey:attributeName];
        }
        else if ([attributeClass isEqualToString:@"NSString"]) {
            [entry setValue:value forKey:attributeName];
        }
        else {
            // This is the transformable type. Special processing is required.
        } //end else
        
    } //end for
    
    //NSLog(@"Created object: %@", entry);
    
    // Save the managed object context
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error while saving %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
        exit(1);
    }
    
    // Check databse for new shapes
    NSLog(@"Number of shape families in database: %i", [database.shapeFamilies count]);
}

- (void)processShapeEntry:(NSString*)line withHeader:(NSString *)headerLine
{
    NSArray *attributeNames = [headerLine componentsSeparatedByString:@"\t"];
    NSArray *fields = [line componentsSeparatedByString:@"\t"];
    
    // Create the object
    AW_Shape *entry = [NSEntityDescription insertNewObjectForEntityForName:@"AW_Shape" inManagedObjectContext:self.managedObjectContext];
    NSDictionary *entityAttributes = [[entry entity] attributesByName];
    
    // Get shape family
    NSString *databaseKey = fields[0];
    NSString *shapeFamilyKey = fields[1];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"AW_ShapeFamily" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    // Specify criteria for filtering which objects to fetch
    NSPredicate *predicate1 = [NSPredicate predicateWithFormat:@"key MATCHES %@", shapeFamilyKey];
    NSPredicate *predicate2 = [NSPredicate predicateWithFormat:@"database.key MATCHES %@", databaseKey];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate1, predicate2]];
    [fetchRequest setPredicate:predicate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        [NSException raise:@"Fetch error" format:@"Error trying to fetch AW_Databse object"];
    }
    
    AW_ShapeFamily *shapeFamily = fetchedObjects[0];
    entry.shapeFamily = shapeFamily;
    
    // Set attributes
    int FIRST_ATTRIBUTE_INDEX = 2;
    int FIRST_PROPERTY_INDEX = 8;
    for (int col = FIRST_ATTRIBUTE_INDEX; col < FIRST_PROPERTY_INDEX; col++) {
        
        NSString *attributeName = attributeNames[col];
        attributeName = [attributeName stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];   // Sanitize attributeName
        
        NSAttributeDescription *attribute = [entityAttributes objectForKey:attributeName];
        NSString *attributeClass = [attribute attributeValueClassName];
        NSString *value = fields[col];
        
        // Skip blank field
        if ([value isEqualToString:@""]) {
            continue;
        }
        
        // Add field to entry
        if ([attributeClass isEqualToString:@"NSNumber"]) {
            [entry setValue:[NSNumber numberWithInt:[value intValue]] forKey:attributeName];
        }
        else if ([attributeClass isEqualToString:@"NSDecimalNumber"]) {
            [entry setValue:[[NSDecimalNumber alloc] initWithString:value] forKey:attributeName];
        }
        else if ([attributeClass isEqualToString:@"NSString"]) {
            [entry setValue:value forKey:attributeName];
        }
        else {
            // This is the transformable type. Special processing is required.
        } //end else
        
    } //end for
    
    // Create properties
    NSDictionary *propertyDictionary = [self createPropertyDictionary];
    
    for (int col = FIRST_PROPERTY_INDEX; col < [attributeNames count]; col+=2) {
        NSString *propertyKey = [attributeNames[col] stringByReplacingOccurrencesOfString:@"imp_" withString:@""];
        propertyKey = [propertyKey stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];   // Sanitize propertyKey
        
        NSString *impValue = fields[col];
        NSString *metValue = fields[col+1];
        
        // Skip blank field
        if ([impValue isEqualToString:@""]) {
            continue;
        }
        
        [self createPropertyWithKey:propertyKey impValue:impValue metValue:metValue forShape:entry withPropertyDictionary:propertyDictionary];
        
    }
    
    //NSLog(@"Created object: %@", entry);
    
    // Save the managed object context
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Error while saving %@", ([error localizedDescription] != nil) ? [error localizedDescription] : @"Unknown Error");
        exit(1);
    }
    
}

- (void)createPropertyWithKey:(NSString *)key impValue: (id)impValue metValue: (id)metValue forShape:(AW_Shape *)shape withPropertyDictionary:(NSDictionary *)propertyDictionary
{
    // Create property
    NSArray *propertyAttributes = propertyDictionary[@"header"];
    NSArray *propertyValues = propertyDictionary[key];
    
    AW_Property *entry = [NSEntityDescription insertNewObjectForEntityForName:@"AW_Property" inManagedObjectContext:self.managedObjectContext];
    NSDictionary *entityAttributes = [[entry entity] attributesByName];
    
    
    // Set attributes
    for (int index = 0; index < [propertyAttributes count]; index++) {
        
        NSString *value = propertyValues[index];
        NSAttributeDescription *attributeDescription = [entityAttributes objectForKey:propertyAttributes[index]];
        NSString *attributeClass = [attributeDescription attributeValueClassName];
        
        // Add field to entry
        if ([attributeClass isEqualToString:@"NSNumber"]) {
            [entry setValue:[NSNumber numberWithInt:[value intValue]] forKey:propertyAttributes[index]];
        }
        else if ([attributeClass isEqualToString:@"NSDecimalNumber"]) {
            [entry setValue:[[NSDecimalNumber alloc] initWithString:value] forKey:propertyAttributes[index]];
        }
        else if ([attributeClass isEqualToString:@"NSString"]) {
            [entry setValue:value forKey:propertyAttributes[index]];
        }
        else {
            // This is the transformable type. Special processing is required.
        } //end else
    }
    
    // Set property value
    [entry setValue:[[NSDecimalNumber alloc] initWithString:impValue] forKeyPath:@"imp_value"];
    [entry setValue:[[NSDecimalNumber alloc] initWithString:metValue] forKeyPath:@"met_value"];
    
    // Set shape
    entry.shape = shape;
}

- (NSDictionary *)createPropertyDictionary
{
    // INITIALIZE VARIABLES
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Properties" ofType:@"txt"];
    NSString *fileText;     // stores full contents of file
    NSArray *lines;         // stores each line of the file
    NSString *headerLine;   // stores the header (first line) of the file
    NSString *line;         // stores the current line being read
    NSArray *attributes;    // stores the attributes of the property
    NSString *key;          // property key
    NSMutableDictionary *propertyDictionary = [[NSMutableDictionary alloc] init];
    
    // IMPORT OBJECTS
    
    if (!filePath) {
        [NSException raise:@"File not found" format:[NSString stringWithFormat:@"File not found %@", filePath]];
    }
    
    // Read in text
    fileText = [[NSString alloc] initWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    lines = [fileText componentsSeparatedByString:@"\n"];
    
    // Read in header
    headerLine = lines[0];
    [propertyDictionary setObject:[headerLine componentsSeparatedByString:@"\t"] forKey:@"header"];
    
    // Process entries
    for (int row = 1; row < [lines count]; row++) {
        
        line = lines[row];
        attributes = [line componentsSeparatedByString:@"\t"];
        key = attributes[0];
        
        [propertyDictionary setObject:attributes forKey:key];
    } //end for
    
    return [propertyDictionary copy];
}

#pragma mark -

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"AW_Steel_Shapes_Database_Import_Utility" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"AW_Steel_Shapes_Database_Import_Utility.sqlite"];
    
    NSLog(@"Store URL: %@", storeURL);
    
    //Delete existing store
    NSError *error;
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:storeURL.path]) {
        NSLog(@"Deleting file at path: %@", storeURL.path);
        [fileManager removeItemAtPath:storeURL.path error:&error];
    }
    
    // Create new store
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = @{ NSSQLitePragmasOption : @{@"journal_mode" : @"DELETE"} };
    
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
