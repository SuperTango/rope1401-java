module PASS_3_M

! Final assembly and output

  use BCD_TO_ASCII_M, only: Ascii_To_Bcd, Bcd_To_Ascii, B_GRPMRK, B_RECMRK, B_WM
  use ERROR_M, only: AddrErr, BadStatement, Do_Error, ErrCode, ERROR, LabelErr, &
    & MacroErr, NoBXLErr, NoErr, N_Errors, OpErr, Overcall, SymErr, UndefOrg
  use IO_UNITS, only: U_DIAG, U_LIST, U_OBJ, U_SCRATCH, U_TAPE
  use LITERALS_M, only: LITERALS
  use OPERAND_M, only: K_ACTUAL, K_ADCON_LIT, K_ADDR_CON, K_AREA_DEF, &
    & K_ASTERISK, K_BLANK_CON, K_CHAR_LIT, K_DEVICE, K_NUM_LIT, K_SYMBOLIC, &
    & OPERANDS, X00
  use OP_CODES_M, only: OPT, OP_CODES, PRO, REQ
  use SYMTAB_M, only: DUMP_SYMTAB, SYMBOLS
  use ZONE_M, only: NUM_TO_ADDR, ZONED

  implicit NONE
  private

  character, public :: BootLoader = 'I' ! I for IBM
                                        ! N for None
                                        ! V for Van's Favorite 2-card loader
  integer, public :: CoreSize = 16000   ! 1400, 2000, 8000, 12000 or 16000
  integer, public :: Extra = 0          ! See Extra_... below
  integer, parameter, public :: Extra_EX = 1  ! Quick EX/XFR
  integer, parameter, public :: Extra_End = 2 ! Quick END
  integer, parameter, public :: Extra_SWQ = 4 ! Queue SW instructions
  integer, parameter, public :: Extra_NEX = 8 ! No reloader after EX
  logical, save, public :: Interleave   ! Interleave object deck into listing
  integer, save, public :: MaxLine = 53 ! Lines per page
  logical, save, public :: NotIn_1_80   ! Error if code in 1..80

  public :: Pass_3

contains

  subroutine Pass_3 ( Do_List, Do_Object, Do_Tape, Do_Diag )

    logical, intent(in) :: Do_List      ! Make a listing
    logical, intent(in) :: Do_Object    ! Make an object "deck"
    logical, intent(in) :: Do_Tape      ! Make an object "tape"
    logical, intent(in) :: Do_Diag      ! Make a diagnostic format "deck"
                                        ! (one field per card)

    character(71) :: BOOTSTRAP = & ! Bootstrap card
      & ',008015,022029,036040,047054,061068,072/061039              ,0010011040'
    character(*), parameter :: BOOT_T = &    ! Tape bootstrap record
      & 'U%U1B.L%U1020RB001L.020 BOOTSTRAP'
    character(*), parameter :: BOOT_V = &    ! Van's favorite bootstrap/clear card
      & ',008047/047046       /000H025B022100  4/061046,054061,068072,0010401040'
    character(*), parameter :: BOOT_TW = &   ! Word marks for BOOT_T
      & '1    11       1    1   1'
    character(71) :: CARD
    integer :: CARD_NO
    character(71) :: CS1_4 = & ! First clear-storage card -- IBM 4K
      & ',008015,019026,030,034041,045,053,0570571026                           '
      !  1      1      1   1      1   1   1      1   1       1   1
    character(71) :: CS1_6 = & ! First clear-storage card -- IBM 16K
      & ',008015,022026,030037,044,049,053053N000000N00001026                   '
      !  1      1      1      1   1   1      1      1    1   1
    character(71) :: CS2_4 = & ! Second clear-storage card -- IBM 4K
      & 'L068112,102106,113/101099/I99,027A070028)027B0010270B0261,001/001113I0 '
      !  1      1      1   1      14  1   1      1   1       1   32   2      2
    character(71) :: CS2_6 = & ! Second clear-storage card -- IBM 16K
      & 'L068116,105106,110117B101/I9I#071029C029056B026/B001/0991,001/001117I0?'
      !  1      1      1      1   1   1      1      1    1   3   22   2      2
    character(*), parameter :: CST = &   ! Clear-storage record for tape
      & ',200/000H008V0052001L051115L/100099L%U1001R/007199 CLEAR STORAGE'
    character(*), parameter :: CSTW = &  ! Word marks for CST
      & '1   1   1   1       1      11      1       1       '
    character(*), parameter :: CS_V = &  ! Van's favorite clear bootstrap card
      & ',008015,022026,030040/019,001L020100   ,047054,061068,072072)0810811022'
    character :: D
    character(5) ::Deck_Id         ! From the JOB card, for 76:80 of obj deck
    integer :: Diag_No             ! Card number in "diagnostic format" deck
    integer :: DIGIT
    logical :: EndCard             ! "Saw an END card"
    character(71) :: EX1 = & ! First "restart after EX" card
      & ',015022)024056,029036,040047,0540611001,001008B001     ,001008B001     '
    character(71) :: EX2 = & ! Second "restart after EX" card
      & ',068072)063067/061039                                       ,0010011040'
    character :: GMARK             ! Group Mark
    integer :: I
    integer :: INDEX
    integer :: IxLab               ! Index in Symbols of a label
    integer :: Last_Obj_P          ! Last position loaded by object record
    character(80) :: LINE          ! Input line
    integer :: LINE_NO             ! Line number in the page
    character(len=71) :: Loader(3) ! Loader cards
    character(len=21) :: LoadPrefix(3) ! For the listing
    character :: MachineOp
    logical :: NeedCS              ! Need to emit clear-storage cards
    logical :: NeedDiag            ! Need to start diagnostic deck
    logical :: NeedEX              ! Need to emit re-bootstrap after EX or XFR
                                   ! These are needed because Autocoder wants
                                   ! to put the next deck-id into them if a
                                   ! JOB card follows EX or XFR
    integer :: Nrecs               ! Operands(1) if DA
    integer :: Num_Load_Cds        ! Number of load cards
    integer :: Num_Load_Ops        ! In load area of object card
    integer :: Num_Operands        ! in the scratch record
    integer :: Num_Swms            ! Number of set word mark instructions in TSWMS
    character(8) :: Object         ! Where some object output is built up
    integer :: OBJ_POS             ! Last used in data area
    character(5) :: Op_Field       ! line(16:20) or PrevOpText
    integer :: OP_IX
    integer :: ORG                 ! Used as a surrogate for P
    character(52) :: OUTPUT        ! Where some printed output is built up
    integer :: P                   ! Program counter
    integer :: PAGE_NO             ! Page number
    character(52) :: Page_Head     ! Page heading -- from JOB card
    integer :: P_DA                ! P as of last DA
    integer :: P_IN                ! P from the input -- ignored
    integer :: P_SAVE              ! In case DA has numeric label
    integer :: PrevOp              ! Previous Op_Ix
    integer :: SWQ(16000)          ! Set word mark queue
    integer :: SWQH = 1, SWQT = 0  ! Head, Tail of SWQ
    character(*), parameter :: RE_EX = &     ! Quick re-bootstrap after EX
      & ',008047/047046                         N000000,054061,068072,0010401040'
    integer :: RECSIZ              ! Operands(2) if DA
    character :: RMARK             ! Record Mark
    integer :: SEQ                 ! Sequence number
    character :: SFX
    character :: SKIP              ! Page skip for heading, initially '0', then '1'
    character(56) :: TSWMS         ! Set word mark instructions for tape output
    character(5) :: WHY            ! Code for scratch record
    integer :: WIDTH               ! of the code generated from a scratch record
    character :: X                 ! to print X for indexed EQU

    card_no = 1
    obj_pos = 0
    deck_id = ''
    endCard = .false.
    gmark = bcd_to_ascii(B_GRPMRK)
    last_obj_p = -1
    line_no = 0
    needCS = bootLoader /= 'N'
    needEX = .false.
    num_load_ops = 0
    num_swms = 0
    p = 333
    page_head = ''
    page_no = 0
    rmark = bcd_to_ascii(B_RECMRK)
    seq = 100
    sfx = ' '
    skip = '0'
    if ( bootLoader == 'N' ) skip = ' '
    if ( do_object ) then
      card(1:39) = ''
      card(40:67) = 'L001001,040040,040040,040040'
      card(68:) = ''
    end if
    needDiag = do_diag
    rewind ( u_scratch )
    do
      read ( u_scratch, 200, end=999 ) why, line, ixLab, p_in, width, &
        & errCode, num_operands, operands(1:num_operands)
