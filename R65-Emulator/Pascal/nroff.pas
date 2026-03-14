program nroff;

{ mini nroff                           }
{ Witten March 2026 for the R65 system }
{ R. Richarz / ChatGPT                 }

uses syslib, arglib;

const
  maxperline = 48; { chars on internal display }
  max_per_page = 60; { lines per printed page }
  maxout  = 200;
  margin  = 10;  { left margin }
  indstep = 4;
  maxtabs = 16;
  debug1  = false;
  debug2  = false;

var
  src      : file;
  name     : array[15] of char;
  default  : boolean;
  cyclus, drive : integer;

  ch       : char;
  line     : array[maxperline] of char;
  llen     : integer;

  outbuf   : array[maxout] of char;
  outlen   : integer;

  fillmode : boolean;
  indent   : integer;
  linewidth: integer;
  titlemode: boolean;
  linecount: integer;

  tabstops : array[maxtabs] of integer;
  ntab     : integer;
  ipmode   : boolean;
  ipindent : integer;
  iphang   : integer;
  ipcur    : integer;
  preindent: boolean;

  linenumber: integer;
  pageno    : integer;
  headeron  : boolean;
  textseen  : boolean;

  thname : array[40] of char;
  thlen  : integer;

{ --- helpers --- }

proc printernewline;
begin
  write(@PRINTER, CR);
  write(@PRINTER, LF);
end;

proc startline;
var i: integer;
begin
  { printer margin only on printer output }
  for i:=1 to margin do
    write(@PRINTER,' ');

  { optional debug line number }
  if debug2 then begin
    if linenumber<=9 then write(' ');
    write(linenumber, ' ');
  end;
end;

func istrue(bool:boolean):char;
begin
  if bool then istrue:='T'
  else istrue:='F';
end;

proc printheader;
var i, spaces, n: integer;
begin
  if debug1 then begin
    writeln('< doTH: before, pageno=', pageno,
            ' textseen = ', istrue(textseen),
            ' linenumber=', linenumber,' >');

  end;

  { 3 top margin lines }
  printernewline;
  printernewline;
  printernewline;

  { left margin }
  for i:=1 to margin do
    write(@PRINTER,' ');

  { title left }
  for i:=0 to thlen-1 do
    write(@PRINTER, thname[i]);

  { width of page number }
  n := pageno;
  if n<10 then
    spaces := linewidth - thlen - 6
  else if n<100 then
    spaces := linewidth - thlen - 7
  else
    spaces := linewidth - thlen - 8;

  if spaces<1 then spaces := 1;

  while spaces>0 do begin
    write(@PRINTER,' ');
    spaces := prec(spaces);
  end;

  write(@PRINTER, 'Page ', pageno);
  printernewline;
  printernewline;
end;

proc newpage;
begin
  write(@PRINTER,FF);

  if headeron then begin
    pageno := succ(pageno);
    printheader;
    linenumber := 6;   { 6 for header pages }
  end
  else
    linenumber := 1;

  startline;
end;

proc clearprintout;
{ erase the current printout.txt file }
begin
  _setemucom(9);
end;

func nexttab(col: integer): integer;
var i: integer;
begin
  if ntab>0 then begin
    for i:=0 to ntab-1 do
      if tabstops[i]>col then begin
        nexttab := tabstops[i];
        exit;
      end;

    { falls rechts von letztem tab }
    nexttab := col + 8;
  end
  else begin
    { default unix style }
    nexttab := ((col div 8)+1)*8;
  end;
end;

func upc(c: char): char;
begin
  if (c>='a') and (c<='z') then upc
    := chr(ord(c)-32)
  else upc := c;
end;

proc putspaces(n: integer);
var i: integer;
begin
  for i:=1 to n do write(' ');
end;

