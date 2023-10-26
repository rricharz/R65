{ test10.pas }
{ array of packed char }

program test10;

var i: integer;
    a: array[100] of packed char;

begin {main}
  writeln;
  writeln('Test 10 (packed char):');
  a[0]:=packed('a','b');
  a[1]:='cd';
  writeln(a[0],a[1]);
end.
