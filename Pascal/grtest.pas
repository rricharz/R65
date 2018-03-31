{ test15.pas - graphics }

program grtest;
uses syslib,plotlib;

var ch: char;
    i,j: integer;

proc plott20(x,y:integer;
           t:array[19] of char);
var i:integer;
begin
  for i:=0 to 19 do
    plotchar(x+7*i,y,t[i]);
end;

begin
  grinit;
  cleargr;
  plot(0,0,white);
  plot(223,0,white);
  plot(0,117,white);
  plot(223,117,white);
  for i:=0 to 15 do
    plotchar(7*i+50,70,chr(i+32));
  for i:=0 to 15 do
    plotchar(7*i+50,80,chr(i+48));
  for i:=0 to 15 do
    plotchar(7*i+50,90,chr(i+64));
  for i:=0 to 15 do
    plotchar(7*i+50,100,chr(i+80));
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
    plot(65+5*i,110,white);
    plot(65+5*i+1,110,white);
    plot(65+5*i+2,110,white);
    plot(65+5*i+3,110,white);
    plotmap(65+5*i,112,j);
    j:=j shr 1;
  end;
  plott20(35,5,'Type any key to quit');
  read(@key,ch);
  grend;
end.