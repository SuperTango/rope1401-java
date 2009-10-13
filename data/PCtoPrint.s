     *   1         2         3         4        5          6         7
     *789012345678901234567890123456789012345678901234567890123456789012
     *LABEL    OP---OPERAND---------------------------------------------
     * 
     * THIS PROGRAM IS INTENDED TO BE BOOTED FROM TAPE DRIVE 1.
     * IT WILL THEN READ RECORDS FROM TAPE DRIVE 4 AND PRINT THEM.
     *
     BEGPRT    EQU  201
     ENDPRT    EQU  333
     * 
               ORG  400       BEGINNING OF PROGRAM
     START     CS   ENDPRT    CLEAR THE PRINTER AREA  300-333
               CS             CONTINUE THE CLEAR OPERATION 200-299                                             
               LCA  GMWM,ENDPRT SET A TERMINATING GMWM
               RT   4,BEGPRT  READ A TAPE RECORD INTO THE PRINTER AREA
               BEF  TAPEEN    BRANCH IF END OF REEL INDICATION
               BER  TAPEER    BRANCH IF TAPE ERROR
               MLC  ZERO,RTRYCT ZERO RETRY COUNT
               W    START     PRINT THE LINE AND BRANCH TO BEGINNING
     * *****************************************************************
     * *****   TAPE ERROR RECOVERY ROUTINE
     * *****************************************************************
     TAPEER    A    ONE,RTRYCT
               BCE  TAPEES,RTRYCT,3 IF COUNT = 3, BRANCH
               BSP  4         BACKSPACE A RECORD ON DRIVE 4
               B    START
     *  THIS CODE HANDLES THE RETRY GIVE-UP
     TAPEES    MLC  ERRMSG,BEGPRT MOVE THE ERROR MESSAGE TO THE PRINTER
               MLC  ZERO,RTRYCT
               W    START      SKIP TO THE NEXT RECORD
     * *****************************************************************
     * *****   END OF TAPE ROUTINE
     * *****************************************************************
     TAPEEN    H    TAPEE1,CDSTOP  HALT AND DISPLAY THE STOP CODE IN B
     TAPEE1    RWD  4           REWIND THE DATA TAPE
               B    START       START OVER
     * *****************************************************************
     * *****************************************************************
     * *****   BEGIN CONSTANTS AND DATA VARIABLE AREA
     * *****************************************************************
     * *****************************************************************
     GMWM      DCW  @"@          A GROUP MARK
     ZERO      DCW  @0@          A ZERO
     CDSTOP    DCW  @}@
     ONE       DCW  @1@          A ONE
     RTRYCT    DCW  @0@          THE RECORD READ RETRY COUNT
     ERRMSG    DCW  @*** CAN NOT READ RECORD AT THIS LOCATION. ***@
               END  START
