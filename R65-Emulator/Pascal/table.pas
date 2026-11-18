{ TABLE: simple speadsheet program

  Usage:
  TABLE filespec
                                    }

program table;
uses syslib, arglib, strlib, striolib, txtgrlib;

const MAXROWS = 100;
      MAXCOLS = 8;
      SCREENWIDTH = 56;

      T_TEXT = 1;
      T_INTEGER = 2;
      T_REAL = 3;
      T_DATE = 4;
      T_SUM = 5;

var f: file;
    filename: cpnt;
    datarow: array[MAXROWS] of cpnt;
    ncols,i: integer;
    colsize: array[MAXCOLS] of integer;
    coltype: array[MAXCOLS] of integer;
    colx: array[MAXCOLS] of integer;
    titles: cpnt;
    tablewidth, nrows: integer;
    acc1,acc2: cpnt;
    sumcolumn: integer;

proc showerror(s: cpnt);
{**********************}
begin
  write(INVVID,s);
  if nrows>=0 then write(' at row ',nrows);
  writeln(NORVID);
  _abort;
end;

proc setnumlin(l,c:integer);
{**************************}
mem numlin=$1789: integer&;
    numchr=$178a: integer&;
begin
  numlin:=l; numchr:=c;
end;

proc writetableline(s:cpnt);
{************************}
var i:integer;
begin
  i:=0;
  while s[i]<>ENDMARK do begin
    if s[i]=',' then
      _writetxtgr(TGR_UP+TGR_DOWN)
    else
      write(s[i]);
    i:=i+1;
  end;
end;

func initfile: file;
{******************}
var cyclus, drive: integer;
    default: boolean;
begin
  cyclus  :=  0;
  drive :=  1;
  default :=  true;
  _sgetstring(filename, _carg, default);
  _ssetsubtype(filename,'B', true);
  _agetval(cyclus,    default);
  _agetval(drive,     default);
  _strfio(filename, cyclus, drive);
  openr(f);
  initfile  :=  f;
end;

func validatedate(s:cpnt;pos:integer):boolean;
{*******************************************}
var i,j,n,limit:integer;
    sep:char;
begin
  validatedate:=false;
  i:=pos;

  { Empty date is allowed }
  if (s[i]=',') or (s[i]=ENDMARK) then begin
    validatedate:=true;
    exit;
  end;

  { First component: day or month }
  j:=i;
  n:=0;
  while (s[i]>='0') and (s[i]<='9') do begin
    n:=n*10+ord(s[i])-ord('0');
    i:=i+1;
  end;

  sep:=s[i];
  if (sep<>'.') and (sep<>'/') then exit;
  if (i-j<1) or (i-j>2) then exit;

  if sep='.' then limit:=31 else limit:=12;
  if (n<1) or (n>limit) then exit;

  if i-j=1 then begin
    _strinsc('0',j,s);
    i:=i+1;
  end;

  i:=i+1;
  j:=i;
  n:=0;

  { Second component: month or day }
  while (s[i]>='0') and (s[i]<='9') do begin
    n:=n*10+ord(s[i])-ord('0');
    i:=i+1;
  end;

  if s[i]<>sep then exit;
  if (i-j<1) or (i-j>2) then exit;

  if sep='.' then limit:=12 else limit:=31;
  if (n<1) or (n>limit) then exit;

  if i-j=1 then begin
    _strinsc('0',j,s);
    i:=i+1;
  end;

  i:=i+1;

  { Year: exactly four digits }
  for j:=1 to 4 do begin
    if (s[i]<'0') or (s[i]>'9') then exit;
    i:=i+1;
  end;

  if (s[i]<>',') and (s[i]<>ENDMARK) then exit;

  validatedate:=true;
end;

func validateinteger(s:cpnt):boolean;
{***********************************}
var i:integer;
begin
  validateinteger:=false;
  i:=0;

  if s[i]='-' then i:=i+1;

  if (s[i]=',') or (s[i]=ENDMARK) then begin
    if i<>0 then exit;
    validateinteger:=true;
    exit;
  end;

  while (s[i]<>',') and (s[i]<>ENDMARK) do begin
    if (s[i]<'0') or (s[i]>'9') then exit;
    i:=i+1;
  end;

  validateinteger:=true;
end;

proc rightjustify(s:cpnt;start,len,width:integer);
{**********************************************}
var i,n:integer;
begin
  n:=width-len;

  for i:=len-1 downto 0 do
    s[start+i+n]:=s[start+i];

  for i:=0 to n-1 do
    s[start+i]:=' ';
end;

