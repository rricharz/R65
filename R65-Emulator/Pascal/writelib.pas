{ WRITELIB - Write formatting helper routines

  WRITELIB provides helper functions which return
  temporary cpnt strings for use in write and writeln
  statements

  It also provides the helpers for formatted printing

  Examples:
    writeln(hexb(i));       8-bit hex
    writeln(hexw(i));       16-bit hex
    writeln(flo(r,n));      exponential format
    writeln(string(name));  array[15] of char
    write(d:5);             formatted integer
    write(r:12:3);          fixed point real
    writeln(field,s,20);    right pad a string

  All WRITELIB functions return a pointer to a shared
temporary
  string buffer located at $17D8-$17E8 (16 characters
plus
  terminating zero).

  Limitations:
  - Maximum string length is 16 characters.
  - The result remains valid only until the next WRITE
LIB call.
  - WRITELIB functions must not be nested.
  - Intended for direct use in write and writeln state
ments.

  Memory map:
    $17D8-$17E8  WRITBUF  Temporary cpnt string buffer

writelib also provides the helpers for formatted print
ing
}

library writelib;

func _hexchar(i0: integer): char;
{*******************************}
var i1: integer;
begin
  i1 := i0 and $0f;
  if i1 < 10 then
    _hexchar := chr(ord('0') + i1)
  else
    _hexchar := chr(ord('A') + i1 - 10);
end;

func hexb(i: integer): cpnt;
{**************************}
var cp: cpnt;
begin
  cp := cpnt($17d8);
  cp[0] := _hexchar((i shr 4) and $0f);
  cp[1] := _hexchar(i and $0f);
  cp[2] := chr(0);
  hexb := cp;
end;

func hexw(i: integer): cpnt;
{**************************}
var cp: cpnt;
begin
  cp := cpnt($17d8);
  cp[0] := _hexchar((i shr 12) and $0f);
  cp[1] := _hexchar((i shr 8) and $0f);
  cp[2] := _hexchar((i shr 4) and $0f);
  cp[3] := _hexchar(i and $0f);
  cp[4] := chr(0);
  hexw := cp;
end;

func str16(text: array[15] of char): cpnt;
{****************************************}
var i: integer;
    cp: cpnt;
begin
  cp := cpnt($17d8);
  for i:=0 to 15 do cp[i] := text[i];
  cp[16] := chr(0);
  str16 := cp;
end;

func trim16(text: array[15] of char): cpnt;
{****************************************}
var i,last: integer;
    cp: cpnt;
begin
  cp := cpnt($17d8);
  last := -1;
  for i := 0 to 15 do
    if text[i] <> ' ' then
      last := i;
  for i := 0 to last do
    cp[i] := text[i];
  cp[last+1] := chr(0);
  trim16 := cp;
end;

proc __wrintf(value, width: integer);
{***********************************}
{ Write value right justified in a field of width.
  This procedure is a helper for the compiler. I is
  used in the write and writeln commands for
  justified numbers. Do not change the format.     }
var
  buf: array [5] of char;
  { 0..5, enough for -32768..32767 }
  i, len, n, w, q, r: integer;
  neg: boolean;
begin
  w := width;
  { Special case, because -(-32768) would overflow
    on a 16-bit machine, -32768 cannot be entered }
  if value = $8000 then begin
    len := 6;
    while w > len do begin
      write(' ');
      w := w - 1
    end;
    write('-32768');
    exit
  end;
  neg := value < 0;
  if neg then
    n := -value
  else
    n := value;
  i := 5;
  { Generate digits backwards into buf }
  repeat
    q := n div 10;
    r := n - q*10;
    buf[i] := chr(ord('0') + r);
    n := q;
    i := i - 1
  until n = 0;
  if neg then begin
    buf[i] := '-';
    i := i - 1
  end;
  { Characters are now in buf[i+1..5] }
  len := 5 - i;
  while w > len do begin
    write(' ');
    w := w - 1
  end;
  while i < 5 do begin
    i := i + 1;
    write(buf[i])
  end
end;

func flo(r: real; fl: integer): cpnt;
{*********************************}
{ write real in floating point format
  right justified in field of fl chars
  max 16 chars because of WRITBUF
  4 digits after decimal point }

var m: real;
    e,i,j,n,width,fl1: integer;
    sign: char;
    cp: cpnt;

  proc wrt(ch: char);
  begin
    if j < 16 then begin
      cp[j] := ch;
      j := j + 1;
    end;
  end;

  proc wrti(in: integer);
  var in0: integer;
  begin
    in0 := in;
    if in0 >= 10 then begin
      wrti(in0 div 10);
      in0 := in0 - 10 * (in0 div 10);
    end;
    wrt(chr(ord('0') + in0));
  end;

  func digits(in: integer): integer;
  var in0,d: integer;
  begin
    in0 := in;
    d := 1;
    while in0 >= 10 do begin
      in0 := in0 div 10;
      d := d + 1;
    end;
    digits := d;
  end;

begin
  cp := cpnt($17d8);
  j := 0;

  fl1 := fl;
  if fl1 < 0 then fl1 := 0;
  if fl1 > 16 then fl1 := 16;

  e := 0;
  m := r;
  sign := ' ';

  if m < 0. then begin
    sign := '-';
    m := -m;
  end;

  if m <> 0. then begin
    while m >= 10. do begin
      e := e + 1;
      m := m / 10.;
    end;

    while m < 1. do begin
      e := e - 1;
      m := 10. * m;
    end;
  end;

  m := m + 0.00005;       { round to 4 decimals }

  if m >= 10. then begin
    e := e + 1;
    m := m / 10.;
  end;

  if e < 0 then
    width := 9 + digits(-e)
  else
    width := 9 + digits(e);

  if (e > -10) and (e < 10) then
    width := width + 1;    { leading zero in exponent
}

  n := fl1 - width;
  if n < 0 then n := 0;

  for i := 1 to n do wrt(' ');

  wrt(sign);
  wrti(trunc(m));
  wrt('.');

  for i := 1 to 4 do begin
    m := 10. * (m - conv(trunc(m)));
    wrti(trunc(m));
  end;

  wrt('e');

  if e < 0 then begin
    wrt('-');
    e := -e;
  end else
    wrt('+');

  if e < 10 then wrt('0');
  wrti(e);

  cp[j] := chr(0);
  flo := cp;
end;

proc _writef0(r: real; fl, d:integer;
    centered:boolean);
{***********************************}
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

  if m >= 9999.9 then write(flo(r,fl1))
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
  right justified in field of fl chars,
  d digits after decimal point.
  Real output is reliable to about 6 digits.
  This function is used by write(real). }
begin
  _writef0(r, fl, d, false);
end;

begin
end. 