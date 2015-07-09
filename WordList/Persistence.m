//
// From the book Pro iOS Persistence
// Michael Privat and Rob Warner
// Published by Apress, 2014
// Source released under The MIT License
// http://opensource.org/licenses/MIT
//
// Contact information:
// Michael: @michaelprivat -- http://michaelprivat.com -- mprivat@mac.com
// Rob: @hoop33 -- http://grailbox.com -- rwarner@grailbox.com
//

#import "Persistence.h"

@implementation Persistence

- (id)init {
  self = [super init];
  if (self != nil) {
    // Initialize the managed object model
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"WordList" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    // Initialize the persistent store coordinator
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"PersistenceApp.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
                                                           error:&error]) {
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    }
    
    // Initialize the managed object context
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
  }
  return self;
}

- (void)saveContext {
  NSError *error;
  if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }
}

- (NSURL *)applicationDocumentsDirectory {
  return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)deleteAllObjectsForEntityWithName:(NSString *)name {
    NSLog(@"Deleting all objects in entity %@", name);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:name];
    fetchRequest.resultType = NSManagedObjectIDResultType;
    NSArray *objectIDs = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    for (NSManagedObjectID *objectID in objectIDs) {
        [self.managedObjectContext deleteObject:[self.managedObjectContext objectWithID:objectID]];
    }
    [self saveContext];
    
    NSLog(@"All objects in entity %@ deleted", name);
}

- (void)loadWordList:(NSString *)wordList {
    [self deleteAllObjectsForEntityWithName:@"Word"];
    [self deleteAllObjectsForEntityWithName:@"WordCategory"];
    
    NSMutableDictionary *wordCategories = [NSMutableDictionary dictionaryWithCapacity:26];
    for (char c = 'a'; c <= 'z'; c++) {
        NSString *firstLetter = [NSString stringWithFormat:@"%c", c];
        NSManagedObject *wordCategory = [NSEntityDescription insertNewObjectForEntityForName:@"WordCategory" inManagedObjectContext:self.managedObjectContext];
        [wordCategory setValue:firstLetter forKey:@"firstLetter"];
        [wordCategories setValue:wordCategory forKey:firstLetter];
        NSLog(@"Added category '%@'", firstLetter);
    }
    
    NSUInteger wordsAdded = 0;
    NSArray *newWords = [wordList componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    for (NSString *word in newWords) {
        if (word.length > 0) {
            NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Word" inManagedObjectContext:self.managedObjectContext];
            [object setValue:word forKey:@"text"];
            [object setValue:[NSNumber numberWithInteger:word.length] forKey:@"length"];
            [object setValue:[wordCategories valueForKey:[word substringToIndex:1]] forKey:@"wordCategory"];
            ++wordsAdded;
            if (wordsAdded % 100 == 0)
                NSLog(@"Added %lu words", wordsAdded);
        }
    }
    NSLog(@"Added %lu words", wordsAdded);
    [self saveContext];
    NSLog(@"Context saved");
}

- (NSString *)statistics {
    NSMutableString *string = [[NSMutableString alloc] init];
    [string appendString:[self wordCount]];
    for (char c = 'a'; c <= 'z'; c++) {
        [string appendString:[self wordCountByCategory:[NSString stringWithFormat:@"%c", c]]];
    }
    [string appendString:[self zyzzyvasUsingNSExpression]];
    [string appendString:[self zyzzyvasUsingQueryLanguage]];
    [string appendString:[self wordCountForRange:NSMakeRange(20, 25)]];
    [string appendString:[self endsWithGryWords]];
    [string appendString:[self anyWordContainsZ]];
    [string appendString:[self caseInsensitiveFetch:@"qiviut"]];
    [string appendString:[self twentyLetterWordsEndingInIng]];
    [string appendString:[self containingQButNotU]];
    [string appendString:[self highCountCategories]];
    return string;
}

- (NSString *)zyzzyvasUsingQueryLanguage {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"text = 'zyzzyvas'"];
    NSArray *words = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return words.count == 0 ? @"" : [NSString stringWithFormat:@"%@\n", [words[0] valueForKey:@"text"]];
}

- (NSString *)zyzzyvasUsingNSExpression {
    NSExpression *expressionText = [NSExpression expressionForKeyPath:@"text"];
    NSExpression *expressionZyzzyvas = [NSExpression expressionForConstantValue:@"zyzzyvas"];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:expressionText rightExpression:expressionZyzzyvas
        modifier:NSDirectPredicateModifier
        type:NSEqualToPredicateOperatorType
        options:0];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    fetchRequest.predicate = predicate;
    NSArray *words = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return words.count == 0 ? @"" : [NSString stringWithFormat:@"%@\n", [words[0] valueForKey:@"text"]];
}

