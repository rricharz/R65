{
   ledtest.pas - test program for ledlib
}

program ledtest;
uses syslib,ledlib;

mem keypressed=$1785: char&;

var mask,j: integer;

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
  writeln('LEDTEST: Test led library');
  writeln('Displaying text PASCAL');
  ledstring('PASCAL  ');
  delay10msec(100);
  ledstring('        ');
  writeln('Displaying hex numbers');
  for j:=0 to 255 do
    begin
      ledhex(100*j,0,4);
      ledhex(j,5,2);
      delay10msec(1);
    end;
  delay10msec(100);
  writeln('Dssplaying binary numbers');
  for j:=0 to 255 do
    begin
      ledbyte(j);
      delay10msec(1);
    end;
  delay10msec(100);
  writeln('Type any key to quit');
  mask:=$0001;
  repeat
    for j:=1 to 8 do
      begin
        delay10msec(5);
        ledbyte(mask);
        mask:=mask shl 1;
      end;
    for j:=1 to 7 do
      begin
        delay10msec(5);
        mask:=mask shr 1;
        ledbyte(mask);
      end;
    mask:=mask shr 1;
    until keypressed<>chr(0);
    keypressed:=chr(0);
  ledstop;
end.

 