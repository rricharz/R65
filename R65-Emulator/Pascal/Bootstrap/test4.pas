{ test4.pas }
{ test unbuffered keyboard input and syslib}

program test4;
uses syslib;

var ch1: char;

begin {main}
  writeln('Test 4:');
  writeln('Type key to get ASCII code',
      ' (return to exit):');
  repeat  
    read(@key, ch1);
    writeln('The ASCII code is ', ord(ch1));
    until ch1=cr;
end.
