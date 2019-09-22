program grtest2;

uses syslib,plotlib,mathlib;

var xcenter,ycenter:integer;
    ii,radius:integer;

proc drawcircle(x,y,r:integer);
{ draw a circle, very slow! }
var i,x2,y2: integer; arg:real;
begin
  move(x+r,y);
  for i:=0 to r do begin
    arg:=conv(i)*360.0/conv(r);
    x2:=x+trunc(conv(r)*cos(arg));
    y2:=y+trunc(conv(r)*sin(arg));
    draw(x2,y2,white);
  end;
end;

begin
  xcenter:=xsize div 2;
  ycenter:=ysize div 2;
  radius:=9*ysize div 20;

  grinit; cleargr;

  drawcircle(xcenter, ycenter, radius);

  move(xcenter+radius,ycenter);
  for ii:=1 to 360 do begin
    draw(xcenter+
         trunc(cos(conv(3*ii))*conv(radius)),
         ycenter+
         trunc(sin(conv(4*ii))*conv(radius)),
         white);
  end;

  waitforkey;
  grend;
end. 