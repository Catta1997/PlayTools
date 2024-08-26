//
//  NewInstance.h
//  PlayTools
//
//  Created by Edoardo Cattarin on 26/08/24.
//

#ifndef NewInstance_h
#define NewInstance_h


#endif /* NewInstance_h */

@interface NSObject (SwizzleInstance)

- (void)swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector;


@end
