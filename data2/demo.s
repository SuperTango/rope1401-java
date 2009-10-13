     ***************************************************************************
     *     SSSSS = CARD SEQUENCE NUMBER          ********** = LABEL
     *     OPER- = OPERATION                     OPERANDS--- = OPERATION
     **********OPER-OPERANDS----------------------------------------------------     
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
     X3        DCW  000                *INDEX REGISTER 3
     *              
               ORG  350
     *
               DCW  @THIS IS A VISITOR DEMO JULY 17,2009@
     *         VISITOR PARAMETERS ARE READ FROM A PUNCHED CARD
     *         WITH COMMA SEPARATED FIELDS
     *
     COMMA     DCW  @,@
     BLANK     DCW  @ @
     NAME      DCW  #20
     TOWN      DCW  #20
     FRIEND    DCW  #20
     PET       DCW  #20
               ORG  500
     PTR       DCW  @230@
               DCW  @234@
               DCW  @251@
               DCW  @238@
     PARM      DCW  #20                  *PLACE HOLDER ACCESSED BY PRINT SUBR
     COLM      DCW  #3                   *COLUMN NUMBER IN PRINT AREA
     ONE       DCW  @001@
     TWO       DCW  @002@
     THREE     DCW  @003@
     *
     START     H                         *STOP HERE FIRST
               R                         *READ PARAMETER CARD
               SW   RDBUFF               *DELIMIT CARD INPUT AREA
               MCW  @000@,X1             *INITIALIZE X1 REGISTER
               MCW  @020@,X2             *INITIALIZE X2 REGISTER
     CHKIT     BCE  FOUND,001&X1,,       *GO IF COMMA FOUND
               MA   ONE,X1               *INCREMENT X1
               BCE  STORY,X1-1,8         *GO IF END OF CARD
               B    CHKIT                *TRY AGAIN
     FOUND     SW   002&X1               *DELIMIT FIELD
               MCW  000&X1,NAME&X2       *COPY THE FIELD
               MA   @020@,X2             *INCREMENT X2
               MA   ONE,X1               *MOVE PAST COMMA
               B    CHKIT                *GO FOR NEXT FIELD
     *
     *HERE WHEN PARAMETER CARD IS COMPLETELY PROCESSED
     STORY     MCW  @020@,X2             *NEW USE FOR X2 
               MCW  @000@,X1             *X1 USED FOR COLUMN NUMBER
               MCW  @000@,X3             *X3 USED FOR PTR TO COL NUM 
               CS   080
     L001      R                         *READ STORY CARD(S)
               SW   RDBUFF               *DELIMIT CARD INPUT AREA
               MCW  NAME&X2,PARM         *PASS PARAMETER TO PRINT SUBRTN
               B    PRINT                *CALL SUBROUTINE
               A    @020@,X2             *BUMP TO NEXT PARAMETER
               B    DONE,A               *GO IF NO MORE INPUT CARDS
               B    L001                 *FETCH NEXT INPUT CARD
     DONE      NOP  PTR&3,PTR&6
               NOP    
     *******************************************************************************
     *
     * SUBROUTINE TO INSERT TEXT & PARAMETERS INTO THE PRINT AREA
     * UPON ARRIVAL B REG HOLDS NEXT INSTRUCTION IN CALLING ROUTINE
     *
     *******************************************************************************
     PRINT     SBR  LAST&3               *LINKAGE BACK TO MAIN ROUTINE
               MCW  080,280              *COPY STORY CARD TO PRINT AREA
               MCW  PTR&X3,X1            *GET COLUMN NUMBER IN X1 REG
               MCW  PARM,000&X1          *INSERT PARAMETER INTO PRINT AREA
               W 
               DC   @S@                  *SUPPRESS SPACING
               W                         *PRINT SECOND IMPRESSION
               CS   332
               CS
               W                         *DOUBLE SPACE
               MA   THREE,X3             *BUMP TO NEXT COLUMN
     LAST      B    000                  *TO BE FILLED IN BY FIRST INST (ABOVE)
               END  START
