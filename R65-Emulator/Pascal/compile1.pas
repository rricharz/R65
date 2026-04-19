{   ********************************            }
{   *                              *            }
{   *   R65 Micro Pascal Compiler  *            }
{   *            Pass 1            *            }
{   *                              *            }
{   ********************************            }

{ First version 1978 by rricharz                }
{ Version 3.7 (20K)  01/08/82 rricharz          }
{ Recovered 2018 by rricharz (r77@bluewin.ch)   }
{ Improved 2018-2026 by rricharz                }
{ 2026/4 ignore /F option                       }

{ Original derived from the publication by      }
{ Kin-Man Chung and Herbert Yen in              }
{ Byte, Volume 3, Number 9 and Number 10, 1978  }

{ usage:                                        }
{ compile1 name[.cy[,drv]] [xxx]                }
{  where x:       l,p: no hard copy print       }
{                 i,r: index bound checking     }
{                 n: no loader file             }

program compile1;

uses syslib, arglib, filelib;

const version='4.6';
    idlength  =64;    {max. length of ident}
    stacksize =256;   {stack size}
    pagelenght=60;    {no of lines per page}
    nooutput  =@0;
    maxfi     =3;     {max number of ins fls}
    yesOUTPUT=@255;

    nresw      = 63;    {number of res. words, max 64}
    symbsize   = 256;   {id table entries}
var reswtab: array[ 512] of char; {8*(nresw+1)}
    idtab:   array[2048] of char; {8*symbsize}

    tpos,pc,level,line,offset,dpnt,spnt,fipnt,
    npara,i,stackpnt,stackmax,spntmax,numerr,
    lineinc,linepage: integer;
    scyclus,sdrive,cdrive: integer;
    pname: array[15] of char;
    value: array[1] of integer;
    ch,restype,vartype:char;
    token: packed char;
    prt,libflg,rcheck,ateof: boolean;
    ucheck,lineflg,nlflg: boolean;
    fno,ofno,savefno: file;
    incname: array[15] of char;
    filstk: array[maxfi] of file;
    ident: array[idlength] of char;
    { Only the first 8 characters are        }
    { used to find and differentiate ids!    }

    stype: array[symbsize] of packed char;
{   type of symbol                           }
{   High letter:                             }
{     a:array, c:constant, d;const parameter }
{     e:constant array parameter, f:function }
{     g:array function, h;8-bit memory var   }
{     i:8-bit array memory variable          }
{     m:16-bit memory variable               }
{     n:16-bit array memory variable         }
{     p:procedure                            }
{     q:indexed cpnt                         }
{     r,t:function result                    }
{     s,u:array function result              }
{     v:variable, w:variable parameter       }
{     x:variable array parameter             }
{   Low letter:                              }
{     i:integer, c:char, p:packed char       }
{     q:cpnt (pointer to chars)              }
{     r:real(array multiple of two)          }
{     s:const cpnt                           }
{     f:file, b:boolean, u:undefined         }

    slevel: array[symbsize] of integer;
         {level}
    svda: array[symbsize] of integer;
         {val,dis,addr}
    sspsz: array[symbsize] of integer;
         {stack pointer,size of array}

    reswcod:array[nresw] of packed char;
    stack: array[stacksize] of integer;

{###########################}
{ global forward references }
{###########################}

proc newpage; forward;

{###################}
{ savebyte (global) }
{###################}

proc savebyte(x: integer);
begin
    if ofno<>nooutput then begin
      write(@ofno,
        chr(((x and 255) shr 4)+ord('0')));
      write(@ofno,chr((x and 15)+ord('0')))
    end
end {savebyte};

{###############}
{ crlf (global) }
{###############}

proc crlf;
begin
  writeln;
  line:=succ(line); lineinc:=succ(lineinc);
  linepage:=succ(linepage);
  if ((linepage div pagelenght)
    * pagelength)=linepage then newpage;
end {crlf};

{#################################}
{ merror and error: error message }
{#################################}

proc merror(x: integer; code: packed char);
var k: integer;
    answer: char;
begin
  crlf; numerr:=succ(numerr);
  for k:=2 to tpos do write(' ');
  write('^'); crlf;
  write(INVVID,'ERROR: ');
  case x of
    01: write('Ident');
    02: write('Ident ',code,' expected');
    03: write('Var declaration');
    04: write('Const expected');
    05: write('Ident unknown');
    06: write('Cannot be assigned');
    07: write('Symbol table overflow');
    08: write('Stack overflow');
    09: write('Expression');
    10: write('Statement');
    11: write('Declaration');
    12: write('Constant');
    13: write('Forward reference: ',code);
    14: write('Type mismatch: ',code);
    15: write('Array size');
    16: write('Array (8-bit)');
    17: write('Real');
    18: write('File table overflow');
    19: write('Parameter');
    20: write('Compiler directive syntax');
    21: write('Nested include files');
    22: write('Unexpected EOF');
    23: write('End mark for comment or string');
    24: write('Identifier already defined')
  end {case};
  writeln(NORVID);
  if (ofno<>nooutput) and (ofno<>yesOUTPUT)
    then close(ofno);
  ofno:=nooutput;
  _abort;
end {merror};

proc error(x: integer);
begin
  merror(x,'##')
end;

{############}
{ push & pop }
{############}

proc push(x: %integer);
begin
  if stackpnt>=stacksize then error(8)
  else stackpnt:=succ(stackpnt);
  if stackpnt>stackmax then stackmax:=stackpnt;
  stack[stackpnt]:=x;
end {push};

func pop: integer;
begin
  pop:=stack[stackpnt];
  stackpnt:=prec(stackpnt)
end {pop};

{#########}
{ newpage }
{#########}

proc newpage;
var i: integer;
begin
  if ((linepage)<>0) and prt then
    write(@PRINTER,FF);
  writeln; { Do not count this line}
  if pname[0]<>'x' then begin
    write('R65 COMPILE ');
    write(version);
    if libflg then write(': library ')
    else write(': program ');
    _prtext16(OUTPUT,pname);
  end;
  write(' ');
  _prtdate(OUTPUT);
  writeln(' page ',
    (linepage div pagelenght)+1);
  writeln;
end {newpage};

{################}
{ code1 (global) }
{################}
proc code1(x: %integer);  {set one byte p-code}
begin
  savebyte(x); pc:=succ(pc)
end;

{###################}
{ writenum (global) }
{###################}

proc writenum(i: integer);
begin
  if i<=999 then write(' ');
  if i<=99 then write(' ');
  if i<=9 then write(' ');
  write(i);
end;

{###################}
{ nextline (global) }
{###################}

proc nextline;
var i:integer;
begin
  nlflg:=true;
  if savefno=@0 then writenum(line)
  else begin
    write('{I:');
    for i:=0 to 5 do write(incname[i]);
    write('}');
    line:=line-1; { do not count line }
    writenum(lineinc);
  end;
  write(' (');
  if (pc+2)<9999 then write(' ');
  writenum(pc+2); write(') ');
end;

{#############################}
{ getchr and getchr0 (global) }
{#############################}

proc getchr0;
{ does not eliminate CR }
begin
  if ateof then begin
    if savefno<>@0 then begin
      { end of include file, close it }
      close(fno);
      fno:=savefno;
      { switch back to normal input file }
      savefno:=@0;
      ateof:=false;
      if ch=CR then ch:=' ';
    end else begin
      error(22);
      _abort
    end
  end else begin
    read(@fno,ch);
    if ch=CR then begin
      crlf;
      nextline;
    end {if}
    else if ch=EOF then begin
      ateof:=true;
      { we need to suppy one more char }
      { for end. at end of file to work properly }
      ch:=' ';
    end
    else write(ch);
  end;
end {getchr};

proc getchr;
{ replaces CR with ' ' to make parsing easier }
begin
  getchr0;
  if ch=CR then ch:=' ';
end;

{####################}
{ splitconv (global) }
{####################}

proc splitconv(a: array[1] of %integer;
  var b:array[1] of %integer);
begin
  b:=a;
end;

{###############}
{ init (global) }
{###############}

proc init;
const char96=chr(20);
var i,j,dummy: integer;
    dch: char;
    pch: packed char;
    request: array[15] of char;
    default: boolean;
begin {init}
  writeln('R65 PASCAL COMPILER version ', version,
    ', Pass  1');
  ateof:=false; savefno:=@0;
  cdrive:=FILDRV; { drive of compile program }
  fipnt:=-1;
  pc:=2; dpnt:=0; spnt:=0; offset:=2;
  npara:=0; level:=0;
  stackpnt:=0; libflg:=false;
  stackmax:=0;spntmax:=0; numerr:=0;
  stype[0]:='vi'; slevel[0]:=0;
  svda[0]:=0; sspsz[0]:=0;
  { prepare resword table }
  writeln('Reading list of reserved words');
  _asetfile('RESWORDS:W      ',0,cdrive,'W');
  openr(fno);
  for i:=0 to nresw do begin
    read(@fno,pch,dch);
    reswcod[i]:=pch;
    for j:=0 to 7 do reswtab[8*i+j]:=' ';
    j:=0;
    while (j<8) and (dch<>CR) do begin
      read(@fno,dch);
      if (dch<>CR) then
        reswtab[8*i+j]:=dch;
      j:=succ(j)
    end;
    while (dch<>CR) and (dch<>EOF) do
      read(@fno,dch)
  end;
  close(fno);

  writeln;

  sdrive:=1; {default drive for source }
  scyclus:=0;
  _agetstring(pname,default,scyclus,sdrive);

  _agetstring(request,default,dummy,dummy);

  rcheck:=false;
  ucheck:=false;
  prt:=true;
  ofno:=yesOUTPUT;
  lineflg:=false;
  if not default then begin
    if request[0]<>'/' then _argerror(103);
    for i:=1 to 8 do
      case request[i] of
        'P': prt:=false;
        'L': lineflg:=true;
        'R': rcheck:=true;
        'N': ofno:=nooutput;
        'F': begin end;
        ' ': begin end
        else _argerror(104)
      end; {case}
  end;

  _asetfile(pname,scyclus,sdrive,'P');
  openr(fno);
  scyclus:=FILCYC; { may have changed }
  {save cyclus and drive for compile2}
  ARGLIST[8]:=scyclus;
  ARGLIST[9]:=sdrive;
  NUMARG:=1;

  if prt then begin
    write(PRTON);
    _setemucom(8);
  end

  line:=0; lineinc:=0; linepage:=0;
  newpage; crlf; line:=1; linepage:=1;
  write('   1 (    4) '); getchr
end {init};

{###############}
{ scan (global) }
{ ############# }
{ scan input and make tokens }

proc scan;
var count,ll,hh,i,i1,co: integer;
    name: array[7] of char;

{####################}
{ compresw (of scan) }
{####################}

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

{#################}
{ clear (of scan) }
{#################}

proc clear; {clears 8 chars of identifier}
var i: integer;
begin
  for i:=1 to 8 do ident[i]:=' '
end;

{################}
{ pack (of scan) }
{################}

proc pack;  {packs token and ch to token }
begin
  token:=packed(low(token),ch); getchr
end;

{##################}
{ setval (of scan) }
{##################}

proc setval;
var r: real;
    n,n1: integer;
    ems: boolean;

  func times10(r:real):real;
  {########################}
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

{#####################}
{ directive (of scan) }
{#####################}

proc directive;
var i,icyclus:integer;

  proc onoff(var flag:boolean);
  begin
    getchr0; if ch=CR then error(23);
    case ch of
      '+': flag:=true;
      '-': flag:=false
    else error(20)
    end;
    getchr0; if ch=CR then error(23);
    if ch<>'}' then error(23);
    getchr; scan;
  end {onoff};

begin
  getchr;
  case ch of
    'I': begin
           if savefno<>@0 then error(21);
           getchr0; if ch=CR then error(23);
           if ch<>' ' then error(20);
           i:=0;
           getchr0; if ch=CR then error(23);
           while (ch<>'}') and (i<16) do begin
             incname[i]:=ch; i:=i+1;
             getchr0; if ch=CR then error(23);
           end;
           if ch<>'}' then error(23);
           while (i<16) do begin
             incname[i]:=' '; i:=i+1;
           end;
           icyclus:=0;
           _asetfile(incname,icyclus,sdrive,'P');
           savefno:=fno;
           openr(fno);
           lineinc:=0;
           crlf;
           nextline;
           getchr; scan;
         end;
    'R': onoff(rcheck);
    'U': onoff(ucheck)
  else error(20)
  end {case}
end;

{#################}
{ setid (of scan) }
{#################}

proc setid; {sets one char to ident}
begin
  if count<=idlength then begin
    ident[count]:=ch; count:=succ(count)
  end;
  getchr0;
end {setid};

{######################}
{ isidletter (of scan) }
{######################}

func isidletter: boolean;
{allowed letters in idents}
begin
  isidletter:=
        ( ((ch>='a') and (ch<='z')) or
          ((ch>='A') and (ch<='Z')) or
          (ch='_')
        );
end;

{##############}
{ body of scan }
{##############}

begin
  count:=1; while ch=' ' do getchr;
  tpos:=CURPOS;

  { delayed because of token lookahead }
  if nlflg then begin
    if lineflg and (pc>2) then begin
      code1($59);
      code1((line) and 255);
      code1((line) shr 8);
    end;
    nlflg:=false;
  end;

  if not isidletter then begin {main if}

    if (ch<'0') or (ch>'9') then begin {symb}
      token:=packed(' ',ch); getchr;
      case low(token) of
        '<': if (ch='=') or (ch='>') then pack;
        '>',':': if (ch='=') then pack;
        '{': begin
               if ch='$' then directive
               else begin
                 if ch<>'}' then
                 repeat
                   getchr0;
                   { if ch=CR then error(23); }
                   until ch='}';
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
               repeat
                 setid; if ch=CR then error(23);
               until ch=chr(39);
               value[0]:=prec(count); getchr
              end
      end {case of token}
    end {special symbols}
    else setval {numeric value}
  end {main if}
  else begin { is_id_letter }
        clear;
    repeat
      setid; if ch=CR then ch:=' ';
    until not
      (isidletter or ((ch>='0') and (ch<='9')));
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

{##############}
{ testto/parse }
{##############}

{ parce source for specific token; else error }

proc testto(x: packed char); { current token }
begin
  if token<>x then merror(2,x)
end;

proc parse(x: packed char); { next token }
begin
  scan; testto(x);
end;

{########}
{ getlib }
{########}

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
  write(PRTOFF);
  _asetfile(name&'        ',0,cdrive,'L');
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
    read(@libfil,stype[i],dummy,slevel[i],
      svda[i],sspsz[i]);
    slevel[i]:=slevel[i]+level;
    ltyp2:=high(stype[i]);
    if (ltyp2='p')or(ltyp2='f')
      or(ltyp2='g') then begin
      svda[i]:=svda[i]+base;
      if sspsz[i]<>0 then begin {stack data}
        read(@libfil,num);
        push(num); sspsz[i]:=stackpnt;
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
  if prt then write(PRTON);
end {getlib};

{ ################################ }
{ block (global): handle one block }
{ ################################ }

proc block(bottom: integer);

var l,f9,i,n,stackpn1,forwpn,find,cproc,
    spnt1,dpnt1,parlevel: integer;
    fortab: array[8] of integer;
    ptok: packed char;
    isfunc: boolean;

{#################################}
{ findid: {search in table for id }
{#################################}

func findid;
var k,i: integer;
    id1: char;
begin
  i:=1; k:=8*spnt+9; id1:=ident[1];

  repeat
    k:=k-8;
    while (idtab[k]<>id1) and (k>0) do k:=k-8;
    if k>0 then begin
       i:=1;
       repeat i:=succ(i)
         until (i>8) or
             (idtab[k+i-1]<>ident[i]);
    end;
    until (i>8) or (k<=0);
  if k<=0 then begin
    findid:=0;
  end
  else
    findid:=(k-1) shr 3;
end;

{##################}
{ code2 (of block) }
{##################}

proc code2(x,y: integer);
begin
  code1(x); code1(y);
end;

{##################}
{ code3 (of block) }
{##################}

proc code3(x: integer; y1: %integer);

var y: integer;

begin {code3}
  y:=y1;
  if (x=34) and (y>=0) and (y<256) then
    code2(32,y)
  else begin
    if (x=35) and (y>-128) and (y<=127) then
      begin
        if (y<0) then y:=y+256;
        code2(33,y);
      end
    else begin
      if (x>=36) and (x<=38) then y:=y-pc-1;
      code1(x); code1(y and 255);
      code1(y shr 8);
    end
  end
end {code3};

{#####################}
{ testtype (of block) }
{#####################}

proc testtype(ttype: char);

begin
  if restype<>ttype then
    if (restype<>'u') and (ttype<>'u') then
      merror(14,packed(ttype,restype));
end;

{###################}
{ putsym (of block) }
{###################}

proc putsym(ltyp1,ltyp2: char);

var i,addr,oldid: integer;

begin
  if ucheck then begin
    oldid:=findid;
    if oldid<>0 then
      if not ((ltyp1='f') and
            (oldid=spnt) and
            (high(stype[oldid])='f') and
            (level=slevel[oldid]+1))
      then error(24);
  end;

  if spnt>=symbsize then error(7)
  else spnt:=succ(spnt);

  if spnt>spntmax then spntmax:=spnt;

  stype[spnt]:=packed(ltyp1,ltyp2);
  sspsz[spnt]:=0;

  addr:=8*spnt;
  for i:=1 to 8 do idtab[addr+i]:=ident[i];

  if ltyp1='v' then begin
    svda[spnt]:=dpnt;
    dpnt:=succ(dpnt);
  end;

  slevel[spnt]:=level
end {putsym};

{#######################}
{ checkindex (of block) }
{#######################}

proc checkindex(lowlim,highlim: integer);
begin
  if rcheck then begin
    code3($40,lowlim-1);
    code2(highlim and 255, highlim shr 8)
  end
end;

{###################}
{ getcon (of block) }
{###################}

func getcon;

var idpnt,val,ii: integer;
    rval: real;
    sign: char;
begin
  restype:='i';
  if token=' -' then begin
    sign:='-'; scan
  end else begin
    sign:='+'; if token=' +' then scan
  end;
  case token of
    'nu': val:=value[0];
    'ru': begin val:=value[0];
            restype:='r' end;
    'st': if value[0]=1 then begin
            restype:='c';
            val:=ord(ident[1])
          end else if value[0]=2 then begin
            val:=(ord(ident[1]) shl 8) +
              ord(ident[2]);
            restype:='p';
          end else if value[0]>2 then begin
            val:=pc;
            for ii:=1 to value[0] do
                        code1(ord(ident[ii]));
            code1(0); value[0]:=0; restype:='s';
          end else error(15);
    'cr': begin parse(' ('); scan; val:=getcon;
            if (val>127) or (val<0) then
              error(12);
            testtype('i');
            restype:='c'; parse(' )');
          end;
    'tr': begin val:=1; restype:='b' end;
    'fa': begin val:=0; restype:='b' end;
    'cp': begin
            scan; val:=getcon;
            testtype('i'); restype:='q';
          end;
    ' @': begin scan; val:=getcon;
            if restype<>'q' then testtype('i');
            restype:='f'
          end
    else begin
      testto('id'); idpnt:=findid;
      if (idpnt>0) and (high(stype[idpnt])='c')
      then begin
        val:=svda[idpnt];
        restype:=low(stype[idpnt]);
        if restype='r' then
          value[1]:=sspsz[idpnt];
      end
      else begin error(4); val:=0;
        restype:='i'
      end
    end
  end {case};
  if sign='-' then
    case restype of
      'i': getcon:=-val;
      'r': begin value[0]:=val;
             splitconv(value,rval);
             splitconv(-rval,value);
             getcon:=value[0]
           end
      else error(12)
    end {case}
  else getcon:=val;
end {getcon};

{#####################}
{ deccon ( of block ) }
{#####################}

proc deccon;    { declare constant }
begin
  if token=' ;' then scan;
  testto('id');
  putsym('c','i');
  parse(' ='); scan;
  svda[spnt]:=getcon;
  if (restype='r') then sspsz[spnt]:=value[1];
  if restype<>'i' then
    stype[spnt]:=packed('c',restype);
  scan
end {deccon};

{#####################}
{ decvar ( of block ) }
{#####################}

proc decvar(typ1,typ2: char);
begin
  if token=' ,' then scan;
  testto('id');
  putsym(typ1,typ2);
  scan;
end {decvar};

{######################}
{ gettype ( of block ) }
{######################}

proc gettype(var typ2: char;
  var aflag,uflag: boolean; var n: integer);

begin
  aflag:=false; n:=0; uflag:=false;
  scan;
  if token='ar' then begin
    parse(' ['); scan;
    n:=getcon; testtype('i');
    if (n<1) then begin error(15); n:=1 end;
    parse(' ]'); parse('of'); scan;
    aflag:=true
  end;
  if token=' %' then begin
    scan; uflag:=true
  end;
  case token of
    'in': typ2:='i';
    'ch': typ2:='c';
    'pa': begin parse ('ch'); typ2:='p' end;
    'bo': typ2:='b';
    'rl': begin typ2:='r'; aflag:=true;
            n:=prec(2*succ(n)) end;
    'cp': typ2:='q';
    'fl': typ2:='f'
    else begin error(11); typ2:='i';end
  end {case}
end {gettype};

{######################}
{ variable ( of block) }
{######################}

proc variable;  { variable declarations }

var typ1,typ2: char;
    i,l: integer;
    aflag,uflag: boolean;

begin
  scan;
  repeat {main loop}
    l:=0;
    repeat decvar('v','i'); l:=succ(l);
    until token<> ' ,';
    testto(' :');
    gettype(typ2,aflag,uflag,n);
    if uflag then error(11);
    if aflag then typ1:='a' else typ1:='v';
    if typ1='a' then begin {array}
       dpnt:=dpnt-l; {variable has been assumed}
       for i:=succ(spnt-l) to spnt do begin
         svda[i]:=dpnt; sspsz[i]:=n;
         dpnt:=succ(dpnt+n);
      end
    end {array};
    for i:=succ(spnt-l) to spnt do
      stype[i]:=packed(typ1,typ2);
    parse(' ;');scan
  until token<>'id' {end main loop}
end {variable};

{####################}
{ fixup ( of block ) }
{####################}

proc fixup(x: integer);
begin
  if ofno<>nooutput then begin
    write(@ofno,'F');
    savebyte(succ(x-offset) and 255);
    savebyte(succ(x-offset) shr 8);
    savebyte((pc-x-1) and 255);
    savebyte((pc-x-1) shr 8);
  end;
end;

{#######################}
{ function ( of block ) }
{#######################}

proc function;

var n: integer;
    typ1,typ2: char;
    aflag,uflag: boolean;
begin
  if token<>' :' then begin
    aflag:=false; uflag:=false; typ2:='i' end
  else begin
    gettype(typ2,aflag,uflag,n);
    scan
  end;
  if aflag then begin
    typ1:='s'; sspsz[succ(cproc)]:=n;
    svda[succ(cproc)]:=svda[succ(cproc)]-n
  end
  else typ1:='r';
  stype[succ(cproc)]:=packed(typ1,typ2);
  if uflag then typ2:='u';
  if aflag then typ1:='g'
  else typ1:='f';
  stype[cproc]:=packed(typ1,typ2);
end {function};

{########################}
{ parameter ( of block ) }
{########################}

proc parameter;

var counter1,counter2,i,n,bs: integer;
    aflag,uflag: boolean;
    vtype1,vtype2: char;
    vtype: packed char;

begin
  push(0); { dummy size, fixed later }
  if find=0 then sspsz[spnt-npara]:=stackpnt
  else bs:=stackpnt;
  counter1:=0
  repeat {main loop}
    counter2:=0;
    vtype1:='d'; vtype2:='i';
    scan;
    if token='co' then scan
    else if token='va' then begin
      scan; vtype1:='w' end; {variable param}
    end;
    repeat {inner loop}
      decvar(vtype1,vtype2);
      svda[spnt]:=parlevel;
      parlevel:=succ(parlevel);
      npara:=succ(npara);
      counter2:=succ(counter2);
      until token<>' ,';
    uflag:=false;aflag:=false; n:=0;
    if token<>' :' then
      vtype2:='i' {assume integer }
    else begin
      gettype(vtype2,aflag,uflag,n);
      if n>63 then error(15);
      scan
    end;
    if aflag then begin
      vtype1:=succ(vtype1);
      parlevel:=parlevel-counter2;
    end;
    vtype:=packed(vtype1,vtype2);
    for i:=1 to counter2 do begin
      if uflag then push(packed(vtype1,'u'))
      else push(vtype);
      if aflag then begin
        push(n); sspsz[spnt-counter2+i]:=n;
        svda[spnt-counter2+i]:=parlevel;
        parlevel:=succ(parlevel)+n;
      end {then};
      stype[spnt-counter2+i]:=vtype;
    end {for};
    if aflag then counter2:=2*counter2;
    counter1:=counter1+counter2;
    until token<>' ;'; {outer loop}
  testto(' )'); scan;
  if find=0 then
    stack[sspsz[spnt-npara]]:=counter1
  else begin {information is allready there}
    stack[bs]:=counter1;
    n:=sspsz[fortab[find]]; {existing stack data}
    for i:=0 to stackpnt-bs do
      if stack[bs+i]<>stack[n+i]
        then merror(13,'pa'); {parameter wrong}
    stackpnt:=prec(bs) {clear the new info}
  end  {else}
end {parameter};

{####################}
{ memory ( of block) }
{####################}

proc memory;

var typ1,typ2:char;
    i,l,n: integer;
    aflag,uflag: boolean;

begin
  scan;
  repeat {main loop}
    l:=0;
    repeat
      decvar('m','i');
      l:=succ(l); testto(' ='); scan;
      n:=getcon; testtype('i');
      scan; svda[spnt]:=n;
    until token<>' ,';
    testto(' :');
    gettype(typ2,aflag,uflag,n);
    if uflag then error(11);
    scan;
    if token=' &' then begin {8-bit}
      typ1:='h'; scan
    end
    else typ1:='m';
    if aflag then typ1:=succ(typ1);
    for i:=succ(spnt-l) to spnt do begin
      stype[i]:=packed(typ1,typ2);
      sspsz[i]:=n;
    end;
    testto(' ;'); scan;
  until token<>'id';
end {memory};

{######################}
{ statmnt ( of block ) }
{######################}

proc statmnt;
var idpnt,relad,k2,savpc,bottom1: integer;
    device,wln: boolean;
    savtp1,vartyp2: char;
    wl: boolean;

{########################}
{ code4 ( of statement ) }
{########################}

proc code4(x,y1,z1: integer); {set 4-byte code}
var y,z: integer;
begin
  y:=y1; z:=z1;
  if y<0 then y:=y+256;
  if x=43 then z:=z-pc-2;
  code1(x);code1(y);code1(z and 255);
  code1(z shr 8)
end {code4};

{##############################}
{ testferror ( of statement) ) }
{##############################}

proc testferror;
begin
  code1($4f);
end;

{########################}
{ gpval ( of statement ) }
{########################}

proc gpval(idpnt: integer;
  dir: boolean; typ: char);

var d: integer;

begin {gpval}
  if dir then d:=1 else d:=0;
  case typ of
  'h':  begin code3($22,svda[idpnt]);
          if dir then code1($3f);
          code1($17+d) end;
  'm':  begin code3($22,svda[idpnt]);
          code1($3d+d) end;
  'i':  begin
          if dir then code1($3f);
          code3($22,svda[idpnt]);
          code1(3);
          if dir then code1($3f);
          code1($17+d) end;
  'n':  begin if dir then code1($3f);
          code3($22,1); code1($12);
          code3($22,svda[idpnt]);
          code1(3); code1($3d+d) end
  else begin
    if typ='q' then
      code4($55,level-slevel[idpnt],2*svda[idpnt])
    else
      code4($27+2*d+relad,level-slevel[idpnt],
        2*svda[idpnt]);
    end {else}
  end {case}
end;

{###############################################}
{ FORWARD declaration of mainexp (of statement) }
{###############################################}

proc mainexp(reqtype: char;
  var arsize: integer); forward;

{##########################}
{ express ( of statement ) }
{##########################}

proc express; {requests a normal 16-bit result }
var resultsize: integer;
begin {express}
  mainexp('n',resultsize);
  if resultsize<>0 then error(15)
end {express};

{########################}
{ arrayexp ( of mainexp) }
{########################}

proc arrayexp(size: integer; eltype: char);
var resultsize: integer;
begin
  mainexp(eltype,resultsize);
  if resultsize<>size then error(15);
  testtype(eltype);
end;

{#########################}
{ getvar ( of statement ) }
{#########################}

proc getvar;
begin
  vartyp2:=high(stype[idpnt]);
  vartype:=low(stype[idpnt]);
  scan;
  if (vartype='q') and (token=' [') and
    ((vartyp2='v') or (vartyp2='d')) then begin
    vartyp2:='q'; vartype:='c';
  end;
  case vartyp2 of
  'a','x','s','i','n','q':
      begin
        if token=' [' then begin
          scan; express; relad:=1;
          if vartyp2='r' then begin
            relad:=3;
            code3($22,1); code1($12)
          end;
          if (vartyp2='q') and (sspsz[idpnt]=0) then
            checkindex(0,63)
          else
            checkindex(0,sspsz[idpnt]);
          testtype('i'); testto(' ]'); scan;
        end else relad:=2;
      end;
  'v','w','r','h','m': relad:=0;
  'c','d','e','t','u': error(6)
  else error(1)
  end {case}
end {getvar};

{#########################}
{ prcall ( of statement ) }
{#########################}

proc prcall (idpn1: integer);

var bstack,numpar,i,n,n2: integer;

{ body of prcall follows later }

{#######################}
{ prcall1 ( of prcall ) }
{#######################}

proc prcall1;
var ressize:integer;

  proc prcall3;
  {###########}
  begin {prcall3}
    testto('id');
    idpnt:=findid;
    if idpnt=0 then error(5);
    getvar;
    if chr(stack[i] and 255)<>vartype then
      if chr(stack[i] and 255)<>'u' then
        merror(14,'01');
      push(idpnt);
  end {prcall3};

begin {prcall1}
  case chr(stack[i] shr 8) of
    'd':  begin
            if chr(stack[i] and 255) = 'q' then
              mainexp('q',ressize)
            else
              express;
            if chr(stack[i] and 255)<>'u' then
              testtype(chr(stack[i] and 255));
          end;
    'e':  begin
            arrayexp(stack[succ(i)],
              chr(stack[i]));
            i:=succ(i);
          end;
    'w':  begin
            prcall3;
            if relad<>0 then merror(14,'02');
            gpval(idpnt,false,vartyp2);
          end;
    'x':  begin
            prcall3;
            if relad<>2 then merror(14,'03');
            if vartyp2='i' then error(16);
            i:=succ(i);
            if stack[i]<>sspsz[idpnt] then
              error(15);
            if vartyp2='n' then begin
              code3($22,svda[idpnt]);
              code1($3d);
            end else code4($27,level-slevel[idpnt],
              2*svda[idpnt]);
            code2($3b,stack[i]);
          end
    else merror(14,'04')
  end {case}
end {prcall1};

{#####################}
{ prcall2 (of prcall) }
{#####################}

proc prcall2;
begin
  if n>0 then code3(35,-2*n);
  n:=0
end {prcall2};

{################}
{ body of prcall }
{################}

begin {body of prcall}
  if sspsz[idpn1]<>0 then begin
    bstack:=sspsz[idpn1];
    numpar:=stack[bstack];
    parse(' ('); scan;
    for i:=succ(bstack) to bstack+numpar do
    begin
      prcall1;
      if i<bstack+numpar then begin
        testto(' ,'); scan
      end
    end;
    testto(' )');
  end {then};
  code4(43,level-slevel[idpn1],svda[idpn1]);
  if sspsz[idpn1]<>0 then begin
    n:=0; i:=bstack+numpar;
    repeat
      case chr(stack[i] shr 8) of
      'd':  n:=succ(n);
      'w':  begin
              prcall2; idpnt:=pop;
              gpval(idpnt,true,
                  high(stype[idpnt]));
            end;
      chr(0): begin
            n2:=stack[i];
            i:=i-1;
            case chr(stack[i] shr 8) of
              'e':  n:=succ(n+n2);
              'x':  begin
                      prcall2;
                      idpnt:=pop;
                      if high(stype[idpnt])='n'
                      then begin
                        code3($22,svda[idpnt]+
                          2*sspsz[idpnt]);
                        code1($3e)
                      end else
                        code4(41,
                          level-slevel[idpnt],
                          2*(svda[idpnt]+
                          sspsz[idpnt]));
                      code2($3c,sspsz[idpnt])
                    end
              end {case}
            end
      end; {case}
      i:=prec(i);
    until i=bstack;
    prcall2
  end
end {prcall};

{########################}
{ mainexp (of statement) }
{########################}
{  see forward declaration above    }

proc mainexp(reqtype: char;
  var arsize: integer);

{ variables of mainexp}
var opcode,roff: integer;
    savtype: char;

{########################}
{ argument ( of mainexp ) }
{#########################}

proc argument(rtype: char);
begin
  parse(' ('); scan; express;
  testtype(rtype);
  testto(' )'); scan
end; {argument}

{#######################}
{ simexp ( of mainexp ) }
{#######################}

proc simexp(var arsize1: integer);
var opcode: integer;
    sign: char;

{body of simexp  follows later }

{#####################}
{ term ( of simexp )  }
{#####################}

proc term(var arsize2: integer);

var opcode: integer;

{ body of term follows later }

{#######################}
{ factor ( of term )    }
{#######################}

proc factor(var arsize3: integer);

var i, idpnt: integer;
    h: char;

{ body of factor follows later }

{######################}
{ index ( of factor )  }
{######################}

proc index(chk: boolean);
var savtype: char;
begin {index}
  scan; savtype:=restype;
  express; testtype('i'); testto(' ]');
  if savtype='r' then begin
    code3($22,1); code1($12);
  end;
  if chk then begin
    if (savtype='q') and (sspsz[idpnt]=0) then
      { is an arrayed cpnt }
      checkindex(0,63)
    else
      checkindex(0,sspsz[idpnt]);
  end;
  restype:=savtype; scan
end;

{################}
{ body of factor }
{################}

begin
  arsize3:=0;
  case token of
    'id': begin {identifier }
            idpnt:=findid;
            if idpnt=0 then error(5);
            restype:=low(stype[idpnt]);
            h:=high(stype[idpnt]);
            case h of
              'v','w','d':
                    begin
                      scan;
                      if (restype='q') and (token=' ['
)
                      then begin
                        code4(39,level-slevel[idpnt],
                          2*svda[idpnt]);
                        index(true);
                        code1($03);
                        code1($54);
                        restype:='c';
                      end else
                        code4(39,level-slevel[idpnt],
                          2*svda[idpnt]);
                    end;
              'h':  begin code3($22,svda[idpnt]);
                      code1($17); scan end;
              'i':  begin code3($22,svda[idpnt]);
                      scan;
                      if token=' [' then begin
                        index(true); code1($03);
                        code1($17)
                      end else begin
                        error(16)
                      end
                    end;
              'm':  begin code3($22,svda[idpnt]);
                      code1($3d); scan
                    end;
              'n':  begin code3($22,svda[idpnt]);
                      scan;
                      if token=' [' then begin
                        index(true);
                        code3($22,1);code1($12);
                        code1($03); code1($3d);
                        if restype='r' then
                        begin
                          code2($3b,1);
                          arsize3:=1
                        end
                      end else begin
                        code1($3d);
                        code2($3b,sspsz[idpnt]);
                        arsize3:=sspsz[idpnt];
                      end
                    end;
              'r','t': begin
                      code3(35,2);
                      idpnt:=prec(idpnt);
                      prcall(idpnt); scan;
                      restype:=low(stype[idpnt]);
                    end;
              'c':  if low(stype[idpnt])<>'r' then
                    begin
                      code3(34,svda[idpnt]);
                      scan;
                      if restype='s' then begin
                        if token=' [' then begin
                          index(true);
                          code1($03);
                          code1($58);
                          code1($54);
                          restype:='c';
                        end else begin
                          code1($58);
                          restype:='q';
                        end;
                      end;
                      {scan;}
                    end else begin
                      code2($3a,2);
                      code2(svda[idpnt] and 255,
                        svda[idpnt] shr 8);
                      code2(sspsz[idpnt] and 255,
                        sspsz[idpnt] shr 8);
                      arsize3:=1; scan
                    end;
              'a','e','x':
                    begin scan;
                      if token=' [' then begin
                        index(true);
                        code4($28,
                            level-slevel[idpnt],
                            2*svda[idpnt]);
                        if restype='r' then
                        begin
                          code2($3b,1);
                          arsize3:=1
                        end
                      end else begin
                        code4($27,
                            level-slevel[idpnt],
                            2*svda[idpnt]);
                        code2($3b,sspsz[idpnt]);
                        arsize3:=sspsz[idpnt];
                      end
                    end;
              's','u':
                    begin
                      code3(35,2*sspsz[idpnt]+2);
                      idpnt:=prec(idpnt);
                      prcall(idpnt); scan;
                      restype:=low(stype[idpnt]);
                      idpnt:=succ(idpnt);
                      arsize3:=sspsz[idpnt]
                    end
              else error(1)
            end {case}
          end; {identifier}
    'nu': begin code3(34,value[0]); scan;
            restype:='i'
          end;
    'ru': begin code2($3a,2);
            code2(value[0] and 255,
              value[0] shr 8);
            code2(value[1] and 255,
              value[1] shr 8);
            scan; restype:='r';
            arsize3:=1
          end;
    'st': begin
          if (reqtype='n') and (value[0]<3)
            then begin
              if value[0]<2 then begin
                code3(34,ord(ident[1]));
                restype:='c'
              end else begin
                code3(34,packed(ident[1],
                  ident[2]));
                restype:='p'
              end
            end else begin
              case reqtype of
                'c','u','n','q':
                    begin
                      if (vartype='q') or
                         (reqtype='q') then begin
                        arsize3:=0;
                        restype:='q';
                        code2($56,value[0]);
                      end else begin
                        arsize3:=prec(value[0]);
                        restype:='c';
                        code2($39,value[0]);
                      end;
                      for i:=1 to value[0] do
                        code1(ord(ident[i]));
                      if (vartype='q') or
                         (reqtype='q') then code1(0);
                    end;
                'p': begin
                      if odd(value[0]) then
                        error(15);
                      value[0]:=value[0] shr 1;
                      arsize3:=prec(value[0]);
                      restype:='p';
                      code2($3a,value[0]);
                      for i:=1 to value[0] do
                        begin
                        code1(ident[2*i]);
                        code1(ident[2*i-1]);
                      end
                    end
                else merror(14,'05')
              end {case}
            end;
            scan
          end;
    'od': begin
            argument('i'); code1(7);
            restype:='b'
          end;
    'me': begin
            parse(' ['); index(false);
            code1(23); restype:='i';
          end;
    ' (': begin
            scan; mainexp(reqtype,arsize3);
            testto(' )'); scan
          end; {no type change}
    'no': begin
            scan; factor(arsize3);
            if (arsize3<>0) then error(15);
            code1($11);
            if restype<>'i' then
              testtype('b')
          end;
    'cr': begin
            argument('i'); code1(52);
            restype:='c'
          end;
    'hi': begin
            argument('p'); code1(51);
            restype:='c'
          end;
    'lo': begin
            argument('p'); code1(52);
            restype:='c'
          end;
    'su': begin
            argument('u'); code1($14);
          end;
    'pc': begin
            argument('u'); code1($15)
          end;
    'cp': begin
            argument('i'); restype:='q';
          end;
    'ni': begin
            code3(34,0); scan; restype:='q';
          end;
    'ox': begin
            argument('u');
            restype:='i'
          end;
    ' @': begin
            scan; factor(arsize3);
            if arsize3<>0 then error(15);
            if restype<>'q' then testtype('i');
            restype:='f'
          end;
    'tr': begin
            code3(34,1); scan;
            restype:='b';
          end;
    'fa': begin
            code3(34,0); scan;
            restype:='b'
          end;
    'tc': begin
            parse(' ('); scan;
            arrayexp(1,'r');
            testto(' )'); scan;
            code1($47); restype:='i';
          end;
    'cv': begin
            argument('i');
            code1($46); arsize3:=1;
            restype:='r'
          end;
    'pa': begin
            parse(' ('); scan; express;
            testtype('c');
            if token=' ,' then begin
              scan; express; testtype('c');
              code1(53)
            end;
            testto(' )'); scan; restype:='p'
          end
    else error(1)
  end {case of token}
end {factor};

{##############}
{ body of term }
{##############}

begin
  factor(arsize2);
  repeat
    case token of
      ' *': opcode:=5;
      'di': opcode:=6;
      'an': opcode:=15;
      'sh': opcode:=18;
      'sr': opcode:=19;
      ' /': opcode:=$45
      else opcode:=0
    end {case};
    if opcode>0 then begin
      if (restype='r') and
            (arsize2=1) then begin
        scan; factor(arsize2);
        if (restype<>'r') or (arsize2<>1) then
          merror(14,'06');
        case opcode of
          5: code1($44);
          $45: code1($45)
          else error(17)
        end{case}
      end else begin
        if opcode=$45 then error(9);
        if arsize2<>0 then error(15);
        if (restype='b') and (opcode=15)
          then begin
          scan; factor(arsize2);
          if arsize2<>0 then error(15);
          testtype('b');
          code1(opcode)
        end else begin
          testtype('i'); scan;
          factor(arsize2);
          if arsize2<>0 then error(15);
          testtype('i'); code1(opcode);
        end
      end
    end;
  until opcode=0;
end;

{################}
{ body of simexp }
{################}

begin
  sign:=' ';
  if token=' +' then begin
    sign:='+'; scan
  end else if token=' -' then begin
    sign:='-'; scan
  end;
  term(arsize1);
  if sign<>' ' then begin
    if (restype='r')and (arsize1=1) then begin
      if sign='-' then code1($4e)
    end else begin
      testtype('i');
      if arsize1<>0 then error(15);
      if sign='-' then code1(2);
    end
  end;
  repeat
    case token of
      ' &': opcode:=1;
      ' +': opcode:=3;
      ' -': opcode:=4;
      'or': opcode:=14;
      'xo': opcode:=16
      else opcode:=0
    end {case};
    if opcode>1 then begin {if 1}
      if (restype='r') and (arsize1=1)
        then begin {real}
        scan; term(arsize1);
        if (restype<>'r') or (arsize1<>1) then
          error(17);
        case opcode of
          3:  code1($42);
          4:  code1($43)
          else error(17)
        end {case}
      end {real}
      else begin {not real}
        if (arsize1<>0) then error(15);
        if (restype='b') and (opcode>=14)
          then begin {boolean}
          scan; term(arsize1);
          if arsize1<>0 then error(15);
          testtype('b'); code1(opcode)
        end {boolean}
        else begin {not boolean}
          testtype('i'); scan;
          term(arsize1);
          if arsize1<>0 then error(15);
          testtype('i'); code1(opcode);
        end {not boolean}
      end {not real}
    end {if 1}
    else if opcode=1 then begin {else 1}
      sign:=restype;
      scan; term(opcode);
      arsize1:=arsize1+opcode+1;
      testtype(sign)
    end {else 1}
  until opcode=0
end {simexp};

{#################}
{ body of mainexp }
{#################}

begin { *** body of mainexp *** }
  roff:=0;
  simexp(arsize);
  if (restype='r') and (arsize=1) then
    roff:=$40;
  case token of
    ' =': opcode:=8;
    ' <': opcode:=10;
    ' >': opcode:=12;
    '<>': opcode:=9;
    '<=': opcode:=13;
    '>=': opcode:=11
    else opcode:=0
  end {case};
  if opcode>0 then begin
    if (arsize<>0) and (roff=0) then
      error(15);
    scan; savtype:=restype; simexp(arsize);
    if ((roff=0) and (arsize<>0))
      or((roff<>0) and (arsize>1)) then
      error(15);
    testtype(savtype); code1(opcode+roff);
    arsize:=0; restype:='b'
  end
end {mainexp};

{#########################}
{ assign ( of statement ) }
{#########################}

proc assign;
var sid: integer;
    styp, sknd: char;

  proc assign1;
  begin
    testto(':='); scan; express;
    if (styp='q') and (restype='s') then begin
      code1($58); restype:='q';
    end;
    gpval(sid,true,sknd);
  end {assign1};

begin {assign}
  idpnt:=findid;
  if idpnt=0 then error(5);
  if stype[idpnt]='pr' then begin
    prcall(idpnt); scan
  end else begin
    getvar;
    sid:=idpnt;
    styp:=vartype;
    sknd:=vartyp2;
    if relad<2 then begin
      assign1;
      testtype(styp)
    end else begin
      if sknd='i' then error(16); {8-bit mem}
      testto(':='); scan;
      if relad=3 then begin
        arrayexp(1,styp); relad:=1;
        code1($53);
        if sknd='n' then begin
          code1($3f);
          code3($22,1); code1($12);
          code3($22,svda[sid]+2);
          code1($3); code1($3e)
        end else
          code4($2a,level-slevel[sid],
            2*svda[sid]+2);
        code2($3c,1)
      end else begin
        arrayexp(sspsz[sid],styp);
        if sknd='n' then begin
          code3($22,svda[sid]+2*sspsz[sid]);
          code1($3e);
        end else
          code4($29,level-slevel[sid],
            2*(svda[sid]+sspsz[sid]));
        code2($3c,sspsz[sid]);
      end
    end
  end
end {assign};

{########################}
{ case1 ( of statement ) }
{########################}

proc case1;
var i1,i2,casave: integer;
    savetype: char;

  proc case2;
  {#########}

    proc case3;
    {#########}
    begin
      scan; code1(22); code3(34,getcon);
      testtype(savetype);
      code1(8); scan
    end;

  begin {case2}
    i1:=0; case3;
    while token=' ,' do begin
      push(pc); code3(38,0); i1:=succ(i1);
      case3
    end;
    testto(' :'); savpc:=pc; code3(37,0);
    for k2:=1 to i1 do fixup(pop);
    push(savpc);
    scan; statmnt
  end {case2};

begin {case1}
  scan; express; testto('of');
  savetype:=restype; i2:=1; case2;
  while token=' ;' do begin
    casave:=pc; code3(36,0); fixup(pop);
    push(casave); i2:=succ(i2); case2
  end;
  if token='el' then begin
    casave:=pc; code3(36,0); fixup(pop);
    push(casave); scan; statmnt
  end;
  testto('en'); for k2:=1 to i2 do fixup(pop);
  code3(35,-2); scan
end {case1};

{#########################}
{ openrw ( of statement ) }
{#########################}

proc openrw(x: integer);
begin
  parse(' ('); parse('id');
  idpnt:=findid;
  if idpnt=0 then error(5);
  getvar; code1(x);
  testferror;
  if relad=2 then error(15);
  if vartype<>'f' then merror(14,'07');
  gpval(idpnt,true,vartyp2);
  testto(' )'); scan
end {openrw};

{########################}
{ gpsec ( of statement ) }
{########################}

proc gpsec(code);   { get/put sector }

  proc gpsec1;
  {##########}
  begin
    scan; express; testtype('i');
    testto(' ,');
  end;

begin {gpsec}
  parse(' ('); gpsec1; gpsec1; gpsec1;
  code1(code);
  parse('id'); idpnt:=findid;
  if idpnt=0 then error(5);
  getvar; code3(34,$db); { get file error code }
  if relad=2 then error(15);
  code1(23); if vartype<>'i' then merror(14,'08');
  gpval(idpnt,true,vartyp2);
  testto(' )');
end {gpsec};

{#############}
proc writebool;
{#############}
var savpc, k2: integer;
begin
  { boolean value is already on stack }

  savpc := pc;
  code3(37,0);   { jump if false }

  { TRUE }
  code1(50);
  code1(ord('T') and 127);
  code1(ord('R') and 127);
  code1(ord('U') and 127);
  code1(ord('E') or 128);

  k2 := pc;
  code3(36,0);   { unconditional jump }

  fixup(savpc);

  { FALSE }
  code1(50);
  code1(ord('F') and 127);
  code1(ord('A') and 127);
  code1(ord('L') and 127);
  code1(ord('S') and 127);
  code1(ord('E') or 128);

  fixup(k2);
end;

{###################}
{ body of statement }
{###################}

begin {body of statement }
  if token=' ;' then scan;
  case token of
    'id': assign;

    'if': begin {if}
            scan; express; testtype('b');
            testto('th'); scan;  savpc:=pc;
            code3(37,0); statmnt;
            if token='el' then begin {else}
              k2:=pc; code3(36,0);
              fixup(savpc); scan; statmnt;
              fixup(k2)
            end else fixup(savpc)
          end; {if}

    'be':  begin {begin}
            repeat
              scan; statmnt
            until token<>(' ;');
            testto('en'); scan
          end; {begin}

    'rp': begin {repeat}
            savpc:=pc;
            repeat
              scan; statmnt
            until token='un';
            scan; express; testtype('b');
            code3(37,savpc)
          end {repeat};

    're': begin {read}
            parse(' ('); scan;
            if token=' @' then begin
              scan; express; testtype('f');
              device:=true;
              code1(44); testto(' ,')
            end
            else begin
              device:=false; code1(26)
            end;
            repeat
              begin {main loop of read}
                if token=' ,' then scan;
                testto('id'); idpnt:=findid;
                if idpnt=0 then error(5);
                getvar;
                if relad=2 then error(15);
                case vartype of
                  'i':  code1(28);
                  'c':  code1(27);
                  'p':  begin
                        code1(27); code1(27);
                        code1(53)
                        end
                  else error(114)
                end {case};
                gpval(idpnt,true,vartyp2)
              end {mainloop of read}
            until token<>' ,';
            testto(' )'); scan;
            if device then code1(45);
          end {read};

    'wr','wl':
          begin {write,writeln}
            if token='wl' then wln:=true
            else wln:=false;
            scan;
            if token=' (' then begin
              scan;
              if token=' @' then begin
                scan; express;
                if restype='q' then restype:='f';
                testtype('f');
                device:=true; code1(44);
                if not ((token = ' ,') or
                  (token = ' )')) then merror(2,' ,');
              end else device:=false;
              repeat
                if token=' ,' then scan;
                if (token=' )') and device
                       and wln then
                   {empty writeln except device}
                   k2:=k2 {do nothing}
                else if token='st' then begin
                  {string}
                  code1(50);
                  for k2:=1 to value[0]-1 do
                    code1(ord(ident[k2])
                        and 127);
                  code1(ord(ident[value[0]])
                      or 128);
                  scan
                end else begin
                  {expression}
                  express;
                  case restype of
                    'i':  code1(30);
                    'c':  code1(29);
                    'q':  code1($57);
                    's':  begin
                            code1($58);
                            code1($57);
                          end;
                    'b':  writebool;
                    'p':  begin
                            code1(22);
                            code1(51);
                            code1(29);
                            code1(52);
                            code1(29);
                          end
                    else merror(14,'09')
                  end {case}
                end {expression}
              until token<>' ,';
              if wln then begin {writeln(..)}
                code2(32,13); code1(29);
                code2(32,10); code1(29);
              end;
              if device then code1(45);
              testto(' )'); scan
            end {if}
            else if wln then begin {writeln}
              code2(32,13); code1(29);
              code2(32,10); code1(29);
            end
          end {write, writeln};

    'cs': case1; {case statement}

    'wh': begin {while}
            scan; savpc:=pc; express;
            testtype('b');
            k2:=pc; code3(37,0);
            testto('do'); scan; statmnt;
            code3(36,savpc); fixup(k2)
          end {while};

    'fo': begin {for}
            parse('id'); assign;
            if stype[idpnt]='pr' then error(1);
            savtp1:=low(stype[idpnt]);
            case token of
              'to': k2:=1;
              'dw': k2:=0
              else merror(2,'to')
            end {case of token};
            scan; express; testtype(savtp1);
            bottom1:=pc; code1(22);
            gpval(idpnt,false,vartyp2);
            code1(13-k2-k2);
            savpc:=pc; code3(37,0);
            testto('do'); scan; statmnt;
            gpval(idpnt,false,vartyp2);
            code1(21-k2);
            gpval(idpnt,true,vartyp2);
            code3(36,bottom1); fixup(savpc);
            code3(35,-2);
          end {for};

    'me': begin {mem}
            parse(' ['); scan; express;
            testtype('i');
            testto(' ]'); parse(':=');
            scan; express; code1(24);
            testtype('i');
          end {mem};

    'ca': begin {call}
            parse(' ('); scan; express;
            testtype('i');
            testto(' )'); code1(25); scan
          end {call};

    'op': openrw(47);

    'ow': openrw(48);

    'ob': openrw(80);

    'gb': begin
            parse(' ('); scan; express;
            testtype('f'); testto(' ,');
            scan; express; testtype('i');
            testto(' ,'); scan; testto('id');
            idpnt:=findid;
            if idpnt=0 then error(5);
            getvar;
            if relad<>0 then error(15);
            code1($51); testferror;
            gpval(idpnt,true,vartyp2);
            testto(' )'); scan
          end;

    'pb': begin
            parse(' ('); scan; express;
            testtype('f'); testto(' ,');
            scan; express; testtype('i');
            testto(' ,'); scan; express;
            code1($52);testferror;
            testto(' )');
            scan
          end;

    'ru': begin
            code1($41); scan;
          end;

    'fi': begin
            code1(46); scan
          end;

    'ge': gpsec(55);

    'pu': gpsec(56);

    'ex': begin {exit}
            if level>0 then code1(1) else code1(0);
            scan;
          end;

    'cl': begin {close}
            parse(' (');
            repeat
              scan; express; code1(49);
              testtype('f');
              testferror
            until token<>' ,';
            testto(' )'); scan;
          end {close}

    else if (token<>'en') and (token<>' ;')
      and (token<>'un') then begin
      error(10); scan
    end
  end {case of statements}
end;

{#######################}
{ findforw ( of block ) }
{#######################}

func findforw;

var i,j,sav1: integer;
    done: boolean;

  func found(start: integer):boolean;
  var ii,i9: integer;
  begin {compare}
    ii:= 0;
    repeat
      ii:=succ(ii);
    until (ii >= 8) or
      (ident[ii] <> idtab[start+ii]);
    found:=(ii >= 8);
  end {compare};


begin {findforw}
  i:=succ(forwpn);
  repeat
    i:=prec(i);
    done := (i = 0);
    if not done then
      done := found(8*fortab[i]);
  until done;
  findforw:=i;
  if i>0 then
    if i=forwpn then forwpn:=forwpn-1
    else begin
      sav1:=fortab[i];
      for j:=i to forwpn-1 do
        fortab[j]:=fortab[succ(j)];
      fortab[forwpn]:=sav1;
      findforw:=forwpn;
      forwpn:=forwpn-1
    end
end {findforw};

{###############}
{ body of block }
{###############}

begin
  dpnt:=3; svda[bottom]:=pc;
  code3(36,0);
  stackpn1:=stackpnt; forwpn:=0;

  if token='co' then begin    { * const * }
    scan;
    repeat
      deccon; testto(' ;'); scan
    until token <> 'id';
  end {const};

  if token='me' then memory;  { * mem * }

  if token='va' then variable;{ * var * }

    while (token='pr')or (token='fu') do begin
    parlevel:=0;
    isfunc:=token='fu';
    case token of
    'pr': begin               { * proc * }
            parse('id'); npara:=0;
            if forwpn=0 then find:=0
            else find:=findforw;
            if find=0 then begin
              putsym('p','r');
              cproc:=spnt;
            end else begin
              cproc:=fortab[find];
              fixup(svda[cproc]);
            end;
            level:=succ(level);
          end;
    'fu': begin               { * func * }
            parse('id'); npara:=1;
            if forwpn=0 then find:=0
            else find:=findforw;
            if find=0 then begin
              putsym('f','i');
              cproc:=spnt; level:=succ(level);
              putsym('f','i');
              svda[spnt]:=parlevel;
              parlevel:=succ(parlevel);
            end else begin
              cproc:=fortab[find];
              level:=succ(level);
              parlevel:=1;
              fixup(svda[cproc]);
            end;
          end
    end; {case of token}
    scan; spnt1:=spnt;
    dpnt1:=dpnt;
    if token=' (' then parameter;
    if isfunc then function;
    testto(' ;');
    for i:=1 to npara do
    svda[succ(spnt-i)]:=svda[succ(spnt-i)]
          -parlevel;
    scan;
    if token='fw' then begin
      if forwpn=8 then merror(13,'ov');
      forwpn:=succ(forwpn);
      fortab[forwpn]:=cproc;
      svda[cproc]:=pc;
      code3(36,0);
      scan
    end else block(cproc);
    level:=prec(level);
    dpnt:=dpnt1; spnt:=spnt1;
    case high(stype[spnt]) of
      'r':  stype[spnt]:=packed('t',low(stype[spnt]));
      's':  stype[spnt]:=packed('u',low(stype[spnt]))
    end {case};
    testto(' ;'); scan
  end {procedure of function};

  testto('be');     { * begin * }
  if forwpn<>0 then merror(13,'ur');
  fixup(svda[bottom]);
  svda[bottom]:=pc;
  scan;
  code3(35,2*dpnt);
  repeat
    statmnt
  until token='en';
  scan;
  if level>0 then code1(1) else code1(0);
  stackpnt:=stackpn1;
end {block};

{####################}
{ savtable ( global) }
{####################}

proc savtable; { save lib table in @ofno }

var i,j,num: integer;
    vtype1: char;

begin
  writeln(@ofno,spnt,',',pc+2);
  for i:=1 to spnt do begin {for every entry }
    for j:=1 to 8 do begin
      write(@ofno,idtab[8*i+j])
    end;
    writeln(@ofno,',',stype[i],',',slevel[i],',',
      svda[i],',',sspsz[i]);
    vtype1:=high(stype[i]);
    if ((vtype1='p') or (vtype1='f') or
      (vtype1='g')) and (sspsz[i]<>0) then begin
      num:=stack[sspsz[i]];
      write(@ofno,num);
      for j:=1 to num do
        write(@ofno,',',stack[sspsz[i]+j]);
      write(@ofno,CR,LF);
    end {then};
  end {for}
end {savtable};

{##############}
{ main program }
{##############}

begin {main}
  RUNERR := 0;
  nlflg:=false;
  init;scan;
  case token of
    'pg': begin
            libflg:=false;
            _asetfile(pname,scyclus,sdrive,'Q');
          end;
    'li': begin
            libflg:=true;
            _asetfile(pname,scyclus,sdrive,'T');
          end
    else
      merror(2,'pg')
  end {case}
  parse('id');
  i:=0;
  repeat
    i:=succ(i);
  until (i>7) or (pname[i] = ':') or
      (pname[i]<>_uppercase(ident[i+1]));
  if i<8 then
    merror(2,packed(pname[0],pname[1]));
    { name differs from filename }
  parse(' ;');
  if ofno<>nooutput then openw(ofno);
  scan;
  if (token='us') and (libflg=false) then begin
    repeat
      getlib; scan
    until token<>' ,';
    testto(' ;'); scan
  end;
  block(0); testto(' .');
  if ofno<>nooutput then begin
    write(@ofno,'E');
    savebyte(pc and 255);
    savebyte(pc shr 8);
    close(ofno);
    if libflg then begin
      _asetfile(pname,scyclus,sdrive,'L');
      openw(ofno);
      savtable;
      close(ofno)
    end
  end else
    RUNERR:=$87; {no loader file}
  writeln;
  writeln;
  writeln('End compile');
  writeln;
  writeln('Code lenght:          ',pc);
  writeln('Compiler stack size:  ',stackmax);
  writeln('Ident stack size:     ',spntmax);
  write('Pascal errors:        ');
  if numerr>0 then write(INVVID);
  writeln(numerr,NORVID);
  if prt then begin
    write(PRTOFF);
    _setemucom(9);
  end;
  close(fno);
  { check whether second pass is not required }
  if (RUNERR=0) and libflg then RUNERR:=-1;
end {main}.
