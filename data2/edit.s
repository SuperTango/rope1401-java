               JOB  EDIT PROGRAM
               INCLDPREAMBLE.S
               ORG  350
     *
               DCW  @THIS IS THE PRINT EDIT PROGRAM 5/28/2009@
     MASK      DCW  @      $0.  @           *EDIT MASK
     FIELD     DCW  @00001234@           *FIELD TO BE EDITED
     *
     START     H
     LOOP      CS   PRBUFF&131         *CLEAR 200 TO 332 (& == +)
               CS
               LCA  MASK,PRBUFF&12      *LOAD CONTROL WORD TO PRINT AREA
               MCE  FIELD,PRBUFF&12     *EDIT
               B    LOOP
               NOP    
               END  START
