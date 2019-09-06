{ ***************
  * mathlib.pas *
  ***************

Pascal math library

Math real functions:
  fabs(r)
  sqrt(r)
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
  if x<0. then fabs:=-x
  else fabs:=x;
end;

func sqrt(n:real):real;
{*********************}
{ Newton's approximation }
const accuracy = 0.0001; {rel accuracy }
var lower,upper,guess:real;
begin
  if n<1.0 then begin
    lower:=n;
    upper:=1.0
  end else begin
    lower:=1.0;
    upper:=n
  end;
  guess:=1.0;
  while (upper-lower)>(accuracy*guess) do begin
    guess:=(upper+lower)/2.0;
    if (guess*guess)>n then upper:=guess
    else lower:=guess
  end;
  sqrt:=(upper+lower)/2.0;
end;

func cos(x:real):real;
{********************}
{ argument x in degree }

var m:real;

  func cos0(x:real):real;
  var t,s:real;
    i, p:integer;
  begin
    p:=0; s:=1.; t:=1.;
    while fabs(t/s) > 0.00001 do begin
      p:=p+1;
      t:=(-t*x*x)/(conv(2*p-1)*conv(2*p));
      s:=s+t;
    end;
    cos0:=s;
  end;

begin
  if x<0. then m:=-x
  else m:=x;
  while m>=(360.) do m:=m-360.;
  if m=0. then cos:=1.
  else if m=90. then cos:=0.
  else if m=180. then cos:=-1.
  else if m > 180. then begin
    m:=m-180.;
    if m>90. then
      cos:=cos0((180.-m)*pi/180.)
    else
      cos:=-cos0(m*pi/180.);
  end
  else begin
    if m>90. then
      cos:=-cos0((180.-m)*pi/180.)
    else
      cos:=cos0(m*pi/180.);
  end;
end;

func sin(x:real):real;
{********************}
{ argument x in degree }
begin
  sin:=cos(x-90.);
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
  if m<0. then begin
    sign:='-'; m:=-m;
  end;
  while m>=10. do begin
    e:=e+1; m:=m/10.;
  end;
  if m>0. then
    while m<1. do begin
      e:=e-1; m:=10.*m;
    end;
  m:=m+0.00005; { round }
  if m>=10. then begin
    e:=e+1; m:=m/10.;
  end;
  write(@f,sign,trunc(m),'.');
  for i:=1 to 4 do begin
    m:=10.*(m-conv(trunc(m)));
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
    0: begin max:=32767.; rnd:=0.5 end;
    1: begin max:=10000.; rnd:=0.05 end;
    2: begin max:=1000.; rnd:=0.005 end;
    3: begin max:=100.; rnd:=0.0005 end;
    4: begin max:=10.; rnd:=0.00005 end;
    5: begin max:=1.; rnd:=0.000005 end
  end {case};
  sign:=' ';
  m:=r;
  if m<0. then begin
    sign:='-'; m:=-m;
  end;
  m:=m+rnd; { round }
  if m>(max+rnd) then writeflo(f,r)
  else begin
    if m<2.*rnd then sign:=' ';
    write(@f,sign,trunc(m));
    m:=m-conv(trunc(m));
    if d1>0 then write(@f,'.');
    for i1:=1 to d1 do begin
      m:=10.*m;
      write(@f,trunc(m));
      m:=m-conv(trunc(m));
    end;
  end;
end;

begin
end.
 