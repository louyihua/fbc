# include "fbcu.bi"
#include once "fbgfx.bi"

namespace fbc_tests.gfx.draw_

private sub testRememberPenPositionForXCommand cdecl( )
	const SCREEN_W = 20
	const SCREEN_H = 20

	CU_ASSERT( screenres( SCREEN_W, SCREEN_H, 32, , fb.GFX_NULL ) = 0 )

	CU_ASSERT( point(  0,  0 ) = rgb(0,0,0) )
	CU_ASSERT( point(  4,  4 ) = rgb(0,0,0) )
	CU_ASSERT( point(  9,  9 ) = rgb(0,0,0) )
	CU_ASSERT( point( 14, 14 ) = rgb(0,0,0) )
	CU_ASSERT( point( 19, 19 ) = rgb(0,0,0) )

	const BORDERCOLOR = rgb(255,0,0)
	const FILLCOLOR = rgb(255,255,255)

	dim fillcommand as string = "P " & FILLCOLOR & "," & BORDERCOLOR
	draw "BM 4,4 C" & BORDERCOLOR & " R10 D10 L10 U10 BM +1,1 X" & @fillcommand

	CU_ASSERT( point(  0,  0 ) = rgb(0,0,0)  )
	CU_ASSERT( point(  4,  4 ) = BORDERCOLOR )
	CU_ASSERT( point(  9,  9 ) = FILLCOLOR   )
	CU_ASSERT( point( 14, 14 ) = BORDERCOLOR )
	CU_ASSERT( point( 19, 19 ) = rgb(0,0,0)  )
end sub

private sub testRememberPenPositionFromXCommand cdecl( )
	const SCREEN_W = 20
	const SCREEN_H = 20

	CU_ASSERT( screenres( SCREEN_W, SCREEN_H, 32, , fb.GFX_NULL ) = 0 )

	CU_ASSERT( point(  0,  0 ) = rgb(0,0,0) )
	CU_ASSERT( point(  4,  4 ) = rgb(0,0,0) )
	CU_ASSERT( point(  9,  9 ) = rgb(0,0,0) )
	CU_ASSERT( point( 14, 14 ) = rgb(0,0,0) )
	CU_ASSERT( point( 19, 19 ) = rgb(0,0,0) )

	const BORDERCOLOR = rgb(255,0,0)
	const FILLCOLOR = rgb(255,255,255)

	dim movecommand as string = "BM 4,4"
	draw "X" & @movecommand & " C" & BORDERCOLOR & " R10 D10 L10 U10 BM +1,1 P " & FILLCOLOR & "," & BORDERCOLOR

	CU_ASSERT( point(  0,  0 ) = rgb(0,0,0)  )
	CU_ASSERT( point(  4,  4 ) = BORDERCOLOR )
	CU_ASSERT( point(  9,  9 ) = FILLCOLOR   )
	CU_ASSERT( point( 14, 14 ) = BORDERCOLOR )
	CU_ASSERT( point( 19, 19 ) = rgb(0,0,0)  )
end sub

private sub ctor( ) constructor
	fbcu.add_suite( "fbc_tests.gfx.draw" )
	fbcu.add_test( "remember pen position for X command", @testRememberPenPositionForXCommand )
	fbcu.add_test( "remember pen position from X command", @testRememberPenPositionFromXCommand )
end sub

end namespace
