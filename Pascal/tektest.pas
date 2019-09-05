program tektest;

uses syslib,teklib,mathlib;

var xcenter,ycenter:integer;
    ii,radius:integer;

proc drawcircle(x,y,r:integer);
{ draw a circle, very slow! }
var i,x2,y2: integer; arg:real;
begin
  startdraw(x+r,y);
  for i:=0 to r do begin
    arg:=conv(i)*360.0/conv(r);
    x2:=x+trunc(conv(r)*cos(arg));
    y2:=y+trunc(conv(r)*sin(arg));
    draw(x2,y2);
  end;
  enddraw;
end;

begin
  xcenter:=maxx div 2;
  ycenter:=maxy div 2;
  radius:=9*maxy div 20;

  starttek;
  moveto(450,760);
  write(@plotter,'tektest');

  drawcircle(xcenter,ycenter,radius);

  moveto(10,10);
  delay10msec(200);
  clearscreen;

  startdraw(xcenter+radius,ycenter);
  for ii:=1 to 360 do begin
    draw(xcenter+
         trunc(cos(conv(3*ii))*conv(radius)),
         ycenter+
         trunc(sin(conv(4*ii))*conv(radius)));
  end;
  enddraw;
  moveto(10,10);

  endtek;
end. 