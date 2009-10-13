     ***************************************************************************
     *     SSSSS = CARD SEQUENCE NUMBER          ********** = LABEL
     *     OPER- = OPERATION                     OPERANDS--- = OPERATION
SSSSS**********OPER-OPERANDS----------------------------------------------------     **********|****|***********************************************************
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
     X3        DCW  000                 *INDEX REGISTER 3
     *              
