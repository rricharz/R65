program fixup;
{ Sceleton to fixup a pascal source file }
{ does not do naything at present }

{$U+}

uses syslib, arglib, strlib, filelib;

var debug:           boolean;
    sline:           cpnt;
    numlines:        integer;
    linesfixed:      integer;
    iseof, iserror:  boolean;
    fno, ofno:       file;
    name:            array[15] of char;
    lline, lstring:  integer;
    modified:        boolean;

proc setsubtype(subtype:char);
{ set subtype in name if not already there }
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
    (name[i]=' ') or (i>=14);
  if name[i]<>':' then begin
    name[i]:=':';
    name[i+1]:=subtype;
  end;
end;

proc openfiles;
var default: boolean;
    i, cyclus, drive: integer;
begin
  drive   := 1;
  cyclus  := 0;
  default := true;
  _agetstring(name, default, cyclus, drive);
  setsubtype('P');
  _asetfile(name, cyclus, drive, ' ');
  openr(fno);
  writeln;
  if debug then writeln('$$$ Input file open $$$');
  cyclus := 0;
  if debug then begin
    for i := 1 to 14 do
      name[14 - i] := name [13 - i];
    name[0] := 'F';
  end;
  _asetfile(name, cyclus, drive, ' ');
  openw(ofno);
  if debug then writeln('$$$ Output file open $$$');
end;

proc closefiles;
begin
  close(fno);
  write(@ofno,EOF);
  close(ofno);
  if debug then writeln('$$$ Files closed $$$');
end;

func readline(input: file): boolean;
var ch1: char;
    pos: integer;
begin
  pos := 0;
  read(@fno,ch1);
  sline[0] := ENDMARK;
  while (ch1 >= ' ') and (ch1 < EOF) and
      (pos<(STRSIZE - 2)) do begin
    sline[pos] := ch1;
    pos := pos + 1;
    read(@fno, ch1);
  end;
  sline[pos] := ENDMARK;
  readline:= (ch1 = EOF);
end;

func find(s: cpnt; start: integer): boolean;
var i, st: integer;
begin
  st := start;
  if ((lline + start) >= lstring) then begin
    i := 0;
    while ((sline[st] = s[i]) and (i < lstring))
    do begin
      i  := succ(i);
      st := succ(st);
    end;
    find := (i = lstring);
  end else find := false;
end;

func isletter(ch:char): boolean;
begin
  isletter := ((ch>='A') and (ch<='Z')) or
              ((ch>='a') and (ch<='z'));
end;

proc upper(s: cpnt);
var found: boolean;
    i, start: integer;
begin
  lstring := _strlen(s);
  i := 0;
  repeat
    if i>0 then
      found := find(s, i)
        and (not isletter(sline[i-1]))
        and (not isletter(sline[i+lstring]))
    else
     found := find(s, i);
    i := i+1;
  until found or (i > lline - lstring);
  if found then begin
    start := i - 1;
    modified := true;
    for i:=0 to lstring - 1 do
      if ((sline[i+start]>='a') and
               (sline[i+start]<='z')) then
        sline[i+start] := chr(ord(s[i]) - 32);
    upper(s); { recursive: fix more on same line }
  end;
end;

proc underscore(s: cpnt);
var found: boolean;
    i, start: integer;
    ch : char;
begin
  lstring := _strlen(s);
  i := 0;
  repeat
    if i>0 then
      found := (find(s, i) and (sline[i-1] <> '_'))
        and (not isletter(sline[i-1]))
        and (not isletter(sline[i+lstring]))
    else
      found := find(s, i);
    i := i+1;
  until found or (i > lline - lstring);
  if found then begin
    start := i - 1;
    modified := true;
    _strinsc('_', start, sline);
    { recursive: fix more on same line }
    underscore(s);
  end;
end;

proc fixup_line;
begin
  lline := _strlen(sline);
  modified := false;
end;

proc putline;
var pos: integer;
begin
  pos := 0;
  while ((sline[pos] <> ENDMARK) and
    (pos < STRSIZE)) do begin
    write(@ofno, sline[pos]);
    pos := pos + 1;
  end;
  if not iseof then write(@ofno, CR);
end;

proc showline(show_number: boolean);
begin
  if show_number then write(numlines,' ');
  writeln(sline);
end;

begin
  debug := false;
  openfiles;
  sline := _new;
  numlines := 1;
  linesfixed := 0;
  iserror := false;
  iseof := false;
  while not (iseof or iserror) do begin
    iseof := readline(fno);
    showline(true);
    fixup_line;
    if modified then begin
      write('>>>');
      showline(false);
      linesfixed := succ(linesfixed);
    end;
    putline;
    numlines := succ(numlines);
  end;
  if iserror then begin
    writeln(INVVID, 'ERROR on line ',
      numlines - 1, NORVID);
    showline(false);
  end else
    writeln('Lines fixed ', linesfixed);
  closefiles;
end.
