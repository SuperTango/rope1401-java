/* i1401_cd.c: IBM 1402 card reader/punch

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

   cdr		card reader
   cdp		card punch
   stack	stackers (5 units)
	0	normal
	1	1
	2	2/8
	3	unused
	4	4

   Cards are represented as ASCII text streams terminated by newlines.
   This allows cards to be created and edited as normal files.

   14-Nov-04	WVS	Added column binary support
   25-Apr-03	RMS	Revised for extended file support
   30-May-02	RMS	Widened POS to 32b
   30-Jan-02	RMS	New zero footprint card bootstrap from Van Snyder
   29-Nov-01	RMS	Added read only unit support
   13-Apr-01	RMS	Revised for register arrays
*/

#include "i1401_defs.h"
#include <ctype.h>

extern uint8 M[];
extern int32 ind[64], ssa, iochk;
extern char bcd_to_ascii[64];
extern char ascii_to_bcd[128];
extern int16 colbin[64];
int32 s1sel, s2sel, s4sel, s8sel;
char rbuf[2 * CBUFSIZE];				/* > CDR_WIDTH */
t_stat cdr_svc (UNIT *uptr);
t_stat cdr_boot (int32 unitno, DEVICE *dptr);
t_stat cdr_attach (UNIT *uptr, char *cptr);
t_stat cd_reset (DEVICE *dptr);

/* Card reader data structures

   cdr_dev	CDR descriptor
   cdr_unit	CDR unit descriptor
   cdr_reg	CDR register list
*/

UNIT cdr_unit = {
	UDATA (&cdr_svc, UNIT_SEQ+UNIT_ATTABLE+UNIT_ROABLE, 0), 100 };

REG cdr_reg[] = {
	{ FLDATA (LAST, ind[IN_LST], 0) },
	{ FLDATA (ERR, ind[IN_READ], 0) },
	{ FLDATA (S1, s1sel, 0) },
	{ FLDATA (S2, s2sel, 0) },
	{ DRDATA (POS, cdr_unit.pos, T_ADDR_W), PV_LEFT },
	{ DRDATA (TIME, cdr_unit.wait, 24), PV_LEFT },
	{ BRDATA (BUF, rbuf, 8, 8, CDR_WIDTH) },
	{ NULL }  };

DEVICE cdr_dev = {
	"CDR", &cdr_unit, cdr_reg, NULL,
	1, 10, 31, 1, 8, 7,
	NULL, NULL, &cd_reset,
	&cdr_boot, &cdr_attach, NULL };

/* CDP data structures

   cdp_dev	CDP device descriptor
   cdp_unit	CDP unit descriptor
   cdp_reg	CDP register list
*/

UNIT cdp_unit = {
	UDATA (NULL, UNIT_SEQ+UNIT_ATTABLE, 0) };

REG cdp_reg[] = {
	{ FLDATA (ERR, ind[IN_PNCH], 0) },
	{ FLDATA (S4, s4sel, 0) },
	{ FLDATA (S8, s8sel, 0) },
	{ DRDATA (POS, cdp_unit.pos, T_ADDR_W), PV_LEFT },
	{ NULL }  };

DEVICE cdp_dev = {
	"CDP", &cdp_unit, cdp_reg, NULL,
	1, 10, 31, 1, 8, 7,
	NULL, NULL, &cd_reset,
	NULL, NULL, NULL };

/* Stacker data structures

   stack_dev	STACK device descriptor
   stack_unit	STACK unit descriptors
   stack_reg	STACK register list
*/

UNIT stack_unit[] = {
	{ UDATA (NULL, UNIT_SEQ+UNIT_ATTABLE, 0) },
	{ UDATA (NULL, UNIT_SEQ+UNIT_ATTABLE, 0) },
	{ UDATA (NULL, UNIT_SEQ+UNIT_ATTABLE, 0) },
	{ UDATA (NULL, UNIT_DIS, 0) },			/* unused */
	{ UDATA (NULL, UNIT_SEQ+UNIT_ATTABLE, 0) }  };

REG stack_reg[] = {
	{ DRDATA (POS0, stack_unit[0].pos, T_ADDR_W), PV_LEFT },
	{ DRDATA (POS1, stack_unit[1].pos, T_ADDR_W), PV_LEFT },
	{ DRDATA (POS28, stack_unit[2].pos, T_ADDR_W), PV_LEFT },
	{ DRDATA (POS4, stack_unit[4].pos, T_ADDR_W), PV_LEFT },
	{ NULL }  };

DEVICE stack_dev = {
	"STKR", stack_unit, stack_reg, NULL,
	5, 10, 31, 1, 8, 7,
	NULL, NULL, &cd_reset,
	NULL, NULL, NULL };

/* Card read routine

   Modifiers have been checked by the caller
   C modifier is recognized (column binary is implemented)
*/

t_stat read_card (int32 ilnt, int32 mod)
{
int32 i, j;
int16 c;
t_stat r;

if (sim_is_active (&cdr_unit)) {			/* busy? */
	sim_cancel (&cdr_unit);				/* cancel */
	if (r = cdr_svc (&cdr_unit)) return r;		/* process */
	}
if ((cdr_unit.flags & UNIT_ATT) == 0) return SCPE_UNATT; /* attached? */
ind[IN_READ] = ind[IN_LST] = s1sel = s2sel = 0;		/* default stacker */
for (i = 0; i < 2 * CBUFSIZE; i++) rbuf[i] = 0;		/* clear extended buf */
fgets (rbuf, (mod == BCD_C)? 2 * CBUFSIZE: CBUFSIZE,	/* rd bin/char card */
	 cdr_unit.fileref);
if (feof (cdr_unit.fileref)) return STOP_NOCD;		/* eof? */
if (ferror (cdr_unit.fileref)) {			/* error? */
	perror ("Card reader I/O error");
	clearerr (cdr_unit.fileref);
	if (iochk) return SCPE_IOERR;
	ind[IN_READ] = 1;  
	return SCPE_OK;  }
cdr_unit.pos = ftell (cdr_unit.fileref);		/* update position */
if (ssa) {						/* if last cd on */
	getc (cdr_unit.fileref);			/* see if more */
	if (feof (cdr_unit.fileref)) ind[IN_LST] = 1;	/* eof? set flag */
	fseek (cdr_unit.fileref, cdr_unit.pos, SEEK_SET);  }
if (mod == BCD_C) {					/* column binary */
	for (i = 0; i < 2 * CDR_WIDTH; i++)		/* cvt to BCD */
            rbuf[i] = ascii_to_bcd[rbuf[i]];
	for (i = 0; i < CDR_WIDTH; i++) {
	    M[CD_CBUF1 + i] = (M[CD_CBUF1 + i] & WM) | rbuf[i];
	    M[CD_CBUF2 + i] = (M[CD_CBUF2 + i] & WM) | rbuf[CDR_WIDTH + i];
	    c = (rbuf[i] << 6) | rbuf[CDR_WIDTH + i];
	    M[CDR_BUF + i] = (M[CDR_BUF + i] & WM) | 077;
	    for (j = 0; j < 64; j++) {			/* look for char */
		if (c == colbin[j]) {
		    M[CDR_BUF + i] = (M[CDR_BUF + i] & WM) | j;
		    break;
		    }					/* end if */
		}					/* end for j */
	    }						/* end for i */
	}						/* end if col bin */
else {							/* normal read */
	for (i = 0; i < CDR_WIDTH; i++) {		/* cvt to BCD */
	    rbuf[i] = ascii_to_bcd[rbuf[i]];
	    M[CDR_BUF + i] = (M[CDR_BUF + i] & WM) | rbuf[i];
	    }
	}
M[CDR_BUF - 1] = 060;					/* mem mark */
sim_activate (&cdr_unit, cdr_unit.wait);		/* activate */
return SCPE_OK;
}

/* Card reader service.  If a stacker select is active, copy to the
   selected stacker.  Otherwise, copy to the normal stacker.  If the
   unit is unattached, simply exit.
*/

t_stat cdr_svc (UNIT *uptr)
{
int32 i;

if (s1sel) uptr = &stack_unit[1];			/* stacker 1? */
else if (s2sel) uptr = &stack_unit[2];			/* stacker 2? */
else uptr = &stack_unit[0];				/* then default */
if ((uptr->flags & UNIT_ATT) == 0) return SCPE_OK;	/* attached? */
for (i = 0; i < CDR_WIDTH; i++) rbuf[i] = bcd_to_ascii[rbuf[i]];
for (i = CDR_WIDTH - 1; (i >= 0) && (rbuf[i] == ' '); i--) rbuf[i] = 0;
rbuf[CDR_WIDTH] = 0;					/* null at end */
fputs (rbuf, uptr->fileref);				/* write card */
fputc ('\n', uptr->fileref);				/* plus new line */
if (ferror (uptr->fileref)) {				/* error? */
	perror ("Card stacker I/O error");
	clearerr (uptr->fileref);
	if (iochk) return SCPE_IOERR;  }
uptr->pos = ftell (uptr->fileref);			/* update position */
return SCPE_OK;
}

/* Card punch routine

   Modifiers have been checked by the caller
   C modifier is recognized (column binary is implemented)
*/

t_stat punch_card (int32 ilnt, int32 mod)
{
int32 i;
static char pbuf[(2 * CDP_WIDTH) + 1];			/* + null */
UNIT *uptr;

if (s8sel) uptr = &stack_unit[2];			/* stack 8? */
else if (s4sel) uptr = &stack_unit[4];			/* stack 4? */
else uptr = &cdp_unit;					/* normal output */
if ((uptr->flags & UNIT_ATT) == 0) return SCPE_UNATT;	/* attached? */
ind[IN_PNCH] = s4sel = s8sel = 0;			/* clear flags */

M[CDP_BUF - 1] = 012;					/* set prev loc */
if (mod == BCD_C) {					/* column binary */
	for (i = 0; i < CDP_WIDTH; i++) {
	    pbuf[i] = bcd_to_ascii[M[CD_CBUF1 + i] & CHAR];
	    pbuf[i + CDP_WIDTH] = bcd_to_ascii[M[CD_CBUF2 + i] & CHAR];
	    }
	for (i = 2 * CDP_WIDTH - 1; (i >= 0) && (pbuf[i] == ' '); i--)
	     pbuf[i] = 0;
	pbuf[2 * CDP_WIDTH] = 0;			/* trailing null */
	}
else {							/* normal */
	for (i = 0; i < CDP_WIDTH; i++)
	    pbuf[i] = bcd_to_ascii[M[CDP_BUF + i] & CHAR];
	for (i = CDP_WIDTH - 1; (i >= 0) && (pbuf[i] == ' '); i--)
	    pbuf[i] = 0;
	pbuf[CDP_WIDTH] = 0;				/* trailing null */
	}
fputs (pbuf, uptr->fileref);				/* output card */
fputc ('\n', uptr->fileref);				/* plus new line */
if (ferror (uptr->fileref)) {				/* error? */
	perror ("Card punch I/O error");
	clearerr (uptr->fileref);
	if (iochk) return SCPE_IOERR;
	ind[IN_PNCH] = 1;  }
uptr->pos = ftell (uptr->fileref);			/* update position */
return SCPE_OK;
}

/* Select stack routine

   Modifiers have been checked by the caller
   Modifiers are 1, 2, 4, 8 for the respective stack
*/

t_stat select_stack (int32 ilnt, int32 mod)
{
if (mod == 1) s1sel = 1;
else if (mod == 2) s2sel = 1;
else if (mod == 4) s4sel = 1;
else if (mod == 8) s8sel = 1;
return SCPE_OK;
}

/* Card reader/punch reset */

t_stat cd_reset (DEVICE *dptr)
{
ind[IN_LST] = ind[IN_READ] = ind[IN_PNCH] = 0;		/* clear indicators */
s1sel = s2sel = s4sel = s8sel = 0;			/* clear stacker sel */
sim_cancel (&cdr_unit);					/* clear reader event */
return SCPE_OK;
}

/* Card reader attach */

t_stat cdr_attach (UNIT *uptr, char *cptr)
{
ind[IN_LST] = ind[IN_READ] = 0;				/* clear last card */
return attach_unit (uptr, cptr);
}

/* Bootstrap routine */

#define BOOT_START 0
#define BOOT_LEN (sizeof (boot_rom) / sizeof (unsigned char))

static const unsigned char boot_rom[] = {
	OP_R + WM, OP_NOP + WM };                       /* R, NOP */

t_stat cdr_boot (int32 unitno, DEVICE *dptr)
{
int32 i;
extern int32 saved_IS;

for (i = 0; i < CDR_WIDTH; i++) M[CDR_BUF + i] = 0;	/* clear buffer */
for (i = 0; i < BOOT_LEN; i++) M[BOOT_START + i] = boot_rom[i];
saved_IS = BOOT_START;
return SCPE_OK;
}
