{ plot routines for Tektronix 4010 graphics      }
{  on the R65 PRINTER port. On the original      }
{  R65 computer, a PRINTER or PLOTTER could      }
{  be hooked up using RS-232. On the R65         }
{  emulator, the OUTPUT is stored in the Linux   }
{  file printout.txt. The tek4010 tektronix      }
{  emulator (github.com/rricharz/tek4010) can    }
{  be hooked up to the R65 emulator by           }
{  calling tek4010 as follows, if a copy of      }

{  tek4010 is put in the R65-emulator folder.    }

{    ./tek4010 tail -f printout.txt              }

{$U+}

library teklib;

const MAXX = 1023; { Tektronix 4010 graphics     }
      MAXY = 780;

      MAXCOLUMNS = 74; { Tektronix 4010 }
      MAXLINES   = 35;

      SOLID      = 1;
      DOTTED     = 2;
      DOTDASH    = 3;
      SHORTDASH  = 4;
      LONGDASH   = 5;

      PLOTTER    = @1;

var   _xs,_ys: integer;

proc _clearscreen;
begin
  write(@PLOTTER,chr(27),chr(12));
end;

proc _starttek;
{ switch R65 PRINTER device to raw mode }
begin
  write(@PLOTTER,chr(17));
  _clearscreen;
end;

proc _endtek;
{ switch R65 PRINTER device to normal mode }
begin
  write(@PLOTTER,chr(18));
end;

proc _startdraw(x1,y1:integer);
var x,y: integer;
begin
  x:=x1;
  y:=y1;
  if x<0 then x:=0;
  if x>=MAXX then x:=MAXX-1;
  if y<0 then y:=0;
  if y>=MAXY then y:=MAXY;
  write(@PLOTTER,chr(29));
  write(@PLOTTER,chr((y shr 5)+32));
  write(@PLOTTER,chr((y and 31)+96));
  write(@PLOTTER,chr((x shr 5)+32));
  write(@PLOTTER,chr((x and 31)+64));
  _xs:=x;
  _ys:=y;
end;

proc _draw(x2,y2:integer);
var x,y: integer;
    hxchange,lychange:boolean;
begin
  x:=x2;
  y:=y2;
  if x<0 then x:=0;
  if x>=MAXX then x:=MAXX-1;
  if y<0 then y:=0;
  if y>=MAXY then y:=MAXY;
  if (y shr 5)<>(_ys shr 5) then
    write(@PLOTTER,chr((y shr 5)+32));
  hxchange:=(x shr 5) <> (_xs shr 5);
  lychange:=(y and 31) <> (_ys and 31);
  if hxchange or lychange then
    write(@PLOTTER,chr((y and 31)+96));
  if hxchange then
    write(@PLOTTER,chr((x shr 5)+32));
  write(@PLOTTER,chr((x and 31)+64));
  _xs:=x;
  _ys:=y;
end;

proc _enddraw;
begin
  write(@PLOTTER,chr(31));
end;

proc _drawvector(x1,y1,x2,y2:integer);
begin
  _startdraw(x1,y1);
  _draw(x2,y2);
  _enddraw;
end;

proc _drawrectangle(x1,y1,x2,y2:integer);
begin
  _startdraw(x1,y1);
  _draw(x2,y1);
  _draw(x2,y2);
  _draw(x1,y2);
  _draw(x1,y1);
  _enddraw;
end;

proc _moveto(x1,y1: integer);
{ move in graphics coordinate space }
begin
  _startdraw(x1,y1);
  _enddraw;
end;

proc _delay10msec(time:integer);
{ _delay10msec: delay 10 msec }
{ process is suspended during delay }
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

proc _setchsize(size:integer);
{ set character size }
begin
  if (size>=1)and(size <= 4) then begin
  write(@PLOTTER,chr(27));
  write(@PLOTTER,chr(ord('7') + size));
  end;
end;

proc _setlinemode(type:integer);
begin
  if (type>=SOLID)and(type<=LONGDASH) then begin
    write(@PLOTTER,chr(27));
    write(@PLOTTER,chr(95+type));
  end;
end;

begin
end.
 