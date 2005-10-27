/*
 *  libfb - FreeBASIC's runtime library
 *	Copyright (C) 2004-2005 Andre V. T. Vicentini (av1ctor@yahoo.com.br) and others.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

/*
 * data_ulong.c -- read stmt for ulong integer's
 *
 * chng: oct/2004 written [v1ctor]
 *
 */

#include <stdlib.h>
#include "fb.h"

/*:::::*/
FBCALL void fb_DataReadULongint( unsigned long long *dst )
{
	short len;

	FB_LOCK();

	len = fb_DataRead();

	if( len == 0 )
	{
		*dst = 0;
	}
	else if( len == FB_DATATYPE_OFS )
	{
		*dst = *(unsigned int *)fb_DataPtr;
		fb_DataPtr += sizeof( unsigned int );
	}
	/* wstring? */
	else if( len & 0x8000 )
	{
        len &= 0x7FFF;
        *dst = fb_WstrToULongint( (FB_WCHAR *)fb_DataPtr, len );
		fb_DataPtr += (len + 1) * sizeof( FB_WCHAR );
	}
	else
	{
		*dst = fb_hStr2ULongint( (char *)fb_DataPtr, len );
		fb_DataPtr += len + 1;
	}

	FB_UNLOCK();
}
