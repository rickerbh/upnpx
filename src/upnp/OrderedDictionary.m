//
//  OrderedDictionary.m
//  OrderedDictionary
//
//  Created by Matt Gallagher on 19/12/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file without charge in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "OrderedDictionary.h"

NSString *DescriptionForObject(NSObject *object, id locale, NSUInteger indent) {
	NSString *objectString;
	if ([object isKindOfClass:[NSString class]]) {
		objectString = (NSString *)object;
	} else if ([object respondsToSelector:@selector(descriptionWithLocale:indent:)]) {
		objectString = [(NSDictionary *)object descriptionWithLocale:locale indent:indent];
	} else if ([object respondsToSelector:@selector(descriptionWithLocale:)]) {
		objectString = [(NSSet *)object descriptionWithLocale:locale];
  }	else {
		objectString = [object description];
	}
	return objectString;
}

@interface OrderedDictionary ()
@property (strong) NSMutableDictionary *dictionary;
@property (strong) NSMutableArray *array;
@end

@implementation OrderedDictionary

- (id)init {
  return [self initWithCapacity:0];
}

- (id)initWithCapacity:(NSUInteger)capacity {
	self = [super init];
	if (self) {
		_dictionary = [[NSMutableDictionary alloc] initWithCapacity:capacity];
		_array = [[NSMutableArray alloc] initWithCapacity:capacity];
	}
	return self;
}

- (id)copy {
	return [self mutableCopy];
}

- (void)setObject:(id)anObject forKey:(id)aKey {
	if (![self.dictionary objectForKey:aKey]) {
		[self.array addObject:aKey];
	}
	[self.dictionary setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey {
	[self.dictionary removeObjectForKey:aKey];
	[self.array removeObject:aKey];
}

- (NSUInteger)count {
	return [self.dictionary count];
}

- (id)objectForKey:(id)aKey {
	return [self.dictionary objectForKey:aKey];
}

- (NSEnumerator *)keyEnumerator {
	return [self.array objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator {
	return [self.array reverseObjectEnumerator];
}

- (void)insertObject:(id)anObject forKey:(id)aKey atIndex:(NSUInteger)anIndex {
	if (![self.dictionary objectForKey:aKey]) {
		[self removeObjectForKey:aKey];
	}
	[self.array insertObject:aKey atIndex:anIndex];
	[self.dictionary setObject:anObject forKey:aKey];
}

- (id)keyAtIndex:(NSUInteger)anIndex {
	return [self.array objectAtIndex:anIndex];
}

- (NSString *)descriptionWithLocale:(id)locale indent:(NSUInteger)level {
	NSMutableString *indentString = [NSMutableString string];
	NSUInteger i, count = level;
	for (i = 0; i < count; i++)
	{
		[indentString appendFormat:@"    "];
	}
	
	NSMutableString *description = [NSMutableString string];
	[description appendFormat:@"%@{\n", indentString];
	for (NSObject *key in self) {
		[description appendFormat:@"%@    %@ = %@;\n",
			indentString,
			DescriptionForObject(key, locale, level),
			DescriptionForObject([self objectForKey:key], locale, level)];
	}
	[description appendFormat:@"%@}\n", indentString];
	return description;
}

@end
