program keyval;
uses syslib;
const esc=chr($0);
var ch:char;

begin
  repeat
    read(@key,ch);
    writeln('key value = ',ord(ch));
    until ch=esc;
end.