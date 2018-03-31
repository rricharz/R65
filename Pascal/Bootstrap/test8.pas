{ test8.pas }
{ function isletter, isnumber, uppercase }

program test8;

var b: boolean;
    c: char;
    i: integer;


func isnumber(ch: char): boolean;

begin
  isnumber:=(ch >= '0') and (ch <= '9');
end;

func isletter(ch: char): boolean;

begin
  isletter:=((ch >= 'A') and (ch <= 'Z'))
    or ((ch >= 'a') and (ch <= 'z'));
end;

func uppercase(ch: char): char;

begin
  if (ch >= 'a') and (ch <= 'z') then
    uppercase := chr(ord(ch) - 32)
  else
    uppercase := ch;
end;

func lowercase(ch: char): char;

begin
  if (ch >= 'A') and (ch <= 'Z) then
    lowercase := chr(ord(ch) + 32)
  else
    lowercase := ch;
end;

begin {main}
  writeln;
  for i:=$20 to $7e do begin
    write(chr(i),' >> ',uppercase(chr(i)));
    if isnumber(chr(i)) then
      write(' is number');
    if isletter(chr(i)) then
      write(' is letter');
    writeln;
  end
end.
