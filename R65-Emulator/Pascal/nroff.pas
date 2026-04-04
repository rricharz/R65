program nroff;

{ mini nroff }
{ Written March 2026 for the R65 system }
{ R. Richarz / ChatGPT }

uses syslib, arglib, filelib;

const
  LINEMAX = 132; { max chars per printer output line }
  LINEDEF = 55;  { default line width for A5 output }
  PAGEMAX = 200; { max lines per page in program }
  PAGEDEF = 58;  { default lines per page for A5}
  MAXSRC  = 56;  { max source chars per input line }
  MAXOUT  = 200; { max chars in formatted output }
  LMARGIN = 3;   { left margint }
  TMARGIN = 3;   { top margin }
  INDSTEP = 4;   { indent step for .RS / .RE }
  MAXTABS = 16;  { max number of explicit tab stops }
  IPINDENT= 5;  { default IP indent }

  ERR_MISS  = 1;  { missing argument }
  ERR_NUM   = 2;  { invalid number }
  ERR_EXTRA = 3;  { extra text }
  ERR_RANGE = 4;  { value out of range }
  ERR_REQ   = 5;  { invalid request }
  ERRMAX    = 4;  { max number of errors on screen }

  QUOTE     = chr($27);

  DEBUG1  = false;
  DEBUG2  = false;

var
  src      : file;
  name     : array[15] of char;
  default  : boolean;
  cyclus   : integer;
  drive    : integer;

  ch       : char;

  linelen  : integer; { active output line width }
  pagelen  : integer; { active page length }
  line     : array[MAXSRC] of char;
        { current input line buffer }
  llen     : integer; { current input line length }

  outbuf   : array[MAXOUT] of char;
        { formatted output line }
  outlen   : integer;
        { current formatted output length }

  fillmode : boolean;
        { true = fill mode, false = no-fill }
  indent   : integer; { current left indent }
  titlemod : boolean;
  linecnt  : integer;

  tabstops : array[MAXTABS] of integer;
  ntab     : integer;
  ipmode   : boolean;
  ipindent : integer;
  iphang   : integer;
  ipcur    : integer;
  preind   : boolean;
  errcount : integer;
  srcline  : integer;

  pagepos  : integer; { current line number on page }
  pageno   : integer; { current page number }
  headeron : boolean; { true after .TH }
  textseen : boolean;
        { true after first real text output }

  thname   : array[LINEMAX] of char; { title from .TH }
  thlen    : integer; { length of title text }

proc errec(pos,code:integer);
{***************************}
var i: integer;
begin
  errcount := succ(errcount);
  write('Error in line ',srcline ,': ');
  case code of
    ERR_MISS : writeln('missing argument');
    ERR_NUM  : writeln('invalid number');
    ERR_EXTRA: writeln('extra text');
    ERR_RANGE: writeln('value out of range');
    ERR_REQ  : writeln('invalid request')
  else
    writeln('bad request to errec')
  end;
  for i:=0 to llen-1 do
    write(line[i]);
  writeln;
  for i:=1 to pos do
    write(' ');
  writeln('^');
  if errcount>=ERRMAX then begin
    write('Too many errors');
    _abort;
  end;
end;

func checkeol(pos:integer):boolean;
{*********************************}
var pos0:integer;
begin
  pos0 := pos;
  while (pos0<llen) and (line[pos0]=' ') do
    pos0 := succ(pos0);
  if pos0<llen then begin
    errec(pos0,ERR_EXTRA);
    checkeol := false;
  end
  else
    checkeol := true;
end;

func findarg(pos:integer):integer;
{********************************}
var pos0: integer;
begin
  pos0 := pos;
  while (pos0<llen) and (line[pos0]=' ') do
    pos0 := pos0+1;
  if pos0>=llen then begin
    errec(pos0,ERR_MISS);
    findarg := -1;
  end
  else
    findarg := pos0;
end;

proc printernewline;
{******************}
begin
  write(@PRINTER, CR);
  write(@PRINTER, LF);
end;

