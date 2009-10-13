     ***************************************************************************
     *     SSSSS = CARD SEQUENCE NUMBER          ********** = LABEL
     *     OPER- = OPERATION                     OPERATION--- = OPERATION
SSSSS**********OPER-OPERANDS----------------------------------------------------     **********|****|***********************************************************
               JOB  FIRST PROGRAM
               CTL  6611  *6=16,000C;6=16,000T;1=OBJDECK;,1=MODADD     
     *
     P001      EQU  201                 *DEFINE FIRST CHARACTER OF PRINT BUFFER
     P132      EQU  332                 *DEFINE THE LAST CHARAACTER OF THE PRINT BUFFER
     p201      EQU  201                 *DEFINE THE FIRST CHARACTER OF THE PRINT BUFFER
               ORG  87
     X1        DCW  000                 *INDEX REGISTER 1
               DCW  11                  *IDENTIFING FILLER
     X2        DCW  000                 *INDEX REGISTER 2
               DCW  22                  *IDENTIFING FILLER
     X3        DCW  000                 *INDEX REGISTER 3
               DCW  33                  *IDENTIFING FILLER
     *
               ORG  340                 *ORG JUST AFTER PRINT BUFFER
     *
     IDENT     DCW  @Powers of 2 version 4 program 03/02/2009@  *ID THE PROGRAM DECK
     HOLD      DCW  0
     PAT1      DCW  @,   ,   ,   ,   ,   ,   ,   ,   ,   ,   ,   @
     PAT2      DC   @,   ,   ,   ,   ,   ,   ,   ,   ,   ,   ,   @
     PAT3      DC   @,   ,   ,   ,   ,   ,   ,   ,   ,   ,   ,   @
     AREG      DS   99                  *A PLACE TO ADD STUFF
     CRDCNT    DCW  00                  *CARD COUNTER
     *
     FLADD     EQU  FSTLIN
     FSTLIN    DCW  @FIVE HUNDRED FORTY SIX UNTRIGINTILLION       @
               DCW  @EIGHT HUNDRED TWELVE TRIGINTILLION           @
               DCW  @SIX HUNDRED EIGHTY ONE NOVEMVIGINTILLION     @
               DCW  @ONE HUNDRED NINETY FIVE OCTOVIGINTILLION     @
               DCW  @SEVEN HUNDRED FIFTY TWO SEPTEMVIGINTILLION   @
               DCW  @NINE HUNDRED EIGHTY ONE SESVIGINTILLION      @
               DCW  @NINETY THREE QUINQUAVIGINTILLION             @
               DCW  @ONE HUNDRED TWENTY FIVE QUATTUORVIGINTILLION @
               DCW  @FIVE HUNDRED FIFTY SIX TRESVIGINTILLION      @
               DCW  @SEVEN HUNDRED SEVENTY NINE DUOVIGINTILLION   @
               DCW  @FOUR HUNDRED FIVE UNVIGINTILLION             @
               DCW  @THREE HUNDRED FORTY ONE VIGINTILLION         @
               DCW  @THREE HUNDRED THIRTY EIGHT NOVENDECILLION    @
               DCW  @TWO HUNDRED NINETY TWO OCTODECILLION         @
               DCW  @THREE HUNDRED FIFTY SEVEN SEPTENDECILLION    @
               DCW  @SEVEN HUNDRED TWENTY THREE SEDECILLION       @
               DCW  @THREE HUNDRED THREE QUINQUADECILLION         @
               DCW  @ONE HUNDRED NINE QUATTUORDECILLION           @
               DCW  @ONE HUNDRED SIX TREDECILLION                 @
               DCW  @FOUR HUNDRED FORTY TWO DUODECILLION          @
               DCW  @SIX HUNDRED FIFTY ONE UNDECILLION            @
               DCW  @SIX HUNDRED TWO DECILLION                    @
               DCW  @FOUR HUNDRED EIGHTY EIGHT NONILLION          @
               DCW  @TWO HUNDRED FORTY NINE OCTILLION             @
               DCW  @SEVEN HUNDRED NINETY NINE SEPTILLION         @
               DCW  @EIGHT HUNDRED FORTY THREE SEXTILLION         @
               DCW  @NINE HUNDRED EIGHTY QUINTILLION              @
               DCW  @EIGHT HUNDRED FIVE QUADRILLION               @
               DCW  @EIGHT HUNDRED SEVENTY EIGHT TRILLION         @
               DCW  @TWO HUNDRED NINETY FOUR BILLION              @
               DCW  @TWO HUNDRED FIFTY FIVE MILLION               @
               DCW  @SEVEN HUNDRED SIXTY THREE THOUSAND           @
               DCW  @FOUR HUNDRED FIFTY SIX                       @
     *
     *
     START     CS   332                 *CLEAR 332 TO 300
               CS                       *CLEAR 299 TO 200            
               SW   201                 *SET A WORD MARK AT THE BEGINNING 
               SW   AREG-98                
               ZA   @002@,AREG          *SET THE STARTING NUMBER
     L1        MLCWAPAT3,332
               MCE  AREG,332
     L2        MCW  @000@,X1            *SETUP X1 TO ZERO
     L23       BCE  L27,p201&X1,        *IS IT A SPACE?
               BCE  L25,P201&X1,0       *IS IT A ZERO?
               BCE  L25,P201&X1,,       *IS IT A COMMA?
               B    L29                 *FIRST NON SPACE OR COMMA
     *
     L25       MCW  @ @,P201&X1            *CLEAR THE COMMA OR ZERO
     L27       MA   @001@,X1            *INCREMENT X1 
               B    L23                 *CHECK THE NEXT POSITION
     L29       MCW  202,HOLD            *SAFE KEEPING
               W                        *PRINT IT
               MCW  HOLD,202            *PUT IT BACK
     L35       A    AREG,AREG           *DOUBLE IT
               BAV  L4                  *BRANCH ON OVERFLOW
               B    L1                  *TRY AGAIN
     L4        CS   332
               CS
               W     
               MCW  @THE NUMBER ABOVE IS 2 RAISED TO THE 328 POWER@,250
               W
               CS   299                 *CLEAR STORAGE
               W                        *WRITE A SPACE LINE
               MCW  @IT IS 99 DIGITS LONG           @,236
               W                        *WRITE A SPACE LINE
               CS   299
               W                         *WRITE A BLANK LINE
               MCW  @IN SCIENTIFIC NOTATION, THIS IS@,236
               MCW  @ 5.4681268119575298109312555677941E&98@,274
               W
               CS   332                 *CLEAR 332 TO 300
               CS                       *CLEAR 299 TO 200            
               W                        *WRITE A BLANK LINE
               SW   001                 *FIELD DEFINER
               MCW  @IN TEXT FORMAT@,219 *PUT IN HEADER
               W                        *PRINT THE LINE
               CS                       *B REG AT 333
               CS                       *CONTINUE
               SW   201
               MCW  @049@,X1            *FIRST PRINT POSITION
               MCW  @000@,X2            *FIRST PRINT MESSAGE
     READ      MCW  FSTLIN&X2,201&X1    *MOVE IN THE DATA
               W                        *WRITE DATA 
               CS                       *B REG AT 333
               CS                       *CONTINUE
               SW   201
               MA   @001@,X1            *ADD 1 TO X1
               MA   @045@,X2            *ADD 45 TO X2
               A    @1@,CRDCNT          *ADD ONE TO CARD COUNT
               MZ   CRDCNT-1,CRDCNT     *STRIP ZONE
               C    @33@,CRDCNT         *IS THIS THE 33RD CARD?
               BU   READ                *LETS GO GET MORE
               CS   332                 *CLEAR 332 TO 300
               CS                       *CLEAR 299 TO 200            
               W
               CC   1
               NOP  999,999
               H                        *HALT BEFORE GOING TO THE NEXT PROGRAM
               CC   1                   *EJECT THE PAGE
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