proc writewithtabs;
var i,col,target: integer;
begin
  col := indent;

  for i:=0 to outlen-1 do begin

    if outbuf[i]=TAB8 then begin
      target := nexttab(col);
      while col<target do begin
        write(' ');
        col := succ(col);
      end;
    end
    else begin
      write(outbuf[i]);
      col := succ(col);
    end;

  end;
end;

proc newline;
begin
  writeln;
  linenumber := succ(linenumber);

  if linenumber > max_per_page then
    newpage
  else
    startline;
end;

proc underline(n: integer; c: char);
var m,i: integer;
begin
  m := n;
  if m>linewidth then m := linewidth;
  for i:=1 to m do write(c);
  newline;
end;

proc flushline;
begin
  if outlen>0 then begin
    textseen := true;
    if not preindent then
      putspaces(indent);
    writewithtabs;
    newline;
    outlen := 0;
    preindent := false;
  end;
end;

proc emitblank;
begin
  flushline;
  newline;
end;

proc needspace(n: integer);
begin
  if linenumber > max_per_page - n then begin
    linenumber := max_per_page;
    newline;
  end;
end;

proc emittextnofill;
var i: integer;
begin
  flushline;
  textseen := true;
  putspaces(indent);
  for i:=0 to llen-1 do
    write(line[i]);
  newline;
end;

func isspace(c: char): boolean;
begin
  isspace := (c=' ') or (c=TAB8);
end;

{ tab expansion to spaces (tab stops 8) }
{ into the current input line buffer }

proc addchartoline(c: char);
var k,spaces: integer;
begin
  if llen>=maxperline then exit;
  line[llen] := c;
  llen := succ(llen);
end;

{ parse integer from line starting at pos }
{ returns 0 if none }
func parseintfrom(p: integer): integer;
var v,pos: integer;
begin
  v := 0;
  pos:=p;
  while (pos<llen) and (line[pos]>='0')
    and (line[pos]<='9')
  do begin
    v := v*10 + (ord(line[pos]) - ord('0'));
    pos := succ(pos);
  end;
  parseintfrom := v;
end;

{formatter: add word to outbuf with wrapping}

proc addword(start, wlen: integer);
var need, i: integer;
begin
  { space before word if not first }
  need := wlen;
  if outlen>0 then need := need + 1;

  if (indent + outlen + need) > linewidth
  then begin
    flushline;
  end;

  if outlen>0 then begin
    outbuf[outlen] := ' ';
    outlen := succ(outlen);
  end;

  for i:=0 to wlen-1 do begin
    if outlen<maxout then begin
      outbuf[outlen] := line[start+i];
      outlen := succ(outlen);
    end;
  end;
end;

proc formatfillfromline;
var i, wstart, wlen: integer;
begin
  i := 0;

  { Ignore leading whitespace }
  while (i < llen) and isspace(line[i]) do
    i := succ(i);

  while i<llen do begin
    while (i<llen) and isspace(line[i]) do
      i:=succ(i);

    if i>=llen then exit;
    wstart := i;
    wlen := 0;
    while (i<llen) and (not isspace(line[i]))
    do begin
      i := succ(i);
      wlen := succ(wlen);
    end;
    addword(wstart, wlen);
  end;
end;

proc saveth(startpos: integer);
var pos: integer;
begin
  pos:=startpos;
  thlen := 0;

  while (pos<llen) and (line[pos]=' ') do
    pos := succ(pos);

  while (pos<llen) and (line[pos]<>' ') do
  begin
    thname[thlen] := line[pos];
    thlen := succ(thlen);
    pos := succ(pos);
  end;

  { section "(x)" anhC$ngen falls vorhanden }
  while (pos<llen) and (line[pos]=' ') do
    pos := succ(pos);

  if pos<llen then begin
    thname[thlen] := '(';
    thlen := succ(thlen);

    thname[thlen] := line[pos];
    thlen := succ(thlen);
    pos := succ(pos);

    thname[thlen] := ')'; thlen := succ(thlen);
  end;
end;


