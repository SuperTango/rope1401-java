/* i1401_iq.c: IBM 1407 inquiry terminal

   Copyright (c) 1993-2004, Robert M. Supnik

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the "Software"),
   to deal in the Software without restriction, including without limitation
   the rights to use, copy, modify, merge, publish, distribute, sublicense,
   and/or sell copies of the Software, and to permit persons to whom the
   Software is furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
   ROBERT M SUPNIK BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
   IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
   CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

   Except as contained in this notice, the name of Robert M Supnik shall not
   be used in advertising or otherwise to promote the sale, use or other dealings
   in this Software without prior written authorization from Robert M Supnik.

   inq		1407 inquiry terminal

   22-Dec-02	RMS	Added break support
   07-Sep-01	RMS	Moved function prototypes
   14-Apr-99	RMS	Changed t_addr to unsigned
*/

#include "i1401_defs.h"
#include <ctype.h>

extern volatile int32 stop_cpu;
extern uint8 M[];
extern int32 BS, iochk, ind[64];
extern char ascii_to_bcd[128], bcd_to_ascii[64];
extern UNIT cpu_unit;

int32 inq_char = 033;					/* request inq */
t_stat inq_svc (UNIT *uptr);
t_stat inq_reset (DEVICE *dptr);

void puts_tty (char *cptr);

/* INQ data structures

   inq_dev	INQ device descriptor
   inq_unit	INQ unit descriptor
   inq_reg	INQ register list
*/

UNIT inq_unit = { UDATA (&inq_svc, 0, 0), KBD_POLL_WAIT };

REG inq_reg[] = {
	{ ORDATA (INQC, inq_char, 7) },
	{ FLDATA (INR, ind[IN_INR], 0) },
	{ FLDATA (INC, ind[IN_INC], 0) },
	{ DRDATA (TIME, inq_unit.wait, 24), REG_NZ + PV_LEFT },
	{ NULL }  };

DEVICE inq_dev = {
	"INQ", &inq_unit, inq_reg, NULL,
	1, 10, 31, 1, 8, 7,
	NULL, NULL, &inq_reset,
	NULL, NULL, NULL };

/* Terminal I/O

   Modifiers have not been checked; legal modifiers are R and W
*/

t_stat inq_io (int32 flag, int32 mod)
{
int32 i, t, wm_seen = 0;

ind[IN_INC] = 0;					/* clear inq clear */
switch (mod) {						/* case on mod */
case BCD_R:						/* input */
/*	if (ind[IN_INR] == 0) return SCPE_OK;		/* return if no req */
	ind[IN_INR] = 0;				/* clear req */
	puts_tty ("[Enter]\r\n");			/* prompt */
	for (i = 0; M[BS] != (BCD_GRPMRK + WM); i++) {	/* until GM + WM */
	    while (((t = sim_poll_kbd ()) == SCPE_OK) ||
		    (t & SCPE_BREAK)) {
		if (stop_cpu) return SCPE_STOP;  }	/* interrupt? */
	    if (t < SCPE_KFLAG) return t;		/* if not char, err */
	    t = t & 0177;
	    if ((t == '\r') || (t == '\n')) break;
	    if (t == inq_char) {			/* cancel? */
		ind[IN_INC] = 1;			/* set indicator */
		puts_tty ("\r\n[Canceled]\r\n");
		return SCPE_OK;  }
	    if (i && ((i % INQ_WIDTH) == 0)) puts_tty ("\r\n");
	    sim_putchar (t);				/* echo */
	    if (flag == MD_WM) {			/* word mark mode? */
		if ((t == '~') && (wm_seen == 0)) wm_seen = WM;
		else {
		    M[BS] = wm_seen | ascii_to_bcd[t];
		    wm_seen = 0; }  }
	    else M[BS] = (M[BS] & WM) | ascii_to_bcd[t];
	    if (!wm_seen) BS++;
	    if (ADDR_ERR (BS)) {
		BS = BA | (BS % MAXMEMSIZE);
		return STOP_NXM;  }  }
	puts_tty ("\r\n");
	M[BS++] = BCD_GRPMRK + WM;
	return SCPE_OK;
case BCD_W:						/* output */
	for (i = 0; (t = M[BS++]) != (BCD_GRPMRK + WM); i++) {
	    if ((flag == MD_WM) && (t & WM)) {
		if (i && ((i % INQ_WIDTH) == 0)) puts_tty ("\r\n");
		sim_putchar ('~');  }
	    if (i && ((i % INQ_WIDTH) == 0)) puts_tty ("\r\n");
	    sim_putchar (bcd_to_ascii[t & CHAR]);
	    if (ADDR_ERR (BS)) {
		BS = BA | (BS % MAXMEMSIZE);
		return STOP_NXM;  }  }
	puts_tty ("\r\n");
	return SCPE_OK;
default:
	return STOP_INVM;  }				/* invalid mod */
}

/* Unit service - polls for WRU or inquiry request */

t_stat inq_svc (UNIT *uptr)
{
int32 temp;

sim_activate (&inq_unit, inq_unit.wait);		/* continue poll */
if ((temp = sim_poll_kbd ()) < SCPE_KFLAG) return temp;	/* no char or error? */
if ((temp & 0177) == inq_char) ind[IN_INR] = 1;		/* set indicator */
return SCPE_OK;
}

/* Output multiple characters */

void puts_tty (char *cptr)
{
if (cptr == NULL) return;
while (*cptr != 0) sim_putchar (*cptr++);
return;
}

/* Reset routine */

t_stat inq_reset (DEVICE *dptr)
{
ind[IN_INR] = ind[IN_INC] = 0;				/* clear indicators */
sim_activate (&inq_unit, inq_unit.wait);		/* activate poll */
return SCPE_OK;
}
