{  Plot routines for Tektronix 4014 graphics
   on the R65 PRINTER port. On the original
   R65 computer, a PRINTER or PLOTTER could
   be hooked up using RS-232. On the R65
   emulator, the OUTPUT is stored in the Linux
   file printout.txt. The tek4010 tektronix
   emulator (github.com/rricharz/tek4010) must
   be installed. starttek opens a tek4010 window }

{$U+}

library tek4klib;

const MAXX = 4091; { Tektronix 4010 graphic mode }
      MAXY = 3071;

      MAXCOLUMNS = 74;
      MAXLINES   = 35;

      SOLID      = 1;
      DOTTED     = 2;
      DOTDASH    = 3;
      SHORTDASH  = 4;
      LONGDASH   = 5;

      PLOTTER    = @1;

      { tek4010 window modes }
      T_FULLV    = 1;
      T_FAST     = 2;
      T_BOTH     = 3; { T_FULLV or T_FAST }

var   _xs,_ys: integer;

proc _delay10msec(time:integer);
{ _delay10msec: delay 10 msec }
{ process is suspended during delay }
mem
{$I IHIDDENMEM}
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

proc _clearscreen;
begin
  write(@PLOTTER,chr(27),chr(12));
end;

proc _starttek(mode: integer);
{ Switch R65 PRINTER device to raw mode
  and start tek4010. All R65 system functions
  are hidden. tek4010 is called with the following
  arguments

  T_HALF  start with -half, else with -fullv
  T_FAST  start in fast mode, else 192000 baud
  T_BOTH for both                               }


const C_SHELL  = 10;
      STOPCODE = $2010;
      NORVID   = chr($0b);
      INVVID   = chr($0e);

mem   str    = $0004: cpnt;
      RUNERR = $000c: integer&;

{$I IHIDDENMEM:P}

var dummy, res: integer;

  func sh(s: cpnt): integer;
  { uses flp scratch register to transfer pointer }
  var result:   integer;
  begin
    str := s;
    emucom := (C_SHELL);
    sh  := emures;
  end;

begin {starttek}

  dummy := sh('truncate -s 0 printout.txt');
  _delay10msec(5);
  res := sh('pgrep -x tek4010 >/dev/null');

  if res <> 0 then begin

    case mode of
      0:
          dummy := sh('./r65tek 0 &');
      T_FULLV:
          dummy := sh('./r65tek 1 &');
      T_FAST:
          dummy := sh('./r65tek 2 &');
      T_BOTH:
          dummy := sh('./r65tek 3 &')
        else
          dummy := sh('./r65tek 0 &')
    end;

    _delay10msec(50);
    res := sh('pgrep -x tek4010 >/dev/null');
    if res <> 0 then begin
      writeln(INVVID,'tek4010 did not start', NORVID);
      RUNERR := 54;
        call(STOPCODE);
    end;
  end;

    emucom := 11; { start raw mode }
    _clearscreen;

end {starttek};

proc _endtek;
{ switch R65 PRINTER device to normal mode
  tek4010 window is not closed }
mem
{$I IHIDDENMEM:P}
begin
  emucom := 12; { end raw mode }
end;

proc _startdraw(x1,y1:integer);
var x,y,xy4014: integer;
begin
  x:=x1;
  y:=y1;
  if x<0 then x:=0;
  if x>=MAXX then x:=MAXX-1;
  if y<0 then y:=0;
  if y>=MAXY then y:=MAXY-1;
  xy4014 := 96 + ((y and 3) shl 2) + (x and 3);
  write(@PLOTTER,chr(29));
  write(@PLOTTER,chr((y shr 7)+32));
  write(@PLOTTER,chr(xy4014));
  write(@PLOTTER,chr(((y shr 2) and 31)+96));
  write(@PLOTTER,chr((x shr 7)+32));
  write(@PLOTTER,chr(((x shr 2) and 31)+64));
  _xs:=x;
  _ys:=y;
end;

proc _draw(x2,y2:integer);
var x,y,xy4014: integer;
    hxchange:boolean;
begin
  x:=x2;
  y:=y2;
  if x<0 then x:=0;
  if x>=MAXX then x:=MAXX-1;
  if y<0 then y:=0;
  if y>=MAXY then y:=MAXY-1;
  xy4014 := 96 + ((y and 3) shl 2) + (x and 3);
  if (y shr 7)<>(_ys shr 7) then
    write(@PLOTTER,chr((y shr 7)+32));
  write(@PLOTTER,chr(xy4014));
  hxchange:=(x shr 7) <> (_xs shr 7);
  write(@PLOTTER,chr(((y shr 2) and 31)+96));
  if hxchange then
    write(@PLOTTER,chr((x shr 7)+32));
  write(@PLOTTER,chr(((x shr 2) and 31)+64));
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

