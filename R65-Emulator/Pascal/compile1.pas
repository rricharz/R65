{   ********************************
    *                              *
    *   R65 Micro Pascal Compiler  *
    *            Pass 1            *
    *                              *
    ********************************

First version 1978 by rricharz
Version 3.7 (20K)  01/08/82 rricharz

Recovered 2018 by rricharz (r77@bluewin.ch)
Improved 2018-2024 by rricharz
Version 4 with cpnt strings and exit statement
Version 4.3 with include compiler directive
Version 4.6 splits the source file into 4 files

Original derived from the publication by
Kin-Man Chung and Herbert Yen in
Byte, Volume 3, Number 9 and Number 10, 1978

Adapted for the R65 computer system and
substantially enhanced by rricharz 1978-2023

This is a Pascal derivative optimized for 8-bit
microprocessors (integer type is 16 bit) with
additional features (mem) to interact directly
with the microprocessor hardware. Only one
dimensional arrays and no records or user
defined types. Floating point numbers (real)
and file io to floppy disks are supported.

Precompiled libraries are merged in the loader.
The table of reserved words and the library
tables are loaded from the same drive as
the compiler.

The output of the program is a loader file for
the Pascal loader (compile2).

usage:
 compile1 name[.cy[,drv]] [xxx]
  where x:       l,p: no hard copy print
                 i,r: index bound checking
                 n: no loader file
  [] means not required
                                        }

program compile1;

uses syslib, arglib;

{$I IGLOBAL:P}
{$I ISCANNER:P}

{ ################################ }
{ block (global): handle one block }
{ ################################ }

proc block(bottom: integer);

var l,f9,i,n,stackpn1,forwpn,find,cproc,
    spnt1,dpnt1,parlevel: integer;
    fortab: array[8] of integer;

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

var i,addr: integer;
begin
  if spnt>symbsize then error(7)
  else spnt:=succ(spnt);
  if spnt>spntmax then spntmax:=spnt;
  stype[spnt]:=packed(ltyp1,ltyp2);
  sspsz[spnt]:=0;
  addr:=8*spnt;
  for i:=1 to 8 do idtab[addr+i]:=ident[i];
  if ltyp1='v' then begin
    svda[spnt]:=dpnt; dpnt:=succ(dpnt);
  end;
  slevel[spnt]:=level
end {putsym};

{#######################}
{ checkindex (of block) }
{#######################}

proc checkindex(lowlim,highlim: integer);
begin
  if icheck then begin
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
      if stack[bs+1]<>stack[n+1]
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

{$I ISTATEMENT:P}

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
      for j:=1 to forwpn-1 do
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
    case token of
    'pr': begin               { * proc * }
            parse('id'); npara:=0;
            putsym('p','r'); cproc:=spnt;
            level:=succ(level);
          end;
    'fu': begin               { * func * }
            parse('id'); npara:=1;
            putsym('f','i');
            cproc:=spnt; level:=succ(level);
            putsym('f','i');
            svda[spnt]:=parlevel;
            parlevel:=succ(parlevel);
          end
    end; {case of token}
    if forwpn=0 then find:=0
    else find:=findforw;
    if find<>0 then begin
      spnt:=spnt-npara-1;
      cproc:=fortab[find];
      fixup(svda[cproc]);
    end;
    scan; spnt1:=spnt;
    dpnt1:=dpnt;
    if token=' (' then parameter;
    if stype[cproc]='fi' then function;
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
