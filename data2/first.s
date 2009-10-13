     ***************************************************************************
     *     SSSSS = CARD SEQUENCE NUMBER          ********** = LABEL
     *     OPER- = OPERATION                     OPERANDS--- = OPERATION
SSSSS**********OPER-OPERANDS----------------------------------------------------     **********|****|***********************************************************
               JOB  FIRST PROGRAM
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
               ORG  350
     *
               DCW  @FIRST PROGRAM DEMO 2/13/2008@
     MYDATA    DCW  @THIS IS MY FIRST PROGRAM@      *DATA TO PRINT
     *
     START     H
               CS   PRBUFF&132          *CLEAR 332 TO 300 (& == +)
               CS                       *CLEAR 299 TO 200
               CS                       *CLEAR 199 TO 100
               MCW  MYDATA,PRBUFF&25    *MOVE TAIL END OF MY DATA IN 25 LOCATIONS
               W                        *PRINT IT
               CS   PRBUFF&132          *CLEAR 332 TO 300
               CS                       *CLEAR 299 TO 200
               W                        *WRITE A BLANK LINE
               W                        *WRITE A BLANK LINE
               W                        *WRITE A BLANK LINE
               W                        *WRITE A BLANK LINE
               B    START               *BRANCH TO START
               END  START
