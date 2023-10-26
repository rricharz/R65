
program test2;
{ tests variable, integer math and proc }

const   cr = chr($0d);
        lf = chr($0a);
        
var a, b, c, d: integer;

proc crlf;

begin
  write(cr,lf);
end;

begin {main}
  
  write('Test2:');
  crlf;
  
  a := 25; b := 4; c:= a+b; d:=c;
  
  writeln('a=',a,',b=',b,',c=a+b=',c,'.');

  writeln('a-b=',a-b);
  writeln('a*b=',a*b);
  writeln('a div b=',a div b);
  writeln('a and b=',a and b);
  writeln('a or b=',a or b);

end.


