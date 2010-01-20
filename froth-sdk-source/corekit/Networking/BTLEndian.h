////////////////////////////////////////////////////////////////////////////////
//  endian.h
//  Author(s):     Michael Buckley
//  First Created: 21 August 2007
//  Last Edited:   21 August 2007
////////////////////////////////////////////////////////////////////////////////

#ifndef __BTL_ENDIAN_H__
#define __BTL_ENDIAN_H__

#ifndef LITTLE_ENDIAN
#ifdef __LITTLE_ENDIAN
#define LITTLE_ENDIAN __LITTLE_ENDIAN
#else
#define LITTLE_ENDIAN 0
#endif
#endif

#ifndef BIG_ENDIAN
#ifdef __BIG_ENDIAN
#define BIG_ENDIAN __BIG_ENDIAN
#else
#define BIG_ENDIAN 1
#endif
#endif

#ifndef BYTE_ORDER
#ifdef __BYTE_ORDER
#define BYTE_ORDER __BYTE_ORDER
#else

#if defined (__sparc) || defined(__sparc__) \
|| defined(_POWER) || defined(__powerpc__) \
|| defined(__ppc__) || defined(__hppa) \
|| defined(_MIPSEB) || defined(_POWER) \
|| defined(__s390__)
#define BYTE_ORDER BIG_ENDIAN
#else
// Assume little endian, as x86 is the most popular architecture
#define BYTE_ORDER LITTLE_ENDIAN
#endif
#endif
#endif
#endif
