{ _test15.pas - graphics }

program grtest;
uses syslib,plotlib;

var ch: char;
    i,j: integer;

begin
  _grinit;
  _splitview;
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
  _move(20,20);
  _draw(203,20,WHITE);
  _draw(203,65,WHITE);
  _draw(20,65,WHITE);
  _draw(20,20,WHITE);
  _draw(203,65,WHITE);
  _move(203,20);
  _draw(20,65,WHITE);
  j:=$8000;
  for i:=0 to 15 do begin
    _plot(45+4*i,110,WHITE);
    _plot(45+4*i+1,110,WHITE);
    _plot(45+4*i+2,110,WHITE);
    _plot(45+4*i+3,110,WHITE);
    _plotmap(45+4*i,112,j);
    j:=j shr 1;
  end;
  _move(25,5);
  write(@PLOTDEV,'Testing string display')
end.
