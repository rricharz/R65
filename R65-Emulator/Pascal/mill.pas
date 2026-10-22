{ MILL/PLOTMILL/TEKMILL - The game of NINE MORRIS

  This game is available in 3 versions
  MILL:     Version for TXTTGR character graphics
  PLOTMILL: Version for the low resolution graphics
  TEKMILL:  Version for the Tektronix 4014 Terminal

  All versions include common code:
  IMILLTOP:P, IMILLCOMM:P and IMILLAI:P

  They use different graphics code:
  MILL:     TXTGRLIB and IMILLTGR
  PLOTMILL: PLOTLIB and IMILLPLOT
  TEKLIB:   TEKLIB and IMILLTEK

  Command line options:
  /P  Do not make a protocol at the Linux level
      in printout.txt during the game
      in Print/timestamps after a game
  /M  No marks (MILL and TEKMILL)

  2026 rricharz and ChatGPT                 }

program mill;
uses txtgrlib, syslib, strlib, striolib;

const
  WHITE=0;
  INVERSE=1;
  BLACK=2;

mem KEYPRESSED=$1785: char&;

proc _delay10msec(time:integer);
mem
{$I IHIDDENMEM}
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

{$I IMILLTOP}
{$I IMILLTGR}
{$I IMILLCOMM}
{$I IMILLAI}

begin
  main;
end.
