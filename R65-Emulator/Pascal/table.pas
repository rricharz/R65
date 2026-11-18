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

proc parsetitle(s:cpnt;len:integer);
{*********************************}
var i,j,k,x:integer;
begin
  if _strncmp(s,'TITLE=',6)<>0 then begin
    writeln('TABLE: TITLE expected');
    exit;
  end;

  i:=6;
  for j:=0 to ncols-1 do begin
    x:=colx[j]-1;
    k:=0;

    while (i<len) and (s[i]<>',') do begin
      if k>=colsize[j] then begin
        writeln('TABLE: Title too long');
        exit;
      end;
      titles[x+k]:=s[i];
      k:=k+1;
      i:=i+1;
    end;

    while k<colsize[j] do begin
      titles[x+k]:=' ';
      k:=k+1;
    end;

    if j<ncols-1 then begin
      if (i>=len) or (s[i]<>',') then begin
        writeln('TABLE: Missing title');
        exit;
      end;
      titles[x+colsize[j]]:=',';
      i:=i+1;
    end;
  end;

  if i<>len then begin
    writeln('TABLE: Too many titles');
    exit;
  end;

  titles[54]:=ENDMARK;
end;

proc parsetype(s:cpnt;len:integer);
{********************************}
var i,j,k,t:integer;
begin
  if _strncmp(s,'TYPE=',5)<>0 then begin
    writeln('TABLE: TYPE expected');
    exit;
  end;

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

    if t=0 then begin
      writeln('TABLE: Invalid TYPE');
      exit;
    end;

    coltype[j]:=t;
    i:=i+1;
  end;

  if i<>len+1 then begin
    writeln('TABLE: Wrong number of types');
    exit;
  end;
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

  if _strncmp(s,'SIZE=',5)<>0 then begin
    writeln('TABLE: SIZE expected');
    exit;
  end;

  i:=5;
  ncols:=0;
  x:=1;

  while (i<len) and (ncols<MAXCOLS) do begin

    { Read decimal column width }
    n:=0;
    while (i<len) and (s[i]<>',') do begin
      if (s[i]<'0') or (s[i]>'9') then begin
        writeln('TABLE: Invalid SIZE');
        exit;
      end;
      n:=n*10+ord(s[i])-ord('0');
      i:=i+1;
    end;

    if n=0 then begin
      writeln('TABLE: Invalid column width');
      exit;
    end;

    colsize[ncols]:=n;
    colx[ncols]:=x;
    x:=x+n+1;
    ncols:=ncols+1;

    if (i<len) and (s[i]=',') then i:=i+1;
  end;

  if x>SCREENWIDTH then begin
    writeln('TABLE: Table too wide');
    exit;
  end;

  writeln('Columns: ',ncols);
  for j:=0 to ncols-1 do
    writeln(j,' SIZE=',colsize[j],' X=',colx[j]);

  len:=_strread(f,s,eof);
  parsetype(s,len);

  len:=_strread(f,s,eof);
  parsetitle(s,len);

  len:=_strread(f,s,eof);
  if _strcmp(s,'DATA=')<>0 then
    writeln('TABLE: DATA expected');

  _release(s);
end;

proc showtable;
{*************}
var i: integer;
    ch: char;
begin
  _htxtgr(0,55,0,CYAN);
  _htxtgr(0,55,2,CYAN);
  _htxtgr(0,55,15,CYAN);
  _vtxtgr(55,0,15,CYAN);
  for i:= 0 to ncols-1 do
    _vtxtgr(colx[i]-1,0,15,CYAN);
  _setcursor(1,1);
  writetableline(titles);
  repeat
    read(@KEY,ch);
  until ch<>chr(0);
end;

begin
  for i:=0 to MAXROWS-1 do datarow[i] := nil;
  filename:=_new;
  titles := _new;
  f:=initfile;
  parse(f);

  setnumlin($0f,$37);
  write(HOM,CSC);
  showtable;

  setnumlin($54,$2f);
  write(HOM,CSC);

  close(f);
  _release(titles);
  _release(filename);
end.


