{ ***************
  * mathlib.pas *
  ***************

Pascal math library

Version 1.2 RR 2019

Math real functions:
  fabs(r)
  sqrt(r)
  sin(r)        r in deg
  cos(r)        r in deg
  tan(r)        r in deg
  ln(r),log(r)
  exp(r)                      }

{$U+}

library mathlib;

const PI = 3.14159;
      E  = 2.71828;

func fabs(x:real):real;
{*********************}
begin
  if x<0. then fabs:=-x else fabs:=x;
end;

func sqrt(n:real):real;
{*********************}
{ using bisection }
const accuracy = 0.0001; {rel accuracy}
      STOPCODE = $2010;
      NORVID   = chr($0b);
      INVVID   = chr($0e);
mem   RUNERR   = $000c: integer&;
var   lower,upper,guess:real;
begin
  if n=0.0 then begin sqrt:=0.0; exit end;
  if n<0.0 then begin
    writeln(INVVID,'sqrt(x) for x<0 called',NORVID);
    RUNERR := 54;
    call(STOPCODE);
    end;
  if n<1.0 then begin
    lower:=n; upper:=1.0
  end else begin
    lower:=1.0; upper:=n
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

const eps = 0.0001;

var m:real;

  func cos0(x0:real):real;
  var t,s:real;
    i, p:integer;
  begin
    p:=0; s:=1.; t:=1.;
    while fabs(t/s) > 0.00001 do begin
      p:=p+1;
      t:=(-t*x0*x0)/(conv(2*p-1)*conv(2*p));
      s:=s+t;
    end;
    cos0:=s;
  end;

begin
  if x<0. then m:=-x else m:=x;

  while m>=360. do m:=m-360.;

  if fabs(m-0.) < eps then cos:=1.
  else if fabs(m-90.) < eps then cos:=0.
  else if fabs(m-180.) < eps then cos:=-1.
  else if fabs(m-270.) < eps then cos:=0.
  else if m>270. then
    cos:=cos0((360.-m)*PI/180.)
  else if m>180. then
    cos:=-cos0((m-180.)*PI/180.)
  else if m>90. then
    cos:=-cos0((180.-m)*PI/180.)
  else
    cos:=cos0(m*PI/180.);
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
const eps = 0.0001;
var s,c: real;
begin
  s:=sin(x);
  c:=cos(x);
  if fabs(c)<eps then begin
    if s>=0.0 then tan:=1.0e+38
    else tan:=-1.0e+38
  end else
    tan:=s/c;
end;

proc writeflo(r:real; fl:integer);
{********************************}
{ write real in floating point format
  right justified in field of fl chars
  more chars if necessary
  4 digits after decimal point }

var m: real;
    e,i,n,width,fl1: integer;
    sign: char;
begin
  fl1:=fl;
  if fl1<0 then fl1:=0;

  e:=0; m:=r; sign:=' ';
  if m<0. then begin sign:='-'; m:=-m; end;

  while m>=10. do begin e:=e+1; m:=m/10.; end;
  if m>0. then
    while m<1. do begin e:=e-1; m:=10.*m; end;

  m:=m+0.00005; { round to 4 decimals }
  if m>=10. then begin e:=e+1; m:=m/10.; end;

  width:=12; { sign, digit, dot, 4 decimals, e+xx }
  if e<=-10 then width:=13;
  if e>=100 then width:=13;
  if e<=-100 then width:=14;

  n:=fl1-width;
  if n<0 then n:=0;
  for i:=1 to n do write(' ');

  write(sign,trunc(m),'.');
  for i:=1 to 4 do begin
    m:=10.*(m-conv(trunc(m)));
    write(trunc(m));
  end;

  if e<0 then begin write('e-'); e:=-e end
  else write('e+');

  if e>=10 then write(e)
  else write('0',e);
end;

proc writef0(r: real; fl, d:integer;
    centered:boolean);
{**************************************}
{ write real in fixed point format
  right justified or centered in field
  of fl chars (more if necessary)
  d digits after decimal point
  Real output is reliable to about 6 digits. }

var m,rnd,p: real;
    d1,i1,digit,ndig,width,n,n1,fl1: integer;
    sign: char;
    started: boolean;
