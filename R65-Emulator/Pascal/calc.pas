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

    F_AUTO=0;
    F_FIX2=1;

    T_AND = chr($80);
    T_OR  = chr($81);
    T_XOR = chr($82);
    T_MOD = chr($83);
    T_SHL = chr($84);
    T_SHR = chr($85);

mem vidpnt=$00e9:integer;

var ch: char;
    r, lastr: real;
    stop, dotused, firsterror, dummy: boolean;
    line: cpnt;
    pos, n, mode, format: integer;

proc error(s1,s2:cpnt);
{*********************}
begin
  if firsterror then
    writeln(INVVID,s1,' ',s2,NORVID);
  firsterror:=false;
end;

func isletter(ch:char):boolean;
{*****************************}
begin
  isletter:=(ord(ch)>=ord('A'))and(ord(ch)<=ord('Z'))
end;

proc readch;
{**********}
begin
  if firsterror then begin
    ch:=line[pos];

    if ch=ENDMARK then begin
      ch:=CR;
    end else begin

      if isletter(ch) then begin
        if (_strncmp(line+pos,'AND',3)=0)
          and not isletter(line[pos+3]) then begin
          ch:=T_AND;
          pos:=pos+3;
        end else
        if (_strncmp(line+pos,'OR',2)=0)
          and not isletter(line[pos+2]) then begin
          ch:=T_OR;
          pos:=pos+2;
        end else
        if (_strncmp(line+pos,'XOR',3)=0)
          and not isletter(line[pos+3]) then begin
          ch:=T_XOR;
          pos:=pos+3;
        end else
        if (_strncmp(line+pos,'MOD',3)=0)
          and not isletter(line[pos+3]) then begin
          ch:=T_MOD;
          pos:=pos+3;
        end else
        if (_strncmp(line+pos,'SHL',3)=0)
          and not isletter(line[pos+3]) then begin
          ch:=T_SHL;
          pos:=pos+3;
        end else
        if (_strncmp(line+pos,'SHR',3)=0)
          and not isletter(line[pos+3]) then begin
          ch:=T_SHR;
          pos:=pos+3;
        end else
          pos:=pos+1;
      end else
        pos:=pos+1;
    end;
  end else
    ch:=CR;
end;

proc skipblanks;
{**************}
begin
  while ch=' ' do readch;
end;

func fix(rf: real): integer;
{**************************}
var r:real;
begin
  if mode=M_BYTE then begin
    r:=rf-conv(floor(rf/256.0))*256.0;
    fix:=floor(r+0.5) and $ff;
  end else begin
    if rf>=32767.5 then begin
      error('Integer exceeds',
        'upper limit, set to 32767');
      fix:=$7fff;
    end else if rf< -32768.5 then begin
      error('Integer exceeds',
        'lower limit, set to -32768');
      fix:=$8000;
    end else
      fix:=floor(rf+0.5);
  end;
end;

proc checkfor(c: char);
{*********************}
var s: cpnt;
begin
  if ch<>c then begin
    s:=_new;
    write(@s,pos);
    error('Syntax error at position',s);
    _release(s);
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

proc writeascii(i:integer);
{*************************}
var c:integer;
begin
  c:=i and $7f;

  if (i and $80)<>0 then write(INVVID);

  case c of
     0: write('<NUL>');
     1: write('<SOH>');
     2: write('<STX>');
     3: write('<ETX>');
     4: write('<EOT>');
     5: write('<ENQ>');
     6: write('<ACK>');
     7: write('<BEL>');
     8: write('<BS>');
     9: write('<HT>');
    10: write('<LF>');
    11: write('<VT>');
    12: write('<FF>');
    13: write('<CR>');
    14: write('<SO>');
    15: write('<SI>');
    16: write('<DLE>');
    17: write('<DC1>');
    18: write('<DC2>');
    19: write('<DC3>');
    20: write('<DC4>');
    21: write('<NAK>');
    22: write('<SYN>');
    23: write('<ETB>');
    24: write('<CAN>');
    25: write('<EM>');
    26: write('<SUB>');
    27: write('<ESC>');
    28: write('<FS>');
    29: write('<GS>');
    30: write('<RS>');
    31: write('<US>');
    32: write('<SP>');
   127: write('<EOF>');
   127: write('<EOF>')
  else
    write(chr(c))
  end;

  if (i and $80)<>0 then write(NORVID);
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
          write(i:5);
          if i>=128 then
            write((i-256):6)
          else
            write(i:6);
          write('  $',hexb(i),'  ');
          writebinary(OUTPUT,i,8);
          write('  ');
          writeascii(i);
        end

  end;
  writeln;
