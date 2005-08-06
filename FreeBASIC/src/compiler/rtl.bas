''	FreeBASIC - 32-bit BASIC Compiler.
''	Copyright (C) 2004-2005 Andre Victor T. Vicentini (av1ctor@yahoo.com.br)
''
''	This program is free software; you can redistribute it and/or modify
''	it under the terms of the GNU General Public License as published by
''	the Free Software Foundation; either version 2 of the License, or
''	(at your option) any later version.
''
''	This program is distributed in the hope that it will be useful,
''	but WITHOUT ANY WARRANTY; without even the implied warranty of
''	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
''	GNU General Public License for more details.
''
''	You should have received a copy of the GNU General Public License
''	along with this program; if not, write to the Free Software
''	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA.


'' runtime-lib helpers -- for when simple calls can't be done, because args of
'' 						  diff types, quirk syntaxes, etc
''
'' chng: oct/2004 written [v1ctor]

defint a-z
option explicit
option escape

#include once "inc\fb.bi"
#include once "inc\fbint.bi"
#include once "inc\lex.bi"
#include once "inc\ir.bi"
#include once "inc\ast.bi"
#include once "inc\emit.bi"
#include once "inc\rtl.bi"

type RTLCTX
	datainited		as integer
	lastlabel		as FBSYMBOL ptr
    labelcnt 		as integer
end type


declare function 	hMultithread_cb		( byval sym as FBSYMBOL ptr ) as integer
declare function 	hGfxlib_cb			( byval sym as FBSYMBOL ptr ) as integer
declare function 	hMultinput_cb		( byval sym as FBSYMBOL ptr ) as integer


''globals
	dim shared ctx as RTLCTX

	redim shared ifuncTB( 0 ) as FBSYMBOL ptr


'':::::::::::::::::::::::::::::::::::::::::::::::::::
'' FUNCTIONS
'':::::::::::::::::::::::::::::::::::::::::::::::::::

'' name, alias, _
'' type, mode, _
'' callback, checkerror, overloaded, _
'' args, _
'' [arg typ,mode,optional[,value]]*args
ifuncdata:

'' fb_StrConcat ( byref dst as string, _
''				  byref str1 as any, byval str1len as integer, _
''				  byref str2 as any, byval str2len as integer ) as string
data "fb_StrConcat","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_StrCompare ( byref str1 as any, byval str1len as integer, _
''				   byref str2 as any, byval str2len as integer ) as integer
'' returns: 0= equal; -1=str1 < str2; 1=str1 > str2
data "fb_StrCompare","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_StrAssign ( byref dst as any, byval dst_len as integer, _
'' 				  byref src as any, byval src_len as integer, _
''                byval fillrem as integer = 1 ) as string
data "fb_StrAssign","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1
'' fb_StrConcatAssign ( byref dst as any, byval dst_len as integer, _
'' 				        byref src as any, byval src_len as integer, _
''					    byval fillrem as integer = 1 ) as string
data "fb_StrConcatAssign","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1
'' fb_StrDelete ( byref str as string ) as void
data "fb_StrDelete","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_StrAllocTempResult ( byref str as string ) as string
data "fb_StrAllocTempResult","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_StrAllocTempDescV ( byref str as string ) as string
data "fb_StrAllocTempDescV","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_StrAllocTempDescF ( byref str as any, byval strlen as integer ) as string
data "fb_StrAllocTempDescF","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_StrAllocTempDescZ ( byval str as string ) as string
data "fb_StrAllocTempDescZ","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE

'' fb_LongintDIV ( byval x as longint, byval y as longint ) as longint
data "__divdi3","", _
	 FB_SYMBTYPE_LONGINT,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE
'' fb_ULongintDIV ( byval x as ulongint, byval y as ulongint ) as ulongint
data "__udivdi3","", _
	 FB_SYMBTYPE_ULONGINT,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE
'' fb_LongintMOD ( byval x as longint, byval y as longint ) as longint
data "__moddi3","", _
	 FB_SYMBTYPE_LONGINT,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE
'' fb_ULongintMOD ( byval x as ulongint, byval y as ulongint ) as ulongint
data "__umoddi3","", _
	 FB_SYMBTYPE_ULONGINT,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE
'' fb_Dbl2ULongint ( byval x as double ) as ulongint
data "__fixunsdfdi","", _
	 FB_SYMBTYPE_ULONGINT,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE

'' fb_ArrayRedim CDECL ( array() as ANY, byval elementlen as integer, _
''					     byval isvarlen as integer, _
''						 byval dimensions as integer, ... ) as integer
data "fb_ArrayRedim","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 INVALID,FB_ARGMODE_VARARG, FALSE
'' fb_ArrayRedimPresv CDECL ( array() as ANY, byval elementlen as integer, _
''					          byval isvarlen as integer, _
''						      byval dimensions as integer, ... ) as integer
data "fb_ArrayRedimPresv","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 INVALID,FB_ARGMODE_VARARG, FALSE
'' fb_ArrayErase ( array() as ANY, byval isvarlen as integer ) as integer
data "fb_ArrayErase","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_ArrayClear ( array() as ANY, byval isvarlen as integer ) as integer
data "fb_ArrayClear","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_ArrayLBound ( array() as ANY, byval dimension as integer ) as integer
data "fb_ArrayLBound","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_ArrayUBound ( array() as ANY, byval dimension as integer ) as integer
data "fb_ArrayUBound","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_ArraySetDesc CDECL ( array() as ANY, byref arraydata as any, byval elementlen as integer, _
''						   byval dimensions as integer, ... ) as void
data "fb_ArraySetDesc","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 INVALID,FB_ARGMODE_VARARG, FALSE
'' fb_ArrayStrErase ( array() as any ) as void
data "fb_ArrayStrErase","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE
'' fb_ArrayAllocTempDesc CDECL ( byref pdesc as any ptr, arraydata as any, byval elementlen as integer, _
''						         byval dimensions as integer, ... ) as void ptr
data "fb_ArrayAllocTempDesc","", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 INVALID,FB_ARGMODE_VARARG, FALSE
'' fb_ArrayFreeTempDesc ( byval pdesc as any ptr) as void
data "fb_ArrayFreeTempDesc","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE

'' fb_ArraySngBoundChk ( byval idx as integer, byval ubound as integer, _
''						 byval linenum as integer ) as any ptr
data "fb_ArraySngBoundChk","", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_ArrayBoundChk ( byval idx as integer, byval lbound as integer, byval ubound as integer, _
''						byval linenum as integer ) as any ptr
data "fb_ArrayBoundChk","", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_NullPtrChk ( byval p as any ptr, byval linenum as integer ) as any ptr
data "fb_NullPtrChk","", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

''
'' fb_IntToStr ( byval number as integer ) as string
data "fb_IntToStr","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_UIntToStr ( byval number as uinteger ) as string
data "fb_UIntToStr","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE
'' fb_LongintToStr ( byval number as longint ) as string
data "fb_LongintToStr","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE
'' fb_ULongintToStr ( byval number as ulongint ) as string
data "fb_ULongintToStr","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE
'' fb_FloatToStr ( byval number as single ) as string
data "fb_FloatToStr","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE
'' fb_DoubleToStr ( byval number as double ) as string
data "fb_DoubleToStr","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE

'' fb_StrMid ( byref str as string, byval start as integer, byval len as integer ) as string
data "fb_StrMid","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_StrAssignMid ( byref dst as string, byval start as integer, byval len as integer, src as string ) as void
data "fb_StrAssignMid","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_StrFill1 ( byval cnt as integer, byval char as integer ) as string
data "fb_StrFill1","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_StrFill2 ( byval cnt as integer, byref str as string ) as string
data "fb_StrFill2","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_StrLen ( byref str as any, byval strlen as integer ) as integer
data "fb_StrLen","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' lset ( byref dst as string, byref src as string ) as void
data "fb_StrLset","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_ASC ( byref str as string, byval pos as integer = 0 ) as uinteger
data "fb_ASC", "", _
	 FB_SYMBTYPE_UINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE, 0
'' fb_CHR CDECL ( byval args as integer, ... ) as string
data "fb_CHR", "", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 INVALID,FB_ARGMODE_VARARG, FALSE
'' fb_StrInstr ( byval start as integer, srcstr as string, pattern as string ) as integer
data "fb_StrInstr","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_StrInstrAny ( byval start as integer, srcstr as string, pattern as string ) as integer
data "fb_StrInstrAny","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_RTRIM ( str as string ) as string
data "fb_RTRIM","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_RTrimAny ( str as string ) as string
data "fb_RTrimAny","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_RTrimEx ( str as string, str as pattern ) as string
data "fb_RTrimEx","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_LTRIM ( str as string ) as string
data "fb_LTRIM","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_LTrimAny ( str as string ) as string
data "fb_LTrimAny","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_LTrimEx ( str as string, str as pattern ) as string
data "fb_LTrimEx","", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE


''
'' fb_Init ( byval argc as integer, byval argv as zstring ptr ptr ) as void
data "fb_Init","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE
'' fb_InitSignals ( ) as void
data "fb_InitSignals","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' fb_InitProfile ( ) as void
data "fb_InitProfile","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' fb_END ( byval errlevel as integer ) as void
data "fb_End","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

''
'' fb_DataRestore ( byval labeladdrs as void ptr ) as void
data "fb_DataRestore","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE
'' fb_DataReadStr ( byref dst as any, byval dst_size as integer, _
''                  byval fillrem as integer = 1 ) as void
data "fb_DataReadStr","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1
'' fb_DataReadByte ( byref dst as byte ) as void
data "fb_DataReadByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadShort ( byref dst as short ) as void
data "fb_DataReadShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadInt ( byref dst as integer ) as void
data "fb_DataReadInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadLongint ( byref dst as longint ) as void
data "fb_DataReadLongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadUByte ( byref dst as ubyte ) as void
data "fb_DataReadUByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_UBYTE,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadUShort ( byref dst as ushort ) as void
data "fb_DataReadUShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_USHORT,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadUInt ( byref dst as uinteger ) as void
data "fb_DataReadUInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadULongint ( byref dst as ulongint ) as void
data "fb_DataReadULongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadSingle ( byref dst as single ) as void
data "fb_DataReadSingle","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, FALSE
'' fb_DataReadDouble ( byref dst as single ) as void
data "fb_DataReadDouble","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYREF, FALSE

''
'' fb_Pow CDECL ( byval x as double, byval y as double ) as double
data "fb_Pow","pow", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' fb_SGNSingle ( byval x as single ) as integer
data "fb_SGNSingle","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE
'' fb_SGNDouble ( byval x as double ) as integer
data "fb_SGNDouble","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' fb_FIXSingle ( byval x as single ) as single
data "fb_FIXSingle","", _
	 FB_SYMBTYPE_SINGLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE
'' fb_FIXDouble ( byval x as double ) as double
data "fb_FIXDouble","", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' asin CDECL ( byval x as double ) as double
data "{asin}","asin", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' acos CDECL ( byval x as double ) as double
data "{acos}","acos", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' log CDECL ( byval x as double ) as double
data "{log}","log", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE

''
'' fb_PrintVoid ( byval filenum as integer = 0, byval mask as integer ) as void
data "fb_PrintVoid","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintByte ( byval filenum as integer = 0, byval x as byte, byval mask as integer ) as void
data "fb_PrintByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintUByte ( byval filenum as integer = 0, byval x as ubyte, byval mask as integer ) as void
data "fb_PrintUByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_UBYTE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintShort ( byval filenum as integer = 0, byval x as short, byval mask as integer ) as void
data "fb_PrintShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintUShort ( byval filenum as integer = 0, byval x as ushort, byval mask as integer ) as void
data "fb_PrintUShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_USHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintInt ( byval filenum as integer = 0, byval x as integer, byval mask as integer ) as void
data "fb_PrintInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintUInt ( byval filenum as integer = 0, byval x as uinteger, byval mask as integer ) as void
data "fb_PrintUInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintLongint ( byval filenum as integer = 0, byval x as longint, byval mask as integer ) as void
data "fb_PrintLongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintULongint ( byval filenum as integer = 0, byval x as ulongint, byval mask as integer ) as void
data "fb_PrintULongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintSingle ( byval filenum as integer = 0, byval x as single, byval mask as integer ) as void
data "fb_PrintSingle","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintDouble ( byval filenum as integer = 0, byval x as double, byval mask as integer ) as void
data "fb_PrintDouble","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintString ( byval filenum as integer = 0, x as string, byval mask as integer ) as void
data "fb_PrintString","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

''
'' fb_LPrintVoid ( byval filenum as integer = 0, byval mask as integer ) as void
data "fb_LPrintVoid","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintByte ( byval filenum as integer = 0, byval x as byte, byval mask as integer ) as void
data "fb_LPrintByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintUByte ( byval filenum as integer = 0, byval x as ubyte, byval mask as integer ) as void
data "fb_LPrintUByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_UBYTE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintShort ( byval filenum as integer = 0, byval x as short, byval mask as integer ) as void
data "fb_LPrintShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintUShort ( byval filenum as integer = 0, byval x as ushort, byval mask as integer ) as void
data "fb_LPrintUShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_USHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintInt ( byval filenum as integer = 0, byval x as integer, byval mask as integer ) as void
data "fb_LPrintInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintUInt ( byval filenum as integer = 0, byval x as uinteger, byval mask as integer ) as void
data "fb_LPrintUInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintLongint ( byval filenum as integer = 0, byval x as longint, byval mask as integer ) as void
data "fb_LPrintLongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintULongint ( byval filenum as integer = 0, byval x as ulongint, byval mask as integer ) as void
data "fb_LPrintULongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintSingle ( byval filenum as integer = 0, byval x as single, byval mask as integer ) as void
data "fb_LPrintSingle","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintDouble ( byval filenum as integer = 0, byval x as double, byval mask as integer ) as void
data "fb_LPrintDouble","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintString ( byval filenum as integer = 0, x as string, byval mask as integer ) as void
data "fb_LPrintString","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' spc ( byval filenum as integer = 0, byval n as integer ) as void
data "fb_PrintSPC","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' tab ( byval filenum as integer = 0, byval newcol as integer ) as void
data "fb_PrintTab","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

''
'' fb_WriteVoid ( byval filenum as integer = 0, byval mask as integer ) as void
data "fb_WriteVoid","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteByte ( byval filenum as integer = 0, byval x as byte, byval mask as integer ) as void
data "fb_WriteByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteUByte ( byval filenum as integer = 0, byval x as ubyte, byval mask as integer ) as void
data "fb_WriteUByte","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_UBYTE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteShort ( byval filenum as integer = 0, byval x as short, byval mask as integer ) as void
data "fb_WriteShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteUShort ( byval filenum as integer = 0, byval x as ushort, byval mask as integer ) as void
data "fb_WriteUShort","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_USHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteInt ( byval filenum as integer = 0, byval x as integer, byval mask as integer ) as void
data "fb_WriteInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteUInt ( byval filenum as integer = 0, byval x as uinteger, byval mask as integer ) as void
data "fb_WriteUInt","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteLongint ( byval filenum as integer = 0, byval x as longint, byval mask as integer ) as void
data "fb_WriteLongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteULongint ( byval filenum as integer = 0, byval x as ulongint, byval mask as integer ) as void
data "fb_WriteULongint","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_ULONGINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteSingle ( byval filenum as integer = 0, byval x as single, byval mask as integer ) as void
data "fb_WriteSingle","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteDouble ( byval filenum as integer = 0, byval x as double, byval mask as integer ) as void
data "fb_WriteDouble","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_WriteString ( byval filenum as integer = 0, x as string, byval mask as integer ) as void
data "fb_WriteString","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_PrintUsingInit ( fmtstr as string ) as integer
data "fb_PrintUsingInit","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_PrintUsingStr ( byval filenum as integer, s as string, byval mask as integer ) as integer
data "fb_PrintUsingStr","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintUsingVal ( byval filenum as integer, byval v as double, byval mask as integer ) as integer
data "fb_PrintUsingVal","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_PrintUsingEnd ( byval filenum as integer ) as integer
data "fb_PrintUsingEnd","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_LPrintUsingInit ( fmtstr as string ) as integer
data "fb_LPrintUsingInit","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE


'' fb_ConsoleView ( byval toprow as integer = 0, byval botrow as integer = 0 ) as void
data "fb_ConsoleView","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0
'' fb_ConsoleReadXY ( byval y as integer, byval x as integer, byval colorflag as integer ) as integer
data "fb_ConsoleReadXY","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0


''
'' fb_MemCopy cdecl ( dst as any, src as any, byval bytes as integer ) as void
data "fb_MemCopy","memcpy", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_MemSwap ( dst as any, src as any, byval bytes as integer ) as void
data "fb_MemSwap","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_StrSwap ( str1 as any, byval str1len as integer, str2 as any, byval str2len as integer ) as void
data "fb_StrSwap","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_MemCopyClear ( dst as any, byval dstlen as integer, src as any, byval srclen as integer ) as void
data "fb_MemCopyClear","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

''
'' fb_FileOpen( s as string, byval mode as integer, byval access as integer,
''		        byval lock as integer, byval filenum as integer, byval len as integer ) as integer
data "fb_FileOpen","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FileOpenShort( mode as string, byval filenum as integer,
''                   filename as string, byval len as integer,
''                   access_mode as string, lock_mode as string) as integer
data "fb_FileOpenShort","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fb_FileOpenCons( s as string, byval mode as integer, byval access as integer,
''		           byval lock as integer, byval filenum as integer, byval len as integer ) as integer
data "fb_FileOpenCons","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_FileOpenErr( s as string, byval mode as integer, byval access as integer,
''		           byval lock as integer, byval filenum as integer, byval len as integer ) as integer
data "fb_FileOpenErr","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_FileOpenPipe( s as string, byval mode as integer, byval access as integer,
''		           byval lock as integer, byval filenum as integer, byval len as integer ) as integer
data "fb_FileOpenPipe","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_FileOpenScrn( s as string, byval mode as integer, byval access as integer,
''		           byval lock as integer, byval filenum as integer, byval len as integer ) as integer
data "fb_FileOpenScrn","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_FileOpenLpt( s as string, byval mode as integer, byval access as integer,
''		           byval lock as integer, byval filenum as integer, byval len as integer ) as integer
data "fb_FileOpenLpt","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_FileClose	( byval filenum as integer ) as integer
data "fb_FileClose","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FilePut ( byval filenum as integer, byval offset as uinteger, value as any, byval valuelen as integer ) as integer
data "fb_FilePut","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FilePutStr ( byval filenum as integer, byval offset as uinteger, str as any, byval strlen as integer ) as integer
data "fb_FilePutStr","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FilePutArray ( byval filenum as integer, byval offset as uinteger, array() as any ) as integer
data "fb_FilePutArray","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE
'' fb_FileGet ( byval filenum as integer, byval offset as uinteger, value as any, byval valuelen as integer ) as integer
data "fb_FileGet","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FileGetStr ( byval filenum as integer, byval offset as uinteger, str as any, byval strlen as integer ) as integer
data "fb_FileGetStr","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FileGetArray ( byval filenum as integer, byval offset as uinteger, array() as any ) as integer
data "fb_FileGetArray","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE

