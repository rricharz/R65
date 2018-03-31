{ test3.pas }
{ test syslib procedure call }

program test3;
uses t3lib;

var x,y: integer;

begin
  x:=-3;
  y:=abs(x);
  write('Test3: x=',x,' abs(x)=',y);
end.
  
