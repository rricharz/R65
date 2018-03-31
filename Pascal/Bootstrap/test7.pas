{ test7.pas }
{ procedure call with var array }

program test7;

var stk: array[3] of char;
    k: integer;

proc show1(i:integer);
begin
  writeln(i);
end;

proc show2(var i:integer);
begin
  writeln(i);
end;

proc show(var a: array[3] of char);

begin
  a[0] := 'a'
  write('a[1]=',a[1]);
  a[2] := 'b';
  a[3] := 'c';
end;

begin {main}
  stk[0]:='g';
  stk[1]:='h';
  stk[2]:='i';
  stk[3]:='j';
  writeln('test7');
  k:=89;
  show1(k);
  k:=98;
  show2(k);
  show(stk);
  writeln(' stk[0]=',stk[0],' stk[1]=',stk[1],
    ' stk[2]=',stk[2],' stk[3]=',stk[3]);
end.
