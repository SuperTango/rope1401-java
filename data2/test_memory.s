     ***************************************************************************
     *     SSSSS = CARD SEQUENCE NUMBER          ********** = LABEL
     *     OPER- = OPERATION                     OPERANDS--- = OPERATION
SSSSS**********OPER-OPERANDS----------------------------------------------------     **********|****|***********************************************************
               JOB  EDIT PROGRAM
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
               DCW  @THIS IS A MEMORY TEST  JUNE 24, 2009@
     *         NOTE: SENSE SWITCH B ON TO STOP AFTER FIRST PATTERN
     *         NOTE: SENSE SWITCH C ON TO STOP AFTER SECOND PATTERN
     *         NOTE: REPEAT IF NEITHER SENSE SWITCH ON
     *
     PATN1     DCW  @W@                  *010101
     PATN2     DCW  @R@                  *101010
     *
     START     H
     LOOP      MCW  PATN1,15999
               MCW  15999,15998
               B    STOP1,B
     NEXTP     MCW  PATN2,15999
               MCW  15999,15998
               B    STOP2,C
               B    LOOP
     STOP1     B    NEXTP
     STOP2     B    LOOP
               NOP    
               END  START
