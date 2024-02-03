{ test15.pas - graphics }

program grtest;
uses syslib,plotlib;

var ch: char;
    i,j: integer;

begin
  grinit;
  cleargr;
  plot(0,0,white);
  plot(223,0,white);
  plot(0,117,white);
  plot(223,117,white);
  move(38,70);
  for i:=0 to 15 do
    write(@plotdev,chr(i+32));
  move(38,80);
  for i:=0 to 15 do
    write(@plotdev,chr(i+48));
  move(38,90);
  for i:=0 to 15 do
    write(@plotdev,chr(i+64));
  move(38,100);
  for i:=0 to 15 do
    write(@plotdev,chr(i+80));
  move(20,20);
  draw(203,20,white);
  draw(203,65,white);
  draw(20,65,white);
  draw(20,20,white);
  draw(203,65,white);
  move(203,20);
  draw(20,65,white);
  j:=$8000;
  for i:=0 to 15 do begin
    plot(45+4*i,110,white);
    plot(45+4*i+1,110,white);
    plot(45+4*i+2,110,white);
    plot(45+4*i+3,110,white);
    plotmap(45+4*i,112,j);
    j:=j shr 1;
  end;
  move(35,5);
  write(@plotdev,'Type any key to quit');
  waitforkey;
  grend;
end.