end;

func express:real;
{****************}
var
    re,operand:real;
    i1,i2,i3:integer;

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

func fixaddress(r:real):integer;
{***************************}
begin
  if r>=32768.0 then
    fixaddress:=floor(r-65536.0+0.5)
  else
    fixaddress:=floor(r+0.5);
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

  if _strcmp(lstring,'MEM')=0 then begin
    if mode=M_FLOAT then begin
      error('MEM requires','WORD or BYTE mode');
      function:=0.0;
      _release(lstring);
      exit;
    end;

    skipblanks;
    checkfor('(');
    r:=express;
    skip(')');
    i:=fixaddress(r);
    if mode=M_BYTE then
      function:=conv(mem[i])
    else
      function:=conv(mem[i] or
                   (mem[(i+1) and $ffff] shl 8));
    _release(lstring);
    exit;
  end;

  if mode<>M_FLOAT then begin
    error('Mathematical functions',
          'require FLOAT mode');
    function:=0.0;
    _release(lstring);
    exit;
  end;

  if _strcmp(lstring,'PI')=0 then begin
    function:=PI; _release(lstring); exit;
  end;

  if _strcmp(lstring,'E')=0 then begin
    function:=E; _release(lstring); exit;
  end;

  { functions with single argument follow }
  skipblanks;
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
  negative:=false;
  rf:=0.0;
  readch;
  skipblanks;

  if ch='-' then begin
    negative:=true;
    readch;
    skipblanks;
  end;

  if (ch=CR) and (pos>1) then
    error('Unexpected', 'end of line');

  if ch=chr(39) then begin
    stop:=false;
    readch;
    rf:=conv(ord(ch));
    readch;
    checkfor(chr(39));
    readch;
  end else if ch='(' then begin
    stop:=false;
    rf:=express;
    checkfor(')');
    readch;
  end else if ch='%' then begin
    stop:=false;
    readch;
    iv:=0;
    while binval>=0 do begin
      iv:=(iv shl 1)+binval;
      readch;
    end;
    rf:=conv(iv);
  end else if ch='$' then begin
    stop:=false;
    readch;
    iv:=0;
    while hexval>=0 do begin
      iv:=(iv shl 4)+hexval; readch;
    end;
    rf:=conv(iv)
  end else if isletter(ch) then
    rf:=function
  else if ch<>chr(0) then begin
    if ch<>CR then begin
      stop:=false;
      if ch='+' then readch;

      if not isnumber(ch) then
        error('Expected','number');

      while isnumber(ch) do begin
        rt:=rf+rf;
        rt:=rt+rt;
        rf:=rt+rt+rf+rf+conv(ord(ch)-ord('0'));
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
  skipblanks;
  factor:=rf;
end;

func simexp:real;
{***************}
var
  rs,divisor:real;
  i1,i2,i3:integer;
