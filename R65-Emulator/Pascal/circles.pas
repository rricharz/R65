{ circles: display circles on graphics canvas }
program circles;
uses syslib,plotlib,mathlib;

const toggle=chr($0c);
      autorepeat=false;

mem   sflag=$1781:integer&;

var   x,y,r:integer;

{$I ICIRCLE:P}
{$I IRANDOM:P}

func expaint:boolean;
begin
  expaint:=false;
  r := 3 + _random div 5;
  x := irandom(r div 2, XSIZE - r div 2);
  y := irandom(r div 2, YSIZE - r div 2);
  circle(x,y,r,WHITE);
end;

func exkey(ch:char):boolean;
begin
  exkey := (ch = chr(0));  { stop on escape }
  { otherwise nothing to do }
end;

{$I IANIMATE:P}

begin
  _grinit; _cleargr; _fullview;
  animate(autorepeat);
  _splitview;
end.