200   format ( a5, a80, 3i6, a1, i6, (4(3i6,a2,a1,a6)) )
      if ( why == 'LITS' ) cycle ! controls timing in pass 2; not used here
      if ( line(6:6) /= '*' .and. line(16:20) == 'JOB' ) then
        if ( extra == 0 ) then
          call flush_sw_queue
          if ( obj_pos > 0 ) call finish_obj ( '1040' )
        end if
        deck_id = line(76:80)
        page_head = line(21:72)
      end if
      if ( needCS ) then
        num_load_cds = 3
        select case ( bootLoader )
        case ( 'B')
          num_load_cds = 1
          loader(1) = boot_v
          loadPrefix(1) = ' BOOTSTRAP NO CLEAR  '
        case ( 'I' )
          loadPrefix = (/ ' CLEAR STORAGE 1     ', &
                       &  ' CLEAR STORAGE 2     ', &
                       &  ' BOOTSTRAP           ' /)
          if ( coreSize <= 4000 ) then
            loader = (/ cs1_4, cs2_4, bootstrap /)
            if ( coreSize == 0 ) then ! Boot only, no clear
              loadPrefix(3) = ' BOOTSTRAP NO CLEAR  '
              num_load_cds = 1
              card_no = 3
            end if
          else
            loader = (/ cs1_6, cs2_6, bootstrap /)
          end if
          call num_to_addr ( coreSize-1, 0, loader(2)(27:29) )
        case ( 'V' )
          num_load_cds = 2
          loader(1:2) = (/ cs_v, boot_v /)
          loadPrefix(1:2) = (/ ' BOOTSTRAP FOR CLEAR ', &
                            &  ' CLEAR OR BOOTSTRAP  ' /)
        end select
        do i = card_no, card_no+num_load_cds-1
          if ( do_list ) write ( u_list, '(a21,a71,i23)' ) &
            & loadPrefix(i), loader(i), i
          if ( do_object ) then
            card = loader(i)
            call finish_obj
          end if
        end do
        line_no = 3
        if ( do_object .and. interleave ) line_no = 5
        if ( do_tape ) then
          call write_tape ( cst, cstw, 80 )
          call write_tape ( boot_t, boot_tw, 80 )
        end if
        needCS = .false.
      end if
      if ( needEX .and. bootLoader /= 'N') then
        if ( iand(extra,extra_ex) == 0 ) then
          card = ex1
          call finish_obj
          card = ex2
          if ( bootLoader == 'V' ) card = boot_v
        else
          card = re_ex
        end if
        call finish_obj
        if ( do_tape ) call write_tape ( boot_t, boot_tw, 80 )
        needEX = .false.
      end if
      output = ''
      p_in = p
      if ( line(6:6) == '*' ) then
        if ( do_list ) then
          if ( line_no >= maxLine .or. skip /= '1' ) call heading
          if ( errCode /= noErr ) then
            seq = seq + 1
            write ( u_list, 300 ) seq, line(1:2), line(3:5), line(6:), why, &
              & trim(errorMsg(errCode))