'' fb_FileTell ( byval filenum as integer ) as uinteger
data "fb_FileTell","", _
	 FB_SYMBTYPE_UINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FileSeek ( byval filenum as integer, byval newpos as uinteger ) as integer
data "fb_FileSeek","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE

'' fb_FileStrInput ( byval bytes as integer, byval filenum as integer = 0 ) as string
data "fb_FileStrInput", "", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' fb_FileLineInput ( byval filenum as integer, _
''					  dst as any, byval dstlen as integer, byval fillrem as integer = 1 ) as integer
data "fb_FileLineInput", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1
'' fb_LineInput ( text as string, _
''				  dst as any, byval dstlen as integer, byval fillrem as integer = 1, _
''				  byval addquestion as integer, byval addnewline as integer ) as integer
data "fb_LineInput", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1

'' fb_FileInput ( byval filenum as integer ) as integer
data "fb_FileInput", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_ConsoleInput ( text as string,  byval addquestion as integer, _
''				     byval addnewline as integer ) as integer
data "fb_ConsoleInput", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_InputByte ( x as byte ) as void
data "fb_InputByte","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYREF, FALSE
'' fb_InputShort ( x as short ) as void
data "fb_InputShort","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYREF, FALSE
'' fb_InputInt ( x as integer ) as void
data "fb_InputInt","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE
'' fb_InputLongint ( x as longint ) as void
data "fb_InputLongint","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYREF, FALSE
'' fb_InputSingle ( x as single ) as void
data "fb_InputSingle","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, FALSE
'' fb_InputDouble ( x as double ) as void
data "fb_InputDouble","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYREF, FALSE
'' fb_InputString ( x as any, byval strlen as integer, byval fillrem as integer = 1 ) as void
data "fb_InputString","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1

'' fb_FileLock ( byval inipos as integer, byval endpos as integer ) as integer
data "fb_FileLock","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0
'' fb_FileUnlock ( byval inipos as integer, byval endpos as integer ) as integer
data "fb_FileUnlock","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0
'' rename ( byval oldname as string, byval newname as string ) as integer
data "rename","", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE



'' width( byval cols as integer = 0, byval width_arg as integer = 0 ) as integer
data "fb_Width", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0
'' width( dev as string, byval width_arg as integer = 0 ) as integer
data "fb_WidthDev", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE, 0
'' width( byval fnum as integer, byval width_arg as integer = 0 ) as integer
data "fb_WidthFile", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE, 0



''
'' fb_ErrorThrow cdecl ( byval linenum as integer, _
''						 byval reslabel as any ptr, byval resnxtlabel as any ptr ) as integer
data "fb_ErrorThrow","", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE
''
'' fb_ErrorThrowEx cdecl ( byval errnum as integer, byval linenum as integer, _
''						   byval reslabel as any ptr, byval resnxtlabel as any ptr ) as any ptr
data "fb_ErrorThrowEx","", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE
'' fb_ErrorSetHandler( byval newhandler as any ptr ) as any ptr
data "fb_ErrorSetHandler","", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE

'' fb_ErrorGetNum( ) as integer
data "fb_ErrorGetNum", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' fb_ErrorSetNum( byval errnum as integer ) as void
data "fb_ErrorSetNum", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_ErrorResume( ) as any ptr
data "fb_ErrorResume", "", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 0
'' fb_ErrorResumeNext( ) as any ptr
data "fb_ErrorResumeNext", "", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 0


''
'' fb_GfxPset ( byref target as any, byval x as single, byval y as single, byval color as uinteger, _
''				byval coordType as integer, byval ispreset as integer ) as void
data "fb_GfxPset", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxPoint ( byref target as any, byval x as single, byval y as single ) as integer
data "fb_GfxPoint", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxLine ( byref target as any, byval x1 as single = 0, byval y1 as single = 0, byval x2 as single = 0, byval y2 as single = 0, _
''              byval color as uinteger = DEFAULT_COLOR, byval line_type as integer = LINE_TYPE_LINE, _
''              byval style as uinteger = &hFFFF, byval coordType as integer = COORD_TYPE_AA ) as integer
data "fb_GfxLine", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 9, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxEllipse ( byref target as any, byval x as single, byval y as single, byval radius as single, _
''				   byval color as uinteger = DEFAULT_COLOR, byval aspect as single = 0.0, _
''				   byval iniarc as single = 0.0, byval endarc as single = 6.283185, _
''				   byval FillFlag as integer = 0, byval CoordType as integer = COORD_TYPE_A ) as integer
data "fb_GfxEllipse", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 10, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxPaint ( byref target as any, byval x as single, byval y as single, byval color as uinteger = DEFAULT_COLOR, _
''				 byval border_color as uinteger = DEFAULT_COLOR, pattern as string, _
''				 byval mode as integer = PAINT_TYPE_FILL, byval coord_type as integer = COORD_TYPE_A ) as integer
data "fb_GfxPaint", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 8, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxDraw ( byval target as any, cmd as string )
data "fb_GfxDraw", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fb_GfxView ( byval x1 as integer = -32768, byval y1 as integer = -32768, _
''              byval x1 as integer = -32768, byval y1 as integer = -32768, _
''				byval fillcol as uinteger = DEFAULT_COLOR, byval bordercol as uinteger = DEFAULT_COLOR, _
''              byval screenFlag as integer = 0) as integer
data "fb_GfxView", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 7, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UINT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxWindow (byval x1 as single = 0, byval y1 as single = 0, byval x2 as single = 0, _
'' 				 byval y2 as single = 0, byval screenflag as integer = 0 ) as integer
data "fb_GfxWindow", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' fb_GfxPalette( byval attribute as integer = -1, byval r as integer = -1, _
''				  byval g as integer = -1, byval b as integer = -1 ) as void
data "fb_GfxPalette", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1

'' fb_GfxPaletteUsing ( array as integer ) as void
data "fb_GfxPaletteUsing", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE

'' fb_GfxPaletteGet( byval attribute as integer, byref r as integer, _
''					 byref g as integer, byref b as integer ) as void
data "fb_GfxPaletteGet", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE

'' fb_GfxPaletteGetUsing ( array as integer ) as void
data "fb_GfxPaletteGetUsing", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE

'' fb_GfxPut ( byref target as any, byval x as single, byval y as single, byref array as any, _
''			   byval x1 as integer = &hFFFF0000, byval y1 as integer = &hFFFF0000, _
''			   byval x2 as integer = &hFFFF0000, byval y2 as integer = &hFFFF0000, _
''			   byval coordType as integer, byval mode as integer, byval alpha as integer = -1, _
''			   byval func as function( src as uinteger, dest as uinteger ) as uinteger = 0 ) as integer
data "fb_GfxPut", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 12, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxGet ( byref target as any, byval x1 as single, byval y1 as single, byval x2 as single, byval y2 as single, _
''			   byref array as any, byval coordType as integer, array() as any ) as integer
data "fb_GfxGet", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 8, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYDESC, FALSE

'' fb_GfxScreen ( byval w as integer, byval h as integer = 0, byval depth as integer = 0, _
''                byval fullscreenFlag as integer = 0 ) as integer
data "fb_GfxScreen", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 5, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' fb_GfxScreenRes ( byval w as integer, byval h as integer, byval depth as integer = 8, _
''					 byval num_pages as integer = 1, byval flags as integer = 0, byval refresh_rate as integer = 0 )
data "fb_GfxScreenRes", "", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 6, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,8, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' fb_ProfileBeginCall ( procname as string ) as any ptr
data "fb_ProfileBeginCall", "", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE

'' fb_ProfileEndCall ( call as any ptr ) as void
data "fb_ProfileEndCall", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE

'' fb_EndProfile ( ) as void
data "fb_EndProfile", "", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0

'':::::::::::::::::::::::::::::::::::::::::::::::::::

'' fb_GfxBload ( filename as string, byval dest as any ptr = NULL ) as integer
data "bload", "fb_GfxBload", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, TRUE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, TRUE,NULL

'' fb_GfxBsave ( filename as string, byval src as any ptr, byval length as integer ) as integer
data "bsave", "fb_GfxBsave", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, TRUE, FALSE, _
	 3, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE, 0


'' fb_GfxFlip ( byval frompage as integer = -1, byval topage as integer = -1 ) as void
data "flip", "fb_GfxFlip", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1

'' pcopy ( byval frompage as integer, byval topage as integer ) as void
data "pcopy", "fb_GfxFlip", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

data "screencopy", "fb_GfxFlip", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1

'' fb_GfxCursor ( number as integer) as single
data "pointcoord", "fb_GfxCursor", _
	 FB_SYMBTYPE_SINGLE,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxPMap ( byval Coord as single, byval num as integer ) as single
data "pmap", "fb_GfxPMap", _
	 FB_SYMBTYPE_SINGLE,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_Out( byval port as ushort, byval data as ubyte ) as void
data "out", "fb_Out", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, TRUE, FALSE, _
	 2, _
	 FB_SYMBTYPE_USHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_UBYTE,FB_ARGMODE_BYVAL, FALSE

'' fb_In( byval port as ushort ) as integer
data "inp", "fb_In", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, TRUE, FALSE, _
	 1, _
	 FB_SYMBTYPE_USHORT,FB_ARGMODE_BYVAL, FALSE

'' fb_Wait ( byval port as ushort, byval and_mask as integer, byval xor_mask as integer = 0 )
data "wait", "fb_Wait", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, TRUE, FALSE, _
	 3, _
	 FB_SYMBTYPE_USHORT,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' fb_GfxWaitVSync ( void ) as integer
data "screensync", "fb_GfxWaitVSync", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, TRUE, FALSE, _
	 0

'' fb_GfxSetPage ( byval work_page as integer = -1, byval visible_page as integer = -1 ) as void
data "screenset", "fb_GfxSetPage", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1

'' fb_GfxLock ( ) as void
data "screenlock", "fb_GfxLock", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 0

'' fb_GfxUnlock ( ) as void
data "screenunlock", "fb_GfxUnlock", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1

'' fb_GfxScreenPtr ( ) as any ptr
data "screenptr", "fb_GfxScreenPtr", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 0

'' fb_GfxSetWindowTitle ( title as string ) as void
data "windowtitle", "fb_GfxSetWindowTitle", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fb_Multikey ( byval scancode as integer ) as integer
data "multikey", "fb_Multikey", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hMultinput_cb, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_GfxGetMouse ( byref x as integer, byref y as integer, byref z as integer, byref buttons as integer ) as integer
data "getmouse", "fb_GetMouse", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hMultinput_cb, TRUE, FALSE, _
	 4, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0

'' fb_GfxSetMouse ( byval x as integer = -1, byval y as integer = -1, byval cursor as integer = -1 ) as integer
data "setmouse", "fb_SetMouse", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hMultinput_cb, TRUE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1

'' fb_GfxGetJoystick ( byval id as integer, byref buttons as integer = 0, _
''					   byref a1 as single = 0, byref a2 as single = 0, byref a3 as single = 0, _
''					   byref a4 as single = 0, byref a5 as single = 0, byref a6 as single = 0 ) as integer
data "getjoystick", "fb_GfxGetJoystick", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, TRUE, FALSE, _
	 8, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYREF, TRUE,0

'' fb_GfxScreenInfo ( byref w as integer, byref h as integer, byref depth as integer, _
''					  byref bpp as integer, byref pitch as integer, byref driver_name as string ) as void
data "screeninfo", "fb_GfxScreenInfo", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 7, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYREF, TRUE,0, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, TRUE,""

'' fb_GfxScreenList ( byval depth as integer ) as integer
data "screenlist", "fb_GfxScreenList", _
FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, TRUE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' fb_GfxImageCreate ( byval width as integer, byval height as integer ) as any ptr
data "imagecreate", "fb_GfxImageCreate", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,&hFEFF00FF

'' fb_GfxImageDestroy ( byval image as any ptr ) as void
data "imagedestroy", "fb_GfxImageDestroy", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hGfxlib_cb, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE


'':::::::::::::::::::::::::::::::::::::::::::::::::::

'' fb_FileFree ( ) as integer
data "freefile", "fb_FileFree", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' fb_FileEof ( byval filenum as integer ) as integer
data "eof", "fb_FileEof", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_FileKill ( s as string ) as integer
data "kill", "fb_FileKill", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fb_CVD ( str as string ) as double
data "cvd","fb_CVD", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
data "cvs","fb_CVS", _
	 FB_SYMBTYPE_SINGLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_CVI ( str as string ) as integer
data "cvi","fb_CVI", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
data "cvl","fb_CVI", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_CVSHORT ( str as string ) as short
data "cvshort","fb_CVSHORT", _
	 FB_SYMBTYPE_SHORT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_CVLONGINT ( str as string ) as longint
data "cvlongint","fb_CVLONGINT", _
	 FB_SYMBTYPE_LONGINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fb_HEX_b ( byval number as byte ) as string
data "hex","fb_HEX_b", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYVAL, FALSE
'' fb_HEX_s ( byval number as short ) as string
data "hex","fb_HEX_s", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYVAL, FALSE
'' fb_HEX_i ( byval number as integer ) as string
data "hex","fb_HEX_i", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_HEX_l ( byval number as longint ) as string
data "hex","fb_HEX_l", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE

'' fb_OCT_b ( byval number as byte ) as string
data "oct","fb_OCT_b", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYVAL, FALSE
'' fb_OCT_s ( byval number as short ) as string
data "oct","fb_OCT_s", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYVAL, FALSE
'' fb_OCT_i ( byval number as integer ) as string
data "oct","fb_OCT_i", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_OCT_l ( byval number as longint ) as string
data "oct","fb_OCT_l", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE

'' fb_BIN_b ( byval number as byte ) as string
data "bin","fb_BIN_b", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_BYTE,FB_ARGMODE_BYVAL, FALSE
'' fb_BIN_s ( byval number as short ) as string
data "bin","fb_BIN_s", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYVAL, FALSE
'' fb_BIN_i ( byval number as integer ) as string
data "bin","fb_BIN_i", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_BIN_l ( byval number as longint ) as string
data "bin","fb_BIN_l", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, TRUE, _
	 1, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE

'' fb_MKD ( byval number as double ) as string
data "mkd","fb_MKD", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' fb_MKS ( byval number as single ) as string
data "mks","fb_MKS", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SINGLE,FB_ARGMODE_BYVAL, FALSE
'' fb_MKI ( byval number as integer ) as string
data "mki","fb_MKI", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
data "mkl","fb_MKI", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_MKSHORT ( byval number as short ) as string
data "mkshort","fb_MKSHORT", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_SHORT,FB_ARGMODE_BYVAL, FALSE
'' fb_MKLONGINT ( byval number as longint ) as string
data "mklongint","fb_MKLONGINT", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_LONGINT,FB_ARGMODE_BYVAL, FALSE

'' fb_LEFT ( str as string, byval n as integer ) as string
data "left","fb_LEFT", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' fb_RIGHT ( str as string, byval n as integer ) as string
data "right","fb_RIGHT", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_SPACE ( byval n as integer ) as string
data "space","fb_SPACE", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' fb_TRIM ( str as string ) as string
data "trim","fb_TRIM", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_LCASE ( str as string ) as string
data "lcase","fb_LCASE", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_UCASE ( str as string ) as string
data "ucase","fb_UCASE", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fb_VAL ( str as string ) as double
data "val","fb_VAL", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_VALINT ( str as string ) as integer
data "valint","fb_VALINT", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_VALUINT ( str as string ) as uinteger
data "valuint","fb_VALUINT", _
	 FB_SYMBTYPE_UINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_VALLNG ( str as string ) as longint
data "vallng","fb_VALLNG", _
	 FB_SYMBTYPE_LONGINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' fb_VALULNG ( str as string ) as ulongint
data "valulng","fb_VALULNG", _
	 FB_SYMBTYPE_ULONGINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' exp CDECL ( byval rad as double ) as double
data "exp","exp", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE

'' command ( byval argc as integer = -1 ) as string
data "command","fb_Command", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1
'' curdir ( ) as string
data "curdir","fb_CurDir", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' exepath ( ) as string
data "exepath","fb_ExePath", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0

'' randomize ( byval seed as double = -1.0 ) as void
data "randomize","fb_Randomize", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, TRUE, -1.0
'' rnd ( byval n as integer ) as double
data "rnd","fb_Rnd", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1

'' timer ( ) as double
data "timer","fb_Timer", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' time ( ) as string
data "time","fb_Time", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' date ( ) as string
data "date","fb_Date", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' dateserial ( byval year as integer, byval month as integer, byval day as integer ) as integer
data "DateSerial","fb_DateSerial", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     3, _
     FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
     FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
     FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' datevalue ( s as string ) as integer
data "DateValue","fb_DateValue", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, TRUE, FALSE, _
     1, _
     FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' year ( byval serial as double ) as integer
data "Year","fb_Year", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     1, _
     FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' month ( byval serial as double ) as integer
data "Month","fb_Month", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     1, _
     FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' day ( byval serial as double ) as integer
data "Day","fb_Day", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     1, _
     FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' weekday ( byval serial as double ) as integer
data "Weekday","fb_Weekday", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     1, _
     FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' timeserial ( byval hour as integer, byval minute as integer, byval second as integer ) as integer
data "TimeSerial","fb_TimeSerial", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     3, _
     FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
     FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
     FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' timevalue ( s as string ) as double
data "TimeValue","fb_TimeValue", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, TRUE, FALSE, _
     1, _
     FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' hour ( byval serial as double ) as integer
data "Hour","fb_Hour", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     1, _
     FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' minute ( byval serial as double ) as integer
data "Minute","fb_Minute", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     1, _
     FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' second ( byval serial as double ) as integer
data "Second","fb_Second", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     1, _
     FB_SYMBTYPE_DOUBLE,FB_ARGMODE_BYVAL, FALSE
