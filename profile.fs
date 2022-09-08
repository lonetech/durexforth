#! /usr/bin/env gforth-fast

$10000 cells constant size

create cycles size allot
cycles size erase
create execs size allot
execs size erase

\ .C:080d  BA          TSX            - A:00 X:00 Y:00 SP:f6 ..-.....    7081566
\ #1 (Trace  exec 080e)   85/$055,  53/$35
\ .C:080e  8E 12 0D    STX $0D12      - A:00 X:F6 Y:00 SP:f6 N.-.....    7081568
\ #1 (Trace  exec 0811)   85/$055,  57/$39
\ .C:0811  A2 00       LDX #$00       - A:00 X:F6 Y:00 SP:f6 N.-.....    7081572
\ The cycle count is when we reached this instruction,
\ so time spent is available by subtracting from the next time.


: lstrip
  begin
    over c@ bl =
  while
    1 /string
  repeat
;

: parse-lines  ( Read Vice trace log )
  0 cycles \ not a real executable address
  begin
    \ Read a line and check we could
    pad dup 90 stdin read-line 0= and
  while
    2dup s" .C:" string-prefix? if
      3 /string
      0.0 2swap hex >number     \ address
      60 /string lstrip         \ skip to cycles
      0.0 2swap decimal >number \ parse cycle
      2drop drop nip            \ drop string and high parts

      ( prevaddr prevcycles logaddr cycles )
      \ cr decimal . space hex . cr
      swap
      cells dup
      execs + 1 swap +!
      cycles +
      ( t0 dtaddr t1 dt1addr )
      2swap ( t1 dt1addr t0 dtaddr )
      swap 3 pick swap - swap +!
    else
      2drop
    then
  repeat
  2drop
;

create labels size allot
labels size erase

: store-label
  dup @ 0= if
    here swap !
    dup c,
    \ 2dup type
    over + swap
    do
      i c@ c,
    loop
  else
    drop drop drop
  then
;

: parse-label
  2dup s" al C:" string-prefix? if
    5 /string
  else 2dup s" al " string-prefix? if
    3 /string
  else
    exit
  then then
  0.0 2swap hex >number  \ address
  2 /string
  2swap drop cells labels +
  store-label
;
: parse-labels ( file-id -- )
  begin
    \ Read a line and check we could
    pad dup 90 3 pick read-line 0= and
  while
    \ cr 2dup type
    ?dup if parse-label else drop then
  repeat
  drop
;

: print-array
  ." addr   hits   time"
  $10000 1 do    \ skip 0 which is not an instruction
    cycles i cells + @
    execs i cells + @
    2dup or if
      cr hex i s>d <# # # # # #> type space decimal 6 .r 10 .r
      i cells labels + @ ?dup if
        space count type
      then
    else
      2drop
    then
  loop
  cr
;

: main
  s" acme.lbl"  r/o open-file 0= if dup parse-labels then
  s" forth.lbl" r/o open-file 0= if dup parse-labels then
  parse-lines
  print-array
;

main
bye
