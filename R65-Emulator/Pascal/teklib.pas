{  Plot routines for Tektronix 4010 graphics
   on the R65 PRINTER port. On the original
   R65 computer, a PRINTER or PLOTTER could
   be hooked up using RS-232. On the R65
   emulator, the OUTPUT is stored in the Linux
   file printout.txt. The tek4010 tektronix
   emulator (github.com/rricharz/tek4010) must
   be installed. starttek opens a tek4010 window }

{$U+}

library teklib;

const MAXX = 1023; { Tektronix 4010 graphic mode }
      MAXY = 780;

      MAXCOLUMNS = 74;
      MAXLINES   = 35;

      SOLID      = 1;
      DOTTED     = 2;
      DOTDASH    = 3;
      SHORTDASH  = 4;
      LONGDASH   = 5;

      PLOTTER    = @1;

      { tek4010 window modes }
      T_HALF     = 0;   { default }
      T_FULLV    = 1;
      T_GAMING   = 2;

var   _xs,_ys: integer;

proc _clearscreen;
begin
  write(@PLOTTER,chr(27),chr(12));
end;

proc _starttek(mode: integer);
{ Switch R65 PRINTER device to raw mode
  and start tek4010. All R65 system functions
  are hidden. tek4010 is called with the following
  arguments

  mode T_HALF:    -half        (default)
  mode T_FULLV:   -fullv       (for large window)
  mode T_GAMING:  -half -fast  (for games)       }

const C_SHELL  = 10;
      STOPCODE = $2010;
      NORVID   = chr($0b);
      INVVID   = chr($0e);

mem   str    = $0004: cpnt;
      RUNERR = $000c: integer&;

{$I IHIDDENMEM:P}

var dummy, res: integer;

  proc delay10msec(times: integer);
  var icount: integer;
  begin
    for icount := 1 to times do
      emucom:=6;
  end;

  func sh(s: cpnt): integer;
  { uses flp scratch register to transfer pointer }
  var result:   integer;
  begin
    str := s;
    emucom := (C_SHELL);
    sh  := emures;
  end;

begin {starttek}

  dummy := sh('pkill tek4010');
  delay10msec(5);

  dummy := sh('truncate -s 0 printout.txt');
  delay10msec(5);

  case mode of
    T_FULLV: dummy := sh(
        'tek4010 -fullv tail -f printout.txt &');
    T_GAMING: dummy := sh(
        'tek4010 -half -fast tail -f printout.txt &')
    else dummy := sh(
        'tek4010 -half tail -f printout.txt &')
    end {case}
  delay10msec(50);

  res := sh('pgrep -x tek4010 >/dev/null');
  if res <> 0 then begin
    writeln(INVVID, 'tek4010 did not start', NORVID);
    RUNERR := 54;
    call(STOPCODE);
  end;

  write(@PLOTTER,chr(17)); { switch to raw mode }
  _clearscreen;

end {starttek};

proc _endtek;
{ switch R65 PRINTER device to normal mode
  tek4010 window is not closed }
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
mem
{$I IHIDDENMEM}
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
 