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
  r := 3 + random div 5;
  x := irandom(r div 2, xsize - r div 2);
  y := irandom(r div 2, ysize - r div 2);
  circle(x,y,r,white);
end;

func exkey(ch:char):boolean;
begin
  exkey := (ch = chr(0));  { stop on escape }
  { otherwise nothing to do }
end;

{$I IANIMATE:P}

begin
  grinit; cleargr; fullview;
  animate(autorepeat);
  splitview;
end.