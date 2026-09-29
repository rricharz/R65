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
end.
 