'' now ( ) as double
data "Now","fb_Now", _
	 FB_SYMBTYPE_DOUBLE,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
     0

'' pos( ) as integer
data "pos", "fb_GetX", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' csrlin( ) as integer
data "csrlin", "fb_GetY", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' cls( byval n as integer = 1 ) as void
data "cls", "fb_Cls", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,&hFFFF0000
'' locate( byval row as integer = 0, byval col as integer = 0, byval cursor as integer = -1 ) as integer
data "locate", "fb_Locate", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1
'' color( byval fc as integer = -1, byval bc as integer = -1 ) as integer
data "color", "fb_Color", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,-1
'' inkey ( ) as string
data "inkey","fb_Inkey", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' getkey ( ) as integer
data "getkey","fb_Getkey", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0

'' shell ( byval cmm as string = "" ) as integer
data "shell","fb_Shell", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, TRUE,""

'' system ( ) as void
data "system","fb_End", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0
'' stop ( ) as void
data "stop","fb_End", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' run ( exename as string ) as integer
data "run","fb_Run", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' chain ( exename as string ) as integer
data "chain","fb_Chain", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' exec ( exename as string, arguments as string ) as integer
data "exec","fb_Exec", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' environ ( varname as string ) as string
data "environ","fb_GetEnviron", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' setenviron ( varname as string ) as integer
data "setenviron","fb_SetEnviron", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' sleep ( byval msecs as integer ) as void
data "sleep","fb_Sleep", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE, -1

'' reset ( ) as void
data "reset","fb_FileReset", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' lof ( byval filenum as integer ) as uinteger
data "lof","fb_FileSize", _
	 FB_SYMBTYPE_UINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' loc ( byval filenum as integer ) as uinteger
data "loc","fb_FileLocation", _
	 FB_SYMBTYPE_UINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' lpos( int ) as integer
data "lpos", "fb_LPos", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' rset ( dst as string, src as string ) as void
data "rset","fb_StrRset", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fre ( ) as uinteger
data "fre","fb_GetMemAvail", _
	 FB_SYMBTYPE_UINT,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0

'' allocate ( byval bytes as integer ) as any ptr
data "allocate","malloc", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' callocate ( byval bytes as integer ) as any ptr
data "callocate","calloc", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,1
'' reallocate ( byval p as any ptr, byval bytes as integer ) as any ptr
data "reallocate","realloc", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' deallocate ( byval p as any ptr ) as void
data "deallocate","free", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE
'' clear ( dst as any, byval value as integer = 0, byval bytes as integer ) as void
data "clear","memset", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_CDECL, _
	 NULL, FALSE, FALSE, _
	 3, _
	 FB_SYMBTYPE_VOID,FB_ARGMODE_BYREF, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' dir ( mask as string, byval v as integer = &h33 ) as string
data "dir","fb_Dir", _
	 FB_SYMBTYPE_STRING,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, TRUE,"", _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,&h33

'' settime ( time as string ) as integer
data "settime","fb_SetTime", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' setdate ( date as string ) as integer
data "setdate","fb_SetDate", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' threadcreate ( byval proc as sub( byval param as integer ), byval param as integer = 0) as integer
data "threadcreate", "fb_ThreadCreate", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 @hMultithread_cb, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, TRUE,0
'' threadwait ( byval id as integer ) as void
data "threadwait","fb_ThreadWait", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 @hMultithread_cb, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' mutexcreate ( ) as integer
data "mutexcreate","fb_MutexCreate", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' mutexdestroy ( byval id as integer ) as void
data "mutexdestroy","fb_MutexDestroy", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' mutexlock ( byval id as integer ) as void
data "mutexlock","fb_MutexLock", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' mutexunlock ( byval id as integer ) as void
data "mutexunlock","fb_MutexUnlock", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' condcreate ( ) as integer
data "condcreate","fb_CondCreate", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0
'' conddestroy ( byval id as integer ) as void
data "conddestroy","fb_CondDestroy", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' condsignal ( byval id as integer ) as void
data "condsignal","fb_CondSignal", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' condbroadcast ( byval id as integer ) as void
data "condbroadcast","fb_CondBroadcast", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE
'' condwait ( byval id as integer ) as void
data "condwait","fb_CondWait", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'' dylibload ( filename as string ) as integer
data "dylibload","fb_DylibLoad", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' dylibsymbol ( byval library as integer, symbol as string) as any ptr
data "dylibsymbol","fb_DylibSymbol", _
	 FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 2, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' dylibfree ( byval library as integer ) as void
data "dylibfree","fb_DylibFree", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE

'':::::::::::::::::::::::::::::::::::::::::::::::::::

'' beep ( ) as void
data "beep","fb_Beep", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0

'' mkdir ( byref path as string ) as integer
data "mkdir","fb_MkDir", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' rmdir ( byref path as string ) as integer
data "rmdir","fb_RmDir", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE
'' chdir ( byref path as string ) as integer
data "chdir","fb_ChDir", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 1, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYREF, FALSE

'' fb_Assert ( byval fname as string, byval linenum as integer, byval funcname as string, _
''			   byval expression as string ) as void
data "fb_Assert","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE

'' fb_AssertWarn ( byval fname as string, byval linenum as integer, byval funcname as string, _
''			       byval expression as string ) as void
data "fb_AssertWarn","", _
	 FB_SYMBTYPE_VOID,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 4, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_INTEGER,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE, _
	 FB_SYMBTYPE_STRING,FB_ARGMODE_BYVAL, FALSE

'' ERL ( ) as integer
data "erl", "fb_ErrorGetLineNum", _
	 FB_SYMBTYPE_INTEGER,FB_FUNCMODE_STDCALL, _
	 NULL, FALSE, FALSE, _
	 0

'' EOL
data ""

'':::::::::::::::::::::::::::::::::::::::::::::::::::
'' MACROS
'':::::::::::::::::::::::::::::::::::::::::::::::::::

'' name, debugonly?, args, arg[0] to arg[n] names, macro text
imacrodata:
''#define RGB(r,g,b) ((cuint(r) shl 16) or (cuint(g) shl 8) or cuint(b))
data "RGB", _
	 FALSE, _
	 3, "R", "G", "B", _
	 "((cuint(!R!) shl 16) or (cuint(!G!) shl 8) or cuint(!B!))"
''#define RGBA(r,g,b,a) ((cuint(r) shl 16) or (cuint(g) shl 8) or cuint(b) or (cuint(a) shl 24))
data "RGBA", FALSE, _
	 4, "R", "G", "B", "A", _
	 "((cuint(!R!) shl 16) or (cuint(!G!) shl 8) or cuint(!B!) or (cuint(!A!) shl 24))"

''#define va_arg(a,t) peek( t, a )
data "VA_ARG", _
	 FALSE, _
	 2, "A", "T", _
	 "peek( !T!, !A! )"
''#define va_next(a,t) (a + len( t ))
data "VA_NEXT", _
	 FALSE, _
	 2, "A", "T", _
	 "(cptr( !T! ptr, !A! ) + 1)"

''#define ASSERT(e) if not (e) then fb_Assert(__FILE__, __LINE__, __FUNCTION__, #e)
data "ASSERT", _
	 TRUE, _
	 1, "E", _
	 "if not (!E!) then fb_Assert(__FILE__, __LINE__, __FUNCTION__, \"!E!\")"
''#define ASSERTWARN(e) if not (e) then fb_AssertWarn(__FILE__, __LINE__, __FUNCTION__, #e)
data "ASSERTWARN", _
	 TRUE, _
	 1, "E", _
	 "if not (!E!) then fb_AssertWarn(__FILE__, __LINE__, __FUNCTION__, \"!E!\")"

''#define OFFSETOF(type_,field_) cint( @cptr( type_ ptr, 0 )->field_ )
data "OFFSETOF", _
	 FALSE, _
	 2, "T", "F", _
	 "cint( @cptr( !T! ptr, 0 )->!F! )"

data "__FB_MIN_VERSION__", _
     FALSE, _
     3, "MAJOR", "MINOR", "PATCH_LEVEL", _
	 "((__FB_VER_MAJOR__ > (!MAJOR!)) or ((__FB_VER_MAJOR__ = (!MAJOR!)) and ((__FB_VER_MINOR__ > (!MINOR!)) or (__FB_VER_MINOR__ = (!MINOR!) and __FB_VER_PATCH__ >= (!PATCH_LEVEL!)))))"

'#ifndef FB__BIGENDIAN
''#define LOWORD(x) (cuint(x) and &h0000FFFF)
data "LOWORD", _
	 FALSE, _
	 1, "X", _
	 "(cuint(!X!) and &h0000FFFF)"
''#define HIWORD(x) (cyint(x) shr 16)
data "HIWORD", _
	 FALSE, _
	 1, "X", _
	 "(cuint(!X!) shr 16)"
''#define LOBYTE(x) (cuint(x) and &h000000FF)
data "LOBYTE", _
	 FALSE, _
	 1, "X", _
	 "(cuint(!X!) and &h000000FF)"
''#define HIBYTE(x) ((cuint(x) and &h0000FF00) shr 8)
data "HIBYTE", _
	 FALSE, _
	 1, "X", _
	 "((cuint(!X!) and &h0000FF00) shr 8)"
''#define BIT(x,y) (((x) and (1 shl (y))) > 0)
data "BIT", _
	 FALSE, _
	 2, "X", "Y", _
	 "(((!X!) and (1 shl (!Y!))) <> 0)"
''#define BITSET(x,y) ((x) or (1 shl (y)))
data "BITSET", _
	 FALSE, _
	 2, "X", "Y", _
	 "((!X!) or (1 shl (!Y!)))"
''#define BITRESET(x,y) ((x) and not (y))
data "BITRESET", _
	 FALSE, _
	 2, "X", "Y", _
	 "((!X!) and not (1 shl (!Y!)))"
'#endif

'' EOL
data ""


'':::::::::::::::::::::::::::::::::::::::::::::::::::
'' implementation
'':::::::::::::::::::::::::::::::::::::::::::::::::::

#define cntptr(typ,t,cnt)						_
	t = typ                                     : _
	cnt = 0                                     : _
	do while( t >= IR_DATATYPE_POINTER )		: _
		t -= IR_DATATYPE_POINTER				: _
		cnt += 1								: _
	loop


'':::::
private sub hAddIntrinsicProcs
	dim as integer i, typ
	dim as string pname, aname, optstr
	dim as integer p, ptype, pmode, pargs, palloctype
	dim as integer a, atype, alen, amode, optional, ptrcnt, errorcheck, overloaded
	dim as FBSYMBOL ptr proc, argtail
	dim as FBRTLCALLBACK pcallback
	dim as FBVALUE optval

	''
	redim ifuncTB( 0 to FB_RTL_MAXFUNCTIONS-1 ) as FBSYMBOL ptr

	restore ifuncdata
	i = 0
	do
		read pname
		if( len( pname ) = 0 ) then
			exit do
		end if

		read aname
		read ptype, pmode
		read pcallback, errorcheck, overloaded
		read pargs

		argtail = NULL
		for a = 0 to pargs-1
			read atype, amode, optional

			if( optional ) then
				select case as const atype
				case IR_DATATYPE_STRING
					read optstr
					optval.valuestr = hAllocStringConst( optstr, 0 )
				case IR_DATATYPE_LONGINT, IR_DATATYPE_ULONGINT
					read optval.value64
				case IR_DATATYPE_SINGLE, IR_DATATYPE_DOUBLE
					read optval.valuef
				case else
					read optval.valuei
				end select
			end if

			if( atype <> INVALID ) then
				alen = symbCalcArgLen( atype, NULL, amode )
			else
				alen = FB_POINTERSIZE
			end if

			cntptr( atype, typ, ptrcnt )

			argtail = symbAddArg( "", argtail, atype, NULL, ptrcnt, _
								  alen, amode, INVALID, optional, @optval )
		next a

		''
		if( overloaded ) then
			palloctype = FB_ALLOCTYPE_OVERLOADED
		else
			palloctype = 0
		end if

		''
		cntptr( ptype, typ, ptrcnt )

		proc = symbAddPrototype( pname, aname, "fb", ptype, NULL, ptrcnt, _
								 palloctype, pmode, pargs, argtail, TRUE )

		ifuncTB(i) = proc

		''
		if( proc <> NULL ) then
			symbSetProcIsRTL( proc, TRUE )
			symbSetProcCallback( proc, pcallback )
			symbSetProcErrorCheck( proc, errorcheck )
		end if

		i += 1
	loop

end sub

'':::::
private sub hAddIntrinsicMacros
	dim as integer i, args, dbgonly
	dim as FBDEFARG ptr arghead, lastarg, arg
	dim as string oldname, newname, mname, mtext, aname

	restore imacrodata
	do
		read mname
		if( len( mname ) = 0 ) then
			exit do
		end if

		read dbgonly

		arghead = NULL
		lastarg = NULL

		'' for each argument, add it
		read args
		for i = 0 to args-1
			read aname

			lastarg = symbAddDefineArg( lastarg, aname )

			if( arghead = NULL ) then
				arghead = lastarg
			end if
		next i

		read mtext

    	'' only if debugging?
    	if( dbgonly and not env.clopt.debug ) then
    		mtext = ""

        else
    		'' replace the pattern by the one that Lex expects
    		arg = arghead
    		do while( arg <> NULL )
        		oldname = "!"
        		oldname += arg->name
        		oldname += "!"

        		newname = "\27"
        		newname += hex( arg->id )
        		newname += "\27"

        		hReplace( mtext, oldname, newname )

        		arg = arg->next
        	loop
        end if

        symbAddDefine( mname, mtext, len( mtext ), args, arghead )

	loop

end sub

'':::::
sub rtlInit static

	''
	fbAddDefaultLibs( )

	''
	hAddIntrinsicProcs( )

	''
	hAddIntrinsicMacros( )

	''
	ctx.datainited	= FALSE
	ctx.lastlabel	= NULL
    ctx.labelcnt 	= 0

end sub

'':::::
sub rtlEnd

	'' procs will be deleted when symbEnd is called

	'' ditto with macros

	erase ifuncTB

end sub

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' strings
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
#define FIXSTRGETLEN(e) symbGetLen( astGetSymbolOrElm( e ) )

#define ZSTRGETLEN(e) iif( astIsPTR( e ), 0, symbGetLen( astGetSymbolOrElm( e ) ) )

#define STRGETLEN(e,t,l)												_
	select case as const t                                              :_
	case IR_DATATYPE_BYTE, IR_DATATYPE_UBYTE       						:_
		l = 0                                                           :_
	case IR_DATATYPE_FIXSTR                                             :_
		l = FIXSTRGETLEN( e )                         					:_
	case IR_DATATYPE_CHAR                                               :_
		l = ZSTRGETLEN( e )                            					:_
	case else                                                           :_
		l = -1															:_
	end select

