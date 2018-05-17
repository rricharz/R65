{ ***************
  * mathlib.pas *
  ***************

Pascal math library

Math real functions:
  fabs(r)
  sin(r)        r in deg
  cos(r)        r in deg
  tan(r)        r in deg

Real output functions:
  writeflo(f,r)         exponential format
  writefix(f,d,r)       fix point format
  f     file to write to
  d     digits after decimal point
  r     real number to write             }

library mathlib;

const pi = 3.14159;

func fabs(x:real):real;
{*********************}
begin
  if x<0.0 then fabs:=-x
  else fabs:=x;
end;

func cos(x:real):real;
{********************}
{ argument x in degree }

var m:real;

  func cos0(x:real):real;
  var t,s:real;
    i, p:integer;
  begin
    p:=0; s:=1.0; t:=1.0;
    while fabs(t/s) > 0.00001 do begin
      p:=p+1;
      t:=(-t*x*x)/(conv(2*p-1)*conv(2*p));
      s:=s+t;
    end;
    cos0:=s;
  end;

begin
  if x<0.0 then m:=-x
  else m:=x;
  while m>=(360.0) do m:=m-360.0;
  if m=0.0 then cos:=1.0
  else if m=90.0 then cos:=0.0
  else if m=180.0 then cos:=-1.0
  else if m > 180.0 then begin
    m:=m-180.0;
    if m>90.0 then
      cos:=cos0((180.0-m)*pi/180.0)
    else
      cos:=-cos0(m*pi/180.0);
  end
  else begin
    if m>90.0 then
      cos:=-cos0((180.0-m)*pi/180.0)
    else
      cos:=cos0(m*pi/180.0);
  end;
end;

func sin(x:real):real;
{********************}
{ argument x in degree }
begin
  sin:=cos(x-90.0);
end;

func tan(x:real):real;
{********************}
{ argument x in degree }
begin
  tan:=sin(x)/cos(x);
end;

proc writeflo(f:file;r:real);
{***************************}
var m: real;
    e,i: integer;
    sign: char;
begin
  e:=0; m:=r; sign:=' ';
  if m<0.0 then begin
    sign:='-'; m:=-m;
  end;
  while m>=10.0 do begin
    e:=e+1; m:=m/10.0;
  end;
  while m<1.0 do begin
    e:=e-1; m:=10.0*m;
  end;
  m:=m+0.0005; { round }
  if m>=10.0 then begin
    e:=e+1; m:=m/10.0;
  end;
  write(@f,sign,trunc(m),'.');
  for i:=1 to 3 do begin
    m:=10.0*(m-conv(trunc(m)));
    write(@f,trunc(m));
  end;
  if e>=0 then write(@f,'E+',e)
  else if e<0 then write(@f,'E',e);
end;

proc writefix(f:file;d:integer;r:real);
{*************************************}
var m,max,rnd: real;
    d1,i1:integer;
    sign: char;
begin
  d1:=d;
  if d1<0 then d1:=0;
  if d1>5 then d1:=5;
  case d1 of
    0: begin max:=32767.0; rnd:=0.5 end;
    1: begin max:=10000.0; rnd:=0.05 end;
    2: begin max:=1000.0; rnd:=0.005 end;
    3: begin max:=100.0; rnd:=0.0005 end;
    4: begin max:=10.0; rnd:=0.00005 end;
    5: begin max:=1.0; rnd:=0.000005 end
  end {case};
  sign:=' ';
  m:=r;
  if m<0.0 then begin
    sign:='-'; m:=-m;
  end;
  m:=m+rnd; { round }
  if m>=max then writeflo(f,r)
  else begin
    if m<2.0*rnd then sign:=' ';
    write(@f,sign,trunc(m));
    m:=m-conv(trunc(m));
    if d1>0 then write(@f,'.');
    for i1:=1 to d1 do begin
      m:=10.0*m;
      write(@f,trunc(m));
      m:=m-conv(trunc(m));
    end;
  end;
end;

begin
end.
 