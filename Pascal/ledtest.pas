{
   ledtest.pas - test program for ledlib
}

program ledtest;
uses syslib,ledlib;

var j: integer;

proc delay10msec(time:integer);
{*****************************}
{ delay10msec: delay 10 msec }
{ process is suspended during delay }
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

begin
  ledstring('PASCAL  ');
  delay10msec(100);
  ledstring('        ');
  for j:=0 to 255 do
    begin
      ledhex(100*j,0,4);
      ledhex(j,5,2);
      delay10msec(1);
    end;
  delay10msec(100);
  for j:=0 to 255 do
    begin
      ledbyte(j);
      delay10msec(1);
    end;
  delay10msec(100);
  ledstop;
end.

 