proc endip;
begin
  if ipmode then begin
    indent := indent - ipcur;
    ipmode := false;
    preindent := false;
    ipcur := 0;
  end;
end;

proc closeip;
begin
  flushline;
  endip;
end;

{ --- command handlers --- }

proc printTH;
var i,spaces: integer;
begin
  flushline;
  needspace(4);

  newline;
  putspaces(indent);

  for i:=0 to thlen-1 do
    write(thname[i]);

  if linewidth>47 then begin
    spaces := linewidth - (2*thlen) - indent;
    if spaces<1 then spaces := 1;
    while spaces>0 do begin
      write(' ');
      spaces := prec(spaces);
    end;

    for i:=0 to thlen-1 do
      write(thname[i]);
  end;

  newline;
  newline;
end;

proc doB;
var i: integer;
begin
  flushline;
  textseen := true;
  putspaces(indent);
  write(INVVID);

  i := 3;
  while i<llen do begin
    write(line[i]);
    i := succ(i);
  end;

  write(NORVID);
  newline;
end;

proc doI;
var i: integer;
begin
  flushline;
  textseen := true;
  putspaces(indent);

  i := 3;
  while i<llen do begin
    write(line[i]);
    i := succ(i);
  end;

  newline;
end;

proc doIP;
var pos,col: integer;
begin
  closeip;

  pos := 3;
  while (pos<llen) and (line[pos]=' ') do
    pos := succ(pos);

  textseen := true;
  putspaces(indent);
  col := indent;

  while pos<llen do begin
    write(line[pos]);
    pos := succ(pos);
    col := succ(col);
  end;

  if col < (indent + iphang) then begin
    while col < (indent + iphang) do begin
      write(' ');
      col := succ(col);
    end;
    ipcur := iphang;
    preindent := true;
  end
  else begin
    newline;
    putspaces(indent + iphang);
    ipcur := iphang;
    preindent := true;
  end;

  indent := indent + ipcur;
  ipmode := true;
end;

proc doTH;
begin
  if debug1 then
    writeln('< doTH: before, pageno=', pageno,
            ' linenumber=', linenumber,
            ' textseen=', istrue(textseen), ' >');

  closeip;
  saveth(3);
  headeron := true;

  if debug1 then
    writeln('< doTH: headeron set, thlen=', thlen, ' >')

  { page 1 gets header only if no real text seen yet }
  if (pageno=0) and (not textseen) then begin
    if debug1 then
      writeln('< doTH: printing header for page 1 >');

    pageno := 1;
    printheader;
    linenumber := 6;
    startline;
  end;

  { printTH; }
end;

proc doTA;
var p,v: integer;
begin
  if debug1 then writeln('< DOING ta >');
  ntab := 0;
  p := 3;   { nach ".ta" }

  while p<llen do begin

    while (p<llen) and (line[p]=' ') do
      p := succ(p);

    if p>=llen then exit;

    v := parseintfrom(p);

    if (v>0) and (ntab<maxtabs) then begin
      if debug1 then
        writeln('< Setting tabstop ', ntab,
        ' at ', v, '>');
      tabstops[ntab] := v;
      ntab := succ(ntab);
    end;

    while (p<llen) and (line[p]<>' ') do
      p := succ(p);
  end;
end;

proc doSH;
var i, pos: integer;
begin
  closeip;
  needspace(4);

  newline;   { Leerzeile vor der Section }

  pos := 4;
  putspaces(indent);
  i := pos;
  while i<llen do begin
    write(upc(line[i]));
    i := succ(i);
  end;
  newline;

  putspaces(indent);
  underline(llen-4, '=');
end;

proc doSS;
var i, pos: integer;
begin
  closeip;
  needspace(4);

  newline;   { Leerzeile vor der Subsection }

  pos := 4;
  putspaces(indent);
  i := pos;
  while i<llen do begin
    write(upc(line[i]));
    i := succ(i);
  end;
  newline;

  putspaces(indent);
  underline(llen-4, '-');
