/*
 * Simple program which is vulnerable to a command line bufer overflow
 * exploit.
 * 
 * The code passes the first command line argument to a function which
 * uses it without testing for length, or bounds-checking it in any
 * way.
 *
 * A suitably crafted command line will allow a user to exectute
 * arbitary code via this flaw.
 * 
 * Steve
 * --
 *  www.steve.org.uk
 */

#include <stdio.h>
#include <stdlib.h>


/*
 * Print a simple greeting to the named user
 */
void foo( char *user )
{
   char greeting[1024];

   sprintf( greeting, "Hello %s", user );
   printf( "%s\n", greeting );
}


/*
 * Test we got at least one command line argument, if so print them
 * a greeting.
 */
int main( int argc, char *argv[] )
{
   if ( argc >= 2 )
      foo( argv[1] );
   else
      printf("Usage: %s name\n", argv[0] );

   return 0;
}
