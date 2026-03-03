{ ############################# }
{ include file ISCANNER:PAS for COMPILE }

{       *scan*      (global)    }
{ ############################# }
{ scan input and make tokens }

proc scan;

var count,ll,hh,i,i1,co: integer;
    name: array[7] of char;

{       * compresw*     (of scan)       }

func compresw(index: integer);

var addr,ci,i: integer;

begin
  addr:=8*index; i:=0;
  repeat
    ci:=ord(ident[i+1])-ord(reswtab[addr+i]);
    i:=succ(i)
  until (ci<>0) or (i>=8);
  compresw:=ci
end {compresw};

{       * clear *       (of scan)              }

proc clear; {clears 8 chars of identifier}

var i: integer;

begin
  for i:=1 to 8 do ident[i]:=' '
end;

{       * pack *        (of scan)              }

proc pack;  {packs token and ch to token }

begin
  token:=packed(low(token),ch); getchr
end;

{       * setval *      (of scan)              }

proc setval;

var r: real;
    n,n1: integer;
    ems: boolean;

  func times10(r:real):real;
  { slightly more accurate than 10.0*r }
  var r2,r4:real;
  begin
    r2:=r+r;
    r4:=r2+r2;
    times10:=r2+r4+r4;
  end;

begin
  r:=0.0;
  repeat
    r:=times10(r)+conv(ord(ch)-ord('0'));
    getchr;
  until (ch<'0') or (ch>'9');
  if ch<>'.' then begin {numeric integer}
    token:='nu';
    value[0]:=trunc(r+0.5);
  end
  else begin {numeric real}
    n:=0; getchr;
    while (ch<='9') and (ch>='0') do begin
      r:=times10(r)+conv(ord(ch)-ord('0'));
      n:=prec(n); getchr
    end;
    if ch='e' then begin
      ems:=false; getchr;
      case ch of
        '+': getchr;
        '-': begin ems:=true; getchr end
      end;
      if (ch>'9') or (ch<'0') then error(17)
      else begin
        n1:=ord(ch)-ord('0');
        getchr;
        if (ch<='9') and (ch>='0') then begin
          n1:=10*n1+ord(ch)-ord('0');
          getchr
        end;
        if ems then n:=n-n1 else n:=n+n1
      end
    end;
    while n>0 do begin
      n:=prec(n);
      r:=times10(r);
    end;
    while n<0 do begin
      n:=succ(n); r:=0.1*r;
    end;
    splitconv(r,value);
    token:='ru'
  end
end {setval};

{       * directive *   (of scan               }

proc directive;
var i,icyclus:integer;

begin
  getchr;
  case ch of
    'I': begin
           if savefno<>@0 then error(21);
           getchr; if ch<>' ' then error(20);
           i:=0; getchr;
           while (ch<>'}') and (i<16) do begin
             incname[i]:=ch; i:=i+1; getchr;
           end;
           while (i<16) do begin
             incname[i]:=' '; i:=i+1;
           end;
           icyclus:=0;
           asetfile(incname,icyclus,sdrive,'P');
           savefno:=fno;
           openr(fno);
           lineinc:=0;
           crlf;
           nextline;
           getchr; scan;
         end
    else error(20)
  end {case}
end;

{       * setid *       (of scan)              }

proc setid; {sets one char to ident}

begin
  if count<=idlength then begin
    ident[count]:=ch; count:=succ(count)
  end;
  getchr;
end {setid};

begin { ***** body of scan ***** }
  count:=1; while ch=' ' do getchr;
  tpos:=curpos;

  { delayed because of token lookahead }
  if nlflg then begin
    if lineflg and (pc>2) then begin
      code1($59);
      code1((line) and 255);
      code1((line) shr 8);
    end;
    nlflg:=false;
  end;

  if not (((ch>='a') and (ch<='z')) or
         ((ch>='A') and (ch<='Z')) or
         (ch='_')) then begin {main if}

    if (ch<'0') or (ch>'9') then begin {symb}
      token:=packed(' ',ch); getchr;
      case low(token) of
        '<': if (ch='=') or (ch='>') then pack;
        '>',':': if (ch='=') then pack;
        '{': begin
               if ch='$' then directive
               else begin
                 if ch<>'}' then
                 repeat getchr until ch='}';
                 getchr; scan
               end
             end;
        '$': begin {hex constant}
               token:='nu'; value[0]:=0;
               while ((ch>='0')and(ch<='9'))
                     or((ch>='a')and(ch<='f'))
                     do begin
                 if ch>'9' then
                   value[0]:=(value[0] shl 4)
                     +ord(ch)-ord('a')+10
                 else
                   value[0]:=(value[0] shl 4)
                     +ord(ch)-ord('0');
                 getchr
               end {do}
             end; {hex constant}
        chr(39): begin {string}
               token:='st';
               repeat setid until ch=chr(39);
               value[0]:=prec(count); getchr
              end
      end {case of token}
    end {special symbols}
    else setval {numeric value}
  end {main if}
  else begin {ident}
        clear;
    repeat
      setid
    until (ch<'0') or (ch>'z') or
      ((ch>'9') and (ch<'A')) or
      ((ch>'Z') and (ch<'a'));
    ll:=0; hh:=nresw; {look up in resword table}
    repeat
      i:=(ll+hh) shr 1; co:=compresw(i);
      if (co<0) then hh:=prec(i)
      else ll:=succ(i);
      until (co=0) or (ll>hh);
    if (co=0) then
      token:=reswcod[i] {reserved word found}
    else token:='id' {ident}
  end {odent}
end {scan};

{ * testto/parse * }

{ parce source for specific token; else error }

proc testto(x: packed char); { current token }
begin
  if token<>x then merror(2,x)
end;

proc parse(x: packed char); { next token }
begin
  scan; testto(x);
end;

{ * getlib * }

proc getlib;  { read library data }

var i,j,nent,addr,size,num,x,base: integer;
    libfil: file;
    ch,ltyp2,dummy: char;
    name: array[7] of char;

begin
  scan; if token=' ,' then scan;
  testto('id');
  base:=pc-2;
  if (ofno<>nooutput) then write(@ofno,'L');
  for i:=0 to 7 do begin
    name[i]:=ident[succ(i)];
    if ofno<>nooutput then
      write(@ofno,ident[succ(i)])
  end;
  write(prtoff);
  asetfile(name&'        ',0,cdrive,'L');
  openr(libfil);  { get table file }
  read(@libfil,nent,size);
  {including cr,lf}
  for i:=succ(spnt) to spnt+nent do begin
    if spnt>symbsize then error(7);
    spnt:=succ(spnt); addr:=8*i+1;
    for j:=0 to 7 do begin
      read(@libfil,ch);
      idtab[addr+j]:=ch
    end;
    read(@libfil,ch);
    read(@libfil,t0[i],dummy,t1[i],t2[i],t3[i]);
    t1[i]:=t1[i]+level;
    ltyp2:=high(t0[i]);
    if (ltyp2='p')or(ltyp2='f')
      or(ltyp2='g') then begin
      t2[i]:=t2[i]+base;
      if t3[i]<>0 then begin {stack data}
        read(@libfil,num);
        push(num); t3[i]:=stackpnt;
        for j:=1 to num do begin
          read(@libfil,x);
          push(x);
        end {for j};
      end {stack data}
    end {if ltyp2}
  end {for i}
  level:=succ(level); pc:=pc+size; offset:=pc;
  close(libfil);
  if spnt>spntmax then spntmax:=spnt;
  if stackpnt>stackmax then stackmax:=stackpnt;
  if prt then write(prton);
end {getlib};
