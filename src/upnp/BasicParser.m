// **********************************************************************************
//
// BSD License.
// This file is part of upnpx.
//
// Copyright (c) 2010-2011, Bruno Keymolen, email: bruno.keymolen@gmail.com
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, 
// are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, 
// this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this 
// list of conditions and the following disclaimer in the documentation and/or other 
// materials provided with the distribution.
// Neither the name of "Bruno Keymolen" nor the names of its contributors may be 
// used to endorse or promote products derived from this software without specific 
// prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
// IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
// INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
// POSSIBILITY OF SUCH DAMAGE.
//
// **********************************************************************************


#import "BasicParser.h"

@interface BasicParser ()
@property (strong) NSMutableArray *mElementStack; //NSString
@property (strong) NSMutableArray *mAssets; //BasicParserAssets
@property (assign) BOOL mSupportNamespaces;

- (int)startParser:(NSXMLParser*)parser;

@end

@implementation BasicParser
static NSString *ElementStart = @"ElementStart";
static NSString *ElementStop = @"ElementStop";

- (id)init {
  return [self initWithNamespaceSupport:NO];
}

- (id)initWithNamespaceSupport:(BOOL)namespaceSupport {
  self = [super init];
  if (self) {
    _mSupportNamespaces = namespaceSupport;
    _mElementStack = [[NSMutableArray alloc] init];
    _mAssets = [[NSMutableArray alloc] init];
  }
  return self;	
}

- (int)addAsset:(NSArray *)path callfunction:(SEL)function functionObject:(id)funcObj setStringValueFunction:(SEL)valueFunction setStringValueObject:(id)obj {
	BasicParserAsset *asset = [[BasicParserAsset alloc] initWithPath:path setStringValueFunction:valueFunction setStringValueObject:obj callFunction:function functionObject:funcObj];
	[self.mAssets addObject:asset];
	return 0;
}

- (void)clearAllAssets {
	[self.mAssets removeAllObjects];
}

- (BasicParserAsset *)getAssetForElementStack:(NSMutableArray *)stack {
	BasicParserAsset *ret = nil;
	
  for (BasicParserAsset *asset in self.mAssets) {
		//Full compares go first
		if ([[asset path] isEqualToArray:stack]) {
			ret = asset;
			break;
		} else {
			// * -> leafX -> leafY
			//Maybe we have a wildchar, that means that the path after the wildchar must match
			if ([(NSString *)[[asset path] objectAtIndex:0] isEqualToString:@"*"]) {
				if ([stack count] >= [[asset path] count]) {
					//Path ends with
					NSMutableArray *lastStackPath = [[NSMutableArray alloc] initWithArray:stack];
					NSMutableArray *lastAssetPath = [[NSMutableArray alloc] initWithArray:[asset path]];
					//cut the * from our asset path
					[lastAssetPath removeObjectAtIndex:0];
					//make our (copy of the) curents stack the same length
					NSUInteger elementsToRemove = [lastStackPath count] - [lastAssetPath count];
					NSRange range;
					range.location = 0;
					range.length = elementsToRemove;
					[lastStackPath removeObjectsInRange:range];
					if ([lastAssetPath isEqualToArray:lastStackPath]) {
						ret = asset;
						break;
					}
				}
			}
			// leafX -> leafY -> *
			if ([(NSString *)[[asset path] lastObject] isEqualToString:@"*"]) {
				if ([stack count] == [[asset path] count] && [stack count] > 1) {
					//Path start with
					NSMutableArray *beginStackPath = [[NSMutableArray alloc] initWithArray:stack];
					NSMutableArray *beginAssetPath = [[NSMutableArray alloc] initWithArray:[asset path]];
					//Cut the last entry (which is * in one array and <element> in the other
					[beginStackPath removeLastObject];
					[beginAssetPath removeLastObject];
					if ([beginAssetPath isEqualToArray:beginStackPath]) {
						ret = asset;
						break;
					}
				}
			}
			
		}
  }
	
	return ret;
}

- (int)parseFromData:(NSData *)data {
	int ret=0;
	
  @autoreleasepool {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
    ret = [self startParser:parser];
  }
    
	return ret;
}

