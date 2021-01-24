/*
 * Copyright (c) 2005 Darren Tucker <dtucker@zip.com.au>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF MIND, USE, DATA OR PROFITS, WHETHER
 * IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
 * OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#define SSH_DONT_OVERLOAD_OPENSSL_FUNCS
#include "includes.h"

#ifdef WITH_OPENSSL

#include <stdarg.h>
#include <string.h>

#ifdef USE_OPENSSL_ENGINE
# include <openssl/engine.h>
# include <openssl/conf.h>
#endif

#include "log.h"

#include "openssl-compat.h"

/*
 * OpenSSL version numbers: MNNFFPPS: major minor fix patch status
 * We match major, minor, fix and status (not patch) for <1.0.0.
 * After that, we acceptable compatible fix versions (so we
 * allow 1.0.1 to work with 1.0.0). Going backwards is only allowed
 * within a patch series.
 */

int
ssh_compatible_openssl(long headerver, long libver)
{
  long mask, hfix, lfix;

  /* exact match is always OK */
  if (headerver == libver)
    return 1;

  /* for versions < 1.0.0, major,minor,fix,status must match */
  if (headerver < 0x1000000f) {
    mask = 0xfffff00fL; /* major,minor,fix,status */
    return (headerver & mask) == (libver & mask);
  }

  /*
   * For versions >= 1.0.0, major,minor,status must match and library
   * fix version must be equal to or newer than the header.
   */
  mask = 0xfff0000fL; /* major,minor,status */
  hfix = (headerver & 0x000ff000) >> 12;
  lfix = (libver & 0x000ff000) >> 12;
  if ( (headerver & mask) == (libver & mask) && lfix >= hfix)
    return 1;
  return 0;
}

void
ssh_libcrypto_init(void)
{
#if defined(HAVE_OPENSSL_INIT_CRYPTO) && \
      defined(OPENSSL_INIT_ADD_ALL_CIPHERS) && \
      defined(OPENSSL_INIT_ADD_ALL_DIGESTS)
  OPENSSL_init_crypto(OPENSSL_INIT_ADD_ALL_CIPHERS |
      OPENSSL_INIT_ADD_ALL_DIGESTS, NULL);
#elif defined(HAVE_OPENSSL_ADD_ALL_ALGORITHMS)
  OpenSSL_add_all_algorithms();
#endif

#ifdef  USE_OPENSSL_ENGINE
  /* Enable use of crypto hardware */
  ENGINE_load_builtin_engines();
  ENGINE_register_all_complete();

  /* Load the libcrypto config file to pick up engines defined there */
# if defined(HAVE_OPENSSL_INIT_CRYPTO) && defined(OPENSSL_INIT_LOAD_CONFIG)
  OPENSSL_init_crypto(OPENSSL_INIT_ADD_ALL_CIPHERS |
      OPENSSL_INIT_ADD_ALL_DIGESTS | OPENSSL_INIT_LOAD_CONFIG, NULL);
# else
  OPENSSL_config(NULL);
# endif
#endif /* USE_OPENSSL_ENGINE */
}


 #ifndef HAVE_EVP_CIPHER_CTX_GET_IV
 int
 EVP_CIPHER_CTX_get_iv(const EVP_CIPHER_CTX *ctx, unsigned char *iv, size_t len)
 {
   if (ctx == NULL)
     return 0;
   if (EVP_CIPHER_CTX_iv_length(ctx) < 0)
     return 0;
   if (len != (size_t)EVP_CIPHER_CTX_iv_length(ctx))
     return 0;
   if (len > EVP_MAX_IV_LENGTH)
     return 0; /* sanity check; shouldn't happen */
   /*
    * Skip the memcpy entirely when the requested IV length is zero,
    * since the iv pointer may be NULL or invalid.
    */
   if (len != 0) {
     if (iv == NULL)
       return 0;
 # ifdef HAVE_EVP_CIPHER_CTX_IV
     memcpy(iv, EVP_CIPHER_CTX_iv(ctx), len);
 # else
     memcpy(iv, ctx->iv, len);
 # endif /* HAVE_EVP_CIPHER_CTX_IV */
   }
   return 1;
 }
 #endif /* HAVE_EVP_CIPHER_CTX_GET_IV */

 #ifndef HAVE_EVP_CIPHER_CTX_SET_IV
 int
 EVP_CIPHER_CTX_set_iv(EVP_CIPHER_CTX *ctx, const unsigned char *iv, size_t len)
 {
   if (ctx == NULL)
     return 0;
   if (EVP_CIPHER_CTX_iv_length(ctx) < 0)
     return 0;
   if (len != (size_t)EVP_CIPHER_CTX_iv_length(ctx))
     return 0;
   if (len > EVP_MAX_IV_LENGTH)
     return 0; /* sanity check; shouldn't happen */
   /*
    * Skip the memcpy entirely when the requested IV length is zero,
    * since the iv pointer may be NULL or invalid.
    */
   if (len != 0) {
     if (iv == NULL)
       return 0;
 # ifdef HAVE_EVP_CIPHER_CTX_IV_NOCONST
     memcpy(EVP_CIPHER_CTX_iv_noconst(ctx), iv, len);
 # else
     memcpy(ctx->iv, iv, len);
 # endif /* HAVE_EVP_CIPHER_CTX_IV_NOCONST */
   }
   return 1;
 }
 #endif /* HAVE_EVP_CIPHER_CTX_SET_IV */

 
#endif /* WITH_OPENSSL */
