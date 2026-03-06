{ include file iglobal.pas for compile1 }

const version='4.6';
    table     =$97ff; {user ident table -1}
    idtab     =$95ff; {resword table -1}
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
    prt,libflg,icheck,ateof,lineflg,nlflg: boolean;
    fno,ofno,savefno: file;
    incname: array[15] of char;
    filstk: array[maxfi] of file;
    ident: array[idlength] of char;
    { Only the first 8 characters are
      used to find and differentiate ids! }

    stype: array[symbsize] of packed char;
           {type of symbol}
       { High letter:
           a:array, c:constant, d;const parameter
           e:constant array parameter, f:function
           g:array function, h;8-bit memory var
           i:8-bit array memory variable
           m:16-bit memory variable
           n:16-bit array memory variable
           p:procedure
           q:indexed cpnt
           r,t:function result
           s,u:array function result
           v:variable, w:variable parameter
           x:variable array parameter
         Low letter:
           i:integer, c:char, p:packed char
           q:cpnt (pointer to chars)
           r:real(array multiple of two)
           s:const cpnt
           f:file, b:boolean, u:undefined  }

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
  var i: integer;
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
var i: integer;
    answer: char;
begin
  crlf; numerr:=succ(numerr);
  for i:=2 to tpos do write(' ');
  write('^'); crlf;
  write('*** (',numerr,',',pc,')   ');
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
    22: write('Unexpected EOF')
  end {case};
  writeln;
  write('Continue (Y)?');
  read(@KEY,answer);
  if answer<>'Y' then begin
    crlf; write(PRTOFF); _setemucom(9); close(fno);
    if (ofno<>nooutput) and (ofno<>yesOUTPUT)
      then close(ofno);
    writeln('Aborting compile1 on request');
    _abort
  end
  else crlf;
  if (ofno<>nooutput) and (ofno<>yesOUTPUT)
    then close(ofno);
  ofno:=nooutput;
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

{#################}
{ getchr (global) }
{#################}

proc getchr;
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
      ch:=' ';
    end {if}
    else if ch=EOF then begin
      ateof:=true;
      { we need to suppy one more char }
      { for end. at end of file to work properly }
      ch:=' ';
    end {else if}
    else write(ch);
  end;
end {getchr};

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
  icheck:=false;
  prt:=true; ofno:=yesOUTPUT; lineflg:=false;
  if not default then begin
    if request[0]<>'/' then _argerror(103);
    for i:=1 to 8 do
      case request[i] of
        'P': prt:=false;
        'L': lineflg:=true;
        'I','R': icheck:=true;
        'N': ofno:=nooutput;
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