proc startline;
{*************}
var i: integer;
begin

  if DEBUG1 then
    writeln('< startline: pageno=',pageno,
          ' pagepos=',pagepos,' >');

  { printer margin only on printer output }
  for i := 1 to LMARGIN do
    write(@PRINTER, ' ');

  { optional debug line number }
  if DEBUG2 then begin
    if pagepos <= 9 then write(' ');
    write(pagepos, ' ');
  end;
end;

proc printheader;
{***************}
var i, spaces, n: integer;
begin
  if DEBUG1 then begin
    writeln('< printheader: before, pageno=', pageno,
            ' textseen=', textseen,
            ' pagepos=', pagepos, ' >');
  end;

  { top margin }
  for i := 1 to 3 do begin
    printernewline;
  end;

  { left margin }
  for i := 1 to LMARGIN do
    write(@PRINTER, ' ');

  { title left }
  for i := 0 to thlen - 1 do
    write(@PRINTER, thname[i]);

  { width of page number }
  n := pageno;
  if n < 10 then
    spaces := linelen - thlen - 6
  else if n < 100 then
    spaces := linelen - thlen - 7
  else
    spaces := linelen - thlen - 8;

  if spaces < 1 then spaces := 1;

  while spaces > 0 do begin
    write(@PRINTER, ' ');
    spaces := prec(spaces);
  end;

  write(@PRINTER, 'Page ', pageno);
  printernewline;
  printernewline;
end;

proc newpage;
{***********}
begin
  if pageno>0 then
    write(@PRINTER, FF);

  pageno := succ(pageno);

  if headeron then begin
    printheader;
    pagepos := TMARGIN + 3;
        { line after margin, header, blank }
  end
  else
    pagepos := 1;

  startline;
end;

proc clearprintout;
{*****************}
begin
  { erase the current printout.txt file }
  { this is a command to the emulator }
  _setemucom(9);
end;

func nexttab(col: integer): integer;
{**********************************}
var i: integer;
begin
  if ntab > 0 then begin
    for i := 0 to ntab - 1 do
      if tabstops[i] > col then begin
        nexttab := tabstops[i];
        exit;
      end;

    { right of last tab }
    nexttab := col + 8;
  end
  else begin
    { default unix style }
    nexttab := ((col div 8) + 1) * 8;
  end;
end;

proc putspaces(n: integer);
{*************************}
var i: integer;
begin
  for i := 1 to n do
    write(@PRINTER,' ');
end;

proc writewithtabs;
{*****************}
var i, col, target: integer;
begin
  col := indent;

  for i := 0 to outlen - 1 do begin
    if outbuf[i] = TAB8 then begin
      target := nexttab(col);
      while col < target do begin
        write(@PRINTER,' ');
        col := succ(col);
      end;
    end
    else begin
      write(@PRINTER,outbuf[i]);
      col := succ(col);
    end;
  end;
end;

proc newline;
{***********}
begin
  writeln(@PRINTER);
  pagepos := succ(pagepos);

  if pagepos > pagelen then
    newpage
  else
    startline;
end;

proc doquotedline;
{****************}
var i: integer;
begin
  startline;
  i := 1;
  while (i<llen) and (line[i]<>QUOTE) do begin
    write(@PRINTER,line[i]);
    i := i+1;
  end;
  newline;
end;

proc underline(n: integer; c: char);
{**********************************}
var m, i: integer;
begin
  m := n;
  if m > linelen then m := linelen;
  for i := 1 to m do
    write(@PRINTER,c);
  newline;
end;

proc flushline;
{*************}
begin
  if outlen > 0 then begin
    textseen := true;
    if not preind then
      putspaces(indent);
    writewithtabs;
    newline;
    outlen := 0;
    preind := false;
  end;
end;

proc emitblank;
{*************}
begin
  flushline;
  newline;
end;

proc needspace(n: integer);
{*************************}
begin
  if pagepos > pagelen - n then begin
    pagepos := pagelen;
    newline;
  end;
end;

proc emittextnofill;
{******************}
var i: integer;
begin
  flushline;
  textseen := true;
  putspaces(indent);
  for i := 0 to llen - 1 do
    write(@PRINTER, line[i]);
  newline;
end;

func isspace(c: char): boolean;
{*****************************}
begin
  isspace := (c = ' ') or (c = TAB8);
end;

