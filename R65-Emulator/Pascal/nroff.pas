program nroff;

{ mini nroff }
{ Written March 2026 for the R65 system }
{ R. Richarz / ChatGPT }

uses syslib, arglib;

const
  LINEMAX = 132; { max chars per printer output line }
  LINEDEF = 55;  { default line width for A5 output }
  PAGEMAX = 200; { max lines per page in program }
  PAGEDEF = 58;  { default lines per page for A5}
  MAXSRC  = 56;  { max source chars per input line }
  MAXOUT  = 200; { max chars in formatted output }
  MARGIN  = 10;  { left margin on printer output }
  INDSTEP = 4;   { indent step for .RS / .RE }
  MAXTABS = 16;  { max number of explicit tab stops }
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

  pagepos  : integer; { current line number on page }
  pageno   : integer; { current page number }
  headeron : boolean; { true after .TH }
  textseen : boolean;
        { true after first real text output }

  thname   : array[40] of char; { title text from .TH }
  thlen    : integer; { length of title text }

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
  for i := 1 to MARGIN do
    write(@PRINTER, ' ');

  { optional debug line number }
  if DEBUG2 then begin
    if pagepos <= 9 then write(' ');
    write(pagepos, ' ');
  end;
end;

func istrue(bool: boolean): char;
begin
  if bool then istrue := 'T'
  else istrue := 'F';
end;

proc printheader;
var i, spaces, n: integer;
begin
  if DEBUG1 then begin
    writeln('< doTH: before, pageno=', pageno,
            ' textseen=', istrue(textseen),
            ' pagepos=', pagepos, ' >');
  end;

  { 3 top margin lines }
  printernewline;
  printernewline;
  printernewline;

  { left margin }
  for i := 1 to MARGIN do
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
begin
  write(@PRINTER, FF);

  if headeron then begin
    pageno := succ(pageno);
    printheader;
    pagepos := 6;
          { page line after 3 blanks + header + blank }
  end
  else
    pagepos := 1;

  startline;
end;

proc clearprintout;
begin
  { erase the current printout.txt file }
  _setemucom(9);
end;

func nexttab(col: integer): integer;
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

func upc(c: char): char;
begin
  if (c >= 'a') and (c <= 'z') then
    upc := chr(ord(c) - 32)
  else
    upc := c;
end;

proc putspaces(n: integer);
var i: integer;
begin
  for i := 1 to n do
    write(' ');
end;

proc writewithtabs;
var i, col, target: integer;
begin
  col := indent;

  for i := 0 to outlen - 1 do begin
    if outbuf[i] = TAB8 then begin
      target := nexttab(col);
      while col < target do begin
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
  pagepos := succ(pagepos);

  if pagepos > pagelen then
    newpage
  else
    startline;
end;

proc underline(n: integer; c: char);
var m, i: integer;
begin
  m := n;
  if m > linelen then m := linelen;
  for i := 1 to m do
    write(c);
  newline;
end;

proc flushline;
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
begin
  flushline;
  newline;
end;

proc needspace(n: integer);
begin
  if pagepos > pagelen - n then begin
    pagepos := pagelen;
    newline;
  end;
end;

proc emittextnofill;
var i: integer;
begin
  flushline;
  textseen := true;
  putspaces(indent);
  for i := 0 to llen - 1 do
    write(line[i]);
  newline;
end;

func isspace(c: char): boolean;
begin
  isspace := (c = ' ') or (c = TAB8);
end;

proc addchartoline(c: char);
begin
  if llen >= MAXSRC then exit;
  line[llen] := c;
  llen := succ(llen);
end;

func parseintfrom(p: integer): integer;
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

proc addword(start, wlen: integer);
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
begin
  if ipmode then begin
    indent := indent - ipcur;
    ipmode := false;
    preind := false;
    ipcur := 0;
  end;
end;

proc closeip;
begin
  flushline;
  endip;
end;

{ --- command handlers --- }

proc printth;
var i, spaces: integer;
begin
  flushline;
  needspace(4);

  newline;
  putspaces(indent);

  for i := 0 to thlen - 1 do
    write(thname[i]);

  if linelen > 47 then begin
    spaces := linelen - (2 * thlen) - indent;
    if spaces < 1 then spaces := 1;
    while spaces > 0 do begin
      write(' ');
      spaces := prec(spaces);
    end;

    for i := 0 to thlen - 1 do
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
  while i < llen do begin
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
  while i < llen do begin
    write(line[i]);
    i := succ(i);
  end;

  newline;
end;

proc doIP;
var pos, col: integer;
begin
  closeip;

  pos := 3;
  while (pos < llen) and (line[pos] = ' ') do
    pos := succ(pos);

  textseen := true;
  putspaces(indent);
  col := indent;

  while pos < llen do begin
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
    preind := true;
  end
  else begin
    newline;
    putspaces(indent + iphang);
    ipcur := iphang;
    preind := true;
  end;

  indent := indent + ipcur;
  ipmode := true;
end;

