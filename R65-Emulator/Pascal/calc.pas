 {
   Pascal CALC for R65 computer system

   Note: The R65 Pascal system used
   32 bit floating point representation,
   which is not suitable for serious
   calculations, but was widely used
   in early 8-bit microprocessor
   systems. CALC tries to handle
   this limited accuracy.

   Written 2019-2023 by rricharz  }

program calc;
uses syslib,mathlib,strlib,ledlib;

mem vidpnt=$00e9:integer;
    BUFFPN   = $0015: integer&;

var ch: char;
    r,lastr: real;
    stop,dotused,firsterror: boolean;

proc clearinput;
{**************}
begin
  BUFFPN:=-1;
end;

proc error(s1,s2:cpnt);
{*********************}
begin
  if firsterror then
    writeln(INVVID,'Error: ',s1,' ',s2,NORVID);
  firsterror:=false;
end;

proc readch;
{**********}
begin
  if firsterror then read(@INPUT,ch)
  else ch:=CR;
end;

func fix(rf: real): integer;
{**************************}
var rnd:real;
begin
  if rf>=0.0 then rnd:=0.5 else rnd:=-0.5;
  if (rf>=32767.5) then begin
      error('Integer value exceeds',
        'upper limit, set to 32767');
      fix:=$7fff;
    end else if (rf<=-32768.5) then begin
      error('Integer value exceeds',
        ' lower limit, set to -32768');
      fix:=$8000;
    end else fix:=trunc(rf+rnd);
end;

proc checkfor(c: char);
{*********************}
var s1,s2:cpnt;
begin
  if ch<>c then begin
    s1:=_new; s2:=_new;
    _strcpy('Expected ',s1);
    if c=CR then _strcpy('Expected <eol>',s1)
    else _strinsc(c,9,s1);
    _strcpy('but found ',s2);
    if ch=CR then _strcpy('but found <eol>',s2)
    else _strinsc(ch,10,s2);
    error(s1,s2);
    _release(s2); _release(s1);
  end;
end;

proc skip(c:char);
{****************}
begin
  checkfor(c); readch;
end;

func isnumber(cn:char):boolean;
{*****************************}
begin
  isnumber:=(cn>='0') and (cn<='9');
end;

proc writehex(f:file; r: integer);
{********************************}
var mask, m, n, r1: integer;
begin
  write(@f,'$'); mask := $f000; n := 12;
  while mask <>0 do begin
    r1 := (r and mask) shr n;
    if r1 < 10 then write(@f,r1)
    else  write(@f,chr(ord(r1)+ord('A')-10));
    mask := mask shr 4; n := n - 4;
  end;
end;

proc writebinary(f:file; r: integer);
{***********************************}
var mask: integer;
begin
  write(@f,'% '); mask := $8000;
  while mask <> 0 do begin
   if (r and mask) <> 0 then write(@f,'1')
   else write(@f,'0');
   mask := mask shr 1;
   if mask = $0800 then write(@f,' ');
   if mask = $0080 then write(@f,' ');
   if mask = $0008 then write(@f,' ');
  end;
end;

proc showled(s1:cpnt);
{********************}
var s2:cpnt;
    pos,i,l:integer;
begin
  s2:=_new;
  _strcpy(s1,s2);
  { remove any space }
  pos:=_strpos(' ',s2,0);
  while pos>=0 do begin
    _strdelc(pos,s2);
    pos:=_strpos(' ',s2,0);
  end;
  { remove any plus sign }
  pos:=_strpos('+',s2,0);
  while pos>=0 do begin
    _strdelc(pos,s2);
    pos:=_strpos('+',s2,0);
  end;
  { convert point to bit 8 }
  pos:=_strpos('.',s2,0);
  while pos>0 do begin
    _strdelc(pos,s2);
    s2[pos-1]:=chr(ord(s2[pos-1]) or 128);
    pos:=_strpos('.',s2,0);
  end;
  { remove unnecessary 0 in exponent, if necessary }
  l:=_strlen(s2);
  if (l>8) and (s2[l-2]='0') and
    (_strpos('e',s2,0)>0) then _strdelc(l-2,s2);
  { remove e as a last resort (exp is negative) }
  if _strlen(s2)>8 then begin
    pos:=_strpos('e',s2,0);
    if pos>0 then _strdelc(pos,s2);
  end;
  { right justify }
  while _strlen(s2)<8 do _strinsc(' ',0,s2);
  { show converted string }
  _ledstring(s2);
  _release(s2);
end;

