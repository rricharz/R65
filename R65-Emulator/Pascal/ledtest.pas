 {
   ledtest.pas - _test program for ledlib
}

program ledtest;
uses syslib,ledlib;

mem KEYPRESSED=$1785: char&;

var mask,j,h: integer;

proc _delay10msec(time:integer);
{*****************************}
{ _delay10msec: _delay 10 msec }
{ process is suspended during _delay }
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

begin
  writeln('LEDTEST: Test led library');
  writeln('Displaying text PASCAL');
  _ledstring('PASCAL  ');
  _delay10msec(100);
  _ledstring('        ');
  writeln('Displaying hex numbers');
  h := 0;
  for j:=0 to 255 do
    begin
      _ledhex(h,0,4);
      _ledhex(255-j,5,2);
      _delay10msec(1);
      h := h + 256;
    end;
  _delay10msec(100);
  writeln('Displaying binary numbers');
  for j:=0 to 255 do
    begin
      _ledbyte(j);
      _delay10msec(1);
    end;
  _delay10msec(100);
  writeln('Type any KEY to quit');
  repeat
    _delay10msec(_random div 4);
    _ledbyte(_random);
    until KEYPRESSED<>chr(0);
    KEYPRESSED:=chr(0);
  _ledstop;
end.
 