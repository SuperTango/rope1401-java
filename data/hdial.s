               JOB  Horizontal Dial
               CTL  6611
     *
     *     HORIZONTAL SUNDIAL V4     WRITTEN IN IBM 1401
     *     ROPE 1401 SYSTEM BEING AN IDE WITH AN EDITOR AND AUTOCODER
     *
     *     JANUARY 22 2009 1800 MST           SIMON WHEATON-SMITH 
     *
     *     WWW.ILLUSTRATINGSHADOWS.COM
     *     FILE                               IBM1401AUTOCODERFORPC.PDF
     *     ON WEB PAGE                        IBM 1401
     *     CONTENT                            URL FOR SIMULATOR
     *
     *     DOES NOT USE MULTIPLY NOR DIVIDE FEATURES
     *     DOES USE INDEX REGISTER 1
     *
     *     DISPLAYS THE HOUR LINE ANGLES 
     *
     *     LATITUDE IS READ FROM SWITCHES B, C, D, E, F AND THEN A DEFAULT
     *     BASE LATITUDE IS ADDED. THIS IS BECAUSE SENSE SWITCH A IS ALWAYS
     *     ON, SO IT CANT BE USED FOR LAT 64.
     *
     *     AFTER IT READS LATITUDE IT STOPS WITH A HALT
     *           YOU ENTER LONG DIFF FROM LEGAL STANDARD
     *           AND SWB LEFT SWITCH IS 0 IF WEST OF STD
     *           AND SWB LEFT SWITCH IS 1 IF EAST OF STD
     *           SWITCH B IS USED AND NOT SWITCH A BECAUSE 
     *           SENSE SWITCH A IS ALWAYS ON, SO IT CANT BE USED.
     *     
     *     THE SPS VERSION RUNS ON A SIM WITH COMPARE BH BL NOT ALWAYS WORKING
     *     SO ATAN HAD MULTIPLE PASSES WHEREAS THE AUTOCODER VERSION RUNS ON A
     *     SIMULATOR THAT HANDLES COMPARE BH BL OK ALL THE TIME SO ATAN HAS 
     *     ONLY ONE PASS.
     *
     *     THIS VERSION HAS OVERKILL ON ZONE SETTINGS COMPARED TO SPS VERSION.
     *
     *     DOES NOT USE MULTIPLY NOR DIVIDE BUT USES SUBROUTINE HEREIN
     *     DOES USE INDEX REGISTER 1 SYNTAX IS LABEL&X1 NOT LABEL&1
     *     USES SUBROUTINES SIN TAN MULT AND ATAN
     *     ENTIRE MATH PACKAGE IS HERE FOR SIN COS TAN COT ATAN MULT
     *
     *     T E S T    D A T A     L A T I T U D E    3 0  
     *                            DIAL LONG 3 DEGREES WEST
     *     LAT          32
     *     LONG.DIF      3
     *     IS MINS      12
     *     HR FR NOON   AM         PM
     *     0             2          2
     *     1            10          6
     *     2            19         15
     *     3            31         26
     *     4            46         39
     *     5            68         59
     *     6            84         84
     *     
     *
     *
               ORG  87
     X1        DSA  0                   index register 1
               ORG  92
     X2        DSA  0                   index register 2
               ORG  97
     X3        DSA  0                   index register 3
               ORG  500                 START AT 500
     START     CS   0332                CLEAR THE
               CS                       PRINT AREA
     *
     *     SAY THIS IS A HORIZONTAL DIAL
     *
               MCW  DTYPE,0258          MOVE TEXT TO PA
               W                        PRINT IT
     *
     *
     *
     *
     *
     ******************************************************************************
     *                                  *** TURN CONSOLE ON IN SIM              ***
     *                                  *** TURN A SWITCH OFF                   ***
     *                                  *** SET SWITCES FOR LATITUDE            ***
     *     *** NOTE *** DCW BASLAT          IS ADDED TO ENTERED LATITUDE - GOOD ***
     *                                      VALUES ARE 00 OR 30                 ***
     *                                  *** HIT CONTINUE PROGRAM                ***
     ******************************************************************************
               H
     GETLT     CS   0332                CLEAR PRINT AREA TO 300
               CS                       CHAIN METHOD FOR 299 TO 200
     *
     *         DETERMINE LATITUDE FROM SWITCHES - BUT CANT USE SW A SO ADD
     *         IN A BASE LATITUDE WHICH YOU ESTABLISH BY BASTAT/DCW/NN
     *
               ZA   LATZZ,LAT           ZERO DESIRED LATITUDE
     NO64      BIN  IS32,B              BSWITCH IS 32
               B    NO32                DONT ADD 32
     IS32      A    LAT32,LAT           ADD 32 TO LATITUDE  
     NO32      BIN  IS16,C              CSWITCH IS 16
               B    NO16                DONT ADD 16
     IS16      A    LAT16,LAT           ADD 16 TO LATITUDE  
     NO16      BIN  IS08,D              DSWITCH IS 08
               B    NO08                DONT ADD 08
     IS08      A    LAT08,LAT           ADD 08 TO LATITUDE  
     NO08      BIN  IS04,E              ESWITCH IS 04
               B    NO04                DONT ADD 04
     IS04      A    LAT04,LAT           ADD 04 TO LATITUDE  
     NO04      BIN  IS02,F              FSWITCH IS 02
               B    NO02                DONT ADD 02
     IS02      A    LAT02,LAT           ADD 02 TO LATITUDE  
     NO02      BIN  IS01,G              GSWITCH IS 01
               B    NO01                DONT ADD 01
     IS01      A    LAT01,LAT           ADD 01 TO LATITUDE  
     *
     *         DISPLAY THE DESIRED LATITUDE
     *
     NO01      MZ   LATZZ,LAT           CLEAR ZONES
               MCW  BSLAT,0220          SAY BASE LAT
               MCW  BASLAT,0240         AND DISPLAY IT
               MCW  USLAT,0259          SAY USER ENTERED LAT
               MCW  LAT,0280            AND DISPLAY IT
               W                        PRINT IT
               CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
               A    BASLAT,LAT          ADD THE BASE LATITUDE - SWA NOT USABLE FOR 64
               C    L91,LAT             IS LATITUDE LESS THAN 91
               BL   N001A               IF 91 GT LAT THEN OK
               ZA   LATZZ,LAT           ELSE ZERO THE FIELD
               A    L90,LAT             AND ADD 90 TO SET LAT TO 90
               MZ   LATZZ,LAT           CLEAR ZONES
               MCW  BLAT,0252           AND SAY ERROR CORRECTED                  
     N001A     MCW  ISLAT,0220          SAY IT IS RESULTING LATITUDE
               MCW  LAT,0240            SAY LATITUDE
               W                        PRINT IT
               CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
     *
     *     LOCATE SIN OF THE DESIRED LATITUDE
     *
               LCA  LAT,SININ           * SET SIN IN           
               B    SINFN               * DO SIN FUNCTION      
               MCW  SINOUT,SINLAT       * GET SIN OUT        
               CS   0280                CLEAR PRINT AREA
               MCW  SINLAT,0260         SAY SIN LAT
               MCW  SLATMS,0250         SAY WHAT THIS IS
               MCW  DOT,0257            MAKE DECIMAL PRETTY
               W                        DISPLAY IT 
               CS   0280                AND THEN DO A
               W                        BLANK LINE
     *
     *         DETERMINE DIF IN LONGITUDES FROM SWITCHES
     *         B SWITCH USED FOR EAST WEST - NOT A SWITCH
     *
     *
     *
     *
     *
     *
     ******************************************************************************
     *                                  *** SET LATITUDE SWITCES OFF            ***
     *                                  *** SET SWITCES FOR LONGITUDE DIFFERENCE***
     *                                      FROM STD TIME MERIDIAN              ***
     *                                  *** SET B ON IF EAST                    ***
     *                                      SET B OFF WEST OF LEGAL             ***
     *                                  *** HIT CONTINUE PROGRAM                ***
     *                                  *** LOOK AT PRINT OUT                   ***
     ******************************************************************************
               H
     EORWDL    ZA   LNGZZ,LNGES         ZERO TO DEFAULT TO WEST
               BIN  EASTS,B             B SWITCH IS EAST OF LEGAL 
               B    WESTS               SKIP 
     EASTS     ZA   LNGEOW,LNGES        SAY EAST OF LEGAL  
     *
     WESTS     ZA   LNGZZ,LNGDL         ZERO DESIRED LONGITUDE
     GO16      BIN  GL08,D              D SWITCH IS 08
               B    GO08                DONT ADD 08
     GL08      A    LAT08,LNGDL         ADD 08 TO LONG DIFF
     GO08      BIN  GL04,E              E SWITCH IS 04
               B    GO04                DONT ADD 04
     GL04      A    LAT04,LNGDL         ADD 04 TO LONG DIFF
     GO04      B    GL02,F              F SWITCH IS 02
               B    GO02                DONT ADD 02
     GL02      A    LAT02,LNGDL         ADD 02 TO LONG DIFF 
     GO02      B    GL01,G              GSWITCH IS 01
               B    G001                DONT ADD 01
     GL01      A    LAT01,LNGDL         ADD 01 TO LONG DIFF 
     *
     G001      CS   0280                CLEAR PRINT AREA
               MZ   LATZZ,LNGDL         CLEAR ZONES
               MCW  LNGDL,0260          SAY LONGITUDE DIFFERENCE
               MCW  LNGMSG,0250         SAY WHAT THIS IS
               W                        PRINT
               CS   0280                CLEAR
               MCW  REFMSG,0250         SAY EAST OR WEST CODE
               MZ   LATZZ,LNGES         CLEAR ZONES
               MCW  LNGES,0260          WELL - WHICH IS IT
               W                        PRINT
               CS   0280                CLEAR
               ZA   LNGDL,LNGMIN        GET DEGREES
               A    LNGMIN,LNGMIN       TIMES 2
               A    LNGMIN,LNGMIN       TIMES 4
               MCW  MINMSG,0249         SAY MINUTES DIFF
               MZ   LATZZ,LNGMIN        CLEAR ZONES
               MCW  LNGMIN,0260         AND ITS VALUE
               W                        PRINT
               CS   0280                CLEAR
               W                        BLANK LINE
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - -
     * END OF LONGITUDE FROM LEGAL MERIDIAN CALCULATIONS
     * - - - - - - - - - - - - - - - - - - - - - - - - - - - -
               CS   0280
               MCW  HEADR,0259          LAT   SLAT   HR   HRANGL    TAN.------- 
     *                                    *      *    *        *       *
     *                                  230    237  242      251     259   
     *                                    
               MCW  HEADR2,0285         HRANGL      TAN.HLA    HLA
     *                                       *            *      *
     *                                     265          278    285
     *
               W                        PRINT HEADER
               CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
               MCW  HDRTAN,0237         SAY TIMES 1000
               MCW  HDRTAN,0265         AND TIMES 1000
               MCW  HDRTAN,0278         AND TIMES 1000 AGAIN
               W
               CS   0280          
               MCW  LAT,0230            ACTUAL LATITUDE - PRIME FIRST PRINTED 
               MCW  SINLAT,0237         SIN LAT * 1000  - LINE ONLY
     *
     *     NOW LOOP ON HR AFTERNOON HOURS
     *  
               MCW  PMMSG,0299          SAY PM HOURS
               ZA   HR00,HRWKG          PRIME INITIAL HOURS FROM NOON
     *------------------------------------------------------------------
     *                   0259        LAT   SLAT   HR   HRANGL    TAN.--- 
     *                                 *      *    *        *       *
     *                               230    237  242      251     259   
     *                                    
     *                   0285        HRANGL      TAN.HLA    HLA
     *                                    *            *      *
     *                                  265          278    285
     *------------------------------------------------------------------
     HLOOP     MZ   HR00,HRWKG          ZA STILL LEFT A ZONE
               C    HRLIM,HRWKG         HAVE WE HIT A LIMIT
               BH   HHALT               UIF WKG GT LIM
     *
               MCW  HRWKG,0242          HR OF DAY FROM NOON
               C    HR00,HRWKG                                     IF NOON SKIP IT
               BE   SKIP01                                         AS NOON DONE ELSEWHERE
               ZA   HRWKG,HRWKGM        COPY HOUR TO HOUR ANGLE
               ZA   HRDEG,MPLIER        * SET MULTILPIER   * 15 DEG PER HR
               ZA   HRWKGM,MCAND        * SET MULTIPLICAND * WORKING HR
               B    MULTP               * DO MULTIPLY      * MULTIPLY
               MCW  MULTPP,HRANGL       * GET PRODUCT      * RESULTS
               SW   0246                LIMIT RESULT OF HR ANGLE SIZE
     *     NOW WE ADD OR SUBTRACT SOME HOUR ANGLE DEGREES BASED
     *          ON         1 LNGES DCW* 0 WHERE 0 IS WEST 1 IS EAST
     *          AMOUNT     2 LNGDL DCW* 00LONGITUDE DIFFERENCE
               B    SBWEST,LNGES,0      MEANS WEST SO SUB 
               A    LNGDL,HRANGL        HRANGL IS FIXED
               B    ADEAST              ADDED AS EAST
     SBWEST    B    SKIP01,HRWKG,0      DO NOTHING AS NEGATIVE INDEX 
               S    LNGDL,HRANGL        SUB IF WE ARE WEST HOWEVER
     *                                  UPSETS THINGS
     ADEAST    MZ   ZERO,HRANGL         GET NICE ZONES
               MCW  HRANGL,0251         RESULTS TO PRINT AND WAS 10 CHARS
               MCW  HRANGL,CURHRA       GET 2 CHARS OF HOUR ANGLE ADJUSTED
               B    SKIP01,CURHRA-001,9 ANGLE 90 OR GREATER
               MCW  HRANGL,TANIN        * SET TAN 2 CHARS  *
               B    TANFN               * DO TAN FUNCTION  *
               MCW  TANOUT,HRATAN       * GET TAN OUT      *
               MCW  HRATAN,0265         PRINT ATAN HRA
               ZA   SINLAT,MPLIER       * SET MULTILPIER   *  
               ZA   HRATAN,MCAND        * SET MULTIPLICAND *  
               B    MULTP               * DO MULTIPLY      *  
               MCW  MULTPP-003,HLANGT   * GET PRODUCT      *   
               MCW  HLANGT,0278         PRINT IT  
               ZA   HLANGT,ATNIN        * SET ATAN 6 CHARS *
               B    ATNFN               * DO ATAN FUNCTION *
               MCW  ATNOUT,HLANGL       * GET ANGLE 2 CHARS*
               MZ   HR00,HLANGL         LOSE THE ZONE
               MCW  HLANGL,0285   
     *
     *     ONE COMPLETE LINE DERIVED
     *
     SKIP01    W                        PRINT THE DATA
               CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
               A    ONE,HRWKG           ADD ONE TO HRWKG
               B    HLOOP               DO AGAIN
     ***
     ***   NOW LOOP ON HR FOR MORNING HOURS
     ***
     HHALT     CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
               W                        SEPARATOR LINE
               MCW  AMMSG,0299          SAY AM HOURS
               ZA   HR00,HRWKG          PRIME INITIAL HOURS FROM NOON
     HLOOP1    MZ   HR00,HRWKG          ZA STILL LEFT A ZONE
               C    HRLIM,HRWKG         HAVE WE HIT A LIMIT
               BH   HHALT2              IF WKG GT LIM
               C    HR00,HRWKG          IF NOON SKIP IT
               BE   SKIP02              AS NOON DONE ELSEWHERE
               MCW  HRWKG,0242          HR OF DAY FROM NOON
               ZA   HRWKG,HRWKGM        COPY HOUR TO HOUR ANGLE
               ZA   HRDEG,MPLIER        * SET MULTILPIER   * 15 DEG PER HR
               ZA   HRWKGM,MCAND        * SET MULTIPLICAND * WORKING HR
               B    MULTP               * DO MULTIPLY      * MULTIPLY
               MCW  MULTPP,HRANGL       * GET PRODUCT      * RESULTS
               SW   0246                LIMIT RESULT OF HR ANGLE SIZE
               B    SUWEST,LNGES,0      0 MEANS WEST SO ADD IF MORNING 
               S    LNGDL,HRANGL        HRANGL IS FIXED
               B    ADEEST              SUBTRACTED AS EAST
     SUWEST    B    SKIP02,HRWKG,0      DO NOTHING AS NEGATIVE INDEX 
               A    LNGDL,HRANGL        SUB IF WE ARE WEST HOWEVER
     ADEEST    MZ   ZERO,HRANGL         GET NICE ZONES
               MCW  HRANGL,0251         RESULTS TO PRINT AND WAS 10 CHARS
               MCW  HRANGL,CURHRA       GET 2 CHARS OF HOUR ANGLE ADJUSTED
               B    SKIP02,CURHRA-001,9 ANGLE 90 OR GREATER
               MCW  HRANGL,TANIN        * SET TAN 2 CHARS  *
               B    TANFN               * DO TAN FUNCTION  *
               MCW  TANOUT,HRATAN       * GET TAN OUT      *
               MCW  HRATAN,0265         PRINT ATAN HRA
               ZA   SINLAT,MPLIER       * SET MULTILPIER   *  
               ZA   HRATAN,MCAND        * SET MULTIPLICAND *  
               B    MULTP               * DO MULTIPLY      *  
               MCW  MULTPP-003,HLANGT   * GET PRODUCT      *   
               MCW  HLANGT,0278         PRINT IT  
               ZA   HLANGT,ATNIN        * SET ATAN 6 CHARS *
               B    ATNFN               * DO ATAN FUNCTION *
               MCW  ATNOUT,HLANGL       * GET ANGLE 2 CHARS*
               MZ   HR00,HLANGL         LOSE THE ZONE
               MCW  HLANGL,0285   
     ***
     ***   ONE COMPLETE LINE DERIVED
     ***
     SKIP02    W                        PRINT THE DATA
               CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
               A    ONE,HRWKG           ADD ONE TO HRWKG
               B    HLOOP1              DO AGAIN
     ***
     ***   DO THE NOON HOUR DATA
     ***
     HHALT2    W                        GET A CLEAR
               CS   0290                LINE
               MCW  NNMSG,0299          SAY NOON HOURS
               MCW  HR00,0242           HR OF DAY FROM NOON
               ZA   LNGDL,HRANGL        * GET PRODUCT      * RESULTS
               MZ   ZERO,HRANGL         CLEAR THE ZONE
               SW   0246                LIMIT SIZE OD HR ANGL
               MCW  HRANGL,0251         RESULTS TO PRINT AND WAS 10 CHARS
               MCW  HRANGL,CURHRA       GET 2 CHARS OF HOUR ANGLE ADJUSTED
               MCW  HRANGL,TANIN        * SET TAN 2 CHARS  *
               B    TANFN               * DO TAN FUNCTION  *
               MCW  TANOUT,HRATAN       * GET TAN OUT      *
               MCW  HRATAN,0265         PRINT ATAN HRA
               ZA   SINLAT,MPLIER       * SET MULTILPIER   *  
               ZA   HRATAN,MCAND        * SET MULTIPLICAND *  
               B    MULTP               * DO MULTIPLY      *  
               MCW  MULTPP-003,HLANGT   * GET PRODUCT      *   
               MCW  HLANGT,0278         PRINT IT  
               ZA   HLANGT,ATNIN        * SET ATAN 6 CHARS *
               B    ATNFN               * DO ATAN FUNCTION *
               MZ   ZERO,ATNOUT         CLEAR THE ZONE
               MCW  ATNOUT,0285         * GET ANGLE 2 CHARS*
               W                        PRINT ANY RESIDUAL DATA
               CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
               W                        PRINT A BLANK LINE
               MCW  HEADR3,0259         ADVISE ON ACCURACY
               W                        SAY SO
               MCW  HEADR4,0259         ADVISE ON NOON ISSUES
               W     
               CS   0320                CLEAR PRINT AREA
               CS                       ALL OF IT
               W                        PRINT A BLANK LINE
               MCW  HEADR5,0259         GET HELP AT THIS URL
               MCW  HEADR6,0289         GET HELP AT THIS URL
               W   
               H    START               *** END PROGRAM ***
     *
     **
     ****
     ********
     ****
     **
     *
     ******************************************************************************
     *              L A T I T U D E    D A T A                                    *
     ******************************************************************************
     BASLAT    DCW  00                  A BASE LATITUDE - SINCE SW A NOT USABLE   *
     *              30                  A GOOD BASE LATITUDE IS 00 OR 30          *
     ******************************************************************************
     *
     LATZZ     DCW  00
     LAT64     DCW  64
     LAT32     DCW  32
     LAT16     DCW  16
     LAT08     DCW  08
     LAT04     DCW  04
     LAT02     DCW  02
     LAT01     DCW  01
     LAT       DCW  00
     *
     L91       DCW  91                  TEST FOR BAD LATITUDE
     L90       DCW  90                  CORRECT BAD LATITUDE
     DOT       DCW  @.@                 MAKE SENSE OF DECIMAL ON PRINTOUT
     BLAT      DCW  @LAT GT 90@         ERROR MESSAGE
     *
     DTYPE     DCW  @HORIZONTAL-DIAL@   TEXT TO PRINT
     ISLAT     DCW  @LATITUDE@          NAME THE NEXT FIELD TO PRINT
     BSLAT     DCW  @BASE LATITUDE@     NAME THE NEXT FIELD TO PRINT
     USLAT     DCW  @ENTERED LATITUDE@  NAME THE NEXT FIELD TO PRINT
     SLATMS    DCW  @SIN LAT@           NAM SIN LAT
     SINLAT    DCW  0000                1000 * SIN OF LATITUDE
     *
     INDX      DCW  000                 DESIRED LATITUDE READY FOR MULTIPLY
     K032      DCW  032                 SIZE OF AN ENTRY FOR MULTIPLY
     ZERO      DCW  0                   INITIAL INDEX VALUE
     *
     CTR       DCW  00                  COUNT UP TO LATITUDE IN LOOP
     ONE       DCW  01                  DECREMENT AMOUNT
     *
     *
     *     OTHER DATA  
     *
     *
     HEADR     DCW  @LAT   SLAT   HR   HRANGL    TAN.@ 
     HEADR2    DCW  @HRANGL      TAN.HLA    HLA@
     HEADR3    DCW  @HOUR LINE ANGLES ARE CLOSEISH @ 
     HEADR4    DCW  @NOON ANGLE IS PRETTY GOOD@
     HEADR5    DCW  @FREE SUNDIAL NOTES AT@
     HEADR6    DCW  @WWW.ILLUSTRATINGSHADOWS.COM@
     HDRTAN    DCW  @*1K@               SAYS TIMES 1000
     *
     HR00      DCW  00                  START HR FROM NOON
     HRM6      DCW  06                  MINUS 6
     HRK6      DCW  06                  SIX
     HRWKG     DCW  00                  WORKING HOUR
     HRLIM     DCW  06                  SIX HOURS 
     *                                  A TWO DIGIT LIMIT ON SIN COS TAN
     HRDEG     DCW  000015              15 DEGREES PER HOUR
     HRWKGM    DCW  000000              WORKING HOUR FOR MULTIPLY
     HRANGL    DCW  0000000000          HR ANGLE IS HR FR NOON * 15
     HLANGT    DCW  000000              HR LINE ANGLE AS A TAN
     HRATAN    DCW  000000              HR ANGLE BUT TAN
     HLANGL    DCW  00                  RESULTS OF ATAN
     CURHRA    DCW  00                  HOUR ANGLE AFTER LONG DIFF CALC
     *
     LNGZZ     DCW  00                  LONGITUDE DIFFERENCE ZEROES
     LNGDL     DCW  00                  LONGITUDE DIFFERENCE
     LNGEOW    DCW  1                   1 IS EAST
     LNGES     DCW  0                   0 IS WEST 1 IS EAST
     LNGMSG    DCW  @LNG DIFF@          NAME THE NEXT FIELD TO PRINT
     REFMSG    DCW  @1-EAST 0-WEST@     NAM EAST OR WEST
     MINMSG    DCW  @MINUTES DIFF@      SAY MINUTES OF DIFF
     LNGMIN    DCW  00                  VALUE OF MINUTES OF DIFF
     *
     PMMSG     DCW  @PM HOURS@
     AMMSG     DCW  @AM HOURS@
     NNMSG     DCW  @--NOON--@ 
     *
     *
     ******************************************************************************
     *
     *******************************************************************
     *                                                                 *
     * - - M A T H    F U N C T I O N S    F O L L O W    - - - - - - -* 
     *                                                                 *
     *******************************************************************
     *
     *
     *
     * - - M U L T I P L Y - - - - - - - - - - - - - - - - - - - - - - - 
     *
     *
     ********************************************************
     *     BEGIN MULTIPLY SUBROUTINE * USES SBR AND 3 PARMS *
     ********************************************************
     *     MPLIER - -MULTP - - MULTPP  ARE RESERVED LABELS  *
     *     MCAND- - -                  SET WITH ZA NOT MCW  *
     *     6                   10      SIMPLE PRODUCT       *
     ********************************************************
     *     INPUT EACH  6 CHARS MAX   * OUTPUT 10 CHARS      *
     ********************************************************
     *     ZA VAL1       MPLIER      * SET MULTILPIER       *
     *     ZA VAL2       MCAND       * SET MULTIPLICAND     *
     *     B  MULTP                  * DO MULTIPLY          *
     *     MCWMULTPP     XXXXX       * GET PRODUCT          *
     ********************************************************
     MULTP     SBR  MULTPV-001          SAVE RETURN ADDRESS
               LCA  MULTPC,MULTPA       CLEAR ENTIRE AREA  
               LCA  MPLIER,MULTPA-020   LOAD MULTIPLIER TO -20
               ZA   MULT00,MULTPP       SET PRODUCT TO 0
               C    MPLIER,MULT00       IS MULTIPLIER 0
     *                                  U IF SO STOP - U MEANS B GT A
     *                                  T IF SO STOP - T MEANS B LT  A
     *                                  / IF SO STOP - / MEANS B NE  A
     *                                  S IF SO STOP - S MEANS B EQ  A
               BE   MULTPR              IF ZERO THEN EXIT 
               C    MCAND,MULT00        IS MULTIPLICAND 0
               BE   MULTPR              S IF ZERO THEN EXIT   
     MULTPZ    MN   MULTPA-020,MULTPT   MOVE CURRENT LOW ORDER CHAR
               BCE  MULTPM,MULTPT,0     BRANCH ZERO
     BEGIN     A    MCAND,MULTPA-010    ADD MCAND
               S    MULTP1,MULTPA-020   SUB 1 FROM MULTIPLIER
               B    MULTPZ              REPEAT
     MULTPM    BWZ  MULTPX,MULTPA-020,1 TEST FOR WM
               LCA  MULTPA-001,MULTPA   SHIFT AREA RIGHT ONE POS
               B    MULTPZ              REPEAT FOR THIS PART
     MULTPX    MCW  MULTPA-002,MULTPP   MULTIPLY IS COMPLETE
     MULTPR    B    0000                ADDRESS COMES FROM SBR
     MULTPV    NOP                      SBR TO HERE -1 AS PLUS 
     *                                  UPSET SPS ASSEMBLER
     *
     *                     -20       -10        -0
     *              ----10---*----10---*----10---*
     *                  MPLIER     MCAND    MULTPP  
     MULTPC    DCW  000000000000000000000000000000
     *
     MULTPA    DCW  000000000000000000000000000000   MPLIER/MCAND/PRODUCT 
     MPLIER    DCW  000000000            MULTIPLIER - - 9 CHARS
     MCAND     DCW  000000000            MULTIPLICAND - 9 CHARS
     MULTPP    DCW  0000000000           PRODUCT - - - 10 CHARS
     MULT00    DCW  000000000            0 BUT IS 9 CHARS FOR COMPARE
     MULTP1    DCW  1                    VALUE OF 1 FOR SUBTRACT
     MULTPT    DCW  0                    TEST AREA FOR ONE BYTE
     ********************************************************
     *     END MULTIPLY SUBROUTINE                          *
     ********************************************************
     *
     *
     *
     * - - S I N - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
     *
     *
     *
     ********************************************************
     *     BEGIN SIN SUBROUTINE      * USES SBR AND 2 PARMS *
     ********************************************************
     *     INPUT       2 CHARS       * OUTPUT  4 CHARS      *
     ********************************************************
     *     SININ - - SINFN - - SINOUT  ARE RESERVED LABELS  *
     *     2                   4       SIN * 1000           *
     ********************************************************
     *     LCAVAL1       SININ       * SET SIN IN           *
     *     B  SINFN                  * DO SIN FUNCTION      *
     *     MCWSINOUT     XXXXX       * GET SIN OUT          *
     ********************************************************
     SINFN     SBR  SINEXT-001          SAVE RETURN ADDRESS
               LCA  SININ0,SININI       RESET IN CASE USED BEFORE
               MCW  SININ,SININI        LOAD THEIR ANGLE IN DEGREES
               A    SININI,SININI       DOUBLE IT
               A    SININI,SININI       NOW FOUR TIMES
               MCW  SININI,0089         87-89 IS INDEX REG 1
     *                                  92-94 IS INDEX 2, 97-99 IS INDEX 3
     * -------------------------------- USE INDEX REGISTER 1
               MCW  SIN00&X1,SINOUT     GET SIN00 PLUS INDEX 1
     *                   &X1            THE  1 MEANS INDEX WITH REGISTER 1
               B    0000                ADDRESS COMES FROM SBR
     SINEXT    NOP                      SBR TO HERE -1 AS PLUS 
     *                                  UPSET SPS ASSEMBLER
     SININ     DCW  00                  SIN ANGLE IN DEGREES INCOMING
     SININ0    DCW  000                 MAKES THIS SERIALLY REUSABLE
     SININI    DCW  000                 WORKING ANGLE IN DEGREES 
     SINOUT    DCW  0000                SIN OF ANGLE * 1000 OUTGOING
     ********************************************************
     *  END SIN FUNCTION SUBROUTINE                         *
     ********************************************************
     *
     *
     *
     *
     *
     * - - C O S I N E - - - - - - - - - - - - - - - - - - - - - - - - - 
     *
     *
     *
     ********************************************************
     *     BEGIN COS SUBROUTINE      * USES SBR AND 2 PARMS *
     ********************************************************
     *     LOGIC IS TO SUB THEIR ANGLE FROM 90 AND THEN USE *
     *     THAT AS ANGLE INTO THE SIN SERIES TO SAVE SPACE  *
     *     WHEREAS COS BY ITSELF HAS ITS OWN TABLE          *
     ********************************************************
     *     INPUT       2 CHARS       * OUTPUT  4 CHARS      *
     ********************************************************
     *     COSIN - - COSFN - - COSOUT  ARE RESERVED LABELS  *
     *     2                   4       COS * 1000           *
     ********************************************************
     *     LCAVAL2       COSIN       * SET COS IN           *
     *     B  COSFN                  * DO COS FUNCTION      *
     *     MCWCOSOUT     XXXXX       * GET COS OUT          *
     ********************************************************
     COSFN     SBR  COSEXT-001          SAVE RETURN ADDRESS  
               MCW  COS90,COSINI        SET 90 DEGREES TO OUR ANGLE
               S    COSIN,COSINI        SUB THEIR ANGLE FROM 90
               MN   COSINI,COSWK        GET LOW ORDER AND LOSE ZONES
               MCW  COS00,COSINI        ONE BYTE ONLY       
               MN   COSWK,COSINI        NOW COSINI HAS NO ZONES
     *     NOW THIS IS SIN
               A    COSINI,COSINI       DOUBLE IT
               A    COSINI,COSINI       NOW FOUR TIMES
               MCW  COSINI,0089         87-89 IS INDEX REG 1
     *                                  92-94 IS INDEX 2, 97-99 IS INDEX 3
     * ------------------------------ USE INDEX REGISTER 1
               MCW  SIN00&X1,COSOUT     GET COS00 IE SIN00 NOW PLUS INDEX 1
     *                   &X1            THE 1 MEANS INDEX WITH REGISTER 1
               B    0000                ADDRESS COMES FROM SBR
     COSEXT    NOP                      SBR TO HERE -1 AS PLUS 
     *                                  UPSET SPS ASSEMBLER
     COSIN     DCW  00                  SIN ANGLE IN DEGREES INCOMING
     COSINI    DCW  000                 WORKING ANGLE IN DEGREES 
     COS90     DCW  090                 90 FOR 90-ANGLE HENCE SIN
     COS00     DCW  0                   0 FOR INITIALIZING
     COSWK     DCW  0                   FOR LOSING ZONES
     COSOUT    DCW  0000                COS OF ANGLE * 1000 OUTGOING
     ********************************************************
     *  END COS FUNCTION SUBROUTINE                         *
     ********************************************************
     *
     *
     *
     * - - T A N G E N T - - - - - - - - - - - - - - - - - - - - - - - - 
     *
     *
     *
     ********************************************************
     *     BEGIN TAN SUBROUTINE      * USES SBR AND 2 PARMS *
     ********************************************************
     *     INPUT       2 CHARS       * OUTPUT  6 CHARS      *
     ********************************************************
     *     TANIN - - TANFN - - TANOUT  ARE RESERVED LABELS  *
     *     2                   6       TAN * 1000           *
     ********************************************************
     *     LCAVAL1       TANIN       * SET TAN IN           *
     *     B  TANFN                  * DO TAN FUNCTION      *
     *     MCWTANOUT     XXXXX       * GET TAN OUT          *
     ********************************************************
     TANFN     SBR  TANEXT-001          SAVE RETURN ADDRESS
               LCA  TANIN0,TANINI       RESET IN CASE USED BEFORE
               MCW  TANIN,TANINI        LOAD THEIR ANGLE IN DEGREES
               A    TANINI,TANINI       DOUBLE IT
               A    TANINI,TANINI       NOW FOUR TIMES
               A    TANIN,TANINI        NOW FIVE TIMES
               A    TANIN,TANINI        NOW SIX TIMES
               MCW  TANINI,0089         87-89 IS INDEX REG 1
     *                                  92-94 IS INDEX 2, 97-99 IS INDEX 3
     * -------------------------------- USE INDEX REGISTER 1
               MCW  TAN00&X1,TANOUT     GET TAN00 PLUS INDEX 1
     *                   &X1            THE 1 MEANS INDEX WITH REGISTER 1
               B    0000                ADDRESS COMES FROM SBR
     TANEXT    NOP                      SBR TO HERE -1 AS PLUS 
     *                                  UPSET SPS ASSEMBLER
     TANIN     DCW  00                  SIN ANGLE IN DEGREES INCOMING
     TANIN0    DCW  000                 MAKES THIS SERIALLY REUSABLE
     TANINI    DCW  000                 WORKING ANGLE IN DEGREES 
     TANOUT    DCW  000000              TAN OF ANGLE * 1000 OUTGOING
     ********************************************************
     *  END TAN FUNCTION SUBROUTINE                         *
     ********************************************************
     *
     *
     *
     *
     * - - C O T A N - - - - - - - - - - - - - - - - - - - - - - - - - - 
     *
     *
     *
     ********************************************************
     *     BEGIN COT SUBROUTINE      * USES SBR AND 2 PARMS *
     ********************************************************
     *     LOGIC IS TO SUB THEIR ANGLE FROM 90 AND THEN USE *
     *     THAT AS ANGLE INTO THE TAN SERIES TO SAVE SPACE  *
     *     WHEREAS TAN BY ITSELF HAS ITS OWN TABLE          *
     ********************************************************
     *     INPUT       2 CHARS       * OUTPUT  4 CHARS      *
     ********************************************************
     *     COTIN - - COTFN - - COTOUT  ARE RESERVED LABELS  *
     *     2                   4       COS * 1000           *
     ********************************************************
     *     LCAVAL2       COTIN       * SET COS IN           *
     *     B  COTFN                  * DO COS FUNCTION      *
     *     MCWCOTOUT     XXXXX       * GET COS OUT          *
     ********************************************************
     COTFN     SBR  COTEXT-001          SAVE RETURN ADDRESS  
               MCW  COT90,COTINI        SET 90 DEGREES TO OUR ANGLE
               S    COTIN,COTINI        SUB THEIR ANGLE FROM 90
               MN   COTINI,COTWK        GET LOW ORDER AND LOSE ZONES
               MCW  COT00,COTINI        ONE BYTE ONLY       
               MN   COTWK,COTINI        NOW COTINI HAS NO ZONES
               MCW  COTINI,COTWIN       SAVE WHAT WAS IN FROM 90
     *     NOW THIS IS TAN
               A    COTINI,COTINI       DOUBLE IT
               A    COTINI,COTINI       NOW FOUR TIMES
               A    COTWIN,COTINI       NOW FIVE TIMES
               A    COTWIN,COTINI       NOW SIX TIMES
               MCW  COTINI,0089         87-89 IS INDEX REG 1
     *                                  92-94 IS INDEX 2, 97-99 IS INDEX 3
     * ------------------------------ USE INDEX REGISTER 1
               MCW  TAN00&X1,COTOUT     GET COT00 IE TAN00 NOW PLUS INDEX 1
     *                   &X1            THE 1 MEANS INDEX WITH REGISTER 1
               MCW  TAN00     10220
               B    0000                ADDRESS COMES FROM SBR
     COTEXT    NOP                      SBR TO HERE -1 AS PLUS 
     *                                  UPSET SPS ASSEMBLER
     COTIN     DCW  00                  TANANGLE IN DEGREES INCOMING
     COTINI    DCW  000                 WORKING ANGLE IN DEGREES 
     COTWIN    DCW  000                 USED AS WE MULT BY 6
     COT90     DCW  090                 90 FOR 90-ANGLE HENCE TAN
     COT00     DCW  0                   0 FOR INITIALIZING
     COTWK     DCW  0                   FOR LOSING ZONES
     COTOUT    DCW  0000                COT OF ANGLE * 1000 OUTGOING
     ********************************************************
     *  END COT FUNCTION SUBROUTINE                         *
     ********************************************************
     *
     * - - A R C T A N - - - - - - - - - - - - - - - - - - - - - - - - - 
     *
     *
     *
     ********************************************************
     *     BEGIN ATN SUBROUTINE      * USES SBR AND 2 PARMS *
     ********************************************************
     *     INPUT       6 CHARS       * OUTPUT  2 CHARS      *
     ********************************************************
     *     LOGIC       THE COMPARE HI AND LO WORKS ON THE   *
     *                 SIM THAT SUPPORTS THIS AUTOCODER SO  *
     *                 THAT IS WHY ATTOCODER HAS JUST ONE   *
     *                 PASS AND WHY SPS HAS MULTIPLE PASSES *
     *                 IT IS A SIMULATOR ISSUE NOT AN SPS   *
     *                 NOR AUTOCODER ISSUE.                 *
     ********************************************************
     *     ATNIN - - ATNFN - - ATNOUT  ARE RESERVED LABELS  *
     *     6                           TAN * 1000 IN AND    *
     *                         2       ANGLE IS 2 BACK      *
     ********************************************************
     *     ZA VAL1       ATNIN       * SET ATN IN           *
     *     B  ATNFN                  * DO ATN FUNCTION      *
     *     MCWATNOUT     XXXXX       * GET ATN OUT IN DEGREES
     ********************************************************
     ATNFN     SBR  ATNEXT-001          SAVE RETURN ADDRESS
               ZA   ATNZRO,ATNANG       SET 000 TO RESULTING ANGLE TO 00 
               ZA   ATNZRO,ATNNDX       COPY OF I1
               MZ   ATNZO,ATNNDX        LOSE ZONES
               MZ   ATNZO,ATNNDX-1      LOSE ZONES
               MZ   ATNZO,ATNNDX-2      LOSE ZONES
               MCW  ATNNDX,0089         SET INDEX 1 AT 0089 TO 0 INITIALLY
     *                                  87-89 IS INDEX REG 1
     *                                  92-94 IS INDEX 2, 97-99 IS INDEX 3
     *
     *     LOOP 1 LOOKS FOR EXACT MATCH
     *
     ATNFN1    MZ   ATNZO,ATNANG        CLEAR ZONE
               ZA   ATNANG,ATNOUT       SAVE ANGLE AS OUTPUT JUST IN CASE
               MCW  ATNNDX,0089         SET INDEX 1 AT 0089 TO NEW VALUE
     *                   &X1*-----------MEANS USE INDEX 1
               ZA   TAN00&X1,ATNWK      COPY TABLE INDEXED FOR COMPARE
               C    ATN90,ATNANG        COMPARE 90 TO CURRENT ANGLE SO FAR
               BH   ATNFN2              IF 90 LOWER THAN WORKING ANGLE THEN EXIT
               BE   ATNFN2              IF 90 EQUALS WORKING ANGLE THEN EXIT
               MZ   ATNZO,ATNWK         CLEAR
               MZ   ATNZO,ATNIN         ZONES FOR COMPARE
               C    ATNWK,ATNIN         COMPARE CURRENT TAN TABLE ENTRY TO INPUT
               BE   ATNEXX              ATN00 TABLE ENTRY EQUALS OUR PARAMETER
               BL   ATNEXX              IF IN IS LOW THEN USE WHAT WE GOT  
     *     WORKING ANGLE LT 90 AND NOT EQUL WHERE WE ARE IN TABLE
               A    ATNSIX,ATNNDX       SO ADD 6 TO OUR COPY OF INDEX
               A    ATNONE,ATNANG       AND ADD 1 TO FINAL ANGLE
               B    ATNFN1              AND DO IT AGAIN
     *
     ATNFN2    ZA   ATN90,ATNOUT        SET 90 IF THINGS ARE BALLED UP THEN EXIT
     ATNEXX    MZ   ATNZO,ATNOUT        FIX ZONE
               B    0000                ADDRESS COMES FROM SBR
     ATNEXT    H    0999                SBR TO HERE -1 AS PLUS 
     *
     *     LOOP 2 IS NOT USED IN THE AUTOCODER VERSION BECAUSE
     *     THE SIMULATOR COMPARE BH BL WORKS HERE
     *
     ATNZRO    DCW  000                 ZERO TO START SEARCH
     ATNZO     DCW  00                  ZERO FOR COMPARE
     ATNANG    DCW  00                  ANGLE I.E. NTH ENTRY IN TAN TABLE
     ATNSIX    DCW  006                 INCREMENT SIZE FOR TAN TABLE
     ATNONE    DCW  001                 INCREMENT SIZE FOR DEGREES
     ATNNDX    DCW  000                 INDEX 0 6 12 ETC FOR I1
     ATN90     DCW  90                  LIMIT
     *
     ATNOUT    DCW  00                  ANGLE IN DEGREES OUTGOING
     ATNIN     DCW  000000              TAN OF ANGLE * 1000 INCOMING
     ATNWK     DCW  000000              WKAREA - COPY FROM TAN00 INDEXED
     *
     ********************************************************
     *  END ATN FUNCTION SUBROUTINE                         *
     ********************************************************
     *
     *
     *
     * - - T A B L E S    F O R    T A N    A N D    A R C T A N - - - - 
     *
     *     *** NOTE *** HERE ARE NO MINOR CHANGES OF ABOUT 1/10 DEGREE 
     *     HERE COMPARED TO THE SPS ATAN - THIS IS BECAUSE MULTIPLE 
     *     PASSES ARE NOT NEEDED SO THAT ADJUSTMENT IS NOT NEEDED.
     *
     *
     TAN00     DCW  000000              EACH ENTRY IS 1000 * TAN
               DCW  000017
               DCW  000034
               DCW  000052
               DCW  000069
               DCW  000087
               DCW  000105
               DCW  000122
               DCW  000140
               DCW  000158
               DCW  000176
               DCW  000194
               DCW  000212
               DCW  000230
               DCW  000249
               DCW  000267
               DCW  000286
               DCW  000305
               DCW  000324
               DCW  000344
               DCW  000363
               DCW  000383
               DCW  000404
               DCW  000424
               DCW  000445
               DCW  000466               
               DCW  000487                  
               DCW  000509
               DCW  000531
               DCW  000554
               DCW  000577           
               DCW  000600                   
               DCW  000624
               DCW  000649
               DCW  000674
               DCW  000700
               DCW  000726
               DCW  000753
               DCW  000781
               DCW  000809
               DCW  000839
               DCW  000869
               DCW  000900
               DCW  000932
               DCW  000965
               DCW  001000
               DCW  001035
               DCW  001072
               DCW  001110
               DCW  001150
               DCW  001191
               DCW  001234
               DCW  001279
               DCW  001327
               DCW  001376
               DCW  001428
               DCW  001482
               DCW  001539
               DCW  001600
               DCW  001664
               DCW  001732
               DCW  001804
               DCW  001880
               DCW  001962
               DCW  002050
               DCW  002144
               DCW  002246
               DCW  002355
               DCW  002475
               DCW  002605
               DCW  002747
               DCW  002904
               DCW  003077
               DCW  003270
               DCW  003487
               DCW  003732
               DCW  004010
               DCW  004331
               DCW  004704
               DCW  005144
               DCW  005671
               DCW  006313
               DCW  007115
               DCW  008144
               DCW  009514
               DCW  011430
               DCW  014300
               DCW  019081
               DCW  028636
               DCW  057289
               DCW  999999
     *
     *
     *
     * - - T A B L E S    F O R    S I N    A N D    C O S I N E - - 
     *
     *
     *
     SIN00     DCW  0000                EACH ENTRY IS 1000 * SIN
               DCW  0017
               DCW  0034
               DCW  0052
               DCW  0069
     SIN05     DCW  0087
               DCW  0104
               DCW  0121
               DCW  0139
               DCW  0156
     SIN10     DCW  0173
               DCW  0190
               DCW  0207
               DCW  0224
               DCW  0241
     SIN15     DCW  0258
               DCW  0275
               DCW  0292
               DCW  0309
               DCW  0325
     SIN20     DCW  0342
               DCW  0358
               DCW  0374
               DCW  0390
               DCW  0406
     SIN25     DCW  0422
               DCW  0438
               DCW  0453
               DCW  0469
               DCW  0484
               DCW  0500
               DCW  0515
               DCW  0529
               DCW  0544
               DCW  0559
               DCW  0573
               DCW  0587
               DCW  0601
               DCW  0615
               DCW  0629
               DCW  0642
               DCW  0656
               DCW  0669
               DCW  0681
               DCW  0694
               DCW  0707
               DCW  0719
               DCW  0731
               DCW  0743
               DCW  0754
               DCW  0766
               DCW  0777
               DCW  0788
               DCW  0798
               DCW  0809
               DCW  0819
               DCW  0829
               DCW  0838
               DCW  0848
               DCW  0857
               DCW  0866
               DCW  0874
               DCW  0882
               DCW  0891
               DCW  0898
               DCW  0906
               DCW  0913
               DCW  0920
               DCW  0927
               DCW  0933
               DCW  0939
               DCW  0945
               DCW  0951
               DCW  0956
               DCW  0961
               DCW  0965
               DCW  0970
               DCW  0974
               DCW  0978
               DCW  0981
               DCW  0984
               DCW  0987
               DCW  0990
               DCW  0992
               DCW  0994
               DCW  0996
               DCW  0997
               DCW  0998
               DCW  0999
               DCW  0999
     SIN90     DCW  1000
     *
               END  START   