proc addchartoline(c: char);
{**************************}
begin
  if llen >= MAXSRC then exit;
  line[llen] := c;
  llen := succ(llen);
end;

func parseintfrom(p: integer): integer;
{*************************************}
var v, pos: integer;
begin
  v := 0;
  pos := p;
  while (pos < llen) and (line[pos] >= '0')
    and (line[pos] <= '9') do begin
    v := v * 10 + (ord(line[pos]) - ord('0'));
    pos := succ(pos);
  end;
  parseintfrom := v;
end;

proc getnumarg(pos: integer; var n,npos: integer);
{************************************************}
var i: integer;
begin
  i := pos;
  while (i<llen) and (line[i]=' ') do
    i := i+1;
  if i>=llen then begin
    n := -1;
    npos := i;
    exit;
  end;
  if (line[i]<'0') or (line[i]>'9') then begin
    errec(i,ERR_NUM);
    n := -2;
    npos := i;
    exit;
  end;
  npos := i;
  n := 0;
  while (i<llen) and (line[i]>='0')
                  and (line[i]<='9') do begin
    n := n*10 + ord(line[i]) - ord('0');
    i := i+1;
  end;
  while (i<llen) and (line[i]=' ') do
    i := i+1;
  if i<llen then begin
    errec(i,ERR_EXTRA);
    n := -2;
    exit;
  end;
end;

proc addword(start, wlen: integer);
{*********************************}
var need, i: integer;
begin
  { space before word if not first }
  need := wlen;
  if outlen > 0 then need := need + 1;

  if (indent + outlen + need) > linelen then
    flushline;

  if outlen > 0 then begin
    outbuf[outlen] := ' ';
    outlen := succ(outlen);
  end;

  for i := 0 to wlen - 1 do begin
    if outlen < MAXOUT then begin
      outbuf[outlen] := line[start + i];
      outlen := succ(outlen);
    end;
  end;
end;

proc formatfillfromline;
{**********************}
var i, wstart, wlen: integer;
begin
  i := 0;

  { ignore leading whitespace }
  while (i < llen) and isspace(line[i]) do
    i := succ(i);

  while i < llen do begin
    while (i < llen) and isspace(line[i]) do
      i := succ(i);

    if i >= llen then exit;
    wstart := i;
    wlen := 0;
    while (i < llen) and (not isspace(line[i])) do
    begin
      i := succ(i);
      wlen := succ(wlen);
    end;
    addword(wstart, wlen);
  end;
end;

proc saveth(startpos: integer);
{*****************************}
var pos: integer;
begin
  pos := startpos;
  thlen := 0;

  while (pos < llen) and (line[pos] = ' ') do
    pos := succ(pos);

  while (pos < llen) and (line[pos] <> ' ') do begin
    thname[thlen] := line[pos];
    thlen := succ(thlen);
    pos := succ(pos);
  end;

  { append section "(x)" if present }
  while (pos < llen) and (line[pos] = ' ') do
    pos := succ(pos);

  if pos < llen then begin
    thname[thlen] := '(';
    thlen := succ(thlen);
    thname[thlen] := line[pos];
    thlen := succ(thlen);
    pos := succ(pos);
    thname[thlen] := ')';
    thlen := succ(thlen);
  end;
end;

proc endip;
{*********}
begin
  if ipmode then begin
    indent := indent - ipcur;
    ipmode := false;
    preind := false;
    ipcur := 0;
  end;
end;

proc closeip;
{***********}
begin
  flushline;
  endip;
end;

proc getwordend(i: integer; var j: integer);
{******************************************}
begin
  j := i;
  while (j<llen) and (line[j]<>' ') do
    j := j+1;
end;

proc printth;
{***********}
var i, spaces: integer;
begin
  flushline;
  needspace(4);

  newline;
  putspaces(indent);

  for i := 0 to thlen - 1 do
    write(@PRINTER,thname[i]);

  if linelen > 47 then begin
    spaces := linelen - (2 * thlen) - indent;
    if spaces < 1 then spaces := 1;
    while spaces > 0 do begin
      write(@PRINTER,' ');
      spaces := prec(spaces);
    end;

    for i := 0 to thlen - 1 do
      write(@PRINTER,thname[i]);
  end;

  newline;
  newline;
end;

proc doB;
{*******}
var i: integer;
begin
  i := findarg(3);
  if i<0 then
    exit;
  flushline;
  textseen := true;
  putspaces(indent);
  while i < llen do begin
    write(@PRINTER,line[i]);
    i := succ(i);
  end;
  newline;
end;

proc doI;
{*******}
var i: integer;
begin
  i := findarg(3);
  if i<0 then
    exit;
  flushline;
  textseen := true;
  putspaces(indent);
  while i < llen do begin
    write(@PRINTER,line[i]);
    i := succ(i);
  end;

  newline;
end;

proc doIP;
{********}
var i,j,n,npos,col: integer;
begin
  closeip;
  i := findarg(3);
  if i<0 then
    exit;

  getwordend(i,j);
  getnumarg(j,n,npos);
  if n=-2 then
    exit;
  if n=-1 then
    n := IPINDENT;

  textseen := true;
  putspaces(indent);
  col := indent;

  while i<j do begin
    write(@PRINTER,line[i]);
    i := i+1;
    col := col+1;
  end;

  if col < (indent + n) then begin
    while col < (indent + n) do begin
      write(@PRINTER,' ');
      col := col+1;
    end;
    ipcur := n;
    preind := true;
  end
  else begin
    newline;
    putspaces(indent + n);
    ipcur := n;
    preind := true;
  end;

  indent := indent + ipcur;
  ipmode := true;
end;

proc doTH;
{********}
var i: integer;
begin
  closeip;

  i := 3;
  while (i<llen) and (line[i]=' ') do
    i := i+1

  if i>=llen then begin
    headeron := false;
    thlen := 0;
  end
  else begin
    saveth(i);
    headeron := true;
  end;

  if DEBUG1 then
    writeln('< doTH: pageno=', pageno,
            ' pagepos=', pagepos,
            ' headeron=', headeron,
            ' thlen=', thlen, ' >');

  newpage;
end;

proc doTA;
{********}
var p, v: integer;
begin
  if DEBUG2 then writeln('< doing ta >');
  ntab := 0;
  p := 3;

  while p < llen do begin
    while (p < llen) and (line[p] = ' ') do
      p := succ(p);

    if p >= llen then exit;

    v := parseintfrom(p);

    if (v > 0) and (ntab < MAXTABS) then begin
      if DEBUG2 then
        writeln('< setting tabstop ', ntab, ' at ',
              v, ' >');
      tabstops[ntab] := v;
      ntab := succ(ntab);
    end;

    while (p < llen) and (line[p] <> ' ') do
      p := succ(p);
  end;
end;

proc doSS;
{********}
var i, n: integer;
begin
  i := findarg(3);
  if i<0 then
    exit;
  n := llen - i;
  closeip;
  needspace(4);
  newline;
  putspaces(indent);
  while i < llen do begin
    write(@PRINTER, _uppercase(line[i]));
    i := succ(i);
  end;
  newline;
  putspaces(indent);
  underline(n, '-');
end;

proc doSH;
{********}
var i, n: integer;
begin
  i := findarg(3);
  if i<0 then
    exit;
  n := llen - i;
  closeip;
  needspace(6);
  newline;
  putspaces(indent);
  while i < llen do begin
    write(@PRINTER, _uppercase(line[i]));
    i := succ(i);
  end;
  newline;
  putspaces(indent);
  underline(n, '=');
end;

proc doPP;
{********}
begin
  if not checkeol(3) then
    exit;
  closeip;
  emitblank;
end;

proc doBR;
{********}
begin
  if not checkeol(3) then
    exit;
  flushline;
end;

proc doNF;
{********}
begin
  closeip;
  flushline;
  needspace(5);
  fillmode := false;
end;

proc doFI;
{********}
begin
  if not checkeol(3) then
    exit;
  closeip;
  flushline;
  fillmode := true;
end;

proc doRS;
{********}
begin
  if not checkeol(3) then
    exit;
  closeip;
  flushline;
  indent := indent + INDSTEP;
end;

proc doRE;
{********}
begin
  closeip;
  flushline;
  if indent >= INDSTEP then
    indent := indent - INDSTEP;
end;

