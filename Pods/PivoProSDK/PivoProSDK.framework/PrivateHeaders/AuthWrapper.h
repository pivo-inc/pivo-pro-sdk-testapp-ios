//
//  AuthWrapper.h
//  PivoProSDK
//
//  Created by Tuan on 2020/04/21.
//  Copyright © 2020 3i. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AuthWrapper : NSObject
  
- (id) init;
/// Returns a radomly generated 4 bytes inquiry value;
- (UInt32) getInquiry;
/// Returns authentication code for input value
/// @param input input code
/// @returns authentication code
- (UInt32) calculateAnswer: (UInt32) input;
/// Verify wether input and answer is matched or not
/// @param input input code
/// @param answer the value for verifying authentication
/// @returns 1 : succes, 0 : fail
- (bool) verifyAnswer: (UInt32) input answer: (UInt32) answer;
@end