300         format ( i5, 1x, a2, 1x, a3, 2x, a75, t106, a5: 5x, a)
          else if ( why == '     ' ) then
            seq = seq + 1
            write ( u_list, 310 ) seq, line(1:2), line(3:5), trim(line(6:))
310         format ( i5, 1x, a2, 1x, a3, 2x, a )
          else
            write ( u_list, 320 ) line(1:2), line(3:5), line(6:), why
320         format ( 6x, a2, 1x, a3, 2x, a75, t106, a5: 5x, a)
          end if
          line_no = line_no + 1
        end if
        cycle
      end if
      select case ( why )
      case ( 'ERR' )
        why = ''
        seq = seq + 1
        call listing
      case ( 'FIELD' )
        org = p_da + operands(1)%addr - 1
        if ( maxval(operands(1:2)%addr) > recsiz ) errCode = badStatement
        if ( org > 0 .and. org <= 80 .and. notIn_1_80 ) errCode = addrErr
        do i = 1, nrecs
          seq = seq + 1
          if ( do_object ) then
            if ( num_load_ops >= 6 ) call finish_obj ( '1040' )
          end if
          call sw ( org )
          org = org + recsiz
        end do
        call listing ( loc = p_da + operands(2)%addr - 1 )
      case ( 'MACRO' )
        seq = seq + 1
        call listing
      case ( 'SBFLD' )
        seq = seq + 1
        org = p_da + operands(1)%addr - 1
        if ( operands(1)%addr > recsiz ) errCode = badStatement
        if ( org > 0 .and. org <= 80 .and. notIn_1_80 ) errCode = addrErr
        call listing ( loc = p_da + operands(1)%addr - 1 )
      case default
        if ( why /= 'LIT' .and. why /= 'AREA' .and. why /= 'ADCON' ) seq = seq + 1
        op_field = line(16:20)
        if ( line(16:20) == ' ' ) then
          if ( op_codes(prevOp)%machineOp == 'p' ) &
            & op_field = op_codes(prevOp)%op
        else if ( line(16:18) == ' ' ) then
          machineOp = line(19:19)
          d = line(20:20)
          if ( ascii_to_bcd(iachar(d)) == B_GRPMRK .and. why == '' ) &
            & why = 'GMARK'
          op_ix = 0
        else
          do op_ix = 1, ubound(op_codes,1)
            if ( op_field == op_codes(op_ix)%op ) then
              machineOp = op_codes(op_ix)%machineOp
              exit
            end if
          end do
          d = ' '
        end if
        prevOp = op_ix
        if ( machineOp == ' ' .or. machineOp == 'p' ) then
          p_in = p + width - 1
          select case ( op_field )
          case ( 'CTL' )
            call listing
          case ( 'DA' )
            call test_p ( p )
            p_save = p
            if ( ixlab < 0 ) p = -ixlab
            if ( p > 0 .and. p <= 80 .and. notIn_1_80 ) errCode = addrErr
            p_da = p
            p_in = p
            width = 0
            nrecs = operands(1)%addr
            recsiz = operands(2)%addr
            if ( operands(3)%label(3:3) == rmark ) recsiz = recsiz + 1
            org = p + nrecs*recsiz
            call listing ( loc=p, org=org-1 )
            if ( operands(3)%label(2:2) == 'G' ) org = org + 1
            if ( operands(3)%label(1:1) == 'C' ) &
              & call dc ( '', ' ', p+recsiz*nrecs-1, ixlab, recsiz*nrecs )
            line = ''
            line(16:) = 'DC   @' // rmark // '@'
            p = p_da
            do i = 1, nrecs
              if ( num_load_ops >= 6 ) call finish_obj ( '1040' )
              call sw ( p_in )
              p_in = p_in + recsiz
            end do
            do i = 1, nrecs
              p = p + recsiz
              why = 'RMARK'
              if ( operands(3)%label(3:3) == rmark ) then
                p = p - 1
                call dc ( rmark, ' ', p, 0 )
                call listing ( 1, p-1, card=card_no )
              end if
            end do
            why = 'GMARK'
            line(16:) = 'DCW  @' // gmark // '@'
            if ( operands(3)%label(2:2) == 'G' ) then
              call dc ( gmark, 'W', p, 0 )
              call listing ( 1, p-1, card=card_no )
            end if
            if ( p + width /= org ) print *, 'What went wrong with DA in Pass 3?'
            if ( ixlab < 0 ) p = p_save
          case ( 'DC', 'DCW' )
            call test_p ( p_in )
            if ( ixLab < 0 ) p_in = -ixLab + width - 1
            if ( num_operands == 2 ) operands(1) = operands(2) ! ADCON lit
            select case ( operands(1)%kind )
            case ( k_actual, k_num_lit )
              if ( width <= 0 ) then
                errCode = BadStatement
              else if ( line(21:21) == '+' .or. line(21:21) == '&' .or. &
                & line(21:21) == '-' ) then
                output(:width) = line(22:)
                digit = ichar(output(width:width)) - ichar('0')
                i = 2
                if ( line(21:21) /= '-' ) i = 3
                output(width:width) = zoned(digit,i)
              else
                output(:width) = line(21:)
              end if
              call dc ( output(:width), line(18:18), p_in, ixLab )
              call listing ( width, p_in, card=card_no )
            case ( k_adcon_lit )
              org = literals(operands(1)%addr)%addr
              call num_to_addr ( org, 0, output(1:3) )
              call dc ( output(:3), line(18:18), p_in, ixLab )
              call listing ( 3, p_in, output, card=card_no )
            case ( k_addr_con )
              if ( operands(1)%addr < 0 ) then
                org = -1
                index = 0
              else
                org = symbols(operands(1)%addr)%value
                if ( org >= 0 ) then
                  org = org + operands(1)%offset
                  if ( line(21:21) == '-' ) org = 16000 - org
                end if
                index = symbols(operands(1)%addr)%index
              end if
              if ( operands(1)%index /= ' ' ) &
                & read ( operands(1)%index, '(i1)' ) index
              call num_to_addr ( org, index, output(1:3) )
              if ( output(1:3) == '###' ) errCode = symErr
              call dc ( output(:3), line(18:18), p_in, ixLab )
              call listing ( 3, p_in, output, card=card_no )
            case ( k_area_def, k_blank_con )
              output = ''
              call dc ( output(:width), line(18:18), p_in, ixlab )
              call listing ( width, p_in, card=card_no )
            case ( k_char_lit )
              call dc ( line(22:21+width), line(18:18), p_in, ixLab )
              if ( width == 1 .and. &
                & ascii_to_bcd(iachar(line(22:22))) == B_GRPMRK .and. &
                & why == '' ) why = 'GMARK'
              call listing ( width, p_in, card=card_no )
            case ( k_device )
              call dc ( line(21:23), line(18:18), p_in, ixLab )
              call listing ( 3, p_in, card=card_no )
            end select
          case ( 'DS' )
            call test_p ( p_in )
            call listing ( loc=p_in )
            p = p + width
          case ( 'DSA' )
            call test_p ( p_in )
            if ( ixLab < 0 ) p_in = -ixLab + width - 1
            select case ( operands(1)%kind )
            case ( k_actual )
              org = operands(1)%addr + operands(1)%offset
              read ( operands(1)%index, '(i1)' ) index
              call num_to_addr ( org, index, output(1:3) )
              if ( output(1:3) == '###' ) errCode = symErr
              call dc ( output(:3), 'W', p_in, ixlab )
              call listing ( 3, p_in, output, card=card_no )
            case ( k_asterisk )
              org = p + 2 + operands(1)%offset
              read ( operands(1)%index, '(i1)' ) index
              call num_to_addr ( org, index, output(1:3) )
              if ( output(1:3) == '###' ) errCode = symErr
              call dc ( output(:3), 'W', p_in, ixlab )
              call listing ( 3, p_in, output, card=card_no )
            case ( k_symbolic )
              org = symbols(operands(1)%addr)%value + operands(1)%offset
              index = symbols(operands(1)%addr)%index
              if ( operands(1)%index /= ' ' ) &
                & read ( operands(1)%index, '(i1)' ) index
              call num_to_addr ( org, index, output(1:3) )
              if ( output(1:3) == '###' ) errCode = symErr
              call dc ( output(:3), 'W', p_in, ixlab )
              call listing ( 3, p_in, output, card=card_no )
            end select
          case ( 'END' )
            endCard = .true.
            call flush_sw_queue
            select case ( operands(1)%kind )
            case ( k_actual )
              org = operands(1)%addr
            case ( k_symbolic )
              org = symbols(operands(1)%addr)%value
            end select
            object = '/   080'
            call num_to_addr ( org, 0, object(2:4) )
            if ( object(2:4) == '###' ) errCode = symErr
            call spread ( (/ 1, 3, 3 /) )
            if ( do_object ) then
              if ( iand(extra,extra_end) /= 0 .and. &
                & card(61:67) == ',040040' .and. &
                & (obj_pos > 0 .or. num_load_ops > 0) ) then
                card(61:67) = object(1:7)
                call finish_obj ( '1040' )
              else
                if ( obj_pos > 0 .or. num_load_ops > 0 ) call finish_obj ( '1040' )
                card(40:71) = object(1:7)
                call finish_obj
              end if
            end if
            if ( do_tape ) call write_tape ( object(:8), '1      1', 61 )
            if ( do_diag ) call write_diag ( object(:8) )
            call listing ( output=output )
          case ( 'EQU' )
            x = ''
            if ( operands(1)%index >= '1' .and. operands(1)%index <= '3' ) &
             & x = 'X'
            select case ( operands(1)%kind )
            case ( k_actual )
              call listing ( loc=operands(1)%addr+operands(1)%offset, x=x )
            case ( k_asterisk )
              call listing ( loc=p-1+operands(1)%offset, x=x )
            case ( k_symbolic )
              if ( symbols(operands(1)%addr)%dev == '' ) then
                if ( abs(symbols(operands(1)%addr)%value) > 15999 ) &
                  errCode = symErr
                call listing ( &
                  & loc=symbols(operands(1)%addr)%value+operands(1)%offset, x=x )
              else
                call listing ( dev=symbols(operands(1)%addr)%dev )
              end if
            case ( k_device )
              call listing ( dev=operands(1)%label )
            end select
          case ( 'EX', 'XFR' )
            call flush_sw_queue
            width = 0  ! width on scratch file is num_lits
            select case ( operands(1)%kind )
            case ( k_actual )
              org = operands(1)%addr
            case ( k_symbolic )
              org = symbols(operands(1)%addr)%value
            end select
            object(1:1) = 'B'
            call num_to_addr ( org, 0, object(2:4) )
            if ( object(2:4) == '###' ) errCode = symErr
            call spread ( (/ 1, 3 /) )
            if ( do_object ) then
              if ( iand(extra,extra_ex+extra_nex) == 0 ) then
                ! 1401-AU-037 starts a new card
                call finish_obj ( '1040' )
                card(40:46) = 'N000000'
              end if
              card(68:71) = object(1:4)
              call finish_obj
              ! Set up to emit cards after EX or XFR
              needEX = iand(extra,extra_nex) == 0
            end if
            if ( do_tape ) then
              call write_tape ( 'N000000' // object(1:4) // ' ', &
                &               '1      1   1', 61 )
              needEX = .true.
            end if
            if ( do_diag ) call write_diag ( object(:4) )
            call listing ( output=output, card=card_no )
          case ( 'JOB' )
            call heading
            call listing
            if ( needDiag ) then
              write ( u_diag, '(",0080121001",t49,a24,a5," 0A")' ) &
                & page_head(1:24), deck_id
              needDiag = .false.
              diag_no = 1
            end if
          case ( 'LTORG', 'ORG' )
            call do_org
          case ( 'SFX' )
            sfx = line(21:21)
            call listing
          end select
        else
          call test_p ( p )
          object(1:1) = machineOp
          if ( op_codes(op_ix)%d /= opt .and. op_codes(op_ix)%d /= pro .and. &
               op_codes(op_ix)%d /= req ) d = op_codes(op_ix)%d
          select case ( width )
          case ( 1 )
            output(1:1) = object(1:1)
          case ( 2 )
            object(2:2) = d
            if ( num_operands > 0 ) object(2:2) = operands(1)%d
            call spread ( (/ 1, 1 /) )
          case ( 4 )
            call do_operand ( 1, object(2:4) )
            call spread ( (/ 1, 3 /) )
          case ( 5 )
            call do_operand ( 1, object(2:4) )
            object(5:5) = d
            if ( num_operands >= 2 ) object(5:5) = operands(2)%d
            call spread ( (/ 1, 3, 1 /) )
          case ( 7 )
            call do_operand ( 1, object(2:4) )
            call do_operand ( 2, object(5:7) )
            call spread ( (/ 1, 3, 3 /) )
          case ( 8 )
            call do_operand ( 1, object(2:4) )
            call do_operand ( 2, object(5:7) )
            if ( num_operands >= 3 ) d = operands(3)%d
            object(8:8) = d
            call spread ( (/ 1, 3, 3, 1 /) )
          end select
          call dc ( object(:width), 'W', p+width-1, 0 )
          if ( ascii_to_bcd(iachar(d)) == B_GRPMRK .and. why == '' ) why = 'GMARK'
          call listing ( width, p-width, output, card=card_no )
        end if
      end select
    end do
