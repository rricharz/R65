program nroff;

{ mininroff            }
{ Witten March 2026    }
{ R. Richarz / ChatGPT }

uses syslib, arglib;

const
  maxline = 120;
  maxout  = 200;
  indstep = 4;

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
  linecount: integer; { added by RR }

{ --- helpers --- }

func mod(k,m:integer):integer;
begin mod:=k-((k div m)*m);
end;

func upc(c: char): char;
begin
  if (c>='a') and (c<='z') then upc := chr(ord(c)-32)
  else upc := c;
end;

proc putspaces(n: integer);
var i: integer;
begin
  for i:=1 to n do write(' ');
end;

proc flushline;
var i: integer;
begin
  if outlen>0 then begin
    putspaces(indent);
    for i:=0 to outlen-1 do write(outbuf[i]);
    writeln;
    outlen := 0;
  end;
end;

proc emitblank;
begin
  flushline;
  writeln;
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

  if c=tab8 then begin
    k := llen; { 0-based }
    spaces := 8 - (mod(k,8));
    while (spaces>0) and (llen<maxline) do begin
      line[llen] := ' ';
      llen := succ(llen);
      spaces := prec(spaces);
    end;
  end else begin
    line[llen] := c;
    llen := succ(llen);
  end;
end;

{ parse integer from line starting at pos (0-based), }
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

{ formatter: add a word to outbuf with wrapping }

proc addword(start, wlen: integer);
var need, i: integer;
begin
  { space before word if not first }
  need := wlen;
  if outlen>0 then need := need + 1;

  if (indent + outlen + need) > linewidth then begin
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
  while i<llen do begin
    while (i<llen) and isspace(line[i]) do i:=succ(i);

    if i>=llen then exit;
    wstart := i;
    wlen := 0;
    while (i<llen) and (not isspace(line[i])) do begin
      i := succ(i);
      wlen := succ(wlen);
    end;
    addword(wstart, wlen);
  end;
end;

{ --- command handlers --- }

proc doSH;
var i, pos: integer;
begin
  flushline;
  writeln;

  { print rest of line after ".SH " in uppercase }
  pos := 4; { expects: . S H space ... }
  putspaces(indent);
  i := pos;
  while i<llen do begin
    write(upc(line[i]));
    i := succ(i);
  end;
  writeln;
  writeln;
end;

proc doPP;
begin
  emitblank;
end;

proc doBR;
begin
  flushline;
end;

proc doNF;
begin
  flushline;
  fillmode := false;
end;

proc doFI;
begin
  flushline;
  fillmode := true;
end;

proc doRS;
begin
  flushline;
  indent := indent + indstep;
end;

proc doRE;
begin
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
  if llen>3 then n := parseintfrom(s) else n := 1;
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

{ --- line reader: reads CR-terminated lines; }
{     returns false on EOF }

func readline: boolean;
begin
  llen := 0;

  repeat
    read(@src, ch);
    if ch=eof then begin
      { if already collected chars, return them }
      if llen>0  then readline:=true
      else readline := false;
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
    if (llen>=3) and (line[1]='S') and (line[2]='H')
      then doSH
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
    else if (llen>=2) and (line[1]='B') then doB
    else if (llen>=2) and (line[1]='I') then doI
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
  linewidth := 40; { R65 display width (40 columns) }
  linecount := 0;  { added by RR }

  { get filename from arguments }
  { same pattern as compile }
  cyclus := 0; drive := 1;
  agetstring(name, default, cyclus, drive);
  if default then begin
    writeln('usage: nroff name[.cy[,drv]]');
    abort;
  end;

  asetfile(name, cyclus, drive, 'T'); { 'T' = text }
  openr(src);
  writeln;

  outlen := 0;

  while readline { and (linecount<20)} do begin
    linecount := succ(linecount);
    { writeln('line ', linecount); }
    handleline;
  end;
  flushline;

 end.


