               JOB  EDIT PROGRAM
               INCLDPREAMBLE.S
     *
               DCW  @THIS IS A PERSONALIZED STORY 12 AUGUST 2009@
     *         VISITOR PARAMETERS ARE READ FROM A PUNCHED CARD
     *         WITH COMMA SEPARATED FIELDS
     *
               ORG  400
     M1        DSA  15999                *DECREMENT BY ONE
     M2        DSA  15998                *DECREMENT BY TWO
     M3        DSA  15997                *DECREMENT BY THREE
     COMMA     DCW  @,@
     BLANK     DCW  @ @
     NAME      DC   #16
               DC   #16
               DC   #16
               DC   #16
               DC   #16
     LENGTH    DCW  #3
               DCW  #3
               DCW  #3
               DCW  #3
               DCW  #3
     NICK      DCW  #1                   *PARM NUMBER FOLLOWS '&'
     SKIP      DCW  #1                   *ONE MEANS '&  ON THIS LINE
     ZERO      DCW  @000@
     ONE       DCW  @001@
     TWO       DCW  @002@
     THREE     DCW  @003@
     SIX       DCW  @006@
     SIXTN     DCW  @016@
     EIGHTY    DCW  @080@
     MARK      DCW  @999@                *INDEX VALUE HOLDER
     CHARS     DCW  #3                   *COUNT CHARACTERS IN PARM
     POS       DCW  @080@                *COLUMN NUMBER OF LAST CHAR
     *
     START     H                         *STOP HERE FIRST
     **************************************************************************
     *
     *PROCESS THE HEADER CARD OF PERSONAL NAMES
     *STORE THE NAME AND THE LENGTH OF THE NAME
     *
     **************************************************************************
               R                         *READ PARAMETER CARD
               SW   RDBUFF               *DELIMIT CARD INPUT AREA
               MCW  @000@,X1             *INITIALIZE X1 REGISTER
               MCW  SIXTN,X2             *INITIALIZE X2 REGISTER
               MCW  @000@,X3
               MCW  @000@,CHARS
     CHKIT     BCE  FOUND,001&X1,,       *GO IF COMMA FOUND
               MA   ONE,X1               *INCREMENT X1
               MA   ONE,CHARS            *COUNT LENGTH OF PARM
               BCE  STORY,X1-1,8         *GO IF COLUMN 80
               B    CHKIT                *TRY AGAIN
     FOUND     SW   002&X1               *DELIMIT FIELD
               LCA  000&X1,NAME&X2       *COPY THE PARM TO STORAGE
               MA   M2,CHARS             *ADJUST FOR PRINT
               MCW  CHARS,LENGTH&X3      *SAVE THE LENGTH COUNT
               MCW  @000@,CHARS          *RESET LENGTH COUNT
               MA   SIXTN,X2             *BUMP TO NEXT PARM STORAGE
               MA   THREE,X3             *BUMP TO NEXT LENGTH COUNT
               MA   ONE,X1               *MOVE PAST COMMA
               B    CHKIT                *GO FOR NEXT FIELD
     **************************************************************************
     *
     *READ STORY CARDS
     *
     **************************************************************************
     STORY     MCW  SIXTN,X2             *USE X2 TO ADVANCE THRU PARMS 
               MCW  ZERO,X1              *X1 USED FOR COLUMN NUMBER
               MCW  ZERO,X3              *X3 USED FOR PTR TO COL NUM 
     L001      CS   080                  *CLEAR CARD INPUT
               CS   PRBUFF&131
               CS                        *CLEAR PRINT BUFFER
               MCW  @0@,SKIP             *CLEAR THE BIT
               R                         *READ STORY CARD(S)
               SW   RDBUFF               *DELIMIT CARD INPUT AREA
               B    PRINT                *CALL SUBROUTINE
               BCE  L004,SKIP,1          *GO IF '&' THIS LINE
               MCW  RDBUFF&80,PRBUFF&80  *COPY ENTIRE LINE 
               W                         *PRINT IT
     L004      B    DONE,A               *GO IF NO MORE STORY CARDS
               B    L001                 *FETCH NEXT STORY CARD
     DONE      NOP  
     *    
     ***************************************************************************
     *
     * SUBROUTINE TO SCAN INPUT FOR PERSONAL INSERT
     * UPON ARRIVAL B REG HOLDS NEXT INSTRUCTION IN CALLING ROUTINE
     *
     ***************************************************************************
     PRINT     SBR  LAST&3              *LINKAGE BACK TO CALLING ROUTINE
               CS   PRBUFF&80           *CLEAR WORK BUFFER
               MCW  ZERO,X1             *USE X1 TO ADVANCE THRU CARD IMG
     L002      C    @080@,X1            *IS IT LAST COLUMN OF STORY CARD?
               B    LAST,S              *GO IF NO MORE COLUMNS
               MA   ONE,X1              *BUMP TO NEXT CHAR
               BCE  INSERT,RDBUFF&X1,&  *INSPECT CHAR FOR &
               B    L002                *GO IF NOT '&'
     INSERT    CS   PRBUFF&132
               CS
               MCW  SIXTN,X2            *RESET TO PARM 1
               MCW  ZERO,X3             *RESET TO LENGTH 1
               B    MEASUR              *DETERMINE COLUMN OF LAST CHAR
               MCW  ZERO,X3
               MCW  X1,MARK             *SAVE INDEX
               MA   ONE,X1              *ADVANCE TO PARM NUMBER
               MCW  RDBUFF&X1,NICK      *PICK UP PARM NUMBER
               MCW  BLANK,RDBUFF&X1     *ERASE PARM NUMBER
     L005      BCE  L006,NICK,1         *SELECT PARM
               MA   SIXTN,X2            *ADVANCE TO NEXT PARM
               MA   THREE,X3            *ADVANCE TO NEXT LENGTH
               MA   M1,NICK
               B    L005                
     L006      MA   LENGTH&X3,X1        *RIGHT ADJUST INSERT
               MCW  NAME&X2,PRBUFF&X1   *INSERT PERS PARAMETER
               W                        *PRINT AND...
               DC   @S@                 *...SPACE SUPPRESS
               MCW  MARK,X1             *PICK UP INDEX
               MA   M1,X1               *BACKUP ONE CHAR
               MCW  RDBUFF&X1,PRBUFF&X1 *COPY STORY LINE LEFT PART 
               MA   ONE,X1              *POINT TO '&'
               MCW  BLANK,RDBUFF&X1     *ERASE '&'
               MA   TWO,X1
               SW   RDBUFF&X1           *SET LIMIT ON RIGHT SIDE TRANSFER
               MCW  POS,X2
               MCW  POS,X1
               MA   LENGTH&X3,X1
               MA   ONE,X1   
               MCW  RDBUFF&X2,PRBUFF&X1 *COPY STORY LINE PART RIGHT PART
               W                        *PRINT PERSONALIZED LINE
               MCW  ONE,SKIP            *THIS LINE CONTAINS '&'
     LAST      B    000                 *TO BE FILLED IN BY FIRST INST (ABOVE)
     *                                  *RETURN TO CALLER
     ***************************************************************************
     *
     *SUBROUTINE TO DETERMINE POSITION OF LAST CHARACTER ON THE INPUT LINE
     *
     ***************************************************************************
     MEASUR    SBR  EXIT&3              *INKAGE  BACK TO CALLING ROUTINE
               MCW  EIGHTY,X3            *BEGIN AT LAST COLUMN
     L009      BCE  L008,RDBUFF&X3,     *TEST FOR BLANK
               MA   ONE,X3              *CORRECTION
               MCW  X3,POS              *RETURN VALUE
               B    EXIT                *HERE IF LAST CHAR FOUND
     L008      MA   M1,X3               *BACK ONE COLUMN
               B    L009
     EXIT      B    000                 *TO BE FILLED IN BY FIRST INST (ABOVE)
               END  START
