program keyval;
uses syslib, writelib;
const esc=chr($0);
var ch:char;

begin
  repeat
    read(@KEY,ch);
    write('KEY value = ');
    write('$', hexb(ord(ch)));
    writeln('  ',ord(ch));
    until ch=esc;
end.
