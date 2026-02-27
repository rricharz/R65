program nroff;

{ mininroff            }
{ Witten March 2026    }
{ R. Richarz / ChatGPT }

uses syslib, arglib;

const
  maxline = 40;
  maxout  = 200;
  indstep = 4;
  maxtabs = 16;
  debug   = false;

var
  src      : file;
  name     : array[15] of char;
  default  : boolean;
  cyclus, drive : integer;

  ch       : char;
  line     : array[maxline] of char;
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
  preindent: boolean;

  thname : array[40] of char;
  thlen  : integer;

{ --- helpers --- }

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

proc underline(n: integer; c: char);
var m,i: integer;
begin
  m := n;
  if m>linewidth then m := linewidth;
  for i:=1 to m do write(c);
  writeln;
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

    if outbuf[i]=tab8 then begin
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

proc flushline;
var i: integer;
begin
  if outlen>0 then begin
    if not preindent then
      putspaces(indent);
    writewithtabs;
    writeln;
    outlen := 0;
    preindent := false;
  end;
end;

proc emitblank;
begin
  flushline;
 if linewidth>47 then writeln;
end;

proc emittextnofill;
var i: integer;
begin
  flushline;
  putspaces(indent);
  for i:=0 to llen-1 do write(line[i]);
  writeln;
end;

func isspace(c: char): boolean;
begin
  isspace := (c=' ') or (c=tab8);
end;

{ tab expansion to spaces (tab stops 8) }
{ into the current input line buffer }

proc addchartoline(c: char);
var k,spaces: integer;
begin
  if llen>=maxline then exit;
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

  { NEW: ignore leading whitespace }
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

proc printTH;
var i,spaces: integer;
begin
  flushline;
  writeln;
  putspaces(indent);

  { links }
  for i:=0 to thlen-1 do
    write(thname[i]);

  if linewidth>47 then begin
    spaces := linewidth - (2*thlen) - indent;
    if spaces<1 then spaces := 1;
    while spaces>0 do begin
      write(' ');
      spaces := prec(spaces);
    end;

    { rechts }
    for i:=0 to thlen-1 do
      write(thname[i]);
  end;

  writeln;
  writeln;
end;

proc endip;
begin
  if ipmode then begin
    indent := indent - iphang;
    ipmode := false;
    preindent := false;
  end;
end;

{ --- command handlers --- }

proc doTH;
begin
  endip;
  saveth(3);   { nach ".TH" }
  printTH;
end;

proc doTA;
var p,v: integer;
begin
  if debug then writeln('< DOING ta >');
  ntab := 0;
  p := 3;   { nach ".ta" }

  while p<llen do begin

    while (p<llen) and (line[p]=' ') do
      p := succ(p);

    if p>=llen then exit;

    v := parseintfrom(p);

    if (v>0) and (ntab<maxtabs) then begin
      if debug then
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
  endip;
  flushline;
  writeln;

  { print rest of line after ".SH " }
  { in uppercase }
  pos := 4; { expects: . S H space ... }
  putspaces(indent);
  i := pos;
  while i<llen do begin
    write(upc(line[i]));
    i := succ(i);
  end;
  writeln;

  putspaces(indent);
  underline(llen - 4,'=');
end;

proc doSS;
var i, pos: integer;
begin
  endip;
  flushline;
  writeln;

  { print rest of line after ".SH " }
  { in uppercase }
  pos := 4; { expects: . S H space ... }
  putspaces(indent);
  i := pos;
  while i<llen do begin
    write(upc(line[i]));
    i := succ(i);
  end;
  writeln;
  putspaces(indent);
  underline(llen - 4,'-');
end;

proc doPP;
begin
  endip;
  emitblank;
end;

proc doBR;
begin
  flushline;
end;

proc doNF;
begin
  if debug then writeln('< doing nf >');
  endip;
  flushline;
  fillmode := false;
end;

proc doFI;
begin
  if debug then writeln('< DOING fi >');
  endip;
  flushline;
  fillmode := true;
end;

proc doRS;
begin
  endip;
  flushline;
  indent := indent + indstep;
end;

proc doRE;
begin
  endip;
  flushline;
  if indent>=indstep then
    indent := indent - indstep;
end;

proc doSP;
var n, j, s: integer;
begin
  flushline;
  { syntax: ".sp" or ".sp n" }
  s := 3;
  while (s<llen) and (line[s]=' ') do
    s:=succ(s);
  if llen>3 then
    n := parseintfrom(s)
  else n := 1;
  if n<=0 then n := 1;
  for j:=1 to n do writeln;
end;

proc doB;
var i: integer;
begin
  flushline;
  putspaces(indent);
  write(invvid); { inverse video as "bold" }

  i := 3; { ".B " }
  while i<llen do begin
    write(line[i]);
    i := succ(i);
  end;
  write(norvid);
  writeln;
end;

proc doI;
var i: integer;
begin
  flushline;
  putspaces(indent);
  i := 3; { ".I " }
  while i<llen do begin
    write(line[i]);
    i := succ(i);
  end;
  writeln;
end;

proc doIP;
var pos,col: integer;
begin
  if ipmode then begin
    indent := indent - iphang;
    ipmode := false;
  end;
  flushline;
  pos := 3;   { nach ".IP" }
  while (pos<llen) and (line[pos]=' ') do
    pos := succ(pos);

  { label ausgeben }
  putspaces(indent);
  col := indent;

  while pos<llen do begin
    write(line[pos]);
    pos := succ(pos);
    col := succ(col);
  end;

  { bis zum haenging indent ausfuellen }
  while col < (indent + iphang) do begin
    write (' ');
    col := succ(col);
  end;

  { jetzt folgt text gleich }

  preindent := true;
  indent := indent + iphang;
  ipmode := true;
end;

{ --- line reader: reads CR-terminated lines; }
{     returns false on EOF }

func readline: boolean;
begin
  llen := 0;

  repeat
    read(@src, ch);
    if ch=eof then begin
      readline := false;
      exit;
    end;

    if ch=lf then begin
    end else if ch=cr then begin
      readline := true;
      exit;
    end else begin
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
  { defaults }
  fillmode := true;
  indent := 0;
  linewidth := 47; { printed line width }
  ntab := 0;
  ipmode := false;
  ipindent := 4;
  iphang := 8;
  preindent := false;
  linecount := 0;  { added by RR }

  { get filename from arguments }
  { same pattern as compile }
  cyclus := 0; drive := 1;
  agetstring(name, default, cyclus, drive);
  if default then begin
    writeln('usage: nroff name[.cy[,drv]]');
    abort;
  end;

  asetfile(name, cyclus, drive, 'B');
  { 'B' = text }
  openr(src);

  agetval(linewidth,default); {max chars/line}
  if (linewidth<20) then linewidth := 20;
  if (linewidth>128) then linewidth :=128;
  writeln;
  write(prton);

  outlen := 0;

  while readline { and (linecount<20)} do begin
    linecount := succ(linecount);
    { writeln('line ', linecount); }
    handleline;
  end;
  handleline;
  flushline;
  write(prtoff);

 end.
