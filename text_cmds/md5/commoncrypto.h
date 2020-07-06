#include <CommonCrypto/CommonDigest.h>
//#include <CommonCrypto/CommonDigestSPI.h>
//#include "CommonDigestSPI.h"

enum {
  kCCDigestNone       = 0,
//  kCCDigestMD2        = 1,
//  kCCDigestMD4        = 2,
  kCCDigestMD5        = 3,
//  kCCDigestRMD128     = 4,
//  kCCDigestRMD160     = 5,
//  kCCDigestRMD256     = 6,
//  kCCDigestRMD320     = 7,
  kCCDigestSHA1        = 8,
//  kCCDigestSHA224        = 9,
  kCCDigestSHA256        = 10,
//  kCCDigestSHA384        = 11,
//  kCCDigestSHA512        = 12,
//  kCCDigestSkein128      = 13,
//  kCCDigestSkein160      = 14,
//  kCCDigestSkein224      = 16,
//  kCCDigestSkein256      = 17,
//  kCCDigestSkein384      = 18,
//  kCCDigestSkein512      = 19,
};
typedef uint32_t ios_CCDigestAlgorithm;

#define ios_CCDigestAlg ios_CCDigestAlgorithm

typedef union {
  CC_MD5_CTX md5;
  CC_SHA1_CTX sha1;
  CC_SHA256_CTX sha256;
//  RIPEMD160_CTX ripemd160;
} _DIGEST_CTX;

typedef struct ios_CCDigestCtx_t {
  ios_CCDigestAlgorithm algorithm;
  _DIGEST_CTX ctx;
} ios_CCDigestCtx, *ios_CCDigestRef;


int ios_CCDigestInit(ios_CCDigestAlgorithm alg, ios_CCDigestRef ctx);
int ios_CCDigestFinal(ios_CCDigestRef ctx, unsigned char *md);
int ios_CCDigestUpdate(ios_CCDigestRef ctx, const void *data, size_t len);

char *Digest_End(ios_CCDigestRef, char *);

char *Digest_Data(ios_CCDigestAlg, const void *, size_t, char *);

char *Digest_File(ios_CCDigestAlg, const char *, char *);
