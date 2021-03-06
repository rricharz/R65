{
   Pascal CALC for R65 computer system

   Note: The R65 Pascal system used
   32 bit floating point representation,
   which is not suitable for serious
   calculations, but was widely used
   in early 8-bit mircoprocessor
   systems. CALC tries to deal with
   this limited accuracy.

   Written 2019 by rricharz to demonstate
   R65 Pascal capabilities.

   The following operators are allowed:

     +,-       prefix for decimal input
     +,-,*,/   arithmetic operators
     ()        brackets
     |,&       bitwise operators
     <<,>>     bitwise shift operators

     $XX..     hex numeric input
     %XX..     binary numeric input
}

program calc;
uses syslib,mathlib;

var ch: char;
    r: real;
    stop,dotused: boolean;

func fix(rf: real): integer;
{**************************}
begin
  if (rf>32767.5) then
    begin
      write(invvid,'Integer value exceeds');
      write(' upper limit, set to 32767');
      writeln(norvid);
      fix:=$7fff;
    end
  else if (rf<-32768.5) then
    begin
      write(invvid,'Integer value exceeds');
      write(' lower limit, set to -32768');
      writeln(norvid);
      fix:=$8000;
    end
  else
    fix:=trunc(rf);
end;

proc checkfor(c: char);
{*********************}
begin
  if ch<>c then
    begin
      write(invvid,'SYNTAX ERROR: expected ');
      if c=cr then write('<eol>')
      else write(c);
      write(' but found ');
      if ch=cr then writeln('<eol>',norvid)
      else writeln(ch,norvid);
    end;
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
  write(@f,'$');
  mask := $f000;
  n := 12;
  while mask <>0 do
    begin
      r1 := (r and mask) shr n;
      if r1 < 10 then
        write(@f,r1)
      else
        write(@f,chr(ord(r1)+ord('A')-10));
      mask := mask shr 4;
      n := n - 4;
    end;
end;

proc writebinary(f:file; r: integer);
{***********************************}
var mask: integer;
begin
  write(@f,'% ');
  mask := $8000;
  while mask <> 0 do
    begin
      if (r and mask) <> 0 then
        write(@f,'1')
      else
        write(@f,'0');
      mask := mask shr 1;
      if mask = $0800 then
        write(@f,' ');
      if mask = $0080 then
        write(@f,' ');
      if mask = $0008 then
        write(@f,' ');
    end;
end;

proc writeauto(f:file;r:real);
{****************************}
{ outputs 5 digits }
var m,m1,max,rnd: real;
    i1:integer;
    sign: char;
    d1: integer;
begin

  sign:=' ';
  m:=r;
  if m<0. then begin
    sign:='-'; m:=-m;
  end;

  if dotused then
    writeflo(f,r)
  else if m=0. then
    begin
      write(@f,' 0',tab8,tab8);
      writehex(f,0);
      write(@f,'  ',tab8);
      writebinary(f,0);
    end
  else if r=conv($8000) then
    begin
      write(@f,'-32768',tab8,tab8);
      write(@f,'$8000');
      write(@f,'  ',tab8);
      write(@f,'% 1000 0000 0000 0000');
    end
  else if m>=32767.5 then
    writeflo(f,r)
  else if m<0.01 then
    writeflo(f,r)
  else begin

    if m>=10000. then
      begin d1:=0; rnd:=0.5 end
    else if m>=1000. then
      begin d1:=1; rnd:=0.05 end
    else if m>=100. then
      begin d1:=2; rnd:=0.005 end
    else if m>=10. then
      begin d1:=3; rnd:=0.0005 end
    else if m>=1. then
      begin d1:=4; rnd:=0.00005 end
    else if m>=0.1 then
      begin d1:=5; rnd:=0.000005 end
    else
      begin d1:=6; rnd:=0.0000005 end;

    m:=m+rnd; { round }

    write(@f,sign,trunc(m));
    m1:=m-conv(trunc(m));
    if d1>0 then write(@f,'.');
    for i1:=1 to d1 do begin
      m1:=10.*m1;
      write(@f,trunc(m1));
      m1:=m1-conv(trunc(m1));
    end;
    write(@f,'  ',tab8);
    writehex(f,trunc(r+rnd));
    write(@f,'  ',tab8);
    writebinary(f,trunc(r+rnd))
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

func factor:real;
{***************}
var negative:boolean;
    rf,rt: real;
    i,iv: integer;
begin
  negative:=false;
  rf:=0.;
  read(@input,ch);
  if ch='(' then
    begin
      stop:=false;
      rf:=express;
      checkfor(')');
      read(@input,ch);
    end
  else if ch='%' then
    begin
      stop:=false;
      read(@input,ch);
      iv:=0;
      while binval>=0 do
        begin
          iv:=(iv shl 1)+binval;
          read(@input,ch);
        end;
      rf:=conv(iv);
    end
  else if ch='$' then
    begin
      stop:=false;
      read(@input,ch);
      iv:=0;
      while hexval>=0 do
        begin
          iv:=(iv shl 4)+hexval;
          read(@input,ch);
        end;
      rf:=conv(iv);
    end
  else
    begin
      if ch<>cr then
        begin
          if ch<>cr then stop:=false;
          if ch='+' then read(@input,ch);
          if ch='-' then
            begin
              negative:=true;
              read(@input,ch);
            end;
          while isnumber(ch) do
            begin
              rt:=rf+rf;
              rt:=rt+rt;
              rf:=rt+rt+rf+rf+
                conv(ord(ch)-ord('0'));
              read(@input,ch);
            end;
          if ch='.' then
            begin
              dotused:=true;
              read(@input,ch);
              rt:=0.1;
              while isnumber(ch) do
                begin
                  rf:=rf+conv(ord(ch)-
                    ord('0'))*rt;
                  rt:=rt/10.;
                  read(@input,ch);
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
  while (ch='*') or (ch='/')
       or (ch='&') or (ch='<')
       or (ch='>') do
    begin
      case ch of
        '*': begin
               rs:=rs*factor;
             end;
        '/': begin
               rs:=rs/factor;
             end;
        '&': begin
               rs:=conv(fix(rs) and
                     fix(factor));
             end;
        '<': begin
               read(@input,ch);
               checkfor('<');
               rs:=conv(fix(rs) shl
                     fix(factor));
             end;
        '>': begin
               read(@input,ch);
               checkfor('>');
               rs:=conv(fix(rs) shr
                     fix(factor));
             end
      end {case};
    end;
  simexp:=rs;
end;

{********body of express********}
begin
  re:=simexp;
  while (ch='+') or (ch='-') or
            (ch='|') do
    begin
      case ch of
        '+': begin
               re:=re+simexp;
             end;
        '-': begin
               re:=re-simexp;
             end;
        '|': begin
               re:=conv(fix(re) or
                     fix(factor));
             end
      end {case};
    end;
  express:=re;
end;

{*********main body********}
begin
  writeln('Enter an expression, examples are:');
  writeln('32767     input decimal number');
  writeln('88.       force scientific display');
  writeln('$FFF      input hex number');
  writeln('%1101     input binary number');
  writeln('-55.35    input negative number');
  writeln('2*(5+28)');
  writeln('<return>  exit');
  writeln('operators: +,-,*,/,(),&,|,<<,>>');
  r:=0.;
  dotused:=false;
  repeat
    stop:=true;
    write(invvid);
    writeauto(output,r);
    writeln(norvid);
    dotused:=false;
    r:=express;
    checkfor(cr);
  until stop;
end.
    