proc doTH;
begin
  if DEBUG1 then
    writeln('< doTH: before, pageno=', pageno,
            ' pagepos=', pagepos,
            ' textseen=', istrue(textseen), ' >');

  closeip;
  saveth(3);
  headeron := true;

  if DEBUG1 then
    writeln('< doTH: headeron set, thlen=',
          thlen, ' >');

  { page 1 gets header only if no real text seen yet }
  if (pageno = 0) and (not textseen) then begin
    if DEBUG1 then
      writeln('< doTH: printing header for page 1 >');

    pageno := 1;
    printheader;
    pagepos := 6;
    startline;
  end;

  { printth; }
end;

proc doTA;
var p, v: integer;
begin
  if DEBUG1 then writeln('< doing ta >');
  ntab := 0;
  p := 3;

  while p < llen do begin
    while (p < llen) and (line[p] = ' ') do
      p := succ(p);

    if p >= llen then exit;

    v := parseintfrom(p);

    if (v > 0) and (ntab < MAXTABS) then begin
      if DEBUG1 then
        writeln('< setting tabstop ', ntab, ' at ',
              v, ' >');
      tabstops[ntab] := v;
      ntab := succ(ntab);
    end;

    while (p < llen) and (line[p] <> ' ') do
      p := succ(p);
  end;
end;

proc doSH;
var i, pos: integer;
begin
  closeip;
  needspace(4);

  newline;

  pos := 4;
  putspaces(indent);
  i := pos;
  while i < llen do begin
    write(upc(line[i]));
    i := succ(i);
  end;
  newline;

  putspaces(indent);
  underline(llen - 4, '=');
end;

proc doSS;
var i, pos: integer;
begin
  closeip;
  needspace(4);

  newline;

  pos := 4;
  putspaces(indent);
  i := pos;
  while i < llen do begin
    write(upc(line[i]));
    i := succ(i);
  end;
  newline;

  putspaces(indent);
  underline(llen - 4, '-');
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
  if DEBUG1 then writeln('< doing nf >');
  closeip;
  flushline;
  needspace(5);
  fillmode := false;
end;

proc doFI;
begin
  if DEBUG1 then writeln('< doing fi >');
  closeip;
  flushline;
  fillmode := true;
end;

proc doRS;
begin
  closeip;
  flushline;
  indent := indent + INDSTEP;
end;

proc doRE;
begin
  closeip;
  flushline;
  if indent >= INDSTEP then
    indent := indent - INDSTEP;
end;

proc doSP;
var n, j, s: integer;
begin
  flushline;
  s := 3;
  while (s < llen) and (line[s] = ' ') do
    s := succ(s);

  if llen > 3 then
    n := parseintfrom(s)
  else
    n := 1;

  if n <= 0 then n := 1;

  for j := 1 to n do
    newline;
end;

func readline: boolean;
begin
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

proc handleline;
begin
  if (llen >= 1) and (line[0] = '.') then begin
    if (llen >= 3) and (line[1] = 'S')
      and (line[2] = 'H') then doSH
    else if (llen >= 3) and (line[1] = 'S')
      and (line[2] = 'S') then doSS
    else if (llen >= 3) and (line[1] = 'P')
      and (line[2] = 'P') then doPP
    else if (llen >= 3) and (line[1] = 'b')
      and (line[2] = 'r') then doBR
    else if (llen >= 3) and (line[1] = 'n')
      and (line[2] = 'f') then doNF
    else if (llen >= 3) and (line[1] = 'f')
      and (line[2] = 'i') then doFI
    else if (llen >= 3) and (line[1] = 'R')
      and (line[2] = 'S') then doRS
    else if (llen >= 3) and (line[1] = 'R')
      and (line[2] = 'E') then doRE
    else if (llen >= 3) and (line[1] = 's')
      and (line[2] = 'p') then doSP
    else if (llen >= 3) and (line[1] = 't')
      and (line[2] = 'a') then doTA
    else if (llen >= 3) and (line[1] = 'I')
      and (line[2] = 'P') then doIP
    else if (llen >= 3) and (line[1] = 'T')
      and (line[2] = 'H') then doTH
    else if (llen >= 2) and (line[1] = 'B') then doB
    else if (llen >= 2) and (line[1] = 'I') then doI
    else begin
      { unknown request: ignore }
    end;
  end
  else begin
    if fillmode then formatfillfromline
    else emittextnofill;
  end;
end;

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

  { get filename from arguments }
  cyclus := 0;
  drive := 1;
  _agetstring(name, default, cyclus, drive);
  if default then begin
    writeln(
         'usage: nroff name[.cyc][,drv] [linewidth]');
    _abort;
  end;

  _asetfile(name, cyclus, drive, 'B');
  openr(src);

  _agetval(linelen, default);
  if default then linelen := LINEDEF;

  if linelen < 20 then linelen := 36;
  if linelen > LINEMAX then linelen := LINEMAX;

  write(PRTON);
  startline;

  while readline do
    handleline;

  flushline;
  write(PRTOFF);
end.