- (NSString *)wordCountByCategory:(NSString *)firstLetter {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];

    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"wordCategory.firstLetter = %@", firstLetter];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"Words beginning with %@: %lu\n", firstLetter, count];
}

- (NSString *)wordCount {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"Word Count: %lu\n", count];
}

- (NSString *)wordCountForRange:(NSRange)range {
    NSExpression *length = [NSExpression expressionForKeyPath:@"length"];
    NSExpression *lower = [NSExpression expressionForConstantValue:@(range.location)];
    NSExpression *upper = [NSExpression expressionForConstantValue:@(range.length)];
    NSExpression *expr = [NSExpression expressionForAggregate:@[lower, upper]];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:length
        rightExpression:expr modifier:NSDirectPredicateModifier
        type:NSBetweenPredicateOperatorType options:0];
    NSLog(@"Aggregate predicate: %@", [predicate predicateFormat]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    fetchRequest.predicate = predicate;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"%lu-%lu letter words: %lu\n", range.location, range.length, count];
    
}

- (NSString *)endsWithGryWords {
    NSExpression *text = [NSExpression expressionForKeyPath:@"text"];
    NSExpression *gry = [NSExpression expressionForConstantValue:@"gry"];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:text
        rightExpression:gry
        modifier:NSDirectPredicateModifier
        type:NSEndsWithPredicateOperatorType
        options:0];
    NSLog(@"Predicate: %@", [predicate predicateFormat]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    fetchRequest.predicate = predicate;
    NSArray *gryWords = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"-gry words: %@\n", [[gryWords valueForKey:@"text"] componentsJoinedByString:@","]];
}

- (NSString *)anyWordContainsZ {
    NSExpression *text = [NSExpression expressionForKeyPath:@"words.text"];
    NSExpression *z = [NSExpression expressionForConstantValue:@"z"];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:text
        rightExpression:z modifier:NSAnyPredicateModifier
        type:NSContainsPredicateOperatorType options:0];
    NSLog(@"Predicate: %@", [predicate predicateFormat]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WordCategory"];
    fetchRequest.predicate = predicate;
    NSArray *categories = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"ANY: %@\n", [[categories valueForKey:@"firstLetter"]componentsJoinedByString:@","]];
}

- (NSString *)caseInsensitiveFetch:(NSString *)word {
    NSExpression *text = [NSExpression expressionForKeyPath:@"text"];
    NSExpression *allCapsWord = [NSExpression expressionForConstantValue:[word uppercaseString]];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:text
        rightExpression:allCapsWord modifier:NSDirectPredicateModifier
        type:NSEqualToPredicateOperatorType options:NSCaseInsensitivePredicateOption];
    NSLog(@"Predicate: %@", [predicate predicateFormat]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    fetchRequest.predicate = predicate;
    NSArray *words = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"%@\n", words.count == 0 ? @"" : [words[0] valueForKey:@"text"]];
}

- (NSString *)twentyLetterWordsEndingInIng {
    NSExpression *length = [NSExpression expressionForKeyPath:@"length"];
    NSExpression *twenty = [NSExpression expressionForConstantValue:@20];
    NSPredicate *predicateLength = [NSComparisonPredicate predicateWithLeftExpression:length
        rightExpression:twenty modifier:NSDirectPredicateModifier
        type:NSEqualToPredicateOperatorType options:0];
    
    NSExpression *text = [NSExpression expressionForKeyPath:@"text"];
    NSExpression *ing = [NSExpression expressionForConstantValue:@"ing"];
    NSPredicate *predicateIng = [NSComparisonPredicate predicateWithLeftExpression:text
        rightExpression:ing modifier:NSDirectPredicateModifier
        type:NSEndsWithPredicateOperatorType options:0];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateLength, predicateIng]];
    NSLog(@"Compound predicate : %@", [predicate predicateFormat]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    fetchRequest.predicate = predicate;
    NSArray *words = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"%@\n", [[words valueForKey:@"text"] componentsJoinedByString:@","]];
}

- (NSString *)containingQButNotU {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"text CONTAINS 'q' AND NOT text CONTAINS 'u'"];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Word"];
    request.predicate = predicate;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:NULL];
    return [NSString stringWithFormat:@"With Q, without U(%lu): %@\n", results.count,
        [[results valueForKey:@"text"] componentsJoinedByString:@","]];
}

- (NSString *)highCountCategories {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"words.@count > %d", 10000];
    NSLog(@"Predicate: %@", [predicate predicateFormat]);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"WordCategory"];
    fetchRequest.predicate = predicate;
    NSArray *categories = [self.managedObjectContext executeFetchRequest:fetchRequest error:NULL];
    return [NSString stringWithFormat:@"High count categories: %@\n", [[categories valueForKey:@"firstLetter"] componentsJoinedByString:@","]];
}

@end
