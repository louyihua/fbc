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
 * time_decodesertime.c -- functions to decode a serial time number
 *
 * chng: aug/2005 written [mjs]
 *
 */

#include <malloc.h>
#include <string.h>
#include <time.h>
#include "fb.h"

/*:::::*/
FBCALL void fb_hTimeDecodeSerial ( double serial,
                                   int *pHour, int *pMinute, int *pSecond )
{
    int hour, minute, second;
    double dblFixValue = fb_FIXDouble( serial );

    serial -= dblFixValue;
    if( fb_hSign( serial ) == -1 ) {
        /* Test for both 0.0 and -0.0 because FPUs may handle this as
         * different values ... */
        if( dblFixValue==0.0 || dblFixValue==-0.0 ) {
            /* QB quirk ! */
            serial = -serial;
        } else {
            serial += 1.0l;
        }
    }

    /* The inaccuracies of the IEEE floating point data types ... */
    serial += 0.000000001l;

    serial *= 24.0l;
    hour = (int) serial;
    serial -= hour;
    serial *= 60.0l;
    minute = (int) serial;
    serial -= minute;
    serial *= 60.0l;
    second = (int) serial;

    if( pHour )
        *pHour = hour;
    if( pMinute )
        *pMinute = minute;
    if( pSecond )
        *pSecond = second;
}

FBCALL int fb_Hour( double serial )
{
    int hour;
    fb_hTimeDecodeSerial( serial, &hour, NULL, NULL );
    return hour;
}

FBCALL int fb_Minute( double serial )
{
    int minute;
    fb_hTimeDecodeSerial( serial, NULL, &minute, NULL );
    return minute;
}

FBCALL int fb_Second( double serial )
{
    int second;
    fb_hTimeDecodeSerial( serial, NULL, NULL, &second );
    return second;
}