999 continue
    if ( .not. endCard ) then
      call flush_sw_queue
      call finish_obj ( '1040' )
    end if
    if ( do_list ) then
      call heading_job
      write ( u_list, 400 )
400   format ( '0', 7('SYMBOL  ADDRESS  ') / )
      call dump_symtab ( u_list, sort=.true. )
    end if
    rewind ( u_scratch )

  contains

    subroutine CLEAR ( HOW_MUCH, WM )
      integer, intent(in) :: HOW_MUCH
      character, intent(in) :: WM            ! 'W' for a word mark
      call dc ( '', wm, p+how_much-1, ixlab, clear=how_much )
    end subroutine CLEAR

    subroutine DC ( WHAT, WM, WHERE, IXLAB, CLEAR )
      character(len=*), intent(in) :: WHAT   ! Stuff to store
      character, intent(in) :: WM            ! Set a word mark if 'W'
      integer, intent(in) :: WHERE           ! Low order end
      integer, intent(in) :: IXLAB           ! Don't increment P if < 0
      integer, intent(in), optional :: CLEAR ! Clear instead of using WHAT
      integer :: A, B                        ! Locations of blanks, @
      character(71) :: DDATA                 ! Diag format data
      integer :: I                           ! Index in WHAT
      intrinsic :: Index
      integer :: L                           ! Length for current piece
      integer :: MyP                         ! Copy of WHERE, maybe incremented
      character :: MyWm
      integer :: N                           ! location of nonblank after B
      logical :: NotGM                       ! char to output is not GM
      integer :: Remain                      ! How much remains to be output
      character(61) :: TDATA, TWMS           ! Tape data and word marks

      integer :: MaxCard                     ! Max data on a card

      myWm = wm
      if ( present(clear) ) then
        maxCard = 38
        remain = clear
      else
        maxCard = 39
        remain = len(what)
      end if
      myP = where - remain + 1
      if ( myP > 0 .and. myP <= 80 .and. notIn_1_80 ) errCode = addrErr
      i = 1
      if ( do_object ) then
        if ( obj_pos > 0 .and. last_obj_p+1 /= myP .or. & ! not contiguous
             ! field won't fit
           & obj_pos + remain > maxCard .and. .not. present(clear) .or. &
           & obj_pos == 0 .and. num_load_ops > 0 .and. myWm /= 'W' ) &
             ! don't lose SWs already set up
           & call finish_obj ( '1040' )
        if ( num_load_ops >= 6 .and. myWm == 'W' ) then
          if ( iand(extra,extra_swq) == 0 ) then
            call finish_obj ( '1040' )
          else ! Put the SW address on the queue
            swqt = swqt + 1
            swq(swqt) = myP
            myWm = ' '
          end if
        end if
        do while ( remain > 0 )
          l = min(remain,maxCard-obj_pos)
          if ( present(clear) ) then
            card(obj_pos+1:maxCard) = ' '
          else
            card(obj_pos+1:maxCard) = what(i:l+i-1)
          end if
          if ( obj_pos == 0 ) then
            if ( myWm /= 'W' ) then
              card(47:47) = ')'
              call num_to_addr ( myP, 0, card(48:50) )
              card(51:53) = card(48:50)
              num_load_ops = 2
            end if
          else if ( myWm == 'W' ) then
            if ( num_load_ops >= 6 ) then
              if ( iand(extra,extra_swq) == 0 ) then
                call finish_obj ( '1040' )
              else ! Put the SW address on the queue
                swqt = swqt + 1
                swq(swqt) = myP
                myWm = ' '
              end if
            end if
            if ( myWm == 'W' ) call sw ( myP, .true. ) ! .true. means "calling from DC"
          end if
          i = i + l
          myP = myP + l
          last_obj_p = myP - 1
          myWm = ' '
          obj_pos = obj_pos + l
          if ( obj_pos == maxCard ) call finish_obj ( '1040' )
          remain = remain - l
        end do
      end if
      myWm = wm
      if ( do_tape ) then
        if ( present(clear) ) then
          remain = clear
        else
          remain = len(what)
        end if
        i = 1
        myP = where - remain + 1
        if ( num_swms > 0 ) call output_swms
        do while ( remain > 0 )
          notGM = .true.
          if ( .not. present(clear) ) notGM = what(i:i) /= gmark
          if ( notGM ) then
            l = min(remain,32)
            tdata(:15) = 'L      N000B007'
            twms       = '1      1   1   1'
            write ( tdata(2:4), '(i3.3)' ) l+34
            call num_to_addr ( myP+l-1, 0, tdata(5:7) )
            if ( myWm == ' ' ) then
              tdata(8:8) = ')'
              call num_to_addr ( myP, 0, tdata(9:11) )
            end if
            if ( present(clear) ) then
              tdata(16:) = ''
            else
              tdata(16:) = what(i:i+l-1)
            end if
          else
            l = min(remain,14)
            tdata(:23) = ',043L      )043043B007 '
            twms       = '1   1      1      1   1'
            write ( tdata(6:8), '(i3.3)' ) l+42
            call num_to_addr ( myP+l-1, 0, tdata(9:11) )
            if ( myWm == ' ' ) call num_to_addr ( myP, 0, tdata(16:18) )
            tdata(24:) = what(i:i+l-1)
          end if
          if ( l <= 8 ) tdata(34:53) = line(16:35)
          call write_tape ( tdata, twms, 61 )
          myWm = ''
          myP = myP + l
          remain = remain - l
          i = i + l
        end do
      end if
      if ( do_diag ) then
        if ( present(clear) ) then
          remain = clear
        else
          remain = len(what)
        end if
        i = 1
        myP = where - remain + 20 ! Beginning of field + 19
        do while ( remain > 0 )
          l = min(remain,20)
          ddata(:11) = 'L031   1001'
          call num_to_addr ( myP, 0, ddata(5:7) )
          ddata(12:32) = what(i:l)
          b = index(line(21:),' ')
          if ( b /= 0 ) then ! there's a blank in the operand field
            a = index(line(21:75),'@')
            if ( a > b ) then
              a = 0  ! @ is in a comment
            else
              a = index(line(21:75),'@',back=.true.) + 21
            end if
            b = max(b+20,a)
            if ( a > 35 ) then
              ddata(33:) = line(a:)
            else if ( b > 35 ) then
              ddata(33:) = line(b:)
            else
              n = verify(line(b:),' ')
              if ( n > 0 ) then
                ddata(33:) = line(min(n+b-1,36):)
              else
                ddata(33:) = ''
              end if
            end if
          end if
          call write_diag ( ddata )
          if ( myWm /= 'W' ) then
            ddata(1:31) = ')002   1001'
            call num_to_addr ( myP-19, 0, ddata(5:7) )
            call write_diag ( ddata )
          end if
          myWm = ''
          remain = remain - l
          myP = myP + l
        end do
      end if
      if ( ixlab >= 0 ) then
        if ( present(clear) ) then
          p = p + clear
        else
          p = p + len(what)
        end if
      end if
    end subroutine DC

    subroutine DO_OPERAND ( WHICH, WHERE )
    ! Process an operand indexed by WHICH, putting the equivalent address
    ! in WHERE.
      integer, intent(in) :: WHICH
      character(3), intent(out) :: WHERE
      integer :: ADDR, INDEX
      index = 0
      where = ''
      select case ( operands(which)%kind )
      case ( k_actual )
        addr = operands(which)%addr
      case ( k_asterisk )
        addr = p + width - 1
      case ( k_adcon_lit, k_addr_con, k_area_def, k_char_lit, k_num_lit )
        addr = literals(operands(which)%addr)%addr
      case ( k_symbolic )
        addr = symbols(operands(which)%addr)%value
        index = symbols(operands(which)%addr)%index
        where = symbols(operands(which)%addr)%dev
      end select
      if ( operands(which)%index /= ' ' ) &
        & read ( operands(which)%index, '(i1)' ) index
      if ( operands(which)%kind /= k_device ) then
        if ( where == '' ) then
          call num_to_addr ( addr+operands(which)%offset, index, where )
          if ( where == '###' ) errCode = symErr
        end if
      else
        where = operands(which)%label
      end if
      if ( which == 1 .and. op_codes(op_ix)%a /= opt .and. &
        & op_codes(op_ix)%a /= pro .and. op_codes(op_ix)%a /= req ) then
        where(1:1) = '%'
        where(2:2) = op_codes(op_ix)%a
      end if
    end subroutine DO_OPERAND

    subroutine DO_ORG
      p_in = p
      select case ( operands(1)%kind )
      case ( k_actual )
        p = operands(1)%addr
      case ( k_asterisk )
      case ( k_symbolic )
        p = symbols(operands(1)%addr)%value
        if ( p < 0 ) errCode = undefOrg
      end select
      if ( operands(1)%offset == x00 ) then
        p = p + 99
        p = p - mod(p,100)
      else
        p = p + operands(1)%offset
      end if
      if ( ixlab <= 0 ) then
        call listing ( org=p )
      else
        call listing ( loc=p_in, org=p )
      end if
    end subroutine DO_ORG

    character(15) function ErrorMsg ( ErrCode )
      character, intent(in) :: ErrCode
      select case ( errCode )
      case ( NoErr )
        errorMsg = ''
      case ( AddrErr )      ! 1 <= address <= 80
        errorMsg = '  ADDR'
      case ( LabelErr )     ! Duplicate
        errorMsg = '  LABEL'
      case ( MacroErr )     ! MACRO ERROR
        errorMsg = '  MACRO ERROR'
      case ( NoBXLErr )     ! No bXl in a DA
        errorMsg = '  NO BXL'
      case ( OpErr )        ! Invalid mnemonic op code
        errorMsg = '  OP'
      case ( Overcall )     ! More than 58 calls in one overlay
        errorMsg = '  OVERCALL'
      case ( SymErr )       ! Undefined symbol
        errorMsg = '  SYM'
      case ( UndefOrg )     ! Undefined ORG or LTORG
        errorMsg = '  UNDEF ORG'
      case ( BadStatement ) ! Lots of reasons
        errorMsg = '  BAD STATEMENT'
      case default
        errorMsg = '  Unknown error'
      end select
    end function ErrorMsg

    subroutine FINISH_OBJ ( TOUCH )
    ! Finish a card or tape record
      character(*), intent(in), optional :: TOUCH ! Finishing touch, for cc 68-71
      if ( do_object ) then
        do while ( swqh <= swqt .and. num_load_ops < 6 )
          call sw ( swq(swqh) )
          swqh = swqh + 1
        end do
        if ( obj_pos > 0 ) then
          card(40:40) = 'L'
          write ( card(41:43), '(i3.3)' ) obj_pos
          call num_to_addr ( last_obj_p, 0, card(44:46) )
        end if
        if ( present(touch) ) card(68:71) = '1040'
        write ( u_obj, 100 ) card, card_no, deck_id