proc writeauto(f:file;r:real);
{****************************}
{ outputs 5 digits }
var m,m1,max,rnd: real;
    i1,d1:integer;
    sign: char;
begin
  sign:=' '; m:=r;
  if m<0. then begin
    sign:='-'; m:=-m;
  end;
  if dotused and (m>=10000.0) then writeflo(f,r)
  else if m=0. then write(@f,' 0')
  else if r=conv($8000) then write(@f,'-32768 ')
  else if m>=32767.5 then writeflo(f,r)
  else if m<0.01 then writeflo(f,r)
  else begin
    if m>=10000. then begin
      d1:=0; rnd:=0.5
    end else if m>=1000. then begin
      d1:=1; rnd:=0.05
    end else if m>=100. then begin
      d1:=2; rnd:=0.005
    end else if m>=10. then begin
      d1:=3; rnd:=0.0005
    end else if m>=1. then begin
      d1:=4; rnd:=0.00005
    end else if m>=0.1 then begin
      d1:=5; rnd:=0.000005
    end else begin
      d1:=6; rnd:=0.0000005
    end;
    m:=m+rnd; { round }
    write(@f,sign,trunc(m));
    m1:=m-conv(trunc(m));
    if m1<=rnd then begin
      for i1:=1 to d1+1 do write(@f,' ');
      d1:=0;
    end;
    if d1>0 then write(@f,'.');
    for i1:=1 to d1 do begin
      m1:=10.*m1; write(@f,trunc(m1));
      m1:=m1-conv(trunc(m1));
    end;
  end;
end;

proc showresult;
{**************}
var s1: cpnt;
    rnd: real;
begin
  s1:=_new;
  writeauto(@s1,r);
  write(s1);
  if (r>-32768.5) and (r<32767.5) then begin
    if r>=0.0 then rnd:=0.5 else rnd:=-0.5;
    _tab(16); writehex(OUTPUT,fix(r));
    _tab(24); writebinary(OUTPUT,fix(r));
  end;
  writeln;
  showled(s1);
  _release(s1);
end;

func express:real;
{****************}
var
  re: real;

func binval: integer;
{*******************}
begin
  if (ch='0') then binval:=0
  else if (ch='1') then binval:=1
  else binval:=-1;
end;

func hexval: integer;
{*******************}
begin
  if (ch>='0') and (ch<='9')
    then hexval:=ord(ch)-ord('0')
  else if (ch>='A') and (ch<='F')
    then hexval:=ord(ch)-ord('A')+10
  else hexval:=-1;
end;

func isletter(ch:char):boolean;
{*****************************}
begin
  isletter:=(ord(ch)>=ord('A'))and(ord(ch)<=ord('Z'))
end;

func function:real;
{*****************}
var i: integer;
    r: real;
    lstring: cpnt;
begin
  lstring:=_new;
  lstring[0]:=chr(0);
  _strinsc(ch,0,lstring); readch; i:=1;
  while isletter(ch) do begin
    _strinsc(ch,i,lstring); readch; i:=i+1;
  end;
  stop:=false;
  if _strcmp(lstring,'R')=0 then begin
    function:=lastr; _release(lstring); exit;
  end;
  if _strcmp(lstring,'PI')=0 then begin
    function:=PI; _release(lstring); exit;
  end;
  if _strcmp(lstring,'E')=0 then begin
    function:=E; _release(lstring); exit;
  end;
  { functions with single argument follow }
  checkfor('('); r:=express; skip(')');
  if _strcmp(lstring,'SQR')=0 then begin
    function:=r*r; _release(lstring); exit;
  end;
  if _strcmp(lstring,'SQRT')=0 then begin
    function:=sqrt(r); _release(lstring); exit;
  end;
  if _strcmp(lstring,'SIN')=0 then begin
    function:=sin(r); _release(lstring); exit;
  end;
  if _strcmp(lstring,'COS')=0 then begin
    function:=cos(r); _release(lstring); exit;
  end;
  if _strcmp(lstring,'TAN')=0 then begin
    function:=tan(r); _release(lstring); exit;
  end;
  if _strcmp(lstring,'EXP')=0 then begin
    function:=exp(r); _release(lstring); exit;
  end;
  if _strcmp(lstring,'LN')=0 then begin
    function:=ln(r); _release(lstring); exit;
  end;
  if _strcmp(lstring,'LOG')=0 then begin
    function:=log(r); _release(lstring); exit;
  end;
  error('Unknow function',lstring);
  function:=0.0;
  _release(lstring);