- (int)parseFromURL:(NSURL *)url {
	int ret = 0;

  @autoreleasepool {
    //Workaround for memory leak
    //http://blog.filipekberg.se/2010/11/30/nsxmlparser-has-memory-leaks-in-ios-4/
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];
    
    NSData *xml = [NSData dataWithContentsOfURL:url];
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:xml];;

    ret = [self startParser:parser];
  }
	return ret;
}

- (int)startParser:(NSXMLParser*)parser {
	int ret = 0;
	
	if (parser == nil) {
		return -1;
	}
	
	[parser setShouldProcessNamespaces:self.mSupportNamespaces];
	[parser setDelegate:self];
	
	BOOL pret = [parser parse];
	if (pret) {
		ret = 0;
	} else {
		ret = -1;
	}
	
  [parser setDelegate:nil];
	
	return ret;
}

- (NSMutableArray *)elementStack {
  return self.mElementStack;
}

#pragma mark - NSXMLParserDelegate conformance
- (void)parserDidStartDocument:(NSXMLParser *)parser{
}

- (void)parserDidEndDocument:(NSXMLParser *)parser{
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict {
	//NSLog(@"open=%@", elementName);
	[self.mElementStack addObject:elementName];
	
	//Check if we are looking for this asset
	BasicParserAsset *asset = [self getAssetForElementStack:self.mElementStack];
	if (asset) {
		self.elementAttributeDict = attributeDict; //make temprary available to derived classes

    if ([asset stringValueFunction] && [asset stringValueObject]) {
      //we are interested in a string and we are looking for this
      [[asset stringCache] setString:@""];
      //[asset setStringCache:[[[NSString alloc] init] autorelease]];
    }
		
    if ([asset function] && [asset functionObject] ) {
      if ([[asset functionObject] respondsToSelector:[asset function]]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [[asset functionObject] performSelector:[asset function] withObject:ElementStart];
#pragma clang diagnostic pop
      }
    }
  }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{
	//NSLog(@"close=%@", elementName);
  	
	BasicParserAsset* asset = [self getAssetForElementStack:self.mElementStack];
	if (asset) {
		self.currentElementName = elementName; //make temporary available to derived classes
		
		//We where looking for this
		//Set string (call function to set)
		if ([asset stringValueFunction] && [asset stringValueObject]) {
			if ([[asset stringValueObject] respondsToSelector:[asset stringValueFunction]]) {
        NSString *obj = [[NSString alloc] initWithString:[asset stringCache]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[[asset stringValueObject] performSelector:[asset stringValueFunction] withObject:obj];
#pragma clang diagnostic pop
			} else {
				NSLog(@"Does not respond to selector %@", NSStringFromSelector([asset stringValueFunction]));
			}
		}
    
		//Call function
		if ([asset function] && [asset functionObject]){ 
			if ([[asset functionObject] respondsToSelector:[asset function]]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[[asset functionObject] performSelector:[asset function] withObject:ElementStop];
#pragma clang diagnostic pop
			}
		}
	}
	
	if ([elementName isEqualToString:[self.mElementStack lastObject]]) {
		[self.mElementStack removeLastObject];
	} else {
		//XML structure error (!)
		NSLog(@"XML wrong formatted (!)");
		[parser abortParsing]; 
	}
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
	//The parser object may send the delegate several parser:foundCharacters: messages to report the characters of an element. 
	//Because string may be only part of the total character content for the current element, 
	//you should append it to the current accumulation of characters until the element changes.
	
	//Are we looking for this ?
	//Check if we are looking for this asset
	BasicParserAsset* asset = [self getAssetForElementStack:self.mElementStack];
	if (asset != nil) {
		[[asset stringCache] appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
  NSLog(@"%@", [NSString stringWithFormat:@"Parser Error %i, Description: %@, Line: %i, Column: %i", [parseError code], [[parser parserError] localizedDescription], [parser lineNumber], [parser columnNumber]]);
}

/*
 # – parser:didStartMappingPrefix:toURI:  delegate method
 # – parser:didEndMappingPrefix:  delegate method
 # – parser:resolveExternalEntityName:systemID:  delegate method
 # – parser:parseErrorOccurred:  delegate method
 # – parser:validationErrorOccurred:  delegate method
 # – parser:foundIgnorableWhitespace:  delegate method
 # – parser:foundProcessingInstructionWithTarget:data:  delegate method
 # – parser:foundComment:  delegate method
 # – parser:foundCDATA:  delegate method
 */

@end
