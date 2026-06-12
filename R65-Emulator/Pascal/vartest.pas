program vartest;

var
  g: integer;

proc p;
var
  l: integer;
begin
  g := 1;
  l := 2;
  writeln(g);
  writeln(l);
end;

begin
  p;
end. 