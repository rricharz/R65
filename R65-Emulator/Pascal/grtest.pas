{ grtest.pas - test graphics }

program grtest;
uses syslib,plotlib,spritelib;

const
    autorepeat    = false;
    STEP          = 2;
    STEPSPERFRAME = 2;

var ch:                char;
    i,j, frame:        integer;
    ax, lastax, stepx: integer;

func expaint: boolean;
begin
  expaint := false;
  if lastax > 0 then
    _showsprite(lastax, 51, S_CLEAR);
  if stepx > 0 then
    _showsprite(ax, 51,
      S_RIGHT + frame div STEPSPERFRAME )
  else
    _showsprite(ax, 51,
      S_LEFT + frame div STEPSPERFRAME);
  frame := frame + 1;
  if frame >= 3 * STEPSPERFRAME then frame := 0;
  lastax := ax;
  ax := ax + stepx;
  if ((stepx > 0) and (ax > 195)) or
     ((stepx < 0) and (ax < 24)) then
    stepx := -stepx;
end;

func exkey(ch:char):boolean;
begin
 exkey := (ch = chr(0));  { stop on escape }
end;

{$I IANIMATE:P}

begin
  _grinit;
  _fullview;
  _cleargr;

  _plot(0,0,WHITE);
  _plot(223,0,WHITE);
  _plot(0,117,WHITE);
  _plot(223,117,WHITE);
  _move(38,70);
  for i:=0 to 15 do
    write(@PLOTDEV,chr(i+32));
  _move(38,80);
  for i:=0 to 15 do
    write(@PLOTDEV,chr(i+48));
  _move(38,90);
  for i:=0 to 15 do
    write(@PLOTDEV,chr(i+64));
  _move(38,100);
  for i:=0 to 15 do
    write(@PLOTDEV,chr(i+80));
  { rectangle }
  _move(20,20);
  _draw(203,20,WHITE);
  _draw(203,50,WHITE);
  _draw(20,50,WHITE);
  _draw(20,20,WHITE);
  { diagonals }
  _draw(203,50,WHITE);
  _move(203,20);
  _draw(20,50,WHITE);
  { string }
  _move(24,5);
  write(@PLOTDEV,'Testing string display');

  frame := 0;
  ax := 20;
  stepx := STEP;
  lastax := -1;
  animate(autorepeat);
  _splitview;
end.
