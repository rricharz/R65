library teklib;

{ plot routines for Tektronix 4010 graphics
  on the R65 printer port. On the original
  R65 computer, a printer or plotter could
  be hooked up using RS-232. On the R65
  emulator, the output is stored in the Linux
  file printout.txt. The tek4010 tektronix
  emulator (github.com/rricharz/tek4010) can
  be hooked up to the R65 emulator by
  calling tek4010 as follows, if a copy of
  tek4010 is put in the R65-emulator folder.

    ./tek4010 tail -f printout.txt           }

const maxx = 1023; { Tektronix 4010 graphics }
      maxy = 780;

      maxcolumns = 74; { Tektronix 4010 alpha }
      maxlines   = 35;

      solid      = 1;
      dotted     = 2;
      dotdash    = 3;
      shortdash  = 4;
      longdash   = 5;

      plotter    = @1;

var   xs,ys: integer;

proc clearscreen;
begin
  write(@plotter,chr(27),chr(12));
end;

proc starttek;
{ switch R65 printer device to raw mode }
begin
  write(@plotter,chr(17));
  clearscreen;
end;

proc endtek;
{ switch R65 printer device to normal mode }
begin
  write(@plotter,chr(18));
end;

proc startdraw(x1,y1:integer);
var x,y: integer;
begin
  x:=x1;
  y:=y1;
  if x<0 then x:=0;
  if x>=maxx then x:=maxx-1;
  if y<0 then y:=0;
  if y>=maxy then y:=maxy;
  write(@plotter,chr(29));
  write(@plotter,chr((y shr 5)+32));
  write(@plotter,chr((y and 31)+96));
  write(@plotter,chr((x shr 5)+32));
  write(@plotter,chr((x and 31)+64));
  xs:=x;
  ys:=y;
end;

proc draw(x2,y2:integer);
var x,y: integer;
    hxchange,lychange:boolean;
begin
  x:=x2;
  y:=y2;
  if x<0 then x:=0;
  if x>=maxx then x:=maxx-1;
  if y<0 then y:=0;
  if y>=maxy then y:=maxy;
  if (y shr 5)<>(ys shr 5) then
    write(@plotter,chr((y shr 5)+32));
  hxchange:=(x shr 5) <> (xs shr 5);
  lychange:=(y and 31) <> (ys and 31);
  if hxchange or lychange then
    write(@plotter,chr((y and 31)+96));
  if hxchange then
    write(@plotter,chr((x shr 5)+32));
  write(@plotter,chr((x and 31)+64));
  xs:=x;
  ys:=y;
end;

proc enddraw;
begin
  write(@plotter,chr(31));
end;

proc drawvector(x1,y1,x2,y2:integer);
begin
  startdraw(x1,y1);
  draw(x2,y2);
  enddraw;
end;

proc drawrectange(x1,y1,x2,y2:integer);
begin
  startdraw(x1,y1);
  draw(x2,y1);
  draw(x2,y2);
  draw(x1,y2);
  draw(x1,y1);
  enddraw;
end;

proc moveto(x1,y1: integer);
{ move in graphics coordinate space }
begin
  startdraw(x1,y1);
  enddraw;
end;

proc delay10msec(time:integer);
{ delay10msec: delay 10 msec }
{ process is suspended during delay }
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

begin
end. 