begin
  rs:=factor;
  while (ch='*') or (ch='/') or (ch=T_AND)
        or (ch=T_SHL) or (ch=T_SHR) or (ch=T_MOD)
        do begin
    case ch of
      '*': begin
             divisor:=factor;
             if mode=M_FLOAT then
               rs:=rs*divisor
             else begin
               i1:=fix(rs);
               i2:=fix(divisor);
               i3:=i1*i2;
               if conv(i3)<>conv(i1)*conv(i2) then
                 error('Integer multiplication',
                                         'overflow');
               rs:=conv(i3);
             end;
           end;

      '/': begin
             divisor:=factor;
             if divisor=0.0 then
               error('Division','by zero')
             else if mode=M_FLOAT then
               rs:=rs/divisor
             else begin
               i1:=fix(rs);
               i2:=fix(divisor);
               if i2=0 then
                 error('Integer division','by zero')
               else
                 rs:=conv(i1 div i2);
             end;
           end;

      T_MOD: begin
                i1:=fix(rs);
                i2:=fix(factor);
                if i2=0 then
                  error('Modulo by zero','')
                else
                  rs:=conv(_mod(i1,i2));
           end;

      T_AND: rs:=conv(fix(rs) and fix(factor));

      T_SHL: rs:=conv(fix(rs) shl fix(factor));

      T_SHR: rs:=conv(fix(rs) shr fix(factor))

    end {case};
  end;
  simexp:=rs;
end;

{********body of express********}
begin
  re:=simexp;
  while (ch='+') or (ch='-') or (ch=T_OR)
                            or (ch=T_XOR) do begin
    case ch of
      '+': begin
             operand:=simexp;
             if mode=M_FLOAT then
               re:=re+operand
             else begin
               i1:=fix(re);
               i2:=fix(operand);
               i3:=i1+i2;
               if conv(i3)<>conv(i1)+conv(i2) then
                 error('Integer addition','overflow');
               re:=conv(i3);
             end;
           end;

      '-': begin
             operand:=simexp;
             if mode=M_FLOAT then
               re:=re-operand
             else begin
               i1:=fix(re);
               i2:=fix(operand);
               i3:=i1-i2;
               if conv(i3)<>conv(i1)-conv(i2) then
                 error('Integer subtraction',
                                          'overflow');
               re:=conv(i3);
             end;
           end;

      T_OR: re:=conv(fix(re) or fix(simexp));

      T_XOR: re:=conv(fix(re) xor fix(simexp))

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
  else if _strcmp(line,'WORD')=0 then begin
    mode:=M_WORD;
    r:=conv(fix(r));
  end else if _strcmp(line,'BYTE')=0 then begin
    mode:=M_BYTE;
    r:=conv(fix(r));
    if r<0.0 then r:=0.0;
    if r>255.0 then r:=255.0;
  end else if _strcmp(line,'AUTO')=0 then
    format:=F_AUTO
  else if _strcmp(line,'FIX2')=0 then
    format:=F_FIX2
  else
    command:=false;
end;

{*********main body********}
begin
  line := _new;

  writeln('Enter an expression, for example:');
  writeln('32767      INPUT decimal number');
  writeln('$FFF       INPUT hex number');
  writeln('%1101      INPUT binary number');
  writeln(chr(39),'A',chr(39),
          '        INPUT ASCII character');
  writeln('2*(5+28)   math expression');
  writeln('R*3        last result');
  writeln('<return>,<esc>   exit');
  writeln('Operators: +,-,*,/,(),AND,OR,XOR',
          ',SHL,SHR,MOD');
  writeln('Functions: SQRT(),SQR(),SIN(),COS()');
  writeln('           TAN(),EXP(),LN(),LOG(),MEM()');
  writeln('Modes:     FLOAT,WORD,BYTE');
  writeln('Format:    AUTO,FIX2');
  writeln;

  r := 0.0;
  lastr := 0.0;
  mode := M_FLOAT;
  format := F_AUTO;
  showresult;

  repeat
    firsterror:=true;

    case mode of
      M_FLOAT: write('FLOAT> ');
      M_WORD:  write('WORD> ');
      M_BYTE:  write('BYTE> ')
    end;

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