'':::::
function rtlStrCompare ( byval str1 as ASTNODE ptr, _
						 byval sdtype1 as integer, _
					     byval str2 as ASTNODE ptr, _
					     byval sdtype2 as integer ) as ASTNODE ptr static
    dim lgt as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim str1len as integer, str2len as integer
    dim s as integer

	function = NULL

	''
	f = ifuncTB(FB_RTL_STRCOMPARE)
    proc = astNewFUNCT( f )

   	''
   	STRGETLEN( str1, sdtype1, str1len )

	STRGETLEN( str2, sdtype2, str2len )

    ''
    if( astNewPARAM( proc, str1, sdtype1 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, astNewCONSTi( str1len, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, str2, sdtype2 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, astNewCONSTi( str2len, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrConcat( byval str1 as ASTNODE ptr, _
					   byval sdtype1 as integer, _
					   byval str2 as ASTNODE ptr, _
					   byval sdtype2 as integer ) as ASTNODE ptr static
    dim lgt as integer, tstr as FBSYMBOL ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim str1len as integer, str2len as integer
    dim s as integer

	function = NULL

	''
	f = ifuncTB(FB_RTL_STRCONCAT)
    proc = astNewFUNCT( f )

    '' dst as string
    tstr = symbAddTempVar( FB_SYMBTYPE_STRING )
    if( astNewPARAM( proc, astNewVAR( tstr, NULL, 0, IR_DATATYPE_STRING ), IR_DATATYPE_STRING ) = NULL ) then
    	exit function
    end if

   	''
   	STRGETLEN( str1, sdtype1, str1len )

	STRGETLEN( str2, sdtype2, str2len )

    ''
    if( astNewPARAM( proc, str1, sdtype1 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, astNewCONSTi( str1len, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, str2, sdtype2 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, astNewCONSTi( str2len, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrConcatAssign( byval dst as ASTNODE ptr, _
							 byval src as ASTNODE ptr ) as ASTNODE ptr static
    dim lgt as integer, ddtype as integer, sdtype as integer
    dim f as FBSYMBOL ptr, proc as ASTNODE ptr
    dim s as integer

	function = NULL

	''
	f = ifuncTB(FB_RTL_STRCONCATASSIGN)
    proc = astNewFUNCT( f )

    ''
   	ddtype = astGetDataType( dst )

	'' dst as any
	if( astNewPARAM( proc, dst, ddtype ) = NULL ) then
    	exit function
    end if

	'' byval dstlen as integer
	STRGETLEN( dst, ddtype, lgt )

	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

   	''
   	sdtype = astGetDataType( src )

	'' src as any
	if( astNewPARAM( proc, src, sdtype ) = NULL ) then
    	exit function
    end if

	'' byval srclen as integer
	STRGETLEN( src, sdtype, lgt )

	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' byval fillrem as integer
	if( astNewPARAM( proc, astNewCONSTi( ddtype = IR_DATATYPE_FIXSTR, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	''
	function = proc

end function

'':::::
function rtlStrAssign( byval dst as ASTNODE ptr, _
					   byval src as ASTNODE ptr ) as ASTNODE ptr static
    dim lgt as integer, ddtype as integer, sdtype as integer
    dim f as FBSYMBOL ptr, proc as ASTNODE ptr
    dim s as integer

	function = NULL

	''
	f = ifuncTB(FB_RTL_STRASSIGN)
    proc =  astNewFUNCT( f )

    ''
   	ddtype = astGetDataType( dst )

	'' dst as any
	if( astNewPARAM( proc, dst, ddtype ) = NULL ) then
    	exit function
    end if

	'' byval dstlen as integer
	STRGETLEN( dst, ddtype, lgt )

	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

   	''
   	sdtype = astGetDataType( src )

	'' src as any
	if( astNewPARAM( proc, src, sdtype ) = NULL ) then
    	exit function
    end if

	'' byval srclen as integer
	STRGETLEN( src, sdtype, lgt )

	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' byval fillrem as integer
	if( astNewPARAM( proc, astNewCONSTi( ddtype = IR_DATATYPE_FIXSTR, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	''
	function = proc

end function

'':::::
function rtlStrDelete( byval strg as ASTNODE ptr ) as ASTNODE ptr static
    dim lgt as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_STRDELETE)
    proc = astNewFUNCT( f )

    '' str as ANY
    if( astNewPARAM( proc, strg, IR_DATATYPE_STRING ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrAllocTmpResult( byval strg as ASTNODE ptr ) as ASTNODE ptr static
    dim lgt as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_STRALLOCTMPRES)
    proc = astNewFUNCT( f, NULL, TRUE )

    '' src as string
    if( astNewPARAM( proc, strg, IR_DATATYPE_STRING ) = NULL ) then
    	exit function
    end if

	function = proc

end function

'':::::
function rtlStrAllocTmpDesc	( byval strg as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim s as integer, lgt as integer, dtype as integer

    function = NULL

	''
   	dtype = astGetDataType( strg )

	select case dtype
	case IR_DATATYPE_STRING
		f = ifuncTB(FB_RTL_STRALLOCTMPDESCV)
    	proc = astNewFUNCT( f )

    	'' str as string
    	if( astNewPARAM( proc, strg ) = NULL ) then
    		exit function
    	end if

	case IR_DATATYPE_CHAR
		f = ifuncTB(FB_RTL_STRALLOCTMPDESCZ)
    	proc = astNewFUNCT( f )

    	'' byval str as string
    	if( astNewPARAM( proc, strg ) = NULL ) then
    		exit function
    	end if

	case IR_DATATYPE_FIXSTR
		f = ifuncTB(FB_RTL_STRALLOCTMPDESCF)
    	proc = astNewFUNCT( f )

    	'' str as any
    	if( astNewPARAM( proc, strg ) = NULL ) then
    		exit function
    	end if

    	'' byval strlen as integer
		STRGETLEN( strg, dtype, lgt )

		if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if

    end select

	''
	function = proc

end function

'':::::
function rtlToStr( byval expr as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

    ''
	select case astGetDataClass( expr )
	case IR_DATACLASS_INTEGER

		select case as const astGetDataType( expr )
		case IR_DATATYPE_LONGINT
			f = ifuncTB(FB_RTL_LONGINT2STR)
		case IR_DATATYPE_ULONGINT
			f = ifuncTB(FB_RTL_ULONGINT2STR)
		case IR_DATATYPE_BYTE, IR_DATATYPE_SHORT, IR_DATATYPE_INTEGER
			f = ifuncTB(FB_RTL_INT2STR)
		case IR_DATATYPE_UBYTE, IR_DATATYPE_USHORT, IR_DATATYPE_UINT
			f = ifuncTB(FB_RTL_UINT2STR)
		case else
			f = ifuncTB(FB_RTL_UINT2STR)
		end select

	case IR_DATACLASS_FPOINT
		if( astGetDataType( expr ) = IR_DATATYPE_SINGLE ) then
			f = ifuncTB(FB_RTL_FLT2STR)
		else
			f = ifuncTB(FB_RTL_DBL2STR)
		end if
	case else
		return NULL
	end select

	''
    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, expr ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrMid( byval expr1 as ASTNODE ptr, _
					byval expr2 as ASTNODE ptr, _
					byval expr3 as ASTNODE ptr ) as ASTNODE ptr static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	''
	f = ifuncTB(FB_RTL_STRMID)
    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, expr1 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, expr2 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, expr3 ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrAssignMid( byval expr1 as ASTNODE ptr, _
						  byval expr2 as ASTNODE ptr, _
						  byval expr3 as ASTNODE ptr, _
						  byval expr4 as ASTNODE ptr ) as ASTNODE ptr static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	''
	f = ifuncTB(FB_RTL_STRASSIGNMID)
    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, expr1 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, expr2 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, expr3 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, expr4 ) = NULL ) then
    	exit function
    end if

    ''
    astAdd( proc )

    function = proc

end function

'':::::
function rtlStrLSet( byval dstexpr as ASTNODE ptr, _
					 byval srcexpr as ASTNODE ptr ) as integer static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = FALSE

	''
	f = ifuncTB(FB_RTL_STRLSET)
    proc = astNewFUNCT( f )

    '' dst as string
    if( astNewPARAM( proc, dstexpr ) = NULL ) then
    	exit function
    end if

    '' src as string
    if( astNewPARAM( proc, srcexpr ) = NULL ) then
    	exit function
    end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlStrFill( byval expr1 as ASTNODE ptr, _
					 byval expr2 as ASTNODE ptr ) as ASTNODE ptr static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	select case astGetDataClass( expr2 )
	case IR_DATACLASS_INTEGER, IR_DATACLASS_FPOINT
		f = ifuncTB(FB_RTL_STRFILL1)
	case else
		f = ifuncTB(FB_RTL_STRFILL2)
	end select

    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, expr1 ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, expr2 ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrAsc( byval expr as ASTNODE ptr, _
					byval posexpr as ASTNODE ptr ) as ASTNODE ptr static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	f = ifuncTB(FB_RTL_STRASC)
    proc = astNewFUNCT( f )

    '' src as string
    if( astNewPARAM( proc, expr ) = NULL ) then
    	exit function
    end if

    '' byval pos as integer
    if( posexpr = NULL ) then
    	posexpr = astNewCONSTi( 1, IR_DATATYPE_INTEGER )
    end if

    if( astNewPARAM( proc, posexpr ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrChr( byval args as integer, _
					exprtb() as ASTNODE ptr ) as ASTNODE ptr static
	dim i as integer, expr as ASTNODE ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	f = ifuncTB(FB_RTL_STRCHR)
    proc = astNewFUNCT( f )

    '' byval args as integer
    if( astNewPARAM( proc, astNewCONSTi( args, IR_DATATYPE_INTEGER ) ) = NULL ) then
    	exit function
    end if

    '' ...
    for i = 0 to args-1
    	expr = exprtb(i)

    	'' check if non-numeric
    	if( astGetDataClass( expr ) >= IR_DATACLASS_STRING ) then
    		hReportErrorEx( FB_ERRMSG_PARAMTYPEMISMATCHAT, "at parameter: " + str$( i+1 ) )
    		exit function
    	end if

    	'' convert to int
    	if( astGetDataType( expr ) <> IR_DATATYPE_INTEGER ) then
    		expr = astNewCONV( INVALID, IR_DATATYPE_INTEGER, NULL, expr )
    	end if

    	if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if
    next i

    function = proc

end function

'':::::
function rtlStrInstr( byval nd_start as ASTNODE ptr, _
					  byval nd_text as ASTNODE ptr, _
					  byval nd_pattern as ASTNODE ptr, _
                      byval search_any as integer ) as ASTNODE ptr static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	''
    if( search_any ) then
		f = ifuncTB(FB_RTL_STRINSTRANY)
    else
		f = ifuncTB(FB_RTL_STRINSTR)
    end if
    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, nd_start ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, nd_text ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, nd_pattern ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlStrRTrim( byval nd_text as ASTNODE ptr, _
					  byval nd_pattern as ASTNODE ptr, _
                      byval is_any as integer ) as ASTNODE ptr static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	''
    if( is_any ) then
		f = ifuncTB(FB_RTL_STRRTRIMANY)
    elseif( nd_pattern<>NULL ) then
		f = ifuncTB(FB_RTL_STRRTRIMEX)
    else
		f = ifuncTB(FB_RTL_STRRTRIM)
    end if
    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, nd_text ) = NULL ) then
    	exit function
    end if

    if( nd_pattern<>NULL or is_any ) then
        if( astNewPARAM( proc, nd_pattern ) = NULL ) then
            exit function
        end if
    end if

    function = proc

end function

'':::::
function rtlStrLTrim( byval nd_text as ASTNODE ptr, _
					  byval nd_pattern as ASTNODE ptr, _
                      byval is_any as integer ) as ASTNODE ptr static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	''
    if( is_any ) then
		f = ifuncTB(FB_RTL_STRLTRIMANY)
    elseif( nd_pattern<>NULL ) then
		f = ifuncTB(FB_RTL_STRLTRIMEX)
    else
		f = ifuncTB(FB_RTL_STRLTRIM)
    end if
    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, nd_text ) = NULL ) then
    	exit function
    end if

    if( nd_pattern<>NULL or is_any ) then
        if( astNewPARAM( proc, nd_pattern ) = NULL ) then
            exit function
        end if
    end if

    function = proc

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' arrays
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function rtlArrayRedim( byval s as FBSYMBOL ptr, _
						byval elementlen as integer, _
						byval dimensions as integer, _
				        exprTB() as ASTNODE ptr, _
				        byval dopreserve as integer ) as integer static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dtype as integer, expr as ASTNODE ptr, isvarlen as integer
    dim i as integer
    dim reslabel as FBSYMBOL ptr

    function = FALSE

	''
	if( not dopreserve ) then
		f = ifuncTB(FB_RTL_ARRAYREDIM)
	else
		f = ifuncTB(FB_RTL_ARRAYREDIMPRESV)
	end if
    proc = astNewFUNCT( f )

    '' array() as ANY
    dtype =  symbGetType( s )
	expr = astNewVAR( s, NULL, 0, dtype )
    if( astNewPARAM( proc, expr, dtype ) = NULL ) then
    	exit function
    end if

	'' byval element_len as integer
	expr = astNewCONSTi( elementlen, IR_DATATYPE_INTEGER )
	if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' byval isvarlen as integer
	isvarlen = (dtype = IR_DATATYPE_STRING)
	if( astNewPARAM( proc, astNewCONSTi( isvarlen, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' byval dimensions as integer
	if( astNewPARAM( proc, astNewCONSTi( dimensions, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' ...
	for i = 0 to dimensions-1

		'' lbound
		expr = exprTB(i, 0)

    	'' convert to int
    	if( astGetDataType( expr ) <> IR_DATATYPE_INTEGER ) then
    		expr = astNewCONV( INVALID, IR_DATATYPE_INTEGER, NULL, expr )
    	end if

		if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if

		'' ubound
		expr = exprTB(i, 1)

    	'' convert to int
    	if( astGetDataType( expr ) <> IR_DATATYPE_INTEGER ) then
    		expr = astNewCONV( INVALID, IR_DATATYPE_INTEGER, NULL, expr )
    	end if

		if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if
	next i

    ''
    if( env.clopt.resumeerr ) then
    	reslabel = symbAddLabel( "" )
    	astAdd( astNewLABEL( reslabel ) )
    else
    	reslabel = NULL
    end if

    ''
	function = rtlErrorCheck( proc, reslabel, lexLineNum( ) )

end function

'':::::
function rtlArrayErase( byval arrayexpr as ASTNODE ptr ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim isvarlen as integer

	function = FALSE

	''
	f = ifuncTB(FB_RTL_ARRAYERASE)
    proc = astNewFUNCT( f )

    '' array() as ANY
    if( astNewPARAM( proc, arrayexpr, astGetDataType( arrayexpr ) ) = NULL ) then
    	exit function
    end if

	'' byval isvarlen as integer
	isvarlen = (astGetDataType( arrayexpr ) = IR_DATATYPE_STRING)
	if( astNewPARAM( proc, astNewCONSTi( isvarlen, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    ''
	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlArrayClear( byval arrayexpr as ASTNODE ptr ) as integer static
    dim as ASTNODE ptr proc
    dim as integer isvarlen, dtype
    dim as FBSYMBOL ptr f, s

    function = FALSE

	''
	f = ifuncTB(FB_RTL_ARRAYCLEAR)
    proc = astNewFUNCT( f )

    '' array() as ANY
    if( astNewPARAM( proc, arrayexpr, astGetDataType( arrayexpr ) ) = NULL ) then
    	exit function
    end if

	'' byval isvarlen as integer
	s = astGetSymbolOrElm( arrayexpr )
	dtype = symbGetType( s )

    isvarlen = (dtype = IR_DATATYPE_STRING)
	if( astNewPARAM( proc, astNewCONSTi( isvarlen, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    ''
	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlArrayStrErase( byval s as FBSYMBOL ptr ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dtype as integer

	function = FALSE

	''
	f = ifuncTB(FB_RTL_ARRAYSTRERASE)
    proc = astNewFUNCT( f )

    '' array() as ANY
    dtype = symbGetType( s )
    if( astNewPARAM( proc, astNewVAR( s, NULL, 0, dtype ), dtype ) = NULL ) then
    	exit function
    end if

    ''
	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlArrayBound( byval sexpr as ASTNODE ptr, _
						byval dimexpr as ASTNODE ptr, _
						byval islbound as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	if( islbound ) then
		f = ifuncTB(FB_RTL_ARRAYLBOUND)
	else
		f = ifuncTB(FB_RTL_ARRAYUBOUND)
	end if
    proc = astNewFUNCT( f )

    '' array() as ANY
    if( astNewPARAM( proc, sexpr ) = NULL ) then
    	exit function
    end if

	'' byval dimension as integer
	if( astNewPARAM( proc, dimexpr ) = NULL ) then
		exit function
	end if

    ''
    function = proc

end function

'':::::
function rtlArraySetDesc( byval s as FBSYMBOL ptr, _
						  byval elementlen as integer, _
					      byval dimensions as integer, _
					      dTB() as FBARRAYDIM ) as integer static

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dtype as integer, expr as ASTNODE ptr
    dim i as integer

    function = FALSE

	f = ifuncTB(FB_RTL_ARRAYSETDESC)
    proc = astNewFUNCT( f )

    '' array() as ANY
    dtype =  symbGetType( s )
	expr = astNewVAR( s, NULL, 0, dtype )
    if( astNewPARAM( proc, expr, dtype ) = NULL ) then
		exit function
	end if

	'' arraydata as any
	expr = astNewVAR( s, NULL, 0, dtype )
    if( astNewPARAM( proc, expr, dtype ) = NULL ) then
		exit function
	end if

	'' byval element_len as integer
	expr = astNewCONSTi( elementlen, IR_DATATYPE_INTEGER )
	if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
		exit function
	end if

	'' byval dimensions as integer
	expr = astNewCONSTi( dimensions, IR_DATATYPE_INTEGER )
	if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
		exit function
	end if

	'' ...
	for i = 0 to dimensions-1
		'' lbound
		expr = astNewCONSTi( dTB(i).lower, IR_DATATYPE_INTEGER )
		if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
			exit function
		end if

		'' ubound
		expr = astNewCONSTi( dTB(i).upper, IR_DATATYPE_INTEGER )
		if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
			exit function
		end if
	next i

    ''
	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlArrayAllocTmpDesc( byval arrayexpr as ASTNODE ptr, _
							   byval pdesc as FBSYMBOL ptr ) as ASTNODE ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dtype as integer, expr as ASTNODE ptr
    dim s as FBSYMBOL ptr
    dim d as FBVARDIM ptr
    dim dimensions as integer

	function = NULL

	s = astGetSymbolOrElm( arrayexpr )

	dimensions = symbGetArrayDimensions( s )

	f = ifuncTB(FB_RTL_ARRAYALLOCTMPDESC)
    proc = astNewFUNCT( f )

    '' byref pdesc as any ptr
	expr = astNewVAR( pdesc, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID )
    if( astNewPARAM( proc, expr, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ) = NULL ) then
    	exit function
    end if

    '' byref arraydata as any
    if( astNewPARAM( proc, arrayexpr, IR_DATATYPE_VOID ) = NULL ) then
    	exit function
    end if

	'' byval element_len as integer
	expr = astNewCONSTi( symbGetLen( s ), IR_DATATYPE_INTEGER )
	if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' byval dimensions as integer
	expr = astNewCONSTi( dimensions, IR_DATATYPE_INTEGER )
	if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' ...
    d = symbGetArrayFirstDim( s )
    do while( d <> NULL )
		'' lbound
		expr = astNewCONSTi( d->lower, IR_DATATYPE_INTEGER )
		if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if

		'' ubound
		expr = astNewCONSTi( d->upper, IR_DATATYPE_INTEGER )
		if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if

		'' next
		d = d->next
	loop

	function = proc

end function

'':::::
function rtlArrayFreeTempDesc( byval pdesc as FBSYMBOL ptr ) as ASTNODE ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim expr as ASTNODE ptr

	function = NULL

	f = ifuncTB(FB_RTL_ARRAYFREETMPDESC)
    proc = astNewFUNCT( f )

    '' byval pdesc as any ptr
	expr = astNewVAR( pdesc, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID )
    if( astNewPARAM( proc, expr, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' bounds and null-pointer checks
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function rtlArrayBoundsCheck( byval idx as ASTNODE ptr, _
							  byval lb as ASTNODE ptr, _
							  byval rb as ASTNODE ptr, _
							  byval linenum as integer ) as ASTNODE ptr static
    dim as ASTNODE ptr proc
    dim as FBSYMBOL ptr f

   	function = NULL

   	'' lbound 0? do a single check
   	if( lb = NULL ) then
		f = ifuncTB(FB_RTL_ARRAYSNGBOUNDCHK)
	else
    	f = ifuncTB(FB_RTL_ARRAYBOUNDCHK)
	end if

   	proc = astNewFUNCT( f )

	'' idx
	if( astNewPARAM( proc, idx, IR_DATATYPE_INTEGER ) = NULL ) then
		exit function
	end if

	'' lbound
	if( lb <> NULL ) then
		if( astNewPARAM( proc, lb, IR_DATATYPE_INTEGER ) = NULL ) then
			exit function
		end if
	end if

	'' rbound
	if( astNewPARAM( proc, rb, IR_DATATYPE_INTEGER ) = NULL ) then
		exit function
	end if

	'' linenum
	if( astNewPARAM( proc, astNewCONSTi( linenum, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlNullPtrCheck( byval p as ASTNODE ptr, _
						  byval linenum as integer ) as ASTNODE ptr static
    dim as ASTNODE ptr proc

   	function = NULL

   	proc = astNewFUNCT( ifuncTB(FB_RTL_NULLPTRCHK) )

	'' ptr
	p = astNewCONV( IR_OP_TOPOINTER, IR_DATATYPE_POINTER+IR_DATATYPE_VOID, NULL, p )
	if( astNewPARAM( proc, p, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ) = NULL ) then
		exit function
	end if

	'' linenum
	if( astNewPARAM( proc, astNewCONSTi( linenum, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' data
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function rtlDataRead( byval varexpr as ASTNODE ptr ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr, args as integer
    dim dtype as integer, lgt as integer

    function = FALSE

	f = NULL
	args = 1
	select case as const astGetDataType( varexpr )
	case IR_DATATYPE_STRING, IR_DATATYPE_FIXSTR, IR_DATATYPE_CHAR
		f = ifuncTB(FB_RTL_DATAREADSTR)
		args = 3
	case IR_DATATYPE_BYTE
		f = ifuncTB(FB_RTL_DATAREADBYTE)
	case IR_DATATYPE_UBYTE
		f = ifuncTB(FB_RTL_DATAREADUBYTE)
	case IR_DATATYPE_SHORT
		f = ifuncTB(FB_RTL_DATAREADSHORT)
	case IR_DATATYPE_USHORT
		f = ifuncTB(FB_RTL_DATAREADUSHORT)
	case IR_DATATYPE_INTEGER, IR_DATATYPE_ENUM
		f = ifuncTB(FB_RTL_DATAREADINT)
	case IR_DATATYPE_UINT
		f = ifuncTB(FB_RTL_DATAREADUINT)
	case IR_DATATYPE_LONGINT
		f = ifuncTB(FB_RTL_DATAREADLONGINT)
	case IR_DATATYPE_ULONGINT
		f = ifuncTB(FB_RTL_DATAREADULONGINT)
	case IR_DATATYPE_SINGLE
		f = ifuncTB(FB_RTL_DATAREADSINGLE)
	case IR_DATATYPE_DOUBLE
		f = ifuncTB(FB_RTL_DATAREADDOUBLE)
	case IR_DATATYPE_USERDEF
		exit function						'' illegal
	case else
		f = ifuncTB(FB_RTL_DATAREADUINT)
	end select

    if( f = NULL ) then
    	exit function
    end if

    proc = astNewFUNCT( f )

    '' byref var as any
    if( astNewPARAM( proc, varexpr ) = NULL ) then
 		exit function
 	end if

    if( args = 3 ) then
		'' byval dst_size as integer
		dtype = astGetDataType( varexpr )
		STRGETLEN( varexpr, dtype, lgt )
		if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
 			exit function
 		end if

		'' byval fillrem as integer
		if( astNewPARAM( proc, astNewCONSTi( dtype = IR_DATATYPE_FIXSTR, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if
    end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlDataRestore( byval label as FBSYMBOL ptr, _
						 byval afternode as ASTNODE ptr, _
						 byval isprofiler as integer = FALSE ) as integer static
    dim as ASTNODE ptr proc, expr
    dim as FBSYMBOL ptr s, f
    dim as string lname

    function = FALSE

	f = ifuncTB(FB_RTL_DATARESTORE)
    proc = astNewFUNCT( f, NULL, isprofiler )

    '' begin of data or start from label?
    if( label <> NULL ) then
    	lname = FB_DATALABELPREFIX + symbGetName( label )
    else
    	lname = FB_DATALABELNAME
    end if

    '' label already declared?
    s = symbFindByNameAndClass( lname, FB_SYMBCLASS_LABEL )
    if( s = NULL ) then
       	s = symbAddLabel( lname, TRUE, TRUE )
    end if

    '' byval labeladdrs as void ptr
    expr = astNewADDR( IR_OP_ADDROF, astNewVAR( s, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ), s )
    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

	''
	if( afternode = NULL ) then
		astAdd( proc )
	else
		astAddAfter( proc, afternode )
	end if

	function = TRUE

end function

'':::::
sub rtlDataStoreBegin static
    dim as string lname
    dim as FBSYMBOL ptr l, label, s

	'' switch section, can't be code coz it will screw up debugging
	emitSECTION( EMIT_SECTYPE_CONST )

	'' emit default label if not yet emited
	if( not ctx.datainited ) then
		ctx.datainited = TRUE

		l = symbAddLabel( FB_DATALABELNAME, TRUE, TRUE )
		if( l = NULL ) then
			l = symbFindByNameAndClass( FB_DATALABELNAME, FB_SYMBCLASS_LABEL )
		end if

		lname = symbGetName( l )
		emitDATALABEL( lname )

	else
		s = symbFindByNameAndClass( FB_DATALABELNAME, FB_SYMBCLASS_LABEL )
		lname = symbGetName( s )
	end if

	'' emit last label as a label in const section
	'' if any defined already, otherwise it will be the default
	label = symbGetLastLabel( )
	if( label <> NULL ) then
    	''
    	lname = FB_DATALABELPREFIX + symbGetName( label )
    	l = symbFindByNameAndClass( lname, FB_SYMBCLASS_LABEL )
    	if( l = NULL ) then
       		l = symbAddLabel( lname, TRUE, TRUE )
    	end if

    	lname = symbGetName( l )

    	'' stills the same label as before? incrase counter to link DATA's
    	if( ctx.lastlabel = label ) then
    		ctx.labelcnt = ctx.labelcnt + 1
    		lname += "_" + str( ctx.labelcnt )
    	else
    		ctx.lastlabel = label
    		ctx.labelcnt = 0
    	end if

    	emitDATALABEL( lname )

    else
    	symbSetLastLabel( symbFindByNameAndClass( FB_DATALABELNAME, FB_SYMBCLASS_LABEL ) )
    end if

	'' emit will link the last DATA with this one if any exists
	emitDATABEGIN( lname )

end sub

'':::::
function rtlDataStore( byval littext as string, _
					   byval litlen as integer, _
					   byval typ as integer ) as integer static

	'' emit will take care of all dirty details
	emitDATA( littext, litlen, typ )

	function = TRUE

end function

'':::::
function rtlDataStoreOFS( byval sym as FBSYMBOL ptr ) as integer static

	emitDATAOFS( symbGetName( sym ) )

	function = TRUE

end function

'':::::
sub rtlDataStoreEnd static

	'' emit end of data (will be repatched by emit if more DATA stmts follow)
	emitDATAEND( )

end sub

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' math
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function rtlMathPow	( byval xexpr as ASTNODE ptr, _
					  byval yexpr as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_POW)
    proc = astNewFUNCT( f )

    '' byval x as double
    if( astNewPARAM( proc, xexpr ) = NULL ) then
 		exit function
 	end if

    '' byval y as double
    if( astNewPARAM( proc, yexpr ) = NULL ) then
 		exit function
 	end if

    ''
    function = proc

end function

'':::::
function rtlMathFSGN ( byval expr as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	if( astGetDataType( expr ) = IR_DATATYPE_SINGLE ) then
		f = ifuncTB(FB_RTL_SGNSINGLE)
	else
		f = ifuncTB(FB_RTL_SGNDOUBLE)
	end if

    proc = astNewFUNCT( f )

    '' byval x as single|double
    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    ''
    function = proc

end function

'':::::
function rtlMathTRANS( byval op as integer, _
					   byval expr as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	select case op
	case IR_OP_ASIN
		f = ifuncTB(FB_RTL_ASIN)
	case IR_OP_ACOS
		f = ifuncTB(FB_RTL_ACOS)
	case IR_OP_LOG
		f = ifuncTB(FB_RTL_LOG)
	end select

    proc = astNewFUNCT( f )

    '' byval x as double
    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    ''
    function = proc

end function


'':::::
function rtlMathFIX ( byval expr as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	select case astGetDataClass( expr )
	case IR_DATACLASS_FPOINT
		if( astGetDataType( expr ) = IR_DATATYPE_SINGLE ) then
			f = ifuncTB(FB_RTL_FIXSINGLE)
		else
			f = ifuncTB(FB_RTL_FIXDOUBLE)
		end if

	case IR_DATACLASS_INTEGER
		return expr

	case else
		exit function
	end select

    proc = astNewFUNCT( f )

    '' byval x as single|double
    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    ''
    function = proc

end function

'':::::
private function hCalcExprLen( byval expr as ASTNODE ptr, _
							   byval realsize as integer = TRUE ) as integer static
	dim lgt as integer, s as FBSYMBOL ptr
	dim dtype as integer

	lgt = -1

	dtype = astGetDataType( expr )
	select case as const dtype
	case IR_DATATYPE_BYTE, IR_DATATYPE_UBYTE
		lgt = 1

	case IR_DATATYPE_SHORT, IR_DATATYPE_USHORT
		lgt = 2

	case IR_DATATYPE_INTEGER, IR_DATATYPE_UINT, IR_DATATYPE_ENUM
		lgt = FB_INTEGERSIZE

	case IR_DATATYPE_LONGINT, IR_DATATYPE_ULONGINT
		lgt = FB_INTEGERSIZE*2

	case IR_DATATYPE_SINGLE
		lgt = 4

	case IR_DATATYPE_DOUBLE
		lgt = 8

	case IR_DATATYPE_STRING
		lgt = FB_STRSTRUCTSIZE

	case IR_DATATYPE_FIXSTR
		lgt = FIXSTRGETLEN( expr )

	case IR_DATATYPE_CHAR
		lgt = ZSTRGETLEN( expr )
		if( lgt = 0 ) then
			lgt = 1
		end if

	case IR_DATATYPE_USERDEF
		s = astGetSymbolOrElm( expr )
		if( s <> NULL ) then
			'' if it's a type field that's an udt, no pad is ever added, realsize is always TRUE
			if( s->class = FB_SYMBCLASS_UDTELM ) then
				realsize = TRUE
			end if
			lgt = symbGetUDTLen( symbGetSubtype( s ), realsize )
		else
			lgt = 0
		end if

	case else
		if( dtype >= IR_DATATYPE_POINTER ) then
			lgt = FB_POINTERSIZE
		end if
	end select

	hCalcExprLen = lgt

end function

'':::::
function rtlMathLen( byval expr as ASTNODE ptr, _
					 byval checkstrings as integer = TRUE ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dtype as integer, lgt as integer, s as integer

	function = NULL

	dtype = astGetDataType( expr )

	'' LEN()?
	if( checkstrings ) then
		'' dyn-len or zstring?
		if( (dtype = IR_DATATYPE_STRING) or (dtype = IR_DATATYPE_CHAR) ) then
			f = ifuncTB(FB_RTL_STRLEN)
    		proc = astNewFUNCT( f )

    		'' str as any
    		if( astNewPARAM( proc, expr, IR_DATATYPE_STRING ) = NULL ) then
 				exit function
 			end if

    		'' byval strlen as integer
			STRGETLEN( expr, dtype, lgt )

			if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
 				exit function
 			end if

			return proc
		end if
	end if

	''
	lgt = hCalcExprLen( expr, FALSE )

	'' handle fix-len strings (evaluated at compile-time)
	if( checkstrings ) then
		if( dtype = IR_DATATYPE_FIXSTR ) then
			if( lgt > 0 ) then
				lgt -= 1						'' less the null-term
			end if
		end if
	end if

	function = astNewCONSTi( lgt, IR_DATATYPE_INTEGER )

	astDelTree( expr )

end function

'':::::
function rtlMathLongintDIV( byval dtype as integer, _
							byval lexpr as ASTNODE ptr, _
							byval ldtype as integer, _
					        byval rexpr as ASTNODE ptr, _
					        byval rdtype as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	if( dtype = IR_DATATYPE_LONGINT ) then
		f = ifuncTB(FB_RTL_LONGINTDIV)
	else
		f = ifuncTB(FB_RTL_ULONGINTDIV)
	end if

    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, lexpr, ldtype ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, rexpr, rdtype ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlMathLongintMOD( byval dtype as integer, _
							byval lexpr as ASTNODE ptr, _
							byval ldtype as integer, _
					        byval rexpr as ASTNODE ptr, _
					        byval rdtype as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	if( dtype = IR_DATATYPE_LONGINT ) then
		f = ifuncTB(FB_RTL_LONGINTMOD)
	else
		f = ifuncTB(FB_RTL_ULONGINTMOD)
	end if

    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, lexpr, ldtype ) = NULL ) then
    	exit function
    end if

    if( astNewPARAM( proc, rexpr, rdtype ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::
function rtlMathFp2ULongint( byval expr as ASTNODE ptr, _
							 byval dtype as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	f = ifuncTB(FB_RTL_DBL2ULONGINT)
    proc = astNewFUNCT( f )

    ''
    if( astNewPARAM( proc, expr, dtype ) = NULL ) then
    	exit function
    end if

    function = proc

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' console
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
private sub hAddPrinterLibs( )

    static as integer libsAdded = FALSE

	if( not libsadded ) then

		select case env.clopt.target
		case FB_COMPTARGET_WIN32
			symbAddLib( "winspool" )
		end select

	end if

end sub

'':::::
function rtlPrint( byval fileexpr as ASTNODE ptr, _
				   byval iscomma as integer, _
				   byval issemicolon as integer, _
				   byval expr as ASTNODE ptr, _
                   byval islprint as integer = FALSE ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim mask as integer, args as integer
    dim dtype as integer

    function = FALSE

    if islprint then hAddPrinterLibs

	if( expr = NULL ) then
		f = ifuncTB(IIf(islprint, FB_RTL_LPRINTVOID, FB_RTL_PRINTVOID))
		args = 2
	else

		dtype = astGetDataType( expr )
		select case as const dtype
		case IR_DATATYPE_FIXSTR, IR_DATATYPE_STRING, IR_DATATYPE_CHAR
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTSTR, FB_RTL_PRINTSTR))
		case IR_DATATYPE_BYTE
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTBYTE, FB_RTL_PRINTBYTE))
		case IR_DATATYPE_UBYTE
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTUBYTE, FB_RTL_PRINTUBYTE))
		case IR_DATATYPE_SHORT
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTSHORT, FB_RTL_PRINTSHORT))
		case IR_DATATYPE_USHORT
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTUSHORT, FB_RTL_PRINTUSHORT))
		case IR_DATATYPE_INTEGER, IR_DATATYPE_ENUM
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTINT, FB_RTL_PRINTINT))
		case IR_DATATYPE_UINT
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTUINT, FB_RTL_PRINTUINT))
		case IR_DATATYPE_LONGINT
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTLONGINT, FB_RTL_PRINTLONGINT))
		case IR_DATATYPE_ULONGINT
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTULONGINT, FB_RTL_PRINTULONGINT))
		case IR_DATATYPE_SINGLE
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTSINGLE, FB_RTL_PRINTSINGLE))
		case IR_DATATYPE_DOUBLE
			f = ifuncTB(IIf(islprint, FB_RTL_LPRINTDOUBLE, FB_RTL_PRINTDOUBLE))
		case IR_DATATYPE_USERDEF
			exit function						'' illegal
		case else
			if( dtype >= IR_DATATYPE_POINTER ) then
				f = ifuncTB(IIf(islprint, FB_RTL_LPRINTUINT, FB_RTL_PRINTUINT))
				expr = astNewCONV( INVALID, IR_DATATYPE_UINT, NULL, expr )
			end if
		end select

		args = 3
	end if

    ''
	proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, fileexpr ) = NULL ) then
 		exit function
 	end if

    if( expr <> NULL ) then
    	'' byval? x as ???
    	if( astNewPARAM( proc, expr ) = NULL ) then
 			exit function
 		end if
    end if

    '' byval mask as integer
	mask = 0
	if( iscomma ) then
		mask = mask or FB_PRINTMASK_PAD
	elseif( not issemicolon ) then
		mask = mask or FB_PRINTMASK_NEWLINE
	end if

	expr = astNewCONSTi( mask, IR_DATATYPE_INTEGER )
    if( astNewPARAM( proc, expr, IR_DATATYPE_INTEGER ) = NULL ) then
 		exit function
 	end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlPrintSPC( byval fileexpr as ASTNODE ptr, _
					  byval expr as ASTNODE ptr, _
                      byval islprint as integer = FALSE ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

    if islprint then hAddPrinterLibs

	''
	f = ifuncTB(FB_RTL_PRINTSPC)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, fileexpr ) = NULL ) then
 		exit function
 	end if

    '' byval n as integer
    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlPrintTab( byval fileexpr as ASTNODE ptr, _
					  byval expr as ASTNODE ptr, _
                      byval islprint as integer = FALSE ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

    if islprint then hAddPrinterLibs

	''
	f = ifuncTB(FB_RTL_PRINTTAB)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, fileexpr ) = NULL ) then
 		exit function
 	end if

    '' byval newcol as integer
    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlWrite( byval fileexpr as ASTNODE ptr, _
				   byval iscomma as integer, _
				   byval expr as ASTNODE ptr ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim mask as integer, args as integer
    dim dtype as integer

	function = FALSE

	if( expr = NULL ) then
		f = ifuncTB(FB_RTL_WRITEVOID)
		args = 2
	else

		dtype = astGetDataType( expr )
		select case as const dtype
		case IR_DATATYPE_FIXSTR, IR_DATATYPE_STRING, IR_DATATYPE_CHAR
			f = ifuncTB(FB_RTL_WRITESTR)
		case IR_DATATYPE_BYTE
			f = ifuncTB(FB_RTL_WRITEBYTE)
		case IR_DATATYPE_UBYTE
			f = ifuncTB(FB_RTL_WRITEUBYTE)
		case IR_DATATYPE_SHORT
			f = ifuncTB(FB_RTL_WRITESHORT)
		case IR_DATATYPE_USHORT
			f = ifuncTB(FB_RTL_WRITEUSHORT)
		case IR_DATATYPE_INTEGER, IR_DATATYPE_ENUM
			f = ifuncTB(FB_RTL_WRITEINT)
		case IR_DATATYPE_UINT
			f = ifuncTB(FB_RTL_WRITEUINT)
		case IR_DATATYPE_LONGINT
			f = ifuncTB(FB_RTL_WRITELONGINT)
		case IR_DATATYPE_ULONGINT
			f = ifuncTB(FB_RTL_WRITEULONGINT)
		case IR_DATATYPE_SINGLE
			f = ifuncTB(FB_RTL_WRITESINGLE)
		case IR_DATATYPE_DOUBLE
			f = ifuncTB(FB_RTL_WRITEDOUBLE)
		case IR_DATATYPE_USERDEF
			exit function						'' illegal
		case else
			if( dtype >= IR_DATATYPE_POINTER ) then
				f = ifuncTB(FB_RTL_WRITEUINT)
				expr = astNewCONV( INVALID, IR_DATATYPE_UINT, NULL, expr )
			end if
		end select

		args = 3
	end if

    ''
	proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, fileexpr ) = NULL ) then
 		exit function
 	end if

    if( expr <> NULL ) then
    	'' byval? x as ???
    	if( astNewPARAM( proc, expr ) = NULL ) then
 			exit function
 		end if
    end if

    '' byval mask as integer
	mask = 0
	if( iscomma ) then
		mask = mask or FB_PRINTMASK_PAD
	else
		mask = mask or FB_PRINTMASK_NEWLINE
	end if

    if( astNewPARAM( proc, astNewCONSTi( mask, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
 		exit function
 	end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlPrintUsingInit( byval usingexpr as ASTNODE ptr, _
                            byval islprint as integer = FALSE ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

    if islprint then hAddPrinterLibs

	''
	f = ifuncTB(IIf(islprint,FB_RTL_LPRINTUSGINIT, FB_RTL_PRINTUSGINIT))
    proc = astNewFUNCT( f )

    '' fmtstr as string
    if( astNewPARAM( proc, usingexpr ) = NULL ) then
 		exit function
 	end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlPrintUsingEnd( byval fileexpr as ASTNODE ptr, _
                           byval islprint as integer = FALSE ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

    if islprint then hAddPrinterLibs

	''
	f = ifuncTB(FB_RTL_PRINTUSGEND)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, fileexpr ) = NULL ) then
 		exit function
 	end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlPrintUsing( byval fileexpr as ASTNODE ptr, _
						byval expr as ASTNODE ptr, _
						byval iscomma as integer, _
						byval issemicolon as integer, _
                        byval islprint as integer = FALSE ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim mask as integer

	function = FALSE

    if islprint then hAddPrinterLibs

	select case astGetDataType( expr )
	case IR_DATATYPE_FIXSTR, IR_DATATYPE_STRING, IR_DATATYPE_CHAR
		f = ifuncTB(FB_RTL_PRINTUSGSTR)
	case else
		f = ifuncTB(FB_RTL_PRINTUSGVAL)
	end select

    ''
	proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, fileexpr ) = NULL ) then
 		exit function
 	end if

    '' s as string or byval v as double
    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    '' byval mask as integer
	if( iscomma or issemicolon ) then
		mask = 0
	else
		mask = FB_PRINTMASK_NEWLINE or FB_PRINTMASK_ISLAST
	end if

    if( astNewPARAM( proc, astNewCONSTi( mask, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
 		exit function
 	end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' misc
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function rtlInitSignals( ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

	'' init( )
	f = ifuncTB(FB_RTL_INITSIGNALS)
    proc = astNewFUNCT( f, NULL, TRUE )

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlInitProfile( ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

	'' init( )
	f = ifuncTB(FB_RTL_INITPROFILE)
    proc = astNewFUNCT( f, NULL, TRUE )

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlInitRt( byval argc as ASTNODE ptr, _
					byval argv as ASTNODE ptr, _
					byval isdllmain as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	'' init( argc, argv )
	f = ifuncTB(FB_RTL_INIT)
    proc = astNewFUNCT( f, NULL, TRUE )

    '' argc
    if( argc = NULL ) then
    	argc = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, argc ) = NULL ) then
    	exit function
    end if

    '' argv
    if( argv = NULL ) then
    	argv = astNewCONSTi( 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID )
    end if
    if( astNewPARAM( proc, argv ) = NULL ) then
    	exit function
    end if

    astAdd( proc )

    '' if error checking is on, call initSignals
    if( env.clopt.errorcheck ) then
    	if( not isdllmain ) then
    		rtlInitSignals( )
    	end if
    end if

    '' start profiling if requested
    if( env.clopt.profile ) then
	    if( not isdllmain ) then
	    	rtlInitProfile( )
	    end if
    end if

    function = proc

end function

'':::::
function rtlExitRt( byval errlevel as ASTNODE ptr ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

	'' exit profiling?
	if( env.clopt.profile ) then
		f = ifuncTB(FB_RTL_PROFILEEND)
		proc = astNewFUNCT( f, NULL, TRUE )
		astAdd( proc )
	end if

	''
	f = ifuncTB(FB_RTL_END)
    proc = astNewFUNCT( f, NULL, TRUE )

    '' errlevel
    if( errlevel = NULL ) then
    	errlevel = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, errlevel ) = NULL ) then
    	exit function
    end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlMemCopy( byval dst as ASTNODE ptr, _
					 byval src as ASTNODE ptr, _
					 byval bytes as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_MEMCOPY)
    proc = astNewFUNCT( f )

    '' dst as any
    if( astNewPARAM( proc, dst ) = NULL ) then
    	exit function
    end if

    '' src as any
    if( astNewPARAM( proc, src ) = NULL ) then
    	exit function
    end if

    '' byval bytes as integer
    if( astNewPARAM( proc, astNewCONSTi( bytes, IR_DATATYPE_INTEGER ) ) = NULL ) then
    	exit function
    end if

    ''
    function = proc

end function

'':::::
function rtlMemSwap( byval dst as ASTNODE ptr, _
					 byval src as ASTNODE ptr ) as integer static
    dim as ASTNODE ptr proc
    dim as FBSYMBOL ptr f
    dim as integer bytes

    function = FALSE

	'' simple type?
	if( (astGetDataType( dst ) <> IR_DATATYPE_USERDEF) and (astIsVAR( dst )) ) then

		'' push src
		astAdd( astNewSTACK( IR_OP_PUSH, astCloneTree( src ) ) )

		'' src = dst
		astAdd( astNewASSIGN( src, astCloneTree( dst ) ) )

		'' pop dst
		astAdd( astNewSTACK( IR_OP_POP, dst ) )

		exit sub
	end if

	''
	f = ifuncTB(FB_RTL_MEMSWAP)
    proc = astNewFUNCT( f )

    '' dst as any
    if( astNewPARAM( proc, dst ) = NULL ) then
    	exit function
    end if

    '' src as any
    if( astNewPARAM( proc, src ) = NULL ) then
    	exit function
    end if

    '' byval bytes as integer
	bytes = hCalcExprLen( dst )
    if( astNewPARAM( proc, astNewCONSTi( bytes, IR_DATATYPE_INTEGER ) ) = NULL ) then
    	exit function
    end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlStrSwap( byval str1 as ASTNODE ptr, _
					 byval str2 as ASTNODE ptr ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim lgt as integer, s as integer, dtype as integer

	function = FALSE

	''
	f = ifuncTB(FB_RTL_STRSWAP)
    proc = astNewFUNCT( f )

    '' str1 as any
    if( astNewPARAM( proc, str1, IR_DATATYPE_STRING ) = NULL ) then
    	exit function
    end if

    '' byval str1len as integer
	dtype = astGetDataType( str1 )
	STRGETLEN( str1, dtype, lgt )
	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    '' str2 as any
    if( astNewPARAM( proc, str2, IR_DATATYPE_STRING ) = NULL ) then
    	exit function
    end if

    '' byval str1len as integer
	dtype = astGetDataType( str2 )
	STRGETLEN( str2, dtype, lgt )
	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlMemCopyClear( byval dstexpr as ASTNODE ptr, _
					      byval dstlen as integer, _
					      byval srcexpr as ASTNODE ptr, _
					      byval srclen as integer ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

	''
	f = ifuncTB(FB_RTL_MEMCOPYCLEAR)
    proc = astNewFUNCT( f )

    '' dst as any
    if( astNewPARAM( proc, dstexpr ) = NULL ) then
    	exit function
    end if

    '' byval dstlen as integer
    if( astNewPARAM( proc, astNewCONSTi( dstlen, IR_DATATYPE_INTEGER ) ) = NULL ) then
    	exit function
    end if

    '' src as any
    if( astNewPARAM( proc, srcexpr ) = NULL ) then
    	exit function
    end if

    '' byval srclen as integer
    if( astNewPARAM( proc, astNewCONSTi( srclen, IR_DATATYPE_INTEGER ) ) = NULL ) then
    	exit function
    end if

    ''
    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlConsoleView ( byval topexpr as ASTNODE ptr, _
						  byval botexpr as ASTNODE ptr ) as ASTNODE ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_CONSOLEVIEW)
    proc = astNewFUNCT( f )

    '' byval toprow as integer
    if( astNewPARAM( proc, topexpr ) = NULL ) then
    	exit function
    end if

    '' byval botrow as integer
    if( astNewPARAM( proc, botexpr ) = NULL ) then
    	exit function
    end if

'    astAdd( proc )

    function = proc

end function

'':::::
function rtlWidthScreen ( byval width_arg as ASTNODE ptr, _
					      byval height_arg as ASTNODE ptr, _
                          byval isfunc as integer ) as ASTNODE ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_WIDTH)
    proc = astNewFUNCT( f )

    '' byval width_arg as integer
    if( width_arg = NULL ) then
    	width_arg = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, width_arg ) = NULL ) then
    	exit function
    end if

    '' byval height_arg as integer
    if( height_arg = NULL ) then
        height_arg = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, height_arg ) = NULL ) then
    	exit function
    end if

    if( not isfunc ) then
    	dim reslabel as FBSYMBOL ptr
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if
end function

'':::::
function rtlWidthDev ( byval device as ASTNODE ptr, _
					   byval width_arg as ASTNODE ptr, _
                       byval isfunc as integer ) as ASTNODE ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

    '' printer libraries are always required for width on devices
	hAddPrinterLibs

	''
	f = ifuncTB(FB_RTL_WIDTHDEV)
    proc = astNewFUNCT( f )

    '' device as string
    if( astNewPARAM( proc, device ) = NULL ) then
    	exit function
    end if

    '' byval width_arg as integer
    if( astNewPARAM( proc, width_arg ) = NULL ) then
    	exit function
    end if

    ''
    if( not isfunc ) then
    	dim reslabel as FBSYMBOL ptr

    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if
end function

'':::::
function rtlWidthFile ( byval fnum as ASTNODE ptr, _
					    byval width_arg as ASTNODE ptr, _
                        byval isfunc as integer ) as ASTNODE ptr
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_WIDTHFILE)
    proc = astNewFUNCT( f )

    '' byval fnum as integer
    if( astNewPARAM( proc, fnum ) = NULL ) then
    	exit function
    end if

    '' byval width_arg as integer
    if( astNewPARAM( proc, width_arg ) = NULL ) then
    	exit function
    end if

    if( not isfunc ) then
    	dim reslabel as FBSYMBOL ptr

    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if
end function

'':::::
function rtlConsoleReadXY ( byval rowexpr as ASTNODE ptr, _
							byval columnexpr as ASTNODE ptr, _
							byval colorflagexpr as ASTNODE ptr ) as ASTNODE ptr
	dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_CONSOLEREADXY)
	proc = astNewFUNCT( f )

	'' byval column as integer
	if( astNewPARAM( proc, columnexpr ) = NULL ) then
    	exit function
    end if

	'' byval row as integer
	if( astNewPARAM( proc, rowexpr ) = NULL ) then
    	exit function
    end if

	'' byval colorflag as integer
	if( colorflagexpr = NULL ) then
		colorflagexpr = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
	end if
	if( astNewPARAM( proc, colorflagexpr ) = NULL ) then
    	exit function
    end if

	function = proc

end function

'':::::
private function hMultithread_cb( byval sym as FBSYMBOL ptr ) as integer

	env.clopt.multithreaded = TRUE

	return TRUE

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' error
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

function rtlErrorCheck( byval resexpr as ASTNODE ptr, _
						byval reslabel as FBSYMBOL ptr, _
						byval linenum as integer ) as integer static
	dim proc as ASTNODE ptr, f as FBSYMBOL ptr
	dim nxtlabel as FBSYMBOL ptr
	dim param as ASTNODE ptr, dst as ASTNODE ptr

	function = FALSE

	if( not env.clopt.errorcheck ) then
		astAdd( resexpr )
		return TRUE
	end if

	''
	f = ifuncTB(FB_RTL_ERRORTHROW)
	proc = astNewFUNCT( f )

	''
	nxtlabel = symbAddLabel( "" )

	'' result >= FB_RTERROR_OK? skip..
	resexpr = astNewBOP( IR_OP_EQ, resexpr, astNewCONSTi( 0, IR_DATATYPE_INTEGER ), nxtlabel, FALSE )

	astAdd( resexpr )

	'' else, fb_ErrorThrow( linenum, reslabel, resnxtlabel ); -- CDECL

    '' linenum
	if( astNewPARAM( proc, astNewCONSTi( linenum, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

	'' reslabel
	if( reslabel <> NULL ) then
		param = astNewADDR( IR_OP_ADDROF, astNewVAR( reslabel, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ) )
	else
		param = astNewCONSTi( NULL, IR_DATATYPE_UINT )
	end if
	if( astNewPARAM( proc, param ) = NULL ) then
		exit function
	end if

	'' resnxtlabel
	if( env.clopt.resumeerr ) then
		param = astNewADDR( IR_OP_ADDROF, astNewVAR( nxtlabel, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ) )
	else
		param = astNewCONSTi( NULL, IR_DATATYPE_UINT )
	end if
	if( astNewPARAM( proc, param ) = NULL ) then
		exit function
	end if

    '' dst
    dst = astNewBRANCH( IR_OP_JUMPPTR, NULL, proc )

    astAdd( dst )

	''
	astAdd( astNewLABEL( nxtlabel ) )

	'''''symbDelLabel nxtlabel
	'''''symbDelLabel reslabel

	function = TRUE

end function

'':::::
sub rtlErrorThrow( byval errexpr as ASTNODE ptr, _
				   byval linenum as integer ) static
	dim proc as ASTNODE ptr, f as FBSYMBOL ptr
	dim nxtlabel as FBSYMBOL ptr, reslabel as FBSYMBOL ptr
	dim param as ASTNODE ptr, dst as ASTNODE ptr

	''
	f = ifuncTB(FB_RTL_ERRORTHROWEX)
	proc = astNewFUNCT( f )

	''
    reslabel = symbAddLabel( "" )
    astAdd( astNewLABEL( reslabel ) )

	nxtlabel = symbAddLabel( "" )

	'' fb_ErrorThrowEx( errnum, linenum, reslabel, resnxtlabel );

	'' errnum
	if( astNewPARAM( proc, errexpr ) = NULL ) then
		exit sub
	end if

    '' linenum
	if( astNewPARAM( proc, astNewCONSTi( linenum, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit sub
    end if

	'' reslabel
	if( env.clopt.resumeerr ) then
		param = astNewADDR( IR_OP_ADDROF, astNewVAR( reslabel, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ) )
	else
		param = astNewCONSTi( NULL, IR_DATATYPE_UINT )
	end if
	if( astNewPARAM( proc, param ) = NULL ) then
		exit function
	end if

	'' resnxtlabel
	if( env.clopt.resumeerr ) then
		param = astNewADDR( IR_OP_ADDROF, astNewVAR( nxtlabel, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID ) )
	else
		param = astNewCONSTi( NULL, IR_DATATYPE_UINT )
	end if
	if( astNewPARAM( proc, param ) = NULL ) then
		exit function
	end if

    '' dst
    dst = astNewBRANCH( IR_OP_JUMPPTR, NULL, proc )

    astAdd( dst )

	''
	astAdd( astNewLABEL( nxtlabel ) )

	'''''symbDelLabel nxtlabel
	'''''symbDelLabel reslabel

end sub

'':::::
sub rtlErrorSetHandler( byval newhandler as ASTNODE ptr, _
						byval savecurrent as integer ) static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim expr as ASTNODE ptr

	''
	f = ifuncTB(FB_RTL_ERRORSETHANDLER)
    proc = astNewFUNCT( f )

    '' byval newhandler as uint
    if( astNewPARAM( proc, newhandler ) = NULL ) then
    	exit sub
    end if

    ''
    expr = NULL
    if( savecurrent ) then
    	if( env.scope > 0 ) then
    		if( env.procerrorhnd = NULL ) then
				env.procerrorhnd = symbAddTempVar( FB_SYMBTYPE_POINTER+FB_SYMBTYPE_VOID )
                expr = astNewVAR( env.procerrorhnd, NULL, 0, IR_DATATYPE_POINTER+IR_DATATYPE_VOID )
                astAdd( astNewASSIGN( expr, proc ) )
    		end if
		end if
    end if

    if( expr = NULL ) then
    	astAdd( proc )
    end if

end sub

'':::::
function rtlErrorGetNum as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	''
	f = ifuncTB(FB_RTL_ERRORGETNUM)
    proc = astNewFUNCT( f )

    ''
    function = proc

end function

'':::::
sub rtlErrorSetNum( byval errexpr as ASTNODE ptr ) static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	''
	f = ifuncTB(FB_RTL_ERRORSETNUM)
    proc = astNewFUNCT( f )

    '' byval errnum as integer
    if( astNewPARAM( proc, errexpr ) = NULL ) then
    	exit sub
    end if

    ''
    astAdd( proc )

end sub

'':::::
sub rtlErrorResume( byval isnext as integer )
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dst as ASTNODE ptr

	''
	if( not isnext ) then
		f = ifuncTB(FB_RTL_ERRORRESUME)
	else
		f = ifuncTB(FB_RTL_ERRORRESUMENEXT)
	end if

	proc = astNewFUNCT( f )

    ''
    dst = astNewBRANCH( IR_OP_JUMPPTR, NULL, proc )

    astAdd( dst )

end sub

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' file
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
function rtlFileOpen( byval filename as ASTNODE ptr, _
					  byval fmode as ASTNODE ptr, _
					  byval faccess as ASTNODE ptr, _
				      byval flock as ASTNODE ptr, _
				      byval filenum as ASTNODE ptr, _
				      byval flen as ASTNODE ptr, _
				      byval isfunc as integer, _
                      byval openkind as FBOPENKIND ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim reslabel as FBSYMBOL ptr

	function = NULL

    select case astGetDataType( fmode )
    case IR_DATATYPE_STRING, IR_DATATYPE_FIXSTR:
        '' this is the short form of the OPEN command
        f = ifuncTB(FB_RTL_FILEOPEN_SHORT)
        proc = astNewFUNCT( f )

        '' mode as string
        if( astNewPARAM( proc, fmode ) = NULL ) then
            exit function
        end if

        '' byval filenum as integer
        if( astNewPARAM( proc, filenum ) = NULL ) then
            exit function
        end if

        '' filename as string
        if( astNewPARAM( proc, filename ) = NULL ) then
            exit function
        end if

        '' byval len as integer
        if( astNewPARAM( proc, flen ) = NULL ) then
            exit function
        end if

        '' faccess as string
        if( astNewPARAM( proc, faccess ) = NULL ) then
            exit function
        end if

        '' flock as string
        if( astNewPARAM( proc, flock ) = NULL ) then
            exit function
        end if

    case else
        ''
        select case openkind
        case FB_FILE_TYPE_FILE
        	f = ifuncTB(FB_RTL_FILEOPEN)
    	case FB_FILE_TYPE_CONS
        	f = ifuncTB(FB_RTL_FILEOPEN_CONS)
    	case FB_FILE_TYPE_ERR
        	f = ifuncTB(FB_RTL_FILEOPEN_ERR)
    	case FB_FILE_TYPE_PIPE
        	f = ifuncTB(FB_RTL_FILEOPEN_PIPE)
    	case FB_FILE_TYPE_SCRN
        	f = ifuncTB(FB_RTL_FILEOPEN_SCRN)
    	case FB_FILE_TYPE_LPT
        	f = ifuncTB(FB_RTL_FILEOPEN_LPT)
            hAddPrinterLibs
        end select

        proc = astNewFUNCT( f )

        '' filename as string
        if( astNewPARAM( proc, filename ) = NULL ) then
            exit function
        end if

        '' byval mode as integer
        if( astNewPARAM( proc, fmode ) = NULL ) then
            exit function
        end if

        '' byval access as integer
        if( astNewPARAM( proc, faccess ) = NULL ) then
            exit function
        end if

        '' byval lock as integer
        if( astNewPARAM( proc, flock ) = NULL ) then
            exit function
        end if

        '' byval filenum as integer
        if( astNewPARAM( proc, filenum ) = NULL ) then
            exit function
        end if

        '' byval len as integer
        if( astNewPARAM( proc, flen ) = NULL ) then
            exit function
        end if
    end select

    ''
    if( not isfunc ) then
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if

end function

'':::::
function rtlFileClose( byval filenum as ASTNODE ptr, _
					   byval isfunc as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim reslabel as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_FILECLOSE)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    ''
    if( not isfunc ) then
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if

end function

'':::::
function rtlFileSeek( byval filenum as ASTNODE ptr, _
					  byval newpos as ASTNODE ptr ) as integer static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim reslabel as FBSYMBOL ptr

	function = FALSE

	''
	f = ifuncTB(FB_RTL_FILESEEK)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    '' byval newpos as integer
    if( astNewPARAM( proc, newpos ) = NULL ) then
 		exit function
 	end if

    ''
    if( env.clopt.resumeerr ) then
    	reslabel = symbAddLabel( "" )
    	astAdd( astNewLABEL( reslabel ) )
    else
    	reslabel = NULL
    end if

    ''
    function = rtlErrorCheck( proc, reslabel, lexLineNum( ) )

end function

'':::::
function rtlFileTell( byval filenum as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	''
	f = ifuncTB(FB_RTL_FILETELL)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    ''
    function = proc

end function

'':::::
function rtlFilePut( byval filenum as ASTNODE ptr, _
					 byval offset as ASTNODE ptr, _
					 byval src as ASTNODE ptr, _
					 byval isfunc as integer ) as ASTNODE ptr static

    dim as ASTNODE ptr proc
    dim as integer dtype, lgt, isstring
    dim as FBSYMBOL ptr f, reslabel

    function = NULL

	''
	dtype = astGetDataType( src )
	isstring = hIsString( dtype )
	if( isstring ) then
		f = ifuncTB(FB_RTL_FILEPUTSTR)
	else
		f = ifuncTB(FB_RTL_FILEPUT)
	end if

    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    '' byval offset as integer
    if( offset = NULL ) then
    	offset = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, offset ) = NULL ) then
 		exit function
 	end if

    '' value as any | s as string
    if( astNewPARAM( proc, src ) = NULL ) then
 		exit function
 	end if

    '' byval valuelen as integer
    if( isstring ) then
    	STRGETLEN( src, dtype, lgt )
    else
    	lgt = hCalcExprLen( src )
    end if

   	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ) ) = NULL ) then
		exit function
	end if

    ''
    if( not isfunc ) then
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if

end function

'':::::
function rtlFilePutArray( byval filenum as ASTNODE ptr, _
						  byval offset as ASTNODE ptr, _
						  byval src as ASTNODE ptr, _
					 	  byval isfunc as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dtype as integer
    dim reslabel as FBSYMBOL ptr

    function = NULL

	''
	f = ifuncTB(FB_RTL_FILEPUTARRAY)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    '' byval offset as integer
    if( offset = NULL ) then
    	offset = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, offset ) = NULL ) then
 		exit function
 	end if

    '' array() as any
    if( astNewPARAM( proc, src ) = NULL ) then
    	exit function
    end if

    ''
    if( not isfunc ) then
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
	    	reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if

end function

'':::::
function rtlFileGet( byval filenum as ASTNODE ptr, _
					 byval offset as ASTNODE ptr, _
					 byval dst as ASTNODE ptr, _
					 byval isfunc as integer ) as ASTNODE ptr static

    dim as ASTNODE ptr proc
    dim as integer dtype, lgt, isstring
    dim as FBSYMBOL ptr f, reslabel

    function = NULL

	''
	dtype = astGetDataType( dst )
	isstring = hIsString( dtype )
	if( isstring ) then
		f = ifuncTB(FB_RTL_FILEGETSTR)
	else
		f = ifuncTB(FB_RTL_FILEGET)
	end if

    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    '' byval offset as integer
    if( offset = NULL ) then
    	offset = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, offset ) = NULL ) then
 		exit function
 	end if

    '' value as any
    if( astNewPARAM( proc, dst ) = NULL ) then
 		exit function
 	end if

    '' byval valuelen as integer
    if( isstring ) then
    	STRGETLEN( dst, dtype, lgt )
    else
    	lgt = hCalcExprLen( dst )
    end if

    if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

    ''
    if( not isfunc ) then
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if

end function

'':::::
function rtlFileGetArray( byval filenum as ASTNODE ptr, _
						  byval offset as ASTNODE ptr, _
						  byval dst as ASTNODE ptr, _
					 	  byval isfunc as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim dtype as integer
    dim reslabel as FBSYMBOL ptr

	function = NULL

	''
	f = ifuncTB(FB_RTL_FILEGETARRAY)
    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    '' byval offset as integer
    if( offset = NULL ) then
    	offset = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
    end if
    if( astNewPARAM( proc, offset ) = NULL ) then
 		exit function
 	end if

    '' array() as any
    if( astNewPARAM( proc, dst ) = NULL ) then
    	exit function
    end if

    ''
    if( not isfunc ) then
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if

end function

'':::::
function rtlFileStrInput( byval bytesexpr as ASTNODE ptr, _
						  byval filenum as ASTNODE ptr ) as ASTNODE ptr static
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

    function = NULL

	''
	f = ifuncTB(FB_RTL_FILESTRINPUT)
    proc = astNewFUNCT( f )

    '' byval bytes as integer
    if( astNewPARAM( proc, bytesexpr ) = NULL ) then
 		exit function
 	end if

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    ''
    function = proc

end function

'':::::
function rtlFileLineInput( byval isfile as integer, _
						   byval expr as ASTNODE ptr, _
						   byval dstexpr as ASTNODE ptr, _
					       byval addquestion as integer, _
					       byval addnewline as integer ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr, args as integer
	dim lgt as integer, dtype as integer

	function = FALSE

	''
	if( isfile ) then
		f = ifuncTB(FB_RTL_FILELINEINPUT)
		args = 4
	else
		f = ifuncTB(FB_RTL_CONSOLELINEINPUT)
		args = 6
	end if

    proc = astNewFUNCT( f )

    '' "byval filenum as integer" or "text as string "
    if( (not isfile) and (expr = NULL) ) then
		expr = astNewVAR( hAllocStringConst( "", 0 ), NULL, 0, IR_DATATYPE_FIXSTR )
	end if

    if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    '' dst as any
    if( astNewPARAM( proc, dstexpr ) = NULL ) then
 		exit function
 	end if

	'' byval dstlen as integer
	dtype = astGetDataType( dstexpr )
	STRGETLEN( dstexpr, dtype, lgt )
	if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
 		exit function
 	end if

	'' byval fillrem as integer
	if( astNewPARAM( proc, astNewCONSTi( dtype = IR_DATATYPE_FIXSTR, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    	exit function
    end if

    if( args = 6 ) then
    	'' byval addquestion as integer
 		if( astNewPARAM( proc, astNewCONSTi( addquestion, IR_DATATYPE_INTEGER ) ) = NULL ) then
 			exit function
 		end if

    	'' byval addnewline as integer
    	if( astNewPARAM( proc, astNewCONSTi( addnewline, IR_DATATYPE_INTEGER ) ) = NULL ) then
 			exit function
 		end if
    end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlFileInput( byval isfile as integer, _
					   byval expr as ASTNODE ptr, _
				       byval addquestion as integer, _
				       byval addnewline as integer ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr, args as integer

	function = FALSE

	''
	if( isfile ) then
		f = ifuncTB(FB_RTL_FILEINPUT)
		args = 1
	else
		f = ifuncTB(FB_RTL_CONSOLEINPUT)
		args = 3
	end if

    proc = astNewFUNCT( f )

    '' "byval filenum as integer" or "text as string "
    if( (not isfile) and (expr = NULL) ) then
		expr = astNewVAR( hAllocStringConst( "", 0 ), NULL, 0, IR_DATATYPE_FIXSTR )
	end if

	if( astNewPARAM( proc, expr ) = NULL ) then
 		exit function
 	end if

    if( args = 3 ) then
    	'' byval addquestion as integer
    	if( astNewPARAM( proc, astNewCONSTi( addquestion, IR_DATATYPE_INTEGER ) ) = NULL ) then
 			exit function
 		end if

    	'' byval addnewline as integer
    	if( astNewPARAM( proc, astNewCONSTi( addnewline, IR_DATATYPE_INTEGER ) ) = NULL ) then
 			exit function
 		end if
    end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlFileInputGet( byval dstexpr as ASTNODE ptr ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr, args as integer
    dim lgt as integer, dtype as integer

	function = FALSE

	''
	args = 1
	dtype = astGetDataType( dstexpr )
	select case as const dtype
	case IR_DATATYPE_FIXSTR, IR_DATATYPE_STRING, IR_DATATYPE_CHAR
		f = ifuncTB(FB_RTL_INPUTSTR)
		args = 3
	case IR_DATATYPE_BYTE, IR_DATATYPE_UBYTE
		f = ifuncTB(FB_RTL_INPUTBYTE)
	case IR_DATATYPE_SHORT, IR_DATATYPE_USHORT
		f = ifuncTB(FB_RTL_INPUTSHORT)
	case IR_DATATYPE_INTEGER, IR_DATATYPE_UINT, IR_DATATYPE_ENUM
		f = ifuncTB(FB_RTL_INPUTINT)
	case IR_DATATYPE_LONGINT, IR_DATATYPE_ULONGINT
		f = ifuncTB(FB_RTL_INPUTLONGINT)
	case IR_DATATYPE_SINGLE
		f = ifuncTB(FB_RTL_INPUTSINGLE)
	case IR_DATATYPE_DOUBLE
		f = ifuncTB(FB_RTL_INPUTDOUBLE)
	case IR_DATATYPE_USERDEF
		exit function							'' illegal
	case else
		if( dtype >= IR_DATATYPE_POINTER ) then	'' non-sense but..
			f = ifuncTB(FB_RTL_INPUTINT)
			dstexpr = astNewCONV( INVALID, IR_DATATYPE_UINT, NULL, dstexpr )
		end if
	end select

    proc = astNewFUNCT( f )

    '' dst as any
    if( astNewPARAM( proc, dstexpr ) = NULL ) then
 		exit function
 	end if

    if( args > 1 ) then
		'' byval dstlen as integer
		STRGETLEN( dstexpr, dtype, lgt )
		if( astNewPARAM( proc, astNewCONSTi( lgt, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
 			exit function
 		end if

		'' byval fillrem as integer
		if( astNewPARAM( proc, astNewCONSTi( dtype = IR_DATATYPE_FIXSTR, IR_DATATYPE_INTEGER ), IR_DATATYPE_INTEGER ) = NULL ) then
    		exit function
    	end if
    end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlFileLock( byval islock as integer, _
					  byval filenum as ASTNODE ptr, _
					  byval iniexpr as ASTNODE ptr, _
					  byval endexpr as ASTNODE ptr ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

	''
	if( islock ) then
		f = ifuncTB(FB_RTL_FILELOCK)
	else
		f = ifuncTB(FB_RTL_FILEUNLOCK)
	end if

    proc = astNewFUNCT( f )

    '' byval filenum as integer
    if( astNewPARAM( proc, filenum ) = NULL ) then
 		exit function
 	end if

    '' byval inipos as integer
    if( astNewPARAM( proc, iniexpr ) = NULL ) then
 		exit function
 	end if

    '' byval endpos as integer
    if( astNewPARAM( proc, endexpr ) = NULL ) then
 		exit function
 	end if

    astAdd( proc )

    function = TRUE

end function

'':::::
function rtlFileRename( byval filename_new as ASTNODE ptr, _
                        byval filename_old as ASTNODE ptr, _
                        byval isfunc as integer ) as ASTNODE ptr static
    dim proc as ASTNODE ptr
    dim reslabel as FBSYMBOL ptr

	function = NULL

    proc = astNewFUNCT( ifuncTB(FB_RTL_FILERENAME) )

    '' byval filename_old as string
    if( astNewPARAM( proc, filename_old ) = NULL ) then
 		exit function
 	end if

    '' byval filename_new as integer
    if( astNewPARAM( proc, filename_new ) = NULL ) then
 		exit function
 	end if

    ''
    if( not isfunc ) then
    	if( env.clopt.resumeerr ) then
    		reslabel = symbAddLabel( "" )
    		astAdd( astNewLABEL( reslabel ) )
    	else
    		reslabel = NULL
    	end if

    	function = iif( rtlErrorCheck( proc, reslabel, lexLineNum( ) ), proc, NULL )

    else
    	function = proc
    end if

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' gfx
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
private function hMultinput_cb( byval sym as FBSYMBOL ptr ) as integer static
    static as integer libsAdded = FALSE

	if( not libsadded ) then
		libsAdded = TRUE

		select case env.clopt.target
		case FB_COMPTARGET_WIN32
			symbAddLib( "user32" )
		end select
	end if

	function = TRUE

end function

'':::::
private function hGfxlib_cb( byval sym as FBSYMBOL ptr ) as integer static
    static as integer libsAdded = FALSE

	if( not libsadded ) then
		libsAdded = TRUE

		symbAddLib( "fbgfx" )

		select case as const env.clopt.target
		case FB_COMPTARGET_WIN32
			symbAddLib( "user32" )
			symbAddLib( "gdi32" )
			symbAddLib( "winmm" )

		case FB_COMPTARGET_LINUX
#ifdef TARGET_LINUX
			fbAddLibPath( "/usr/X11R6/lib" )
#endif

			symbAddLib( "X11" )
			symbAddLib( "Xext" )
			symbAddLib( "Xpm" )
			symbAddLib( "Xrandr" )
			symbAddLib( "Xrender" )
			symbAddLib( "pthread" )

		end select
	end if

	return TRUE
end function

'':::::
function rtlGfxPset( byval target as ASTNODE ptr, _
					 byval targetisptr as integer, _
					 byval xexpr as ASTNODE ptr, _
					 byval yexpr as ASTNODE ptr, _
					 byval cexpr as ASTNODE ptr, _
					 byval coordtype as integer, _
					 byval ispreset as integer ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim targetmode as integer

	function = FALSE

	f = ifuncTB(FB_RTL_GFXPSET)
    proc = astNewFUNCT( f, )

 	'' byref target as any
 	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval x as single
 	if( astNewPARAM( proc, xexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval y as single
 	if( astNewPARAM( proc, yexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval color as uinteger
 	if( astNewPARAM( proc, cexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval coordtype as integer
 	if( astNewPARAM( proc, astNewCONSTi( coordtype, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	'' byval ispreset as integer
 	if( astNewPARAM( proc, astNewCONSTi( ispreset, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxPoint( byval target as ASTNODE ptr, _
					  byval targetisptr as integer, _
					  byval xexpr as ASTNODE ptr, _
					  byval yexpr as ASTNODE ptr ) as ASTNODE ptr
	dim proc as ASTNODE ptr, f as FBSYMBOL ptr
	dim targetmode as integer

	function = NULL

	f = ifuncTB(FB_RTL_GFXPOINT)
	proc = astNewFUNCT( f )

	'' byref target as any
	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval x as single
 	if( astNewPARAM( proc, xexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval y as single
 	if( yexpr = NULL ) then
 		yexpr = astNewCONSTf( -1, IR_DATATYPE_SINGLE )
 	end if
 	if( astNewPARAM( proc, yexpr ) = NULL ) then
 		exit function
 	end if

	function = proc

end function

'':::::
function rtlGfxLine( byval target as ASTNODE ptr, _
					 byval targetisptr as integer, _
					 byval x1expr as ASTNODE ptr, _
					 byval y1expr as ASTNODE ptr, _
					 byval x2expr as ASTNODE ptr, _
					 byval y2expr as ASTNODE ptr, _
					 byval cexpr as ASTNODE ptr, _
					 byval linetype as integer, _
					 byval styleexpr as ASTNODE ptr, _
					 byval coordtype as integer ) as integer

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim targetmode as integer

	function = FALSE

	f = ifuncTB(FB_RTL_GFXLINE)
    proc = astNewFUNCT( f )

 	'' byref target as any
 	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval x1 as single
 	if( astNewPARAM( proc, x1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y1 as single
 	if( astNewPARAM( proc, y1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval x2 as single
 	if( astNewPARAM( proc, x2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y2 as single
 	if( astNewPARAM( proc, y2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval color as uinteger
 	if( astNewPARAM( proc, cexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval linetype as integer
 	if( astNewPARAM( proc, astNewCONSTi( linetype, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	'' byval style as uinteger
 	if( styleexpr = NULL ) then
 		styleexpr = astNewCONSTi( &h0000FFFF, IR_DATATYPE_UINT )
 	end if
 	if( astNewPARAM( proc, styleexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval coordtype as integer
 	if( astNewPARAM( proc, astNewCONSTi( coordtype, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxCircle( byval target as ASTNODE ptr, _
					   byval targetisptr as integer, _
					   byval xexpr as ASTNODE ptr, _
					   byval yexpr as ASTNODE ptr, _
					   byval radexpr as ASTNODE ptr, _
					   byval cexpr as ASTNODE ptr, _
					   byval aspexpr as ASTNODE ptr, _
					   byval iniexpr as ASTNODE ptr, _
					   byval endexpr as ASTNODE ptr, _
					   byval fillflag as integer, _
					   byval coordtype as integer ) as integer

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim targetmode as integer

	function = FALSE

	f = ifuncTB(FB_RTL_GFXCIRCLE)
    proc = astNewFUNCT( f )

 	'' byref target as any
 	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval x as single
 	if( astNewPARAM( proc, xexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval y as single
 	if( astNewPARAM( proc, yexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval radians as single
 	if( astNewPARAM( proc, radexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval color as uinteger
 	if( astNewPARAM( proc, cexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval aspect as single
 	if( aspexpr = NULL ) then
 		aspexpr = astNewCONSTf( 0.0, IR_DATATYPE_SINGLE )
 	end if
 	if( astNewPARAM( proc, aspexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval arcini as single
 	if( iniexpr = NULL ) then
 		iniexpr = astNewCONSTf( 0.0, IR_DATATYPE_SINGLE )
 	end if
 	if( astNewPARAM( proc, iniexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval arcend as single
 	if( endexpr = NULL ) then
 		endexpr = astNewCONSTf( 3.141593*2, IR_DATATYPE_SINGLE )
 	end if
 	if( astNewPARAM( proc, endexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval fillflag as integer
 	if( astNewPARAM( proc, astNewCONSTi( fillflag, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	'' byval coordtype as integer
 	if( astNewPARAM( proc, astNewCONSTi( coordtype, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxPaint( byval target as ASTNODE ptr, _
					  byval targetisptr as integer, _
					  byval xexpr as ASTNODE ptr, _
					  byval yexpr as ASTNODE ptr, _
					  byval pexpr as ASTNODE ptr, _
					  byval bexpr as ASTNODE ptr, _
					  byval coord_type as integer ) as integer

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim targetmode as integer
    dim pattern as integer

    function = FALSE

	f = ifuncTB(FB_RTL_GFXPAINT)
	proc = astNewFUNCT( f )

 	'' byref target as any
 	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval x as single
 	if( astNewPARAM( proc, xexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval y as single
 	if( astNewPARAM( proc, yexpr ) = NULL ) then
 		exit function
 	end if

	'' byval color as uinteger
	pattern = astGetDataType( pexpr )
	if( ( pattern = IR_DATATYPE_FIXSTR ) or ( pattern = IR_DATATYPE_STRING ) ) then
		pattern = TRUE
		if( astNewPARAM( proc, astNewCONSTi( &hFFFF0000, IR_DATATYPE_INTEGER ) ) = NULL ) then
 			exit function
 		end if
	else
		pattern = FALSE
		if( astNewPARAM( proc, pexpr ) = NULL ) then
 			exit function
 		end if
	end if

	'' byval border_color as uinteger
	if( astNewPARAM( proc, bexpr ) = NULL ) then
 		exit function
 	end if

	'' pattern as string, byval mode as integer
	if( pattern = TRUE ) then
		if( astNewPARAM( proc, pexpr ) = NULL ) then
 			exit function
 		end if
		if( astNewPARAM( proc, astNewCONSTi( 1, IR_DATATYPE_INTEGER ) ) = NULL ) then
 			exit function
 		end if
	else
    	if( astNewPARAM( proc, astNewVAR( hAllocStringConst( "", 0 ), NULL, 0, IR_DATATYPE_FIXSTR ) ) = NULL ) then
 			exit function
 		end if
		if( astNewPARAM( proc, astNewCONSTi( 0, IR_DATATYPE_INTEGER ) ) = NULL ) then
 			exit function
 		end if
	end if

	'' byval coord_type as integer
	if( astNewPARAM( proc, astNewCONSTi( coord_type, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxDraw( byval target as ASTNODE ptr, _
					 byval targetisptr as integer, _
					 byval cexpr as ASTNODE ptr )
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim targetmode as integer

	function = FALSE

	f = ifuncTB(FB_RTL_GFXDRAW)
    proc = astNewFUNCT( f )

 	'' byref target as any
 	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' cmd as string
 	if( astNewPARAM( proc, cexpr ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxView( byval x1expr as ASTNODE ptr, _
					 byval y1expr as ASTNODE ptr, _
					 byval x2expr as ASTNODE ptr, _
					 byval y2expr as ASTNODE ptr, _
			    	 byval fillexpr as ASTNODE ptr, _
			    	 byval bordexpr as ASTNODE ptr, _
			    	 byval screenflag as integer ) as integer

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

	f = ifuncTB(FB_RTL_GFXVIEW)
    proc = astNewFUNCT( f )

 	'' byval x1 as integer
 	if( x1expr = NULL ) then
        x1expr = astNewCONSTi( -32768, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, x1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y1 as integer
 	if( y1expr = NULL ) then
        y1expr = astNewCONSTi( -32768, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, y1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval x2 as integer
 	if( x2expr = NULL ) then
        x2expr = astNewCONSTi( -32768, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, x2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y2 as integer
 	if( y2expr = NULL ) then
        y2expr = astNewCONSTi( -32768, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, y2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval fillcolor as uinteger
 	if( fillexpr = NULL ) then
 		fillexpr = astNewCONSTi( &hFEFF00FF, IR_DATATYPE_UINT )
 	end if
 	if( astNewPARAM( proc, fillexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval bordercolor as uinteger
 	if( bordexpr = NULL ) then
 		bordexpr = astNewCONSTi( &hFEFF00FF, IR_DATATYPE_UINT )
 	end if
 	if( astNewPARAM( proc, bordexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval screenflag as integer
 	if( astNewPARAM( proc, astNewCONSTi( screenflag, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxWindow( byval x1expr as ASTNODE ptr, _
					   byval y1expr as ASTNODE ptr, _
					   byval x2expr as ASTNODE ptr, _
					   byval y2expr as ASTNODE ptr, _
					   byval screenflag as integer ) as integer

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

	f = ifuncTB(FB_RTL_GFXWINDOW)
    proc = astNewFUNCT( f )

 	'' byval x1 as single
 	if( x1expr = NULL ) then
        x1expr = astNewCONSTf( 0.0, IR_DATATYPE_SINGLE )
    end if
 	if( astNewPARAM( proc, x1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y1 as single
 	if( y1expr = NULL ) then
        y1expr = astNewCONSTf( 0.0, IR_DATATYPE_SINGLE )
    end if
 	if( astNewPARAM( proc, y1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval x2 as single
 	if( x2expr = NULL ) then
        x2expr = astNewCONSTf( 0.0, IR_DATATYPE_SINGLE )
    end if
 	if( astNewPARAM( proc, x2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y2 as single
 	if( y2expr = NULL ) then
        y2expr = astNewCONSTf( 0.0, IR_DATATYPE_SINGLE )
    end if
 	if( astNewPARAM( proc, y2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval screenflag as integer
 	if( astNewPARAM( proc, astNewCONSTi( screenflag, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxPalette ( byval attexpr as ASTNODE ptr, _
						 byval rexpr as ASTNODE ptr, _
						 byval gexpr as ASTNODE ptr, _
						 byval bexpr as ASTNODE ptr, _
						 byval isget as integer ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim defval as integer, targetmode as integer

	function = FALSE

    f = ifuncTB( iif( isget, FB_RTL_GFXPALETTEGET, FB_RTL_GFXPALETTE ) )
	proc = astNewFUNCT( f )

	if( isget ) then
		targetmode = FB_ARGMODE_BYREF
		defval = 0
	else
		targetmode = FB_ARGMODE_BYVAL
		defval = -1
	end if

 	'' byval attr as integer
 	if( attexpr = NULL ) then
        attexpr = astNewCONSTi( -1, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, attexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval r as integer
 	if( rexpr = NULL ) then
        rexpr = astNewCONSTi( -1, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, rexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval g as integer
 	if( gexpr = NULL ) then
 		targetmode = FB_ARGMODE_BYVAL
        gexpr = astNewCONSTi( defval, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, gexpr, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval b as integer
 	if( bexpr = NULL ) then
        bexpr = astNewCONSTi( defval, IR_DATATYPE_INTEGER )
    end if
 	if( astNewPARAM( proc, bexpr, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxPaletteUsing ( byval arrayexpr as ASTNODE ptr, _
							  byval isget as integer ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr

	function = FALSE

    f = ifuncTB( iif( isget, FB_RTL_GFXPALETTEGETUSING, FB_RTL_GFXPALETTEUSING ) )
	proc = astNewFUNCT( f )

 	'' byref array as integer
 	if( astNewPARAM( proc, arrayexpr ) = NULL ) then
 		exit function
 	end if

 	''
 	astAdd( proc )

	function = TRUE

end function

'':::::
function rtlGfxPut( byval target as ASTNODE ptr, _
					byval targetisptr as integer, _
					byval xexpr as ASTNODE ptr, _
					byval yexpr as ASTNODE ptr, _
			   		byval arrayexpr as ASTNODE ptr, _
			   		byval isptr as integer, _
					byval x1expr as ASTNODE ptr, _
					byval x2expr as ASTNODE ptr, _
					byval y1expr as ASTNODE ptr, _
					byval y2expr as ASTNODE ptr, _
			   		byval mode as integer, _
			   		byval alphaexpr as ASTNODE ptr, _
			   		byval funcexpr as ASTNODE ptr, _
			   		byval coordtype as integer ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim targetmode as integer
    dim argmode as integer
    dim reslabel as FBSYMBOL ptr

    function = FALSE

	f = ifuncTB(FB_RTL_GFXPUT)
    proc = astNewFUNCT( f )

 	'' byref target as any
 	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval x as single
 	if( astNewPARAM( proc, xexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval y as single
 	if( astNewPARAM( proc, yexpr ) = NULL ) then
 		exit function
 	end if

 	'' byref array as any
	if( isptr ) then
		argmode = FB_ARGMODE_BYVAL
	else
		argmode = INVALID
	end if
 	if( astNewPARAM( proc, arrayexpr, INVALID, argmode ) = NULL ) then
 		exit function
 	end if

 	'' area coordinates, if any
 	if( x1expr = NULL ) then
 		x1expr = astNewCONSTi( &hFFFF0000, IR_DATATYPE_INTEGER )
 		x2expr = astNewCONSTi( &hFFFF0000, IR_DATATYPE_INTEGER )
 		y1expr = astNewCONSTi( &hFFFF0000, IR_DATATYPE_INTEGER )
 		y2expr = astNewCONSTi( &hFFFF0000, IR_DATATYPE_INTEGER )
 	end if
  	if( astNewPARAM( proc, x1expr ) = NULL ) then
 		exit function
 	end if
  	if( astNewPARAM( proc, x2expr ) = NULL ) then
 		exit function
 	end if
  	if( astNewPARAM( proc, y1expr ) = NULL ) then
 		exit function
 	end if
  	if( astNewPARAM( proc, y2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval coordtype as integer
 	if( astNewPARAM( proc, astNewCONSTi( coordtype, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	'' byval mode as integer
 	if( astNewPARAM( proc, astNewCONSTi( mode, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

	'' byval alpha as integer
	if( alphaexpr = NULL ) then
		alphaexpr = astNewCONSTi( -1, IR_DATATYPE_INTEGER )
	end if
 	if( astNewPARAM( proc, alphaexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval func as function( src as uinteger, dest as uinteger ) as uinteger
 	if( funcexpr = NULL ) then
 		funcexpr = astNewCONSTi(0, IR_DATATYPE_INTEGER )
 	end if
 	if( astNewPARAM( proc, funcexpr ) = NULL ) then
 		exit function
 	end if

    ''
    if( env.clopt.resumeerr ) then
    	reslabel = symbAddLabel( "" )
    	astAdd( astNewLABEL( reslabel ) )
    else
    	reslabel = NULL
    end if

	function = rtlErrorCheck( proc, reslabel, lexLineNum( ) )

end function

'':::::
function rtlGfxGet( byval target as ASTNODE ptr, _
					byval targetisptr as integer, _
					byval x1expr as ASTNODE ptr, _
					byval y1expr as ASTNODE ptr, _
					byval x2expr as ASTNODE ptr, _
					byval y2expr as ASTNODE ptr, _
			   		byval arrayexpr as ASTNODE ptr, _
			   		byval isptr as integer, _
			   		byval symbol as FBSYMBOL ptr, _
			   		byval coordtype as integer ) as integer

    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim targetmode as integer
    dim argmode as integer
    dim reslabel as FBSYMBOL ptr

    function = FALSE

	f = ifuncTB(FB_RTL_GFXGET)
    proc = astNewFUNCT( f )

 	'' byref target as any
 	if( target = NULL ) then
 		target = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 		targetmode = INVALID
 	else
		if( targetisptr ) then
			targetmode = FB_ARGMODE_BYVAL
		else
			targetmode = INVALID
		end if
	end if
	if( astNewPARAM( proc, target, INVALID, targetmode ) = NULL ) then
 		exit function
 	end if

 	'' byval x1 as single
 	if( astNewPARAM( proc, x1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y1 as single
 	if( astNewPARAM( proc, y1expr ) = NULL ) then
 		exit function
 	end if

 	'' byval x2 as single
 	if( astNewPARAM( proc, x2expr ) = NULL ) then
 		exit function
 	end if

 	'' byval y2 as single
 	if( astNewPARAM( proc, y2expr ) = NULL ) then
 		exit function
 	end if

 	'' byref array as any
	if( isptr ) then
		argmode = FB_ARGMODE_BYVAL
	else
		argmode = INVALID
	end if
 	if( astNewPARAM( proc, arrayexpr, INVALID, argmode ) = NULL ) then
 		exit function
 	end if

 	'' byval coordtype as integer
 	if( astNewPARAM( proc, astNewCONSTi( coordtype, IR_DATATYPE_INTEGER ) ) = NULL ) then
 		exit function
 	end if

 	'' array() as any
 	if( not isptr ) then
 		arrayexpr = astNewVAR( symbol, NULL, 0, symbGetType( symbol ) )
 	else
 		arrayexpr = astNewCONSTi( NULL, IR_DATATYPE_POINTER+IR_DATATYPE_VOID )
 	end if
 	if( astNewPARAM( proc, arrayexpr, INVALID, argmode ) = NULL ) then
 		exit function
 	end if

    ''
    if( env.clopt.resumeerr ) then
    	reslabel = symbAddLabel( "" )
    	astAdd( astNewLABEL( reslabel ) )
    else
    	reslabel = NULL
    end if

	function = rtlErrorCheck( proc, reslabel, lexLineNum( ) )

end function

'':::::
function rtlGfxScreenSet( byval wexpr as ASTNODE ptr, _
						  byval hexpr as ASTNODE ptr, _
						  byval dexpr as ASTNODE ptr, _
						  byval pexpr as ASTNODE ptr, _
						  byval fexpr as ASTNODE ptr, _
						  byval rexpr as ASTNODE ptr ) as integer
    dim proc as ASTNODE ptr, f as FBSYMBOL ptr
    dim reslabel as FBSYMBOL ptr

	function = FALSE

	f = ifuncTB( iif( hexpr = NULL, FB_RTL_GFXSCREENSET, FB_RTL_GFXSCREENRES ) )
    proc = astNewFUNCT( f )

 	'' byval m as integer
 	if( astNewPARAM( proc, wexpr ) = NULL ) then
 		exit function
 	end if

	if( hexpr <> NULL ) then
		if( astNewPARAM( proc, hexpr ) = NULL ) then
			exit function
		end if
	end if

 	'' byval d as integer
 	if( dexpr = NULL ) then
 		dexpr = astNewCONSTi( 8, IR_DATATYPE_INTEGER )
 	end if
 	if( astNewPARAM( proc, dexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval depth as integer
 	if( pexpr = NULL ) then
 		pexpr = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 	end if
 	if( astNewPARAM( proc, pexpr ) = NULL ) then
 		exit function
 	end if

 	'' byval fullscreen s integer
 	if( fexpr = NULL ) then
 		fexpr = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
 	end if
 	if( astNewPARAM( proc, fexpr ) = NULL ) then
 		exit function
 	end if

	'' byval refresh_rate as integer
	if( rexpr = NULL ) then
		rexpr = astNewCONSTi( 0, IR_DATATYPE_INTEGER )
	end if
 	if( astNewPARAM( proc, rexpr ) = NULL ) then
 		exit function
 	end if

    ''
    if( env.clopt.resumeerr ) then
    	reslabel = symbAddLabel( "" )
    	astAdd( astNewLABEL( reslabel ) )
    else
    	reslabel = NULL
    end if

	function = rtlErrorCheck( proc, reslabel, lexLineNum( ) )

end function

'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
'' profiling
'':::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

'':::::
private function hGetProcName( byval proc as FBSYMBOL ptr ) as ASTNODE ptr
	dim procname as string
	dim s as FBSYMBOL ptr
	dim expr as ASTNODE ptr, at as integer

	if( proc = NULL ) then
		s = hAllocStringConst( "(??)", -1 )
	else
		procname = symbGetName( proc )

		if( fbGetNaming() = FB_COMPNAMING_WIN32 ) then
			procname = mid$( procname, 2)
			at = instr( procname, "@" )
			if( at ) then
				procname = mid$( procname, 1, at - 1 )
			end if
        end if

		if( len( procname ) and 3 ) then
			procname += string$( 4 - ( len( procname ) and 3 ), 32 )
		end if
		s = hAllocStringConst( procname, -1 )
	end if

	expr = astNewADDR( IR_OP_ADDROF, astNewVAR( s, NULL, 0, IR_DATATYPE_FIXSTR ), s, NULL )

	function = expr

end function

'':::::
function rtlProfileBeginCall( byval symbol as FBSYMBOL ptr ) as ASTNODE ptr
	dim proc as ASTNODE ptr, f as FBSYMBOL ptr, s as FBSYMBOL ptr
	dim expr as ASTNODE ptr

	function = NULL

	f = ifuncTB(FB_RTL_PROFILEBEGINCALL)
	proc = astNewFUNCT( f, NULL, TRUE )

	expr = hGetProcName( symbol )
	if( astNewPARAM( proc, expr, INVALID, FB_ARGMODE_BYVAL ) = NULL ) then
		exit function
	end if

	function = proc

end function

'':::::
function rtlProfileEndCall( ) as ASTNODE ptr
    dim proc as ASTNODE ptr
    dim f as FBSYMBOL ptr

	function = NULL

	f = ifuncTB(FB_RTL_PROFILEENDCALL)
    proc = astNewFUNCT( f, NULL, TRUE )

  	function = proc

end function