func validatereal(s:cpnt;pos:integer):boolean;
{******************************************}
var i,j,k,n,decimals:integer;
    negative:boolean;
begin
  validatereal:=false;
  i:=pos;
  negative:=false;

  { Empty field }
  if (s[i]=',') or (s[i]=ENDMARK) then begin
    validatereal:=true;
    exit;
  end;

  { Optional minus }
  if s[i]='-' then begin
    negative:=true;
    i:=i+1;
  end;

  { Count integer digits }
  j:=i;
  while (s[i]>='0') and (s[i]<='9') do
    i:=i+1;

  { Insert zero before decimal point if needed }
  if i=j then begin
    if s[i]<>'.' then exit;
    _strinsc('0',i,s);
    i:=i+1;
  end;

  { Remove unnecessary leading zeros }
  j:=pos;
  if negative then j:=j+1;

  while (s[j]='0') and
        (s[j+1]>='0') and (s[j+1]<='9') do
    _strdelc(j,s);

  { Find decimal point or end of field }
  i:=j;
  while (s[i]>='0') and (s[i]<='9') do
    i:=i+1;

  if (s[i]=',') or (s[i]=ENDMARK) then
    _strinsc('.',i,s)
  else if s[i]<>'.' then exit;

  i:=i+1;
  decimals:=0;

  while (s[i]>='0') and (s[i]<='9') do begin
    decimals:=decimals+1;
    i:=i+1;
  end;

  if decimals>2 then exit;
  if (s[i]<>',') and (s[i]<>ENDMARK) then exit;

  { Complete two decimal places }
  while decimals<2 do begin
    _strinsc('0',i,s);
    i:=i+1;
    decimals:=decimals+1;
  end;

  { Remove minus sign from zero }
  if negative then begin
    j:=pos+1;
    while (s[j]='0') or (s[j]='.') do
      j:=j+1;

    if (s[j]=',') or (s[j]=ENDMARK) then
      _strdelc(pos,s);
  end;

  validatereal:=true;
end;

func add(a,b,r:cpnt;size:integer):boolean;
{****************************************}
var
  a1,b1,t:cpnt;
  i,j,k,n,carry,cmp:integer;
  sa,sb,negative,subtract:boolean;
begin
  add:=false;
  if (size<4) or (size>16) then exit;

  { Determine signs }
  a1:=a;
  b1:=b;
  sa:=false;
  sb:=false;
  if a1[0]='-' then begin
    sa:=true;
    a1:=a1+1;
  end;
  if b1[0]='-' then begin
    sb:=true;
    b1:=b1+1;
  end;

  { Find ends of input fields }
  i:=0;
  while (a1[i]<>ENDMARK) and (a1[i]<>',') do i:=i+1;
  j:=0;
  while (b1[j]<>ENDMARK) and (b1[j]<>',') do j:=j+1;

  { Check decimal points }
  if (i<4) or (j<4) then exit;
  if (a1[i-3]<>'.') or (b1[j-3]<>'.') then exit;

  subtract:=sa<>sb;
  negative:=sa;

  { For subtraction, larger magnitude first }
  if subtract then begin
    if i>j then
      cmp:=1
    else if i<j then
      cmp:=-1
    else
      cmp:=_strncmp(a1,b1,i);

    if cmp<0 then begin
      t:=a1;
      a1:=b1;
      b1:=t;
      k:=i;
      i:=j;
      j:=k;
      negative:=sb;
    end;
  end;

  { Prepare result }
  for k:=0 to size-1 do r[k]:='0';
  r[size]:=ENDMARK;
  r[size-3]:='.';

  { Add or subtract digits from right to left }
  i:=i-1;
  j:=j-1;
  k:=size-1;
  carry:=0;

  while k>=0 do begin
    if k=size-3 then
      k:=k-1
    else begin
      if (i>=0) and (a1[i]='.') then i:=i-1;
      if (j>=0) and (b1[j]='.') then j:=j-1;

      n:=carry;

      if i>=0 then begin
        if (a1[i]<'0') or (a1[i]>'9') then exit;
        n:=n+ord(a1[i])-ord('0');
        i:=i-1;
      end;

      if j>=0 then begin
        if (b1[j]<'0') or (b1[j]>'9') then exit;
        if subtract then
          n:=n-ord(b1[j])+ord('0')
        else
          n:=n+ord(b1[j])-ord('0');
        j:=j-1;
      end;

      if n<0 then begin
        n:=n+10;
        carry:=-1;
      end
      else begin
        carry:=n div 10;
        n:=_mod(n,10);
      end;

      r[k]:=chr(ord('0')+n);
      k:=k-1;
    end;
  end;

  { Overflow or unprocessed input }
  if (i>=0) or (j>=0) or (carry<>0) then exit;

  { Remove leading zeros, keeping one integer digit }
  k:=0;
  while (r[k]='0') and (k<size-4) do k:=k+1;

  { Check if result is zero }
  if r[k]='0' then begin
    if (r[k+2]='0') and (r[k+3]='0') then
      negative:=false;
  end;

  { Check width including possible minus sign }
  if negative and (size-k+1>size) then exit;

  { Move result to beginning }
  i:=0;
  if negative then begin
    r[0]:='-';
    i:=1;
  end;

  while r[k]<>ENDMARK do begin
    r[i]:=r[k];
    i:=i+1;
    k:=k+1;
  end;
  r[i]:=ENDMARK;

  add:=true;
