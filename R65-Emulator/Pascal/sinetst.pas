{ sinetest.pas }

program sinetst;
uses syslib,mathlib,plotlib;

var a,b: real;
    i,x,y: integer;
    ch: char;

begin
  _grinit; _cleargr; _splitview;
  _move(0,YSIZE div 2);
  _draw(XSIZE,YSIZE div 2,WHITE);
  for x:=0 to XSIZE do begin
    a:=conv(x)*360./conv(XSIZE);
    b:=sin(a);
    y:=trunc(b*conv(YSIZE)/2.1)+(YSIZE div 2);
    _plot(x,y,WHITE);
  end;
  for x:=0 to XSIZE do begin
    a:=conv(x)*360./conv(XSIZE);
    b:=cos(a);
    y:=trunc(b*conv(YSIZE)/2.1)+(YSIZE div 2);
    _plot(x,y,WHITE);
  end;

  writeln(' angle',TAB8,'  sin',TAB8,'  cos');
  for i:=1 to 24 do begin
    a:=conv(i*15);
    writeln(a:3:0,sin(a):12:4,cos(a):12:4);
  end;
end.
