 {
   ledtest.pas - test program for ledlib
}
 
program ledtest;
uses syslib,ledlib;
 
mem keypressed=$1785: char&;
 
var mask,j,h: integer;
 
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
  h := 0;
  for j:=0 to 255 do
    begin
      ledhex(h,0,4);
      ledhex(255-j,5,2);
      delay10msec(1);
      h := h + 256;
    end;
  delay10msec(100);
  writeln('Displaying binary numbers');
  for j:=0 to 255 do
    begin
      ledbyte(j);
      delay10msec(1);
    end;
  delay10msec(100);
  writeln('Type any key to quit');
  repeat
    delay10msec(random div 4);
    ledbyte(random);
    until keypressed<>chr(0);
    keypressed:=chr(0);
  ledstop;
end.
 