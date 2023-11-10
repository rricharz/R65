program keyval;
uses syslib;
const esc=chr($0);
var ch:char;

proc writehex(ch:char);
var h:integer;
  func hexdigit(c:char):char;
  var d:integer;
  begin
    d:=ord(c) and 15;
    if d>9 then hexdigit:=chr(d-10+ord('A'))
    else hexdigit:=chr(d+ord('0'));
  end;
begin
  h:=ord(ch) and 255;
  write('$',hexdigit(chr(h shr 4)));
  write(hexdigit(chr(h and 15)));
end;

begin
  repeat
    read(@key,ch);
    write('key value = ');
    writehex(ch);
    writeln('  ',ord(ch));
    until ch=esc;
end.
