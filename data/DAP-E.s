               JOB  1401 Demonstration Assurance Program Extended(DAP-E)                                
     *         CTL  6611
     ***************************************************************************
     *
     *     
     *     Provide a program to assure all components of the
     *     1401 System are operational. To be used by demonstrators
     *     before running demonstrations for Museum visitors. 
     *     All functions under sense switch control
     *
     *     Program written in Autocoder
     *     Programmer:  Dan McInnis  
     *     Date:        May 30, 2007 
     *     Revised:     July 3, 2007 
     *     
     ****************************************************************************
     *
               ORG  333
     *
     *
     *     Clear card reader storage and set word mark at location 1
     *
     BEGIN     CS   080                     *CLEAR READ AREA
               SW   001                     *SET WORK MARK READ AREA
     *     Clear print storage           
     START     CS   332                     *CLEAR PRINT AREA
               CS
               H                            *HALT - CHECK PAPER,PUNCH
     * Read data card and test validity 
               CC   A                       *SKIP PAPER TO BEGINNING LINE
               BLC  LASTC                   *TEST FOR DATA CARD
               R                            *READ DATA CARD
     CLOOP     C    012,CDDATA              *COMPARE NEXT 12 CHARACTERS 
               BU   RDER1                   *bRANCH UNEQUAL - READ ERROR 
               SW   *-14                    *SET WORD MARK FOR ADDRESS
               A    @12@,*-19               *ADD 12 TO COMPARE ADDRESS
               C    *-26,@084@              *COMPARE ADDRESS FOR LAST FULL COMPARE
               BE   ENDRD                   *IF LAST TO TO PARTIAL COMPARE
               CW   *-37                    *CLEAR WORK MARK FROM ADDRESS
               B    CLOOP                   *LOOP TO COMPARE NEXT 12 CHARACTERS
     ENDRD     SW   073                     *SET LAST AREA WORK MARK
               C    80,CDDATA-4             *COMPARE LAST 8 CHARACTERS 
               BU   RDER2                   *BRANCH UNEQUAL - CARD READ ERROR
               CW   073                     *CLEAR WORK MARK READ AREA
               MCW  080,280                 *MOVE DATA CARD TO PRINT AREA
               W                            *PIRNT DATA CARD
               MCW  080,180                 *MOVE DATA CARD TO PUNCH AREA
               P                            *PUNCH DATA CARD
               CS   299                     *CLEAR PRINT AREA
               CC   A                       *SKIP PAPER TO BEGINNING OF PAGE
     * END OF ASSURANCE ROUTINE
               BLC  END                     *NO CARDS, QUIT
               B    SS1B                    *START READ CYCLE
     END       H    SS1B                    *HALT RESTART PROGRAM TO TEST SS
     *  Begin test sense switch routines
     SS1B      MCW  SSOFF,SSTEST            *RESET TEST INDICATOR
               BSS  SSB,B                   *TEST SS B  CARD READ
     SS1C      BSS  SSC,C                   *TEST SS C  PUNCH
     SS1D      BSS  SSD,D                   *TEST SS C  PRINT
     SS1E      BSS  SSE,E                   *TEST SS E  TAPE  
               C    SSOFF,SSTEST            *TEST SS SET
               BE   END                     *NO SS QUIT
               BLC  END                     *LAST CARD QUIT
               B    SS1B                    *CYCLE THROUGH UNTIL READER EMPTY OR NO SS'S  
     SSB       BLC  LASTC                   *TEST FOR LAST CARD - QUIT
               R                            *READ CARD
               MCW  SSON,SSTEST             *SS INDICATOR ON
               B    SS1C                    *RETURN TO CYCLE
     SSC       MCW  080,180                 *MOVE IN NEW DATA
               P                            *PUNCH DATA
               MCW  SSON,SSTEST             *SS INDICATOR ON
               B    SS1D                    *RETURN TO CYCLE
     SSD       MCW  080,280                 *MOVE DATA TO PRINT AREA
               W                            *PRINT DATA
               MCW  SSON,SSTEST             *SS INDICATOR ON
               B    SS1E                    *RETURN TO CYCLE
     SSE       LCA  GRPMRK,081              *GROUP MARK TO CARD AREA
               CS   299                     *CLEAR PRINT AREA
               LCA  GRPMRK,281              *GROUP MARK TO PRINT AREA
               WT   1,001                   *WRITE CARD AREA TO TAPE 1
               B    TPER1,L                 *ERROR WRITING
               BSS  BCKSP,B                 *READING CARDS
               WT   1,001                   *ELSE JUST WRITING TAPE
               B    TPER1,L                 *ERROR WRITING
     BCKSP     BSP  1                       *BACKSPACE OVER LAST RECORD
               RT   1,201                   *READ IN RECORD
               B    TPER1,L                 *ERROR READING
               SW   201                     *SW PRINT AREA
               C    280,080                 *COMPARE RECORD CHARACTERS
               BU   TPER1                   *TAPE DATA READ ERROR
               MCW  SSON,SSTEST             *SS INDICATOR ON
               BSS  SSTP,B                  *PRINT SS ON 
               B    SS1B                    *RETURN TO START OF CYCLE
     SSTP      W    SS1B                    *PRINT DATA AND RETURN                              
     *  START OF ERROR HALT LOCATIONS 
     LASTC     H    END
     RDER1     H    END  
     RDER2     H    END
     TPER1     H    END                            
     *  START OF LITERAL LOCATION
     SSON      DCW  @Y@
     SSOFF     DCW  @N@
     SSTEST    DCW  @N@
     CDDATA    DCW  @0123456789SK@          *DATA
     GRPMRK    DCW  @"@                     *GROUP MARK 
               END  BEGIN