begin
  d1:=d;
  if d1<0 then d1:=0;
  if d1>3 then d1:=3;

  fl1:=fl;
  if fl1<0 then fl1:=0;

  case d1 of
    0: rnd:=0.50001;
    1: rnd:=0.05001;
    2: rnd:=0.00501;
    3: rnd:=0.00051
  end {case};

  sign:=' ';
  m:=r;
  if m<0. then begin
    sign:='-';
    m:=-m;
  end;

  m:=m+rnd; { round }

  { avoid printing -0.000 etc. }
  if m < 2.*rnd then sign:=' ';

  if m >= 99999.5 then writeflo(r, fl1)
  else begin
    if m<10. then ndig:=1
    else if m<100. then ndig:=2
    else if m<1000. then ndig:=3
    else if m<10000. then ndig:=4
    else ndig:=5;

    width:=ndig;
    if d1>0 then width:=width+d1+1;
    if sign='-' then width:=width+1;

    n:=fl1-width;
    if n<0 then n:=0;
    n1:=n;
    if centered then n:=n div 2;

    for i1:=1 to n do write(' ');

    if sign='-' then write('-');

    p:=10000.;
    started:=false;
    for i1:=1 to 5 do begin
      digit:=trunc(m/p);
      if (digit<>0) or started or (i1=5) then begin
        write(digit);
        started:=true;
      end;
      m:=m-conv(digit)*p;
      p:=p/10.;
    end;

    if d1>0 then write('.');

    for i1:=1 to d1 do begin
      m:=10.*m;
      digit:=trunc(m);
      write(digit);
      m:=m-conv(digit);
    end;

    for i1:=1 to n1-n do write(' ');
  end;
end;

proc __wrfix(r:real; fl, d:integer);
{**********************************}
{ write real in fixed point format
  right justified in field of 11 chars
  d digits after decimal point.
  Real output is reliable to about 6 digits.
  This function is used by write(real). }
begin
  writef0(r, fl, d, false);
end;

func readflo(f:file):real;
{************************}
{ read real number                    }

var r: real;
    n,n1: integer;
    neg,ems: boolean;
    ch: char;

begin
  r:=0.0; neg:=false; read(@f,ch);
  if (ch='+') then read(@f,ch)
  else if (ch='-') then begin
    neg:=true; read(@f,ch);
  end;
  while (ch<='9') and (ch>='0') do begin
    r:=10.*r+conv(ord(ch)-ord('0')); read(@f,ch);
  end;
  if (ch<>'.') and (ch<>'E') and (ch<>'e') then
  begin {numeric integer}
    if neg then r:=-r; readflo:=r
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
      if (ch<='9') and (ch>='0') then begin
        n1:=ord(ch)-ord('0'); read(@f,ch);
        if (ch<='9') and (ch>='0') then begin
          n1:=10*n1+ord(ch)-ord('0'); read(@f,ch);
        end;
        if ems then n:=n-n1 else n:=n+n1
      end
    end;
    while n>0 do begin
      n:=prec(n); r:=10.*r;
    end;
    while n<0 do begin n:=succ(n); r:=0.1*r; end;
    if neg then r:=-r;
    readflo:=r;
  end
end;

func ln(r:real):real;
{*******************}
{ compute natural logarithm ln }
const NORVID   = chr($0b);
      INVVID   = chr($0e);
var r0,rm1,rp1,a,b,res,d,q: real;
    e1:integer;

  proc getexp(var r1:array[1] of %integer;
    var e2: integer);
  { extract exponent and set it to 0 }
  { extract binary exponent from internal real format
}
  begin
    e2:=(r1[1] and $ff)-$7f;
    r1[1]:=(r1[1] and $ff00) or $7f;
  end;

begin
  if fabs(r-1.0)<0.0001 then begin ln:=0.0; exit end;
  if r<=0.0 then begin
  writeln('ln: non-positive argument');
    ln:=-1.0e-38
  end else begin
    r0:=r;
    { for faster calculation, extract exp }
    getexp(r0,e1);
    rm1:=r0-1.0; rp1:=r0+1.0; d:=1.0;
    a:=rm1; b:=rp1; res:=0.0;
    rm1:=rm1*rm1; rp1:=rp1*rp1;
    repeat
      q:=a/(d*b); res:=res+q;
      a:=a*rm1; b:=b*rp1;
      d:=d+2.0;
    until fabs(q)<0.0001;;
    ln:=2.0*res+conv(e1)*0.69315;
  end
end;

func exp(x:real):real;
{********************}
{ compute exponential function }
const ln2=0.69315;
      NORVID   = chr($0b);
      INVVID   = chr($0e);
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
    f:=f*x0/conv(n); res:=res+f;
  end;
  { add e2 back into result with bounds check }
  if e2>126 then begin
    if x<0.0 then res:=0.0
    else begin
     writeln(INVVID,'exp: argument too large',NORVID);
      res:=1.0e+38
    end
  end
  else begin
    addpof2(res,e2);
    if x<0.0 then res:=1.0/res;
  end;
  exp:=res;
end;

func log(x:real):real;
{********************}
begin
  if fabs(x-10.0)<0.0001 then begin
    log:=1.0; exit end;
  log:=ln(x)*0.434294;
end;

begin
end.