100     format ( a71, i4.4, a5 )
        if ( do_list .and. interleave ) then
          if ( line_no >= maXline .or. skip /= '1' ) call heading
          write ( u_list, 110 ) card, card_no, deck_id
110       format ( '&', a71, i4.4, a5 )
          line_no = line_no + 1
        end if
        card(1:39) = ''
        card(40:67) = 'L001001,040040,040040,040040'
        card(68:) = ''
        card_no = card_no + 1
      end if
      obj_pos = 0
      num_load_ops = 0
    end subroutine FINISH_OBJ

    subroutine FLUSH_SW_QUEUE
      if ( .not. do_object ) return
      do while ( swqt >= swqh )
        if ( num_load_ops >= 6 ) call finish_obj ( '1040' )
        call sw ( swq(swqh), .true. )
        swqh = swqh + 1
      end do
    end subroutine FLUSH_SW_QUEUE

    subroutine HEADING
      if ( do_list ) then
        call heading_job
        write ( u_list, 110 )
110     format ( '0 SEQ PG LIN  LABEL  OP    OPERANDS',44x, &
          &      'SFX CT  LOCN  INSTRUCTION TYPE  CARD' )
        write ( u_list, * )
        line_no = line_no + 2
      end if
    end subroutine HEADING

    subroutine HEADING_JOB
      page_no = page_no + 1
      write ( u_list, 100 ) skip, page_head, deck_id, page_no
