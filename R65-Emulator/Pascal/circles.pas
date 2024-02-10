{ circles: display circles on graphics canvas }
program circles;
uses syslib,plotlib,mathlib;

const toggle=chr($0c);

mem   sflag=$1781:integer&;

var   x,y,r:integer;

{$I ICIRCLE:P}

begin
  grinit; cleargr; splitview;
  repeat
    if keypresses=toggle then begin
      write(toggle); keypressed:=chr(0);
    end;
    r := 3 + random div 5;
    x := 40 + r + random div 5;
    y := r + random div 5;
    circle(x,y,r,white);
  until (sflag and $80) <> 0;
  sflag:=sflag and $7f;
end.