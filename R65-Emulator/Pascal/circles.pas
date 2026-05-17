{ circles: display circles on graphics canvas }
program circles;
uses syslib,plotlib,mathlib;

const autorepeat=false;

var   x9,y9,r9:integer;

{$I IRANDOM:P}

func expaint:boolean;
begin
  expaint:=false;
  r9 := 3 + _random div 5;
  x9 := irandom(r9 div 2, XSIZE - r9 div 2);
  y9 := irandom(r9 div 2, YSIZE - r9 div 2);
  _circle(x9,y9,r9,WHITE);
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