100   format ( a1, 26x, a52, 7x, a5, 15x, 'PAGE', i5 )
      if ( skip == '1' ) line_no = 0
      line_no = line_no + 1
      skip = '1'
    end subroutine HEADING_JOB

    subroutine LISTING ( WIDTH, LOC, OUTPUT, ORG, CARD, DEV, X )
      integer, intent(in), optional :: WIDTH, LOC, ORG, CARD
      character(len=*), optional :: OUTPUT, DEV, X
      character(len=24) :: EndLine ! Stuff between SFX and WHY
      character(len=132) :: PrintLine   ! To assemble the line, so it can be trimmed
      character(len=5) :: PrintCard ! to print CARD (or not)
      character(len=5) :: PrintSeq ! to print SEQ (or not)
      if ( do_list ) then
        if ( line_no >= maxLine .or. skip /= '1' ) call heading
        if ( why == '' .or. why == 'MACRO' .or. why == 'GMARK' &
          & .or. why == 'GEN' .or. why == 'FIELD' .or. why == 'SBFLD' ) then
          write ( printSeq, '(i5)' ) seq
        else
          printSeq = ' '
        end if
        endLine = ''
        printCard = ''
        if ( present(width) ) write ( endLine(1:4), '(i4)' ) width
        if ( present(loc) ) write ( endLine(5:10), '(i6.4)' ) loc
        if ( present(org) ) write ( endLine(11:17), '(i7.4)' ) org
        if ( present(x) ) endLine(12:12) = x
        if ( present(output) ) endLine(13:) = output
        if ( present(card) .and. do_object ) then
          write ( printCard, '(i5)' ) card
          if ( obj_pos == 0 ) write ( printCard, '(i5)' ) card - 1
        end if
