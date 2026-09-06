 { ledtest.pas - _test program for ledlib }

program ledtest;
uses syslib, ledlib, plotlib;
{ plotlib provides _delay_10msec }

mem KEYPRESSED=$1785: char&;

var mask,j,h: integer;

begin
  writeln('LEDTEST: Test led library');
  writeln('Displaying text PASCAL');
  _ledstring('-1.23456');
  exit;
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
 