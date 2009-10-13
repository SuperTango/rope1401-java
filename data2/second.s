     ***************************************************************************
     *     SSSSS = CARD SEQUENCE NUMBER          ********** = LABEL
     *     OPER- = OPERATION                     OPERANDS--- = OPERATION
SSSSS**********OPER-OPERANDS----------------------------------------------------     **********|****|***********************************************************
               JOB  SECOND PROGRAM 80/80 CARD LISTER
               CTL  6611  *6=16,000C;6=16,000T;1=OBJDECK;,1=MODADD     
     *
     RDBUFF    EQU  1                   *READ BUFFER   (1-80)
     PUBUFF    EQU  101                 *PUNCH BUFFER  (101-181)
     PRBUFF    EQU  201                 *PRINT BUFFER  (201-332) 
     *
               ORG  87
     X1        DCW  000                 *INDEX REGISTER 1
               DC   00
     X2        DCW  000                 *INDEX REGISTER 2
               DC   00
     X3        DCW  0000                *INDEX REGISTER 3
     *              
               ORG  350                 *START JUST ABOVE PRINT BUFFER
     *
               DCW  @SECOND PROGRAM CARD TO PRINT COPY 2/13/2008@
     *
     START     H                        *HALT FOR A GOOD RUNNING START
               CS   PRBUFF&132          *CLEAR THE PRINT BUFFER 332 TO 300
               CS                       *CLEAR THE PRINT BUFFER 299 TO 200
               SW   RDBUFF,PRBUFF       *SET A WORD MARK AT THE BEGINNING
     *                                  *OF THE READ AND PRINT BUFFER
     *
     READ      R                        *READ A CARD
               MCW  RDBUFF&79,PRBUFF&79 *MOVE TO PRINT AREA
               W                        *PRINT IT
               B    DONE,A              *BRANCH IF LAST CARD READ
               B    READ                *ELSE GO READ ANOTHER CARD
     *
     DONE      B    START               *IF YOU LOAD ANOTHER DECK.....
               NOP                      *
               END  START
