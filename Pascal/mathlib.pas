{ ***************
  * mathlib.pas *
  ***************

Pascal math library

Version 1.1 RR 2019

Math real functions:
  fabs(r)
  sqrt(r)
  sin(r)        r in deg
  cos(r)        r in deg
  tan(r)        r in deg
  ln(r)
  exp(r)

Real output functions:
  writeflo(f,r)         exponential format
  writefix(f,d,r)       fix point format
  f     file to write to
  d     digits after decimal point
  r     real number to write             }

library mathlib;

const pi = 3.14159;
      e  = 2.27282;

func fabs(x:real):real;
{*********************}
begin
  if x<0. then fabs:=-x
  else fabs:=x;
end;

func sqrt(n:real):real;
{*********************}
{ using Newton's approximation }
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
{ write real in floating point format  }
{ right justified in field of 11 chars }
{ 3 digits after decimal point         }

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
  m:=m+0.0005; { round }
  if m>=10. then begin
    e:=e+1; m:=m/10.;
  end;
  write(@f,' ',sign,trunc(m),'.');
  for i:=1 to 3 do begin
    m:=10.*(m-conv(trunc(m)));
    write(@f,trunc(m));
  end;
  if e<0 then begin
    write(@f,'e-'); e:=-e
  end else
    write(@f,'e+');
  if e>=10 then write(@f,e)
  else if e>=1 then write(@f,'0',e)
  else write(@f,'00');
end;

proc writef0(f:file;d:integer;
    r:real;fl:integer;centered:boolean);
{**************************************}
{ write real in fixed point format     }
{ right justified or centered in field }
{ of fl chars (more if necessary)      }
{ d digits after decimal point         }
{ Warning! The floating point accuracy }
{ is only approximately 5 digits!      }

var m,rnd: real;
    d1,i1,m1,n,n1:integer;
    sign: char;
begin
  d1:=d;
  if d1<0 then d1:=0;
  if d1>3 then d1:=3;
  case d1 of
    0: rnd:=0.5;
    1: rnd:=0.05;
    2: rnd:=0.005;
    3: rnd:=0.0005
  end {case};
  sign:=' ';
  m:=r;
  if m<0. then begin
    sign:='-'; m:=-m;
  end;
  m:=m+rnd; { round }
  if m>32767. then writeflo(f,r)
  else begin
    { if m<2.*rnd then sign:=' ';}
    m1:=trunc(m);
    if m1<10 then n:=fl-3-d
    else if m1<100 then n:=fl-4-d
    else if m1<1000 then n:=fl-5-d
    else if m1<10000 then n:=fl-6-d
    else n:=fl-7-d;
    if d=0 then n:=n+1;
    n1:=n;
    if centered then n:=(n+1) div 2;
    for i1:=1 to n do write(@f,' ');
    write(@f,sign,m1);
    m:=m-conv(m1);
    if d1>0 then write(@f,'.');
    for i1:=1 to d1 do begin
      m:=10.*m;
      write(@f,trunc(m));
      m:=m-conv(trunc(m));
    end;
    for i1:=1 to n1-n do write(@f,' ');
  end;
end;

proc writefix(f:file;d:integer;r:real);
{*************************************}
{ write real in fixed point format     }
{ right justified in field of 11 chars }
{ d digits after decimal point         }
{ Warning! The floating point accuracy }
{ is only approximately 5 digits!      }
begin
  writef0(f,d,r,11,false);
end;

func readflo(f:file):real;
{************************}
{ read real number                    }

var r: real;
    n,n1: integer;
    neg,ems: boolean;
    ch: char;

begin
  r:=0.0;
  neg:=false;
  read(@f,ch);
  if (ch='+') then
      read(@f,ch)
  else if (ch='-') then begin
    neg:=true;
      read(@f,ch);
  end;
  while (ch<='9') and (ch>='0') do begin
    r:=10.*r+conv(ord(ch)-ord('0'));
    read(@f,ch);
  end;
  if (ch<>'.') and (ch<>'E') and (ch<>'e') then
  begin
    {numeric integer}
    if neg then r:=-r;
    readflo:=r
  end else begin {numeric real}
    n:=0;
    if (ch<>'E') and (ch<>'e') then read(@f,ch);
    while (ch<='9') and (ch>='0') do begin
      r:=10.*r+conv(ord(ch)-ord('0'));
      n:=prec(n); read(@f,ch)
    end;
    if (ch='E') or (ch='e') then begin
      ems:=false; read(@f,ch);
      case ch of
        '+': read(@f,ch);
        '-': begin ems:=true; read(@f,ch) end
      end;
      n1:=0;
      if (ch<='9') or (ch>='0') then begin
        n1:=ord(ch)-ord('0');
        read(@f,ch);
        if (ch<='9') and (ch>='0') then begin
          n1:=10*n1+ord(ch)-ord('0');
          read(@f,ch);
        end;
        if ems then n:=n-n1 else n:=n+n1
      end
    end;
    while n>0 do begin
      n:=prec(n);
      r:=10.*r;
    end;
    while n<0 do begin
      n:=succ(n); r:=0.1*r;
    end;
    if neg then r:=-r;
    readflo:=r;
  end
end;

func ln(r:real):real;
{*******************}
{ compute natural logarithm ln     }
var r0,rm1,rp1,a,b,res,d,q: real;
    e1:integer;

  proc getexp(var r1:array[1] of %integer;
    var e2: integer);
  { extract exponent and set it to 0 }
  begin
    e2:=(r1[1] and $ff)-$7f;
    r1[1]:=(r1[1] and $ff00) or $7f;
  end;

begin
  if r<0.0 then begin
    writeln('ln(x) for x<0 called');
    ln:=-1.0e-38
  end else begin
    r0:=r;
    { for faster calculation, extract exp }
    getexp(r0,e1);
    rm1:=r0-1.0; rp1:=r0+1.0; d:=1.0;
    a:=rm1; b:=rp1; res:=0.0;
    rm1:=rm1*rm1;
    rp1:=rp1*rp1;
    repeat
      q:=a/(d*b);
      res:=res+q;
      a:=a*rm1;
      b:=b*rp1;
      d:=d+2.0;
    until (q<0.0001)and(q>-0.0001);
    ln:=2.0*res+conv(e1)*0.69315
  end
end;

func exp(x:real):real;
{********************}
{ compute exponential function }
const ln2=0.69315;
var x0,f,res:real;
    n,e2:integer;

  proc addpof2(var r1:array[1] of %integer;
    e1: integer);
  { add power of two }
  begin
    e2:=e1+(r1[1] and $ff);
    r1[1]:=(r1[1] and $ff00)+e2;
  end;

begin
  { reduce to range -ln2 .. +ln2 }
  x0:=fabs(x)/ln2;
  e2:=trunc(x0);
  x0:=(x0-conv(e2))*ln2;
  { compute e-function }
  res:=1.0; f:=1.0;
  for n:=1 to 7 do begin
    f:=f*x0/conv(n);
    res:=res+f;
  end;
  { add e2 back into result }
  addpof2(res,e2);
  if x<0.0 then res:=1.0/res;
  exp:=res;
end;

begin
end.
 