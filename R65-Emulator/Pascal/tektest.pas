program tektest;

uses syslib,teklib,mathlib;

var xcenter,ycenter:integer;
    ii,radius:integer;

proc drawcircle(x,y,r:integer);
{ _draw a circle, very slow! }
var i,x2,y2: integer; arg:real;
begin
  _startdraw(x+r,y);
  for i:=0 to r do begin
    arg:=conv(i)*360.0/conv(r);
    x2:=x+trunc(conv(r)*cos(arg));
    y2:=y+trunc(conv(r)*sin(arg));
    _draw(x2,y2);
  end;
  _enddraw;
end;

begin
  writeln('Tektronix terminal required');
  xcenter:=MAXX div 2;
  ycenter:=MAXY div 2;
  radius:=9*MAXY div 20;

  _starttek;
  _moveto(450,760);
  write(@PLOTTER,'tektest');

  drawcircle(xcenter,ycenter,radius);

  _moveto(10,10);
  _delay10msec(200);
  _clearscreen;

  _startdraw(xcenter+radius,ycenter);
  for ii:=1 to 360 do begin
    _draw(xcenter+
         trunc(cos(conv(3*ii))*conv(radius)),
         ycenter+
         trunc(sin(conv(4*ii))*conv(radius)));
  end;
  _enddraw;
  _moveto(10,10);

  _endtek;
end.