{
  ledlib.pas   R65 led display library

On the original R65 computer, the KIM-1
was mounted directly behind the front panel.
The KIM-1 keyboard and 6-digit 7-segment
display was exposed. An interrupt driven
driver was used to display data, including
a few simple games, on this display. Later,
the front panel was replaced and 8 leds were
used to display 1 data byte. 8 switches were
available for input. In Pascal, LEDLIB was
providing a driver for these displays.

This is a modified version of LEDLIB for the R65
emulator. It emulates output to the 7-segment
display (8 digits, not 6 like on the original
system) or the 8 leds. The output appears on
the panel of the emulator. On the R65 replica,
the output appears on the 7-segment display of the
front panel.
}

library ledlib;

mem LEDREG=$1432: array[7] of char&;

proc _ledstring(s:cpnt);
{*********************}
var i: integer;
begin
  for i:=0 to 7 do
    LEDREG[i]:=s[i];
end;

proc _ledstop;
{***********}
begin
  LEDREG[0]:=chr(0);
end;

proc _ledhex(d,p,digits: integer);
{*******************************}
{ d:     value to display
  p:     position of first digit
  digit: number of digits }
var d1,i: integer;
begin
  { turn on led display if necessary }
  if (p>0) and (LEDREG[0]=chr(0)) then
    LEDREG[0]:=' ';
  if (p<0) or (digits<1) or (digits>4)
    or (p+digits>8) then
    _ledstring('????????')
  else
    begin
      d1:=d;
      for i:=1 to digits do
        begin
          if (d1 and $f) > 9 then
            LEDREG[p+digits-i]:=
                chr(ord(d1 and $f)+
                ord('A')-10)
          else
            LEDREG[p+digits-i]:=
                chr(ord(d1 and $f)+
                ord('0'));
          d1:=d1 shr 4;
        end;
    end;
end;

proc _ledbyte(d: integer);
{***********************}
var d1,i:integer;
begin
  d1:=d;
  for i:=7 downto 0 do
    begin
      if (d1 and 1) <> 0 then
        LEDREG[i]:='o'
      else
        LEDREG[i]:=' ';
      d1:=d1 shr 1;
    end;
end;

begin
end.
