               JOB  Compute the square root of 2 to 100 decimal places
               CTL  6611
     *
     * Print header.
     *
     START     CS   332
               CS
               MCW  N,332
               MCW  LABEL1
               W
               CS   332
               CS
               W
     *
     * Newton's algorithm:
     *
     *     x = xprev;
     *     while (x != xprev) {
     *         xprev = x;
     *         x = (x + n/x)/2;
     *     }
     *
     * X = upper half of N
     *
               ZA   N&100,X            +dp
     *
     * Is X = XPREV?
     *
     LOOP      C    X,XPREV
               B    DONE,S             done if yes
               A    @1@,ITERS
     *
     * XPREV = X
     *
               ZA   X,XPREV
     *
     * X = (N/X + X)/2
     *
               ZA   N&200,TEMP&103     +2*dp, +len(N) + dp + 1
               D    X,TEMP-97          +len(N) - dp + 1
               SW   TEMP-102           -(len(N) + dp)
               A    X,TEMP
               ZA   TEMP,X&2           +2
               D    @2@,X-100          -(len(N) + dp) + 2
               CW   TEMP-102           -(len(N) + dp)
     *
     * Print X and loop again.
     *
               LCA  EDIT,332
               MCE  X,332
               W
               B    LOOP
     *
     * Print number of iterations.
     *
     DONE      CS   332
               CS
               W
               CS   332
               CS
               MCW  LABEL2,332
               MCW  ITERS
               W
     FINIS     H    FINIS
               H
     *
     N         DCW  02
               DC   #200               len = 2*dp
     *
     X         DCW  #102               len = len(N) + dp
               DC   #2                 remainder of /2: len = 2
     *
     XPREV     DCW  #102               len = len(X)
     *
     TEMP      DCW  #202               len = len(N) + 2*dp
               DC   #103               remainder of /X: len = len(X) + 1
     *
     ITERS     DCW  000
     *
               DCW  @0.@
     EDIT      DC   #100               len = dp
     *
     LABEL1    DCW  @The square root of @
     LABEL2    DCW  @ iterations@
               END  START
