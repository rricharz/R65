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
uses syslib,mathlib,strlib;

var ch: char;
    r,lastr: real;
    stop,dotused: boolean;

proc release(s: cpnt);
{********************}
{ Only the last allocated string can be released }
{ This is suitable for recursive functions }
mem endstk=$000e: integer;
begin
  if cpnt(endstk)=s then endstk:=endstk+strsize;
end;

func fix(rf: real): integer;
{**************************}
begin
  if (rf>32767.5) then begin
      write(invvid,'Integer value exceeds');
      write(' upper limit, set to 32767');
      writeln(norvid); fix:=$7fff;
    end else if (rf<-32768.5) then begin
      write(invvid,'Integer value exceeds');
      write(' lower limit, set to -32768');
      writeln(norvid); fix:=$8000;
    end else
    fix:=trunc(rf);
end;

proc checkfor(c: char);
{*********************}
begin
  if ch<>c then begin
    write(invvid,'SYNTAX ERROR: expected ');
    if c=cr then write('<eol>')
    else write(c);
    write(' but found ');
    if ch=cr then writeln('<eol>',norvid)
    else writeln(ch,norvid);
  end;
end;

proc skip(c:char);
{****************}
begin
  checkfor(c); read(@input,ch);
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
  else if m=0. then begin
    write(@f,' 0',tab8,tab8); writehex(f,0);
    write(@f,'  ',tab8); writebinary(f,0);
  end else if r=conv($8000) then begin
    write(@f,'-32768',tab8,tab8); write(@f,'$8000');
    write(@f,'  ',tab8);
    write(@f,'% 1000 0000 0000 0000');
  end else if m>=32767.5 then writeflo(f,r)
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
    if d1>0 then write(@f,'.');
    for i1:=1 to d1 do begin
      m1:=10.*m1; write(@f,trunc(m1));
      m1:=m1-conv(trunc(m1));
    end;
    write(@f,'  ',tab8); writehex(f,trunc(r+rnd));
    write(@f,'  ',tab8); writebinary(f,trunc(r+rnd))
  end;
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
  lstring:=strnew;
  lstring[0]:=chr(0);
  strins(ch,0,lstring); read(@input,ch); i:=1;
  while isletter(ch) do begin
    strins(ch,i,lstring); read(@input,ch); i:=i+1;
  end;
  stop:=false;
  if strcmp(lstring,'R')=0 then begin
    function:=lastr; release(lstring); exit;
  end;
  if strcmp(lstring,'PI')=0 then begin
    function:=pi; release(lstring); exit;
  end;
  if strcmp(lstring,'E')=0 then begin
    function:=e; release(lstring); exit;
  end;
  { functions with single argument follow }
  checkfor('('); r:=express; skip(')');
  if strcmp(lstring,'SQR')=0 then begin
    function:=r*r; release(lstring); exit;
  end;
  if strcmp(lstring,'SQRT')=0 then begin
    function:=sqrt(r); release(lstring); exit;
  end;
  if strcmp(lstring,'SIN')=0 then begin
    function:=sin(r); release(lstring); exit;
  end;
  if strcmp(lstring,'COS')=0 then begin
    function:=cos(r); release(lstring); exit;
  end;
  if strcmp(lstring,'TAN')=0 then begin
    function:=tan(r); release(lstring); exit;
  end;
  if strcmp(lstring,'EXP')=0 then begin
    function:=exp(r); release(lstring); exit;
  end;
  if strcmp(lstring,'LN')=0 then begin
    function:=ln(r); release(lstring); exit;
  end;
  if strcmp(lstring,'LOG')=0 then begin
    function:=log(r); release(lstring); exit;
  end;
  writeln(invvid,'Unknown function ',lstring,norvid);
  function:=0.0;
  release(lstring);
end;

func factor:real;
{***************}
var negative:boolean;
    rf,rt: real;
    i,iv: integer;
begin
  negative:=false; rf:=0.;  read(@input,ch);
  if ch='-' then begin
    negative:=true; read(@input,ch);
  end;
  if ch='(' then begin
    stop:=false; rf:=express;
    checkfor(')'); read(@input,ch);
  end else if ch='%' then begin
    stop:=false; read(@input,ch); iv:=0;
    while binval>=0 do begin
      iv:=(iv shl 1)+binval; read(@input,ch);
    end;
    rf:=conv(iv);
  end else if ch='$' then begin
    stop:=false; read(@input,ch); iv:=0;
    while hexval>=0 do begin
      iv:=(iv shl 4)+hexval; read(@input,ch);
    end;
    rf:=conv(iv);
  end else if isletter(ch) then begin
    write(invvid); rf:=function; write(norvid)
  end else if ch<>chr(0) then begin
    if ch<>cr then begin
      if ch<>cr then stop:=false;
      if ch='+' then read(@input,ch);
      {if ch='-' then begin
        negative:=true; read(@input,ch);
      end;}
      if not isnumber(ch) then
        writeln(invvid,
          'SYNTAX ERROR: NUMBER EXPECTED',norvid);
      while isnumber(ch) do begin
        rt:=rf+rf; rt:=rt+rt;
        rf:=rt+rt+rf+rf+conv(ord(ch)-ord('0'));
        read(@input,ch);
      end;
      if ch='.' then begin
        dotused:=true; read(@input,ch); rt:=0.1;
        while isnumber(ch) do begin
          rf:=rf+conv(ord(ch)-ord('0'))*rt;
          rt:=rt/10.; read(@input,ch);
        end;
      end;
    end;
    if negative then rf:=-rf;
  end;
  factor:=rf;
end;

func simexp:real;
{***************}
var
  rs: real;
begin
  rs:=factor;
  while (ch='*') or (ch='/') or (ch='&') or (ch='<')
    or (ch='>') do begin
    case ch of
      '*': begin rs:=rs*factor; end;
      '/': begin rs:=rs/factor; end;
      '&': begin
             rs:=conv(fix(rs) and fix(factor));
           end;
      '<': begin
             read(@input,ch); checkfor('<');
             rs:=conv(fix(rs) shl fix(factor));
             end;
      '>': begin
             read(@input,ch); checkfor('>');
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
  write(invvid);
  writeln('Enter an expression, for example:        ');
  writeln('32767      input decimal number          ');
  writeln('$FFF       input hex number              ');
  writeln('%1101      input binary number           ');
  writeln('-55.35     input negative number         ');
  writeln('2*(5+28)   math expression               ');
  writeln('R*3        last result                   ');
  writeln('<return>,<esc>    exit                   ');
  writeln('Operators: +,-,*,/,(),&,|,<<,>>          ');
  writeln('Functions: SQRT(),SQR(),SIN(),COS()      ');
  writeln('           TAN(),EXP(),LN(),LOG()        ');
  writeln(norvid);
  r:=0.0; lastr:=0.0; dotused:=false;
  repeat
    stop:=true; writeauto(output,r); writeln;
    dotused:=false; lastr:=r; r:=express; checkfor(cr);
  until stop;
end.