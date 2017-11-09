//
//  FMCSecurityConstants.h
//  FMCSecurity
//
//  Created by Joel Fischer on 1/28/16.
//  Copyright © 2016 livio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const FMCSecurityErrorDomain;

typedef NS_ENUM(NSUInteger, FMCTLSErrorCode) {
    FMCTLSErrorCodeNone,
    FMCTLSErrorCodeSSL,
    FMCTLSErrorCodeWantRead,
    FMCTLSErrorCodeWantWrite,
    FMCTLSErrorCodeWriteFailed,
    FMCTLSErrorCodeGeneric,
    FMCTLSErrorCodeNotInitialized,
    FMCTLSErrorCodeInitializationFailure,
    FMCTLSErrorCodeNoCertificate,
    FMCTLSErrorCodeCertificateExpired,
    FMCTLSErrorCodeCertificateInvalid,
    FMCTLSErrorCodeMaxRetriesAllowed
};