end;

proc exponent(var r:real);
{************************}
var minus:boolean;
    exp:integer;
begin
  minus:=false;
  if ch='-' then begin minus:=true; readch end
  else if ch='+' then readch;
  exp:=0;
  if isnumber(ch) then begin
    exp:=ord(ch)-ord('0'); readch
  end else error('Expecting','exponent');
  if isnumber(ch) then begin
    exp:=10*exp+(ord(ch)-ord('0')); readch;
  end;
  if minus then
    while exp>0 do begin r:=0.1*r; exp:=exp-1 end
  else
    while exp>0 do begin r:=10.0*r; exp:=exp-1 end;
end;

func factor:real;
{***************}
var negative:boolean;
    rf,rt: real;
    i,iv: integer;
begin
  negative:=false; rf:=0.;  readch;
  if ch='-' then begin
    negative:=true; readch;
  end;
  if ch='(' then begin
    stop:=false; rf:=express;
    checkfor(')'); readch;
  end else if ch='%' then begin
    stop:=false; readch; iv:=0;
    while binval>=0 do begin
      iv:=(iv shl 1)+binval; readch;
    end;
    rf:=conv(iv);
  end else if ch='$' then begin
    stop:=false; readch; iv:=0;
    while hexval>=0 do begin
      iv:=(iv shl 4)+hexval; readch;
    end;
    rf:=conv(iv);
  end else if isletter(ch) then rf:=function
  else if ch<>chr(0) then begin
    if ch<>CR then begin
      if ch<>CR then stop:=false;
      if ch='+' then readch;
      {if ch='-' then begin
        negative:=true; readch;
      end;}
      if not isnumber(ch) then
        error('Expected','number');
      while isnumber(ch) do begin
        rt:=rf+rf; rt:=rt+rt;
        rf:=rt+rt+rf+rf+conv(ord(ch)-ord('0'));
        readch;
      end;
      if ch='.' then begin
        dotused:=true; readch; rt:=0.1;
        while isnumber(ch) do begin
          rf:=rf+conv(ord(ch)-ord('0'))*rt;
          rt:=rt/10.; readch;
        end;
      end;
      if ch='E' then begin readch; exponent(rf) end;
    end;
    if negative then rf:=-rf;
  end;
  factor:=rf;
end;

func simexp:real;
{***************}
var
  rs,divisor: real;
begin
  rs:=factor;
  while (ch='*') or (ch='/') or (ch='&') or (ch='<')
    or (ch='>') or (ch='^') do begin
    case ch of
      '*': begin rs:=rs*factor; end;
      '/': begin
             divisor:=factor;
             if divisor=0.0 then
               error('Division','by zero')
             else
               rs:=rs/divisor;
           end;
      '&': rs:=conv(fix(rs) and fix(factor));
      '^': rs:=exp(factor*ln(rs));
      '<': begin
             readch; checkfor('<');
             rs:=conv(fix(rs) shl fix(factor));
             end;
      '>': begin
             readch; checkfor('>');
             rs:=conv(fix(rs) shr fix(factor));
           end
      end {case};
  end;
  simexp:=rs;
end;

{********body of express********}
begin
  re:=simexp;
  while (ch='+') or (ch='-') or (ch='|') do begin
    case ch of
      '+': begin re:=re+simexp; end;
      '-': begin re:=re-simexp; end;
      '|': begin
             re:=conv(fix(re) or fix(factor));
           end
    end {case};
  end;
  express:=re;
end;

{*********main body********}
begin
  write(INVVID);
  writeln('Enter an expression, for example:        ')
;
  writeln('32767      INPUT decimal number          ')
;
  writeln('$FFF       INPUT hex number              ')
;
  writeln('%1101      INPUT binary number           ')
;
  writeln('-55.35     INPUT negative number         ')
;
  writeln('2*(5+28)   math expression               ')
;
  writeln('R*3        last result                   ')
;
  writeln('<return>,<esc>    exit                   ')
;
  writeln('Operators: +,-,*,/,^,(),&,|,<<,>>        ')
;
  writeln('Functions: SQRT(),SQR(),SIN(),COS()      ')
;
  writeln('           TAN(),EXP(),LN(),LOG()        ')
;
  writeln(NORVID);
  r:=0.0; lastr:=0.0; dotused:=false;
  repeat
    firsterror:=true;
    clearinput;
    stop:=true; showresult;
    dotused:=false; lastr:=r; r:=express; checkfor(CR)
;
  until stop;
end.