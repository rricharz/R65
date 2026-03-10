program fixup;
{ Fixup a pascal source file }
uses syslib,arglib,strlib;

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
  if (ch1 = EOF) then begin
    readline := true;
    exit;
  end;
  while (ch1 >= ' ') and (pos<(STRSIZE - 2)) do begin
    sline[pos] := ch1;
    {write(pos, ': ', ch1);}
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

{ syslib }
  upper('numarg');
  upper('aglists');
  upper('arglist');
  upper('argtype');
  upper('filflg');
  upper('fildrv');
  upper('filcyc');
  upper('filcy1');
  upper('filnam');
  upper('filnm1');
  upper('filstp');
  upper('tab8');
  upper('hom');
  upper('csv');
  upper('lf');
  upper('ff');
  upper('cr');
  upper('lf');
  upper('norvid');
  upper('invvid');
  upper('prton');
  upper('prtoff');
  upper('mmaxseq');
  upper('topmem');
  upper('maxint');
  upper('input');
  upper('output');
  upper('key');
  upper('printer');
  upper('runerr');
  upper('endstk');
  upper('buffpn');
  upper('iocheck');
{ arglib }
  upper('numarg');
  upper('arglist');
  upper('arglists');
  upper('argtype');
  upper('curpos');
  upper('maxseq');
  upper('fidrtb');
{ strlib }
  upper('strsize');
  upper('endmark');
{ plotlib }
  { upper('xsize'); }
  upper('ysize');
  upper('xwords');
  upper('white');
  upper('inverse');
  upper('black');
  upper('plotdev');
  upper('keypressed');
{ teklib }
  upper('maxx');
  upper('maxy');
  upper('maxcolumns');
  upper('maxlines');
  upper('solid');
  upper('dotted');
  upper('dotdash');
  upper('shortdash');
  upper('longdash');
  upper('plotter');
{ ralib }
  upper('fread');
  upper('fwrite');
  upper('fnew');
{ wildlib }
  upper('numentries');
  upper('namesize');

{ syslib }
  underscore('setemucom');
  underscore('getbcd');
  underscore('getdate');
  underscore('abs');
  underscore('mod');
  underscore('tab');
  underscore('abort');
  underscore('prtext8');
  underscore('prtext16');
  underscore('random');
{ arglib }
  underscore('argerror');
  underscore('agetval');
  underscore('agetstring');
  underscore('uppercase');
  underscore('asetfile');
  underscore('runerr');
  underscore('carg');
{ strlib }
  underscore('new');
  underscore('release');
  underscore('strlen');
  underscore('strcopy');
  underscore('stradd');
  underscore('strcmp');
  underscore('strpos');
  underscore('strread');
  underscore('hexstr');
  underscore('strinsc');
  underscore('strdelch');
  underscore('intstr');
{plotlib }
  underscore('delay');
  underscore('syncscreen');
  underscore('grinit');
  underscore('grend');
  underscore('cleargr');
  underscore('fullview');
  underscore('splitview');
  underscore('plot');
  underscore('move');
  underscore('draw');
  underscore('plotmap');
  underscore('waitforkey');
{ teklib }
  underscore('clearscreen');
  underscore('starttek');
  underscore('endtek');
  underscore('startdraw');
  underscore('enddraw');
  underscore('draw');
  underscore('drawrectangle');
  underscore('drawvector');
  underscore('moveto');
  underscore('delay10msec');
  underscore('setchsize');
  underscore('setlinemode');
{ ralib }
  underscore('uppercase');
  underscore('attach');
  underscore('getsize');
  underscore('getword');
  underscore('putword');
  underscore('getreal');
  underscore('putreal');
{ wildlib }
  underscore('test');
  underscore('findentry');
  underscore('writename');
{ disklib }
  underscore('freedsk');

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
