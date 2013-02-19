#import "Kiwi.h"

#import "BWObjectMapper.h"
#import "User.h"
#import "Comment.h"
#import "Entity.h"
#import "Person.h"
#import "AppDelegate.h"

#define CUSTOM_VALUE_VALUE @"customValue"

SPEC_BEGIN(BWObjectMapperSpecs)

describe(@"mapping", ^{
    
    context(@"Simple object", ^{
        
        beforeAll(^{
            [BWObjectMapping mappingForObject:[User class] block:^(BWObjectMapping *mapping) {
                [mapping mapPrimaryKeyAttribute:@"id" toAttribute:@"userID"];
                [mapping mapKeyPath:@"first_name" toAttribute:@"firstName"];
                [mapping mapKeyPath:@"created_at" toAttribute:@"createdAt"];
                
//                [mapping hasMany:[Comment class] withRootKeyPath:@"comments"];
//                [mapping hasOne:[Comment class] withRootKeyPath:@"comment"];
//                [mapping hasMany:[Comment class] withRelationIDKeyPath:@"user_id"];
//                [mapping hasMany:[Comment class]];
                
                [[BWObjectMapper shared] registerMapping:mapping withRootKeyPath:@"user"];
            }];
            
            [BWObjectMapping mappingForObject:[Comment class] block:^(BWObjectMapping *objectMapping) {
                [objectMapping mapKeyPath:@"comment" toAttribute:@"comment"];
                
                [objectMapping mapKeyPath:@"custom_value" toAttribute:@"customValue" valueBlock:^id(id value, id object) {
                    return CUSTOM_VALUE_VALUE;
                }];
                
                [[BWObjectMapper shared] registerMapping:objectMapping withRootKeyPath:@"comment"];
            }];
            
            [[BWObjectMapper shared] objectWithBlock:^id(Class objectClass, NSString *primaryKey, id primaryKeyValue, id JSON) {
                return [[objectClass alloc] init];
            }];
        });
        
        it(@"should map the right object mapping", ^{
            id expectedFirstName = @"bruno";
            id expectedUserID = [NSNumber numberWithInt:4];
            
            NSDictionary *userJSON = [NSDictionary dictionaryWithObjectsAndKeys:
                                      expectedFirstName, @"first_name",
                                      expectedUserID, @"id",
                                      nil];
            
            NSDictionary *JSON = [NSDictionary dictionaryWithObject:userJSON forKey:@"user"];
            
            NSArray *objects = [[BWObjectMapper shared] objectsFromJSON:JSON withObjectClass:[User class]];
            User *user = [objects lastObject];
            Class class = [[objects lastObject] class];
            
            [[theValue(class) should] equal:theValue([User class])];
            [[theValue(objects.count) should] equal:theValue(1)];
            [[user.userID should] equal:expectedUserID];
            [[user.firstName should] equal:expectedFirstName];
        });
        
        it(@"should map object with the given class", ^{
            NSDictionary *userJSON = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"bruno", @"first_name",
                                      nil];
            
            NSDictionary *JSON = [NSDictionary dictionaryWithObject:userJSON forKey:@"user"];
            
            NSArray *objects = [[BWObjectMapper shared] objectsFromJSON:JSON withObjectClass:[User class]];
            Class class = [[objects lastObject] class];
            
            [[theValue(class) should] equal:theValue([User class])];
        });
        
        it(@"should have many objects", ^{
            NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"bruno", @"first_name",
                                      @"3", @"id",
                                      nil];
            
            NSDictionary *dict = [NSDictionary dictionaryWithObject:userDict forKey:@"user"];
            NSMutableArray *JSON = [NSMutableArray array];
            
            int expectedNumberOfObjects = 5;
            
            for (int i = 0; i < expectedNumberOfObjects; i++) {
                [JSON addObject:dict];
            }
            
            int objectCount = [[[BWObjectMapper shared] objectsFromJSON:JSON withObjectClass:[User class]] count];
            [[theValue(objectCount) should] equal:theValue(expectedNumberOfObjects)];
        });
        
        it(@"should map date", ^{
            NSDictionary *userDict = [NSDictionary dictionaryWithObjectsAndKeys:
                                      @"1981-10-23T07:45:00Z", @"created_at",
                                      nil];
            
            User *user = [[BWObjectMapper shared] objectFromJSON:userDict withObjectClass:[User class]];
            
            NSDate *expectedDate = [NSDate dateWithTimeIntervalSince1970:372671100];
            
            [[user.createdAt should] equal:expectedDate];
        });
        
        it(@"should map custom value", ^{
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                                  @"a value that must be transformed", @"custom_value",
                                  nil];
            
            Comment *comment = [[BWObjectMapper shared] objectFromJSON:dict withObjectClass:[Comment class]];
            
            NSString *expected = CUSTOM_VALUE_VALUE;
            
            [[comment.customValue should] equal:expected];
        });
        
    });
    
    context(@"Nested Attributes", ^{
       
        __block Person *person;
        __block NSDictionary *JSON;
        
        beforeAll(^{
            
            [BWObjectMapping mappingForObject:[Person class] block:^(BWObjectMapping *mapping) {
                [mapping mapKeyPath:@"name" toAttribute:@"name"];
                [mapping mapKeyPath:@"contact.email" toAttribute:@"email"];
                [mapping mapKeyPath:@"contact.others.skype" toAttribute:@"skype"];
                [mapping mapKeyPath:@"contact.phones" toAttribute:@"phones"];
                [mapping mapKeyPath:@"address.location" toAttribute:@"location"];
                [[BWObjectMapper shared] registerMapping:mapping withRootKeyPath:@"person"];
            }];
            
            [[BWObjectMapper shared] objectWithBlock:^id(Class objectClass, NSString *primaryKey, id primaryKeyValue, id JSON) {
                return [[objectClass alloc] init];
            }];
            
        });
        
        beforeEach(^{
           
            JSON = @{ @"person" : @{ @"name" : @"Lucas",
                                     @"contact" : @{
                                                     @"email" : @"lucastoc@gmail.com",
                                                     @"phones" : @[ @"(12)1233-1333", @"(85)12331233" ],
                                                     @"others" : @{ @"skype" : @"aspmedeiros"}
                                                   },
                                     @"address" : @{
                                                     @"location" : @{ @"lat": @(-18.123123123), @"long" : @(3.1123123123) }
                                                   }
                                   }
                    };
            
            person = [[BWObjectMapper shared] objectFromJSON:JSON withObjectClass:[Person class]];
            
        });
        
        specify(^{
            [[person should] beNonNil];
        });
        
        specify(^{
            [[person.name should] equal:[[JSON objectForKey:@"person"] objectForKey:@"name"]];
        });
        
        specify(^{
            [[person.email should] equal:[[[JSON objectForKey:@"person"] objectForKey:@"contact"] objectForKey:@"email"]];
        });
        
        specify(^{
            [[person.skype should] equal:[[[[JSON objectForKey:@"person"] objectForKey:@"contact"] objectForKey:@"others"] objectForKey:@"skype"]];
        });
        
        specify(^{
            int phonesCount = [person.phones count];
            int expectedPhoneCount = [[[[JSON objectForKey:@"person"] objectForKey:@"contact"] objectForKey:@"phones"] count];
            [[theValue(phonesCount) should] equal:theValue(expectedPhoneCount)];
        });
        
        specify(^{
            [[person.location should] equal:[[[JSON objectForKey:@"person"] objectForKey:@"address"] objectForKey:@"location"]];
        });
        
        
    });
    
    context(@"Core data object", ^{
        
        beforeAll(^{
            [BWObjectMapping mappingForObject:[Entity class] block:^(BWObjectMapping *mapping) {
                [mapping mapKeyPath:@"bool" toAttribute:@"boolValue"];
                [mapping mapKeyPath:@"int" toAttribute:@"intValue"];
                [mapping mapKeyPath:@"double" toAttribute:@"doubleValue"];
                [mapping mapKeyPath:@"float" toAttribute:@"floatValue"];
                [mapping mapKeyPath:@"string" toAttribute:@"stringValue"];
                
                [[BWObjectMapper shared] registerMapping:mapping];
            }];
            
            [[BWObjectMapper shared] objectWithBlock:^id(Class objectClass, NSString *primaryKey, id primaryKeyValue, id JSON) {
                AppDelegate *app = [[UIApplication sharedApplication] delegate];
                NSManagedObjectContext *context = [app managedObjectContext];
                
                NSManagedObject *object = [NSEntityDescription insertNewObjectForEntityForName:@"Entity"
                                                                        inManagedObjectContext:context];
                
                return object;
            }];
        });
        
        it(@"should map core data special values", ^{
            id expectedBool = [NSNumber numberWithBool:YES];
            id expectedInt = [NSNumber numberWithInt:10];
            id expectedDouble = [NSNumber numberWithDouble:3.1f];
            id expectedFloat = [NSNumber numberWithFloat:3.4f];
            id expectedString = @"stringValue";
            
            NSDictionary *dict = @{
                @"bool" : expectedBool,
                @"int" : expectedInt,
                @"double" : expectedDouble,
                @"float" : expectedFloat,
                @"string" : expectedString
            };
            
            Entity *entity = [[BWObjectMapper shared] objectFromJSON:dict withObjectClass:[Entity class]];
            [[entity.boolValue should] equal:expectedBool];
            [[entity.intValue should] equal:expectedInt];
            [[entity.doubleValue should] equal:expectedDouble];
            [[entity.floatValue should] equal:expectedFloat];
            [[entity.stringValue should] equal:expectedString];
        });
        
    });
    
});

SPEC_END