end;

proc calculatesum(s:cpnt);
{***********************}
var a,b,t,p:cpnt;
    i,k,n,start:integer;
begin
  if sumcolumn<0 then exit;

  a:=acc1;
  b:=acc2;
  _strcpy('0.00',a);

  for i:=0 to ncols-1 do begin
    if coltype[i]=T_REAL then begin
      start:=colx[i]-1;
      p:=s+start;

      { Skip leading blanks }
      while p[0]=' ' do p:=p+1;

      { Ignore empty fields }
      if (p[0]<>',') and (p[0]<>ENDMARK) then begin
        if not add(a,p,b,16) then
          showerror('TABLE: SUM overflow');

        t:=a;
        a:=b;
        b:=t;
      end;
    end;
  end;

  { Locate SUM field }
  start:=colx[sumcolumn]-1;


  { Check result fits }
  n:=_strlen(a);
  if n>colsize[sumcolumn] then
    showerror('TABLE: SUM field too small');

  { Write right-justified result }
  for k:=0 to colsize[sumcolumn]-1 do
    s[start+k]:=' ';

  for k:=0 to n-1 do
    s[start+colsize[sumcolumn]-n+k]:=a[k];
end;

proc validaterow(s:cpnt);
{***********************}
var i,j,k,start,len:integer;
begin
  i:=0;

  for j:=0 to ncols-1 do begin
    k:=0;
    start:=i;

    { Validate field }
    if coltype[j]=T_DATE then
      if not validatedate(s,start) then
        showerror('TABLE: Invalid date');

    if coltype[j]=T_INTEGER then
      if not validateinteger(s+start) then
        showerror('TABLE: Invalid integer');

    if coltype[j]=T_REAL then
      if not validatereal(s,start) then
        showerror('TABLE: Invalid real');

    { Find end of current field }
    while (s[i]<>',') and (s[i]<>ENDMARK) do begin
      k:=k+1;
      i:=i+1;
    end;

    { Check field width }
    if k>colsize[j] then
      showerror('TABLE: Field width');

    { Check separator }
    if j<ncols-1 then begin
      if s[i]<>',' then
        showerror('TABLE: Missing field');
    end
    else
      if s[i]<>ENDMARK then
        showerror('TABLE: Too many fields');

    len:=k;

    { Expand field with trailing blanks }
    while k<colsize[j] do begin
      _strinsc(' ',i,s);
      i:=i+1;
      k:=k+1;
    end;

    { Right justify numeric fields }
    if (coltype[j]=T_INTEGER) or (coltype[j]=T_REAL)
    then
      rightjustify(s,start,len,colsize[j]);

    { Advance past separator }
    if j<ncols-1 then i:=i+1;
  end;
  calculatesum(s);
end;

proc readrows(f:file);
{********************}
var eof:boolean;
    len:integer;
begin
  nrows:=0;
  eof:=false;

  while not eof do begin
    len:=_strread(f,datarow[nrows],eof);
    writeln(datarow[nrows]);

    if len>0 then begin
      if nrows>=MAXROWS then
        showerror('TABLE: Too many rows');

      validaterow(datarow[nrows]);

      nrows:=nrows+1;
    end;
  end;
end;

proc parsetitle(s:cpnt;len:integer);
{*********************************}
var i,j,k,x:integer;
begin
  if _strncmp(s,'TITLE=',6)<>0 then
    showerror('TABLE: TITLE expected');


  i:=6;
  for j:=0 to ncols-1 do begin
    x:=colx[j]-1;
    k:=0;

    while (i<len) and (s[i]<>',') do begin
      if k>=colsize[j] then
        showerror('TABLE: Title too long');

      titles[x+k]:=s[i];
      k:=k+1;
      i:=i+1;
    end;

    while k<colsize[j] do begin
      titles[x+k]:=' ';
      k:=k+1;
    end;

    if j<ncols-1 then begin
      if (i>=len) or (s[i]<>',') then
        showerror('TABLE: Missing title');

      titles[x+colsize[j]]:=',';
      i:=i+1;
    end;
  end;

  if i<>len then
    showerror('TABLE: Too many titles');

  titles[tablewidth-2]:=ENDMARK;