!       if ( present(dev) ) endLine(15:17) = dev
        if ( present(dev) ) endLine(7:9) = dev
        if ( errCode /= noErr ) n_errors = n_errors + 1
        write ( printLine, 10 ) printSeq, line(1:2), line(3:5), line(6:11), &
          & line(16:20), line(21:72), sfx, endLine, why, printCard, &
          & trim(errorMsg(errCode))
10      format ( a5, 1x, a2, 1x, a3, 2x, a6, 1x, a5, 1x, a52, 1x, a1, a24, &
          & a5, a5, a )
        write ( u_list, '(a)' ) trim(printLine)
        line_no = line_no + 1
      end if
    end subroutine LISTING

    subroutine OUTPUT_SWMS
      ! Output the buffer of set word mark instructions to the object tape
      integer :: I, N
      character(54) :: WMBUF       ! Word marks for set word mark instructions
      if ( num_swms > 0 .and. do_tape ) then
        n = 3*num_swms + num_swms / 2 + 2
        i = 1
        wmbuf = ''
        do while ( i < n )
          wmbuf(i:i) = '1'
          i = min(i+7,n)
        end do
        wmbuf(i:i+4) = '1   1'
        tswms(i:) = 'B007'
        call write_tape ( tswms, wmbuf, 61 )
        num_swms = 0
      end if
    end subroutine OUTPUT_SWMS

    subroutine SPREAD ( HOW_MANY )
      ! Spread OBJECT into OUTPUT.  HOW_MANY is an array, each element of
      ! which indicates the number of characters in a field.
      integer, intent(in) :: HOW_MANY(:)
      integer :: I, J, K ! Indices for how_many, output, object
      integer :: N
      k = 1
      j = 1
      do i = 1, ubound(how_many,1)
        n = how_many(i)
        output(j:j+n-1) = object(k:k+n-1)
        j = j + n + 1
        k = k + n        
      end do
    end subroutine SPREAD

    subroutine SW ( MyP, FromDC )
      ! Generate a set word mark instruction in the load area
      integer, intent(in) :: MyP
      logical, intent(in), optional :: FromDC     ! "Called from DC"
      integer :: J                           ! Index in CARD for SW address
      if ( myP > 0 .and. myP <= 80 .and. notIn_1_80 ) errCode = addrErr
      if ( do_object ) then
        j = 3*num_load_ops + num_load_ops / 2 + 48
        call num_to_addr ( myP, 0, card(j:j+2) )
        num_load_ops = num_load_ops + 1
      end if
      if ( do_tape .and. .not. present(fromDC) ) then
        if ( num_swms == 0 ) then
          tswms = ',      ,      ,      ,      ,      ,      ,'
        else if ( num_swms >= 14 ) then
          call output_swms
        end if
        j = 3*num_swms + num_swms / 2 + 2
        call num_to_addr ( myP, 0, tswms(j:j+2) )
        num_swms = num_swms + 1
      end if
    end subroutine SW

    subroutine TEST_P ( P_TO_TEST )
      ! If ixLab > 0, test whether its P is the same as P_TO_TEST
      integer, intent(in) :: P_TO_TEST
      character(6) :: P_Before, P_Now
      if ( ixLab <= 0 ) return
      if ( symbols(ixlab)%value /= p_to_test .and. &
        & symbols(ixlab)%value >= 0 .and. p_to_test >= 0 ) then
        write ( p_before, '(i6)' ) symbols(ixlab)%value
        write ( p_now, '(i6)' ) p_to_test
        call do_error ( 'Definition of ' // trim(line(6:11)) // ' (' // &
          & trim(adjustl(p_before)) // ') different from current P (' // &
          & trim(adjustl(p_now)) // ')' )
        errCode = symErr
      end if
    end subroutine TEST_P

    subroutine Write_Diag ( DATA )
      ! Write a record to the diagnostic deck.  The deck ID goes in 73-77
      ! and diag_no goes in 78-80.
      character(len=*), intent(in) :: Data
      diag_no = diag_no + 1
      write ( u_diag, '(a,t73,a5,i3.2)' ) data, deck_id, diag_no
    end subroutine Write_Diag

    subroutine WRITE_TAPE ( DATA, WMS, N )
      ! Write data with word marks.  Put the first four characters of the ID
      ! at the end of the record.  The last position gets a group mark and
      ! word mark.
      ! The word mark and group mark are taken from bcd_to_ascii.
      character(len=*), intent(in) :: DATA, WMS   ! Data and Word Marks
      integer, intent(in) :: N     ! Data length, either 80 or 61
      character(160) :: Buffer     ! Room for 80 characters and word marks
      integer :: I, J              ! Input, Buffer positions
      j = 0
      do i = 1, max(len(data),len(wms))
        if ( i <= len(wms) ) then
          if ( wms(i:i) == '1' ) then
            j = j + 1
            buffer(j:j) = bcd_to_ascii(B_WM)
          end if
        end if
        if ( i <= len(data) ) then
          j = j + 1
          buffer(j:j) = data(i:i)
        end if
      end do
      i = len(data)
      buffer(j+1:n-5-i+j) = ' '
      buffer(n-4-i+j:n+1-i+j) = deck_id(1:4) // &
        & bcd_to_ascii(B_WM) // bcd_to_ascii(B_GRPMRK)
      write ( u_tape, '(a)' ) buffer(:n+1-i+j)
    end subroutine WRITE_TAPE

  end subroutine Pass_3

end module PASS_3_M

! $Log: pass_3_m.f90,v $
! Revision 1.1  2009/10/13 08:02:34  altitude
! Initial revision
!
!
! 2005-02-28: Repair 2-character ops with zero operands (D from op_codes)