end;

proc doPP;
begin
  closeip;
  emitblank;
end;

proc doBR;
begin
  flushline;
end;

proc doNF;
begin
  if debug1 then writeln('< doing nf >');
  closeip;
  flushline;
  needspace(5);
  fillmode := false;
end;

proc doFI;
begin
  if debug1 then write('< DOING fi >');
  closeip;
  flushline;
  fillmode := true;
end;

proc doRS;
begin
  closeip;
  flushline;
  indent := indent + indstep;
end;

proc doRE;
begin
  closeip;
  flushline;
  if indent>=indstep then
    indent := indent - indstep;
end;

proc doSP;
var n, j, s: integer;
begin
  flushline;
  s := 3;
  while (s<llen) and (line[s]=' ') do
    s := succ(s);

  if llen>3 then
    n := parseintfrom(s)
  else
    n := 1;

  if n<=0 then n := 1;

  for j:=1 to n do
    newline;
end;

{ --- line reader: reads CR-terminated lines; }
{     returns false on EOF }

func readline: boolean;
begin
  llen := 0;

  repeat
    read(@src, ch);

    if ch=EOF then begin
      if llen>0 then
        readline := true
      else
        readline := false;
      exit;
    end;

    if ch=LF then begin
    end
    else if ch=CR then begin
      readline := true;
      exit;
    end
    else begin
      addchartoline(ch);
    end;
  until false;
end;

{ --- dispatcher --- }

proc handleline;
begin
  if (llen>=1) and (line[0]='.') then begin
    { recognize 2-letter commands }
    if (llen>=3) and (line[1]='S')
      and (line[2]='H') then doSH
    else if (llen>=3) and (line[1]='S')
      and (line[2]='S') then doSS
    else if (llen>=3) and (line[1]='P')
      and (line[2]='P') then doPP
    else if (llen>=3) and (line[1]='b')
      and (line[2]='r') then doBR
    else if (llen>=3) and (line[1]='n')
       and (line[2]='f') then doNF
    else if (llen>=3) and (line[1]='f')
       and (line[2]='i') then doFI
    else if (llen>=3) and (line[1]='R')
       and (line[2]='S') then doRS
    else if (llen>=3) and (line[1]='R')
       and (line[2]='E') then doRE
    else if (llen>=3) and (line[1]='s')
       and (line[2]='p') then doSP
    else if (line[1]='t') and
        (line[2]='a') then doTA
    else if (line[1]='I') and
        (line[2]='P') then doIP
    else if (line[1]='T') and (line[2]='H')
      then doTH
    else if (llen>=2) and (line[1]='B')
      then doB
    else if (llen>=2) and (line[1]='I')
      then doI
    else begin
      { unknown request: ignore }
    end;
  end else begin
    { plain text }
    if fillmode then formatfillfromline
    else emittextnofill;
  end;
end;

{ --- main --- }

begin
  clearprintout;
  { defaults }
  fillmode  := true;
  indent    := 0;
  linewidth := 47;
  ntab      := 0;
  ipmode    := false;
  iphang    := 5;
  ipcur     := 0;
  preindent := false;
  linenumber:= 1;
  pageno    := 0;
  headeron  := false;
  textseen  := false;

  { get filename from arguments }
  cyclus := 0; drive := 1;
  _agetstring(name, default, cyclus, drive);
  if default then begin
    writeln(
      'usage: nroff name[.cyc][,drv] [linewidth]');
    _abort;
  end;

  _asetfile(name, cyclus, drive, 'B'); { 'B' = text }
  openr(src);

  _agetval(linewidth,default); {max chars/line}
  if (linewidth<20) then linewidth := 36;
  if (linewidth>128) then linewidth :=128;

  writeln;
  write(PRTON);
  startline;
  outlen := 0;

  while readline do handleline; { main loop }

  handleline; { last line }
  flushline;

  write(PRTOFF);

 end.