end;

proc parsetype(s:cpnt;len:integer);
{********************************}
var i,j,k,t:integer;
begin
  sumcolumn := -1;
  if _strncmp(s,'TYPE=',5)<>0 then
    showerror('TABLE: TYPE expected');

  i:=5;
  for j:=0 to ncols-1 do begin
    k:=i;
    while (i<len) and (s[i]<>',') do i:=i+1;

    s[i]:=ENDMARK;

    t:=0;
    if _strcmp(s+k,'TEXT')=0 then t:=T_TEXT
    else if _strcmp(s+k,'INTEGER')=0 then t:=T_INTEGER
    else if _strcmp(s+k,'REAL')=0 then t:=T_REAL
    else if _strcmp(s+k,'DATE')=0 then t:=T_DATE
    else if _strcmp(s+k,'SUM')=0 then t:=T_SUM;

    if t=0 then
      showerror('TABLE: Invalid TYPE');

    coltype[j]:=t;
    if t=T_SUM then begin
      if sumcolumn>=0 then
        showerror('TABLE: Multiple SUM columns');
      sumcolumn:=j;
    end;
    i:=i+1;
  end;

  if i<>len+1 then
    showerror('TABLE: Wrong number of types');

  for i:=0 to ncols-1 do
    writeln(i,' TYPE=',coltype[i]);
end;

proc parse(f:file);
{*****************}
var s:cpnt;
    eof:boolean;
    len,i,j,n,x:integer;
begin
  s:=_new;
  len:=_strread(f,s,eof);

  if _strncmp(s,'SIZE=',5)<>0 then
    showerror('TABLE: SIZE expected');

  i:=5;
  ncols:=0;
  x:=1;

  while (i<len) and (ncols<MAXCOLS) do begin

    { Read decimal column width }
    n:=0;
    while (i<len) and (s[i]<>',') do begin
      if (s[i]<'0') or (s[i]>'9') then
        showerror('TABLE: Invalid SIZE');

      n:=n*10+ord(s[i])-ord('0');
      i:=i+1;
    end;

    if n=0 then
      showerror('TABLE: Invalid column width');

    colsize[ncols]:=n;
    colx[ncols]:=x;
    x:=x+n+1;
    ncols:=ncols+1;

    if (i<len) and (s[i]=',') then i:=i+1;
  end;

  tablewidth:=x;

  if x>SCREENWIDTH then
    showerror('TABLE: Table too wide');

  writeln('Columns: ',ncols);
  for j:=0 to ncols-1 do
    writeln(j,' SIZE=',colsize[j],' X=',colx[j]);

  len:=_strread(f,s,eof);
  parsetype(s,len);

  len:=_strread(f,s,eof);
  parsetitle(s,len);

  len:=_strread(f,s,eof);
  if _strcmp(s,'DATA=')<>0 then
    showerror('TABLE: DATA expected');

  nrows := 0;
  readrows(f);

  _release(s);
end;

proc showdata;
{*************}
var i:integer;
begin
  for i:=0 to 1 do
    if i<nrows then begin
      _setcursor(1,i+3);
      writetableline(datarow[i]);
    end;
end;

proc showtable;
{*************}
var i: integer;
    ch: char;
begin
  _htxtgr(0,tablewidth-1,0,CYAN);
  _htxtgr(0,tablewidth-1,2,CYAN);
  _htxtgr(0,tablewidth-1,15,CYAN);

  _vtxtgr(tablewidth-1,0,15,CYAN);

  for i:=0 to ncols-1 do
    _vtxtgr(colx[i]-1,0,15,CYAN);

  _setcursor(1,1);
  writetableline(titles);

  showdata;

  repeat
    read(@KEY,ch);
  until ch<>chr(0);
end;

begin
  for i:=0 to MAXROWS do { alloc. MAXROWS+1 strings }
    datarow[i]:=_new;
  filename:=_new;
  titles := _new;
  acc1 := _new;
  acc2 := _new;
  f:=initfile;
  nrows:=-1;
  parse(f);

  setnumlin($0f,$37);
  write(HOM,CSC);
  showtable;

  setnumlin($54,$2f);
  write(HOM,CSC);

  close(f);
end.


