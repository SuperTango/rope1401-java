     ***************************************************************************
     *     SSSSS = CARD SEQUENCE NUMBER          ********** = LABEL
     *     OPER- = OPERATION                     OPERANDS--- = OPERATION
SSSSS**********OPER-OPERANDS----------------------------------------------------     **********|****|***********************************************************
               JOB  FIRST PROGRAM
               CTL  6611  *6=16,000C;6=16,000T;1=OBJDECK;,1=MODADD     
     *
               ORG  87
     X1        DCW  000                 *INDEX REGISTER 1
               DC   00
     X2        DCW  000                 *INDEX REGISTER 2
               DC   00
     X3        DCW  0000                *INDEX REGISTER 3
     *              
               ORG  350
     *
               DCW  @LOOP PROGRAM@ 07-11-2009@
     COUNT     DCW  0000                *A PLACE TO COUNT LOOPS
     MYCHAR    DCW  @S@
     *******************************************************
     *DEFINE THE PRINT LINE SO IT CAN BE MOVED TO THE PRINT
     *BUFFER VIA CHAINED MCW
     ******************************************************* 
     FTOP      DCW  @FOUND THE CHARACTER (@
     FCHAR     DCW  @ @
     FMEND     DCW  @) AT COLUMN  @
     FCOLM     DCW  000
     *******************************************************
     *DEFINE THE PRINT LINE SO IT CAN BE MOVED TO THE PRINT
     *BUFFER VIA CHAINED MCW
     ******************************************************* 
     NFTOP     DCW  @DID NOT FIND THE CHARACTER (@
     NFCHAR    DCW  @ @
     NFTAG     DCW  @) @
     *************************************************************
     *
     START     H
     *
     * HOW TO DO A SIMPLE LOOP OF 10 LOOPS
     * 100 WORKS THE SAME WAY WITH BCE  LOOP, COUNT-2
     * 132 CAN WORK THE SAME WAY IF YOU INITILIZE COUNTER WITH 78 
     * AND LOOK FOR A 2 IN COUNT-2
     *
     ************************************************************
     *
               ZA   @0@,COUNT           *INITIALIZE THE COUNTER
     LOOP      NOP                      *WORK
               NOP                      *WORK         
               NOP                      *WORK
               A    @1@,COUNT           *ADD 1 TO COUNT
               BCE  LOOP,COUNT-1,0      *HAVE WE DONE 10 LOOPS?
     *
     ************************************************************
     *
     * HOW TO LOOP USING NUMERIC OVERFLOW
     *
     ************************************************************
     *
               ZA   @9990@,COUNT        *INITIALIZE THE COUNTER
     LOOP2     NOP                      *WORK
               NOP                      *WORK         
               NOP                      *WORK
               A    @1@,COUNT           *ADD 1 TO COUNT
               BAV  EXIT2               *HAVE WE DONE 10 LOOPS?
               B    LOOP2               *DO ANOTHER LOOP
     EXIT2     NOP                      *DO THE NEXT THING
     *
     ************************************************************
     *
     * HOW TO LOOP USING CONVENTIAL CODE
     *
     ************************************************************
     *
               ZA   @0@,COUNT           *INITIALIZE THE COUNTER
     LOOP3     NOP                      *WORK
               NOP                      *WORK         
               NOP                      *WORK
               A    @1@,COUNT           *ADD 1 TO COUNT
               MZ   COUNT-1,COUNT       *CLEAR THE UNITS ZONE BITS
               C    @0010@,COUNT        *SEE IF COUNT = 10
               BL   LOOP3               *NOT THERE YET
               NOP                      *GO ON TO NEXT FUNCTION
     *
     ************************************************************
     *
     * HOW TO SEARCH FOR A CHARACTER IN THE CARD BUFFER
     *
     ************************************************************
     *
               CS   080                 *CLEAR THE CARD BUFFER
               MCW  MYCHAR,045          *PUT IT OUT THERE
               MCW  @000@,X1            *INITIALIZE THE X1 REGISTER
               MCW  MYCHAR,CHKIT&7      *MODIFY THE INSTRUCTION
     CHKIT     BCE  FOUND,001&X1,?      *DID WE FIND IT?
               MA   @001@,X1            *INCEREMENT THE X1
               BCE  NOMAT,X1-1,8        *DID WE GET TO 80?
               B    CHKIT               *TRY AGAIN
     *
     FOUND     CS   332                 *CLEAR PRINT BUFFER
               CS                       *CLEAR PRINT BUFFER
               MCS  X1,FCOLM            *MOVE X1 AND CLEAR LEADING ZERO
               SW   FCOLM,-2            *MCS REMOVES WORDMARK
               MCW  MYCHAR,FCHAR        *MOVE THE CHARACTER INTO THE LINE
     *
     ***********************************************************
     *   BY ALIGNING THE VARAIABLES GOING TO THE PRINT LINE
     *   YOU CAN CHAIN THE MOVES. THIS MAKES IT EASIER TO GET
     *   THE CORRECT SPACING ON THE PRINT LINE.
     *********************************************************** 
               MLC  FCOLM,240           *MOVE FIRST FIELD
               MLC                      *MOVE SECOND FIELD
               MLC                      *MOVE THIRD FIELD
               MLC                      *MOVE FOURTH FIELD
               W                        *PRINT
               B    NXTPGM              *LOAD NEXT PROGRAM
     *
     NOMAT     MCW  MYCHAR,NFCHAR       *MOVE CHARACTER INTO MESSAGE
               MCW  NFTAG,235           *MOVE FIRST FIELD
               MCW                      *MOVE SECOND FIELD
               MCW                      *MOVE THIRD FIELD 
               W                        *PRINT
               B    NXTPGM              *LOAD NEXT PROGRAM
     ***********************************************************************
     NXTPGM    CC   1                   *JUMP TO TOP OF PAGE
               NOP  999,999             *PUT 999 IN ADDRESS REGISTER
               H                        *HALT BEFORE GOING TO THE NEXT PROGRAM
               CS   332                 *CLEAR UPPER PRINT BUFFER
               CS                       *CLEAR LOWER PRINT BUFFER
               CS                       *CLEAR PUNCH BUFFER
               CS                       *CLEAR READ BUFFER
               SW   001                 *SET FIRST WM
     MORE      R                        *READ ANOTHER CARD
               BCE  001,001,,           *IF IT IS A COMMA, GO TO THE CODE
               B    MORE                *READ ANOTHER
               NOP                      *TRAILER WITH A WM
               END  START
