program grtest2;

uses syslib,plotlib,mathlib;

var xcenter,ycenter:integer;
    ii,radius:integer;

proc drawcircle(x,y,r:integer);
{ _draw a circle, very slow! }
var i,x2,y2: integer; arg:real;
begin
  _move(x+r,y);
  for i:=0 to r do begin
    arg:=conv(i)*360.0/conv(r);
    x2:=x+trunc(conv(r)*cos(arg));
    y2:=y+trunc(conv(r)*sin(arg));
    _draw(x2,y2,WHITE);
  end;
end;

{$I ICHKESC:P}

begin
  xcenter:=XSIZE div 2;
  ycenter:=YSIZE div 2;
  radius:=9*YSIZE div 20;

  _grinit; _cleargr; _splitview;

  drawcircle(xcenter, ycenter, radius);

  _move(xcenter+radius,ycenter);
  for ii:=1 to 360 do begin
    _draw(xcenter+
         trunc(cos(conv(3*ii))*conv(radius)),
         ycenter+
         trunc(sin(conv(4*ii))*conv(radius)),
         WHITE);
    if chkesc(true) then begin
      _splitview; exit;
    end;
  end;
end.
