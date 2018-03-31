{ test14.pas }
{ floating point test }

program test14;

var r1,r2,r3: real;

proc writef2(value:real);

var ival1,ival2:integer;
    rval:real;

begin
  ival1:=trunc(value+0.001);
  rval:=(value - conv(ival1))*conv(100);
  ival2:=trunc(rval+0.5);
  write(ival1,'.');
  if ival2<10 then write('0');
  write(ival2);
end;

begin
  r1:=200.0;
  r2:=60.0;

  r3:=r1+r2;
  write('+:'); writef2(r3); writeln;

  r3:=r1-r2;
  write('-:'); writef2(r3); writeln;

  r3:=r1*r2;
  write('*:'); writef2(r3); writeln;

  r3:=r1/r2;
  write('/:'); writef2(r3); writeln;

end.