proc doSP;
{********}
var i, j, n: integer;
begin
  closeip;
  i := 3;
  while (i<llen) and (line[i]=' ') do
    i := succ(i);
  if i>=llen then
    n := 1
  else begin
    if (line[i]<'0') or (line[i]>'9') then begin
      errec(i,ERR_NUM);
      exit;
    end;
    n := 0;
    while (i<llen) and (line[i]>='0')
                    and (line[i]<='9') do begin
      n := n*10 + ord(line[i]) - ord('0');
      i := succ(i);
    end;
    while (i<llen) and (line[i]=' ') do
      i := succ(i);
    if i<llen then begin
      errec(i,ERR_EXTRA);
      exit;
    end;
  end;
  for j := 1 to n do
    newline;
end;

proc doLL;
{********}
var n,npos: integer;
begin
  flushline;                  { end current line }
  getnumarg(3,n,npos);

  if n=-2 then
    exit;

  if n=-1 then begin
    linelen := LINEDEF;
    exit;
  end;

  if (n<1) or (n>LINEMAX) then begin
    errec(npos,ERR_RANGE);
    exit;
  end;

  linelen := n;
end;

func readline: boolean;
{*********************}
begin
  srcline := succ(srcline);
  llen := 0;

  repeat
    read(@src, ch);

    if ch = EOF then begin
      if llen > 0 then
        readline := true
      else
        readline := false;
      exit;
    end;

    if ch = LF then begin
    end
    else if ch = CR then begin
      readline := true;
      exit;
    end
    else begin
      addchartoline(ch);
    end;
  until false;
end;

proc emitquotedline;
{********************}
var i: integer;
begin
  i := 1; { skip opening quote }
  while (i<llen) and (line[i]<>QUOTE) do begin
    write(@PRINTER,line[i]);
    i := i+1;
  end;
  newline;
end;

proc handleline;
{**************}
var cmd: packed char;
begin
  if (llen >= 2) and (line[0] = '.') then begin
    if llen>=3 then
      cmd := packed(_uppercase(line[1]),
                              _uppercase(line[2]))
    else
      cmd := packed(_uppercase(line[1]), ' ');

    case cmd of
      'SS': doSS;  { subsection }
      'SH': doSH;  { section }
      'PP': doPP;  { paragraph }
      'BR': doBR;  { break line }
      'NF': doNF;  { no fill }
      'FI': doFI;  { fill }
      'RS': doRS;  { indent start }
      'RE': doRE;  { indent end }
      'SP': doSP;  { space lines }
      'TA': doTA;  { tabs }
      'IP': doIP;  { indented para }
      'TH': doTH;  { title header }
      'LL': doLL;  { line len (todo) }
      'B ': doB;   { bold }
      'I ': doI    { italic }
    else
      errec(1,ERR_REQ)
    end { case }
  end
  else begin
    if line[0]=QUOTE then begin
      flushline;
      emitquotedline;
      exit;
    end;
    if fillmode then formatfillfromline
    else emittextnofill;
  end;
end;

{ main }
{******}
begin
  clearprintout;

  { defaults }
  linelen  := LINEDEF;
  pagelen  := PAGEDEF;
  llen     := 0;
  outlen   := 0;
  fillmode := true;
  indent   := 0;
  ntab     := 0;
  ipmode   := false;
  ipindent := 0;
  iphang   := 5;
  ipcur    := 0;
  preind   := false;
  pagepos  := 1;
  pageno   := 0;
  headeron := false;
  textseen := false;
  titlemod := false;
  linecnt  := 0;
  errcount := 0;
  srcline  := 0;

  { get filename from arguments }
  cyclus := 0;
  drive := 1;
  _agetstring(name, default, cyclus, drive);
  if default then begin
    writeln(
         'usage: nroff name[.cyc][,drv] [linewidth]');
    _abort;
  end;

  _asetfile(name, cyclus, drive, 'N');
  openr(src);
  writeln;

  _agetval(linelen, default);
  if default then linelen := LINEDEF;

  if linelen < 20 then linelen := 36;
  if linelen > LINEMAX then linelen := LINEMAX;

  startline;

  while readline do
    handleline;
  closeip;
  flushline;

end.
