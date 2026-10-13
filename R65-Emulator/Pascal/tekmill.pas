{ MILL/TEKMILL - The game of NINE MORRIS

  This game is available in 2 versions
  MILL:    Version for the low resolution graphics
  TEKMILL: Version for the Tektronix 4014 Terminal

  Both versions include common code:
  IMILLTOP:P, IMILLCOMM:P and IMILLAI:P

  They use different graphics code:
  MILL: PLOTLIB and IMILLPLOT
  TEKLIB: TEKLIB and IMILLTEK

  Command line options:
  /P  Make a protocol at the Linux level
      In printout.txt during the game
      In Print/timestamps after a game
  /M  No marks (TEKMILL only)

  2026 rricharz and ChatGPT                 }

program tekmill;

uses teklib, syslib, strlib, striolib;

{ one cannot draw inverse or black on the
tektronix screen, but these constants are
also used for the players }
const
  WHITE      = 0;
  INVERSE    = 1;
  BLACK      = 2;

{$I IMILLTOP}
{$I IMILLTEK}
{$I IMILLCOMM}
{$I IMILLAI:P}

begin
  main;
  _moveto(0,0);
end.
 