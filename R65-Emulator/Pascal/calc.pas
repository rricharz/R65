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
uses syslib,mathlib,strlib,writelib;

const
  M_FLOAT=0;
  M_WORD=1;
  M_BYTE=2;
  M_BOOL=3;

  F_AUTO=0;
  F_FIX2=1;

mem vidpnt=$00e9:integer;
    BUFFPN   = $0015: integer&;

var ch: char;
    r, lastr: real;
    stop, dotused, firsterror, dummy: boolean;
    line: cpnt;
    pos, n, mode, format: integer;

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
  if firsterror then begin
    ch := line[pos];
    if ch<>ENDMARK then pos := pos + 1
    else ch := CR;
  end else
    ch := CR;
end;

func fix(rf: real): integer;
{**************************}
begin
  if (rf>=32767.5) then begin
      error('Integer value exceeds',
        'upper limit, set to 32767');
      fix:=$7fff;
    end else if (rf<-32768.5) then begin
      error('Integer value exceeds',
        ' lower limit, set to -32768');
      fix:=$8000;
    end else fix:=floor(rf+0.5);
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

proc writebinary(f:file; r,bits:integer);
{***************************************}
var mask,i:integer;
begin
  write(@f,'%');
  if bits=8 then mask:=$0080
  else mask:=$8000;

  i:=0;
  while mask<>0 do begin
    if (r and mask)<>0 then write(@f,'1')
    else write(@f,'0');

    mask:=mask shr 1;
    i:=i+1;
    if (mask<>0) and (_mod(i,4)=0) then
      write(@f,' ');
  end;
end;

proc showresult;
{**************}
var i:integer;
begin
  case mode of
    M_FLOAT:
      if format=F_AUTO then
        write(r:12)
      else
        write(r:12:2);

    M_WORD:
      if (r < -32768.5) or (r >= 32767.5) then
        write('OVERFLOW')
      else begin
        i:=fix(r);
        write(i:12,'  $',hexw(i),'  ');
        writebinary(OUTPUT,i,16);
      end;

    M_BYTE:
      if (r < -0.5) or (r >= 255.5) then
        write('OVERFLOW')
      else begin
        i:=fix(r);
        write(i:12,'    $',hexb(i),'  ');
        write('          ');
        writebinary(OUTPUT,i,8);
      end;

    M_BOOL:
      if r=0.0 then
        write('false')
      else
        write('true')
  end;
  writeln;
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
    rf,rt:real;
    iv:integer;
begin
  negative:=false; rf:=0.0; readch;

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
  end else if isletter(ch) then
    rf:=function
  else if ch<>chr(0) then begin
    if ch<>CR then begin
      stop:=false;
      if ch='+' then readch;

      if not isnumber(ch) then
        error('Expected','number');

      while isnumber(ch) do begin
        rt:=rf+rf; rt:=rt+rt;
        rf:=rt+rt+rf+rf+
            conv(ord(ch)-ord('0'));
        readch;
      end;

      if ch='.' then begin
        dotused:=true; readch; rt:=0.1;
        while isnumber(ch) do begin
          rf:=rf+conv(ord(ch)-ord('0'))*rt;
          rt:=rt/10.0; readch;
        end;
      end;

      if ch='E' then begin
        readch; exponent(rf);
      end;
    end;
  end;

  if negative then rf:=-rf;
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

func command:boolean;
{*******************}
begin
  command:=true;
  if _strcmp(line,'FLOAT')=0 then
    mode:=M_FLOAT
  else if _strcmp(line,'WORD')=0 then
    mode:=M_WORD
  else if _strcmp(line,'BYTE')=0 then
    mode:=M_BYTE
  else if _strcmp(line,'BOOL')=0 then
    mode:=M_BOOL
  else if _strcmp(line,'AUTO')=0 then
    format:=F_AUTO
  else if _strcmp(line,'FIX2')=0 then
    format:=F_FIX2
  else
    command:=false;
end;

{*********main body********}
begin
  line := _new;

  write(INVVID);
  writeln('Enter an expression, for example:');
  writeln('32767      INPUT decimal number');
  writeln('$FFF       INPUT hex number');
  writeln('%1101      INPUT binary number');
  writeln('-55.35     INPUT negative number');
  writeln('2*(5+28)   math expression');
  writeln('R*3        last result');
  writeln('<return>,<esc>    exit');
  writeln('Operators: +,-,*,/,^,(),&,|,<<,>>');
  writeln('Functions: SQRT(),SQR(),SIN(),COS()');
  writeln('           TAN(),EXP(),LN(),LOG()');
  writeln('Modes:     FLOAT,WORD,BYTE,BOOL');
  writeln('Format:    AUTO,FIX2');
  writeln(NORVID);

  r := 0.0;
  lastr := 0.0;
  mode := M_FLOAT;
  format := F_AUTO;
  showresult;

  repeat
    firsterror:=true;
    n := _strread(INPUT, line, dummy);
    pos := 0;
    stop := true;

    if not command then begin
      dotused := false;
      lastr := r;
      r := express;
      checkfor(CR);
    end else
      stop := false;

    if not stop then showresult;
  until stop;

  _release(line);
end.