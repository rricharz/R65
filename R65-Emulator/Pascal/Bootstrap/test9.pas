{ test9.pas }
{ forward references }

program test9;

proc fwda(i: integer); forward;

proc pb;
begin
  fwda(3);
  fwda(5);
end;

proc fwda(i: integer);
begin
  writeln('fwda: i=',i);
end;

begin {main}
  writeln;
  writeln('Test 9 (forward references):');
  pb;
end.
