program view;
uses syslib, arglib, filelib, writelib;

{ written 2026 by rricharz and ChatGPT }

{$U+} { do not allow shadowing or duplicates }

const
      MAXLINES = 1024;
      MINFREE  = 512;
      PAGELEN  = 15;
      LINEMAX  = 56;
      FINDCOL  = 28;
      FINDMAX  = 27;

      { control characters }
      CLRSCR   = chr($11);
      ENDMARK  = chr($00);

      { key codes }
      KESC     = chr(00); { read(@KEY) gives this }
      KUP      = chr(26);
      KDOWN    = chr(24);
      KLEFT    = chr(03);
      KRIGHT   = chr(22);
      KENTER   = chr(13);
      KBS      = chr(127);

var  lineptr: array[MAXLINES] of cpnt;
     nlines: integer;
     topline: integer;
     findline: integer;
     findpos: integer;
     findactive: boolean;
     filename: cpnt;
     findstr, findsav: cpnt;
     key: char;
     stop: boolean;
     f_in: file;
     line: cpnt;

{ ***** freemem ***** }

func freemem: integer;
mem  sp     = $0008: integer;
     endstk = $000e: integer;
begin
  freemem := endstk - sp;
end;

{ ***** strlen: length of 0-ended string ***** }

func strlen(s: cpnt): integer;
var i: integer;
begin
  i:=0;
  while s[i]<>ENDMARK do i:=i+1;
  strlen:=i;
end;

{ ***** findat: find pat in s from start ***** }
{ returns 0 if not found, else 1-based pos }

func findat(s,pat: cpnt;
    start,patlen: integer): integer;
var i,j: integer;
begin
  if patlen=0 then begin
    findat:=start;
    exit
  end;

  if start<1 then begin
    _abort;
  end;

  i:=start-1;
  while s[i]<>ENDMARK do begin
    if s[i]=pat[0] then begin
      j:=1;
      while (j<patlen) and
          (s[i+j]=pat[j]) do j:=j+1;
      if j=patlen then begin
        findat:=i+1;
        exit
      end;
    end;
    i:=i+1;
  end;

  findat:=0;
end;

{ ***** findtext: search through file ***** }

func findtext(startline,startpos: integer;
          pat: cpnt; patlen: integer;
          wrap: boolean;
          var foundline,foundpos: integer): boolean;
var i,p: integer;
    line0: cpnt;
begin
  if patlen=0 then begin
    foundline:=startline;
    foundpos:=startpos;
    findtext:=true;
    exit
  end;

  i:=startline;
  while i<=nlines do begin
    line0:=lineptr[i-1];

    if line0[0]<>ENDMARK then begin
      if i=startline then
        p:=findat(line0,pat,startpos,patlen)
      else
        p:=findat(line0,pat,1,patlen);

      if p<>0 then begin
        foundline:=i;
        foundpos:=p;
        findtext:=true;
        exit
      end;
    end;

    i:=i+1;
  end;

  if wrap then begin
    i:=1;
    while i<startline do begin
      line0:=lineptr[i-1];

      if line0[0]<>ENDMARK then begin
        p:=findat(line0,pat,1,patlen);

        if p<>0 then begin
          foundline:=i;
          foundpos:=p;
          findtext:=true;
          exit
        end;
      end;

      i:=i+1;
    end;
  end;

  findtext:=false;
end;

{ ***** allocate: exact-length heap alloc ***** }

func allocate(size: integer): cpnt;
mem  endstk = $000e: integer;
var  str:cpnt;
begin
  endstk := endstk - (size + 1);
  str := cpnt(endstk);
  str[0] := ENDMARK;
  allocate := str;
end;

{ ***** copy: copy cpnt string ***** }

proc copy(strin, strout:cpnt);
var i: integer;
begin
  i := 0;
  while strin[i] <> ENDMARK do begin
    strout[i] := strin[i];
    i := i + 1;
  end;
  strout[i] := ENDMARK;
end;

{ ***** readline: read line from file ***** }

func readline(f:file; s:cpnt;
          var ateof_here:boolean):integer;
var ch: char;
    i: integer;
    done: boolean;
begin
  ateof_here := false;
  i := 0;
  done := false;
  while not done do begin
    read(@f, ch);
    if ch = EOF then begin
      ateof_here := true;
      done := true;
    end;
    if (not done) and (ch = CR) then
      done := true;
    if not done then
      if i < LINEMAX then begin
        s[i] := ch;
        i := i + 1;
      end;
  end;
  s[i] := ENDMARK;
  readline := i;
end;

{ ***** init ***** }

proc init;
begin
  nlines:=0;
  topline:=1;
  findline:=0;
  findpos:=0;
  findactive:=false;

  filename := allocate(16);
  findstr  := allocate(FINDMAX);
  findsav  := allocate(FINDMAX);
  line     := allocate(LINEMAX);

end;

{ ***** openinput ***** }

proc openinput;
var aname: array[15] of char;
    cyclus, drive: integer;
    default: boolean;
    i: integer;

  proc setsubtype(subtype:char);
  begin
    i:=0;
    repeat
      i:=i+1;
    until (aname[i]=':') or
      (aname[i]=' ') or (i>=14);
    if aname[i]<>':' then begin
      aname[i]:=':';
      aname[i+1]:=subtype;
    end;
  end;

begin
  cyclus:=0; drive:=1;
  _agetstring(aname,default,cyclus,drive);
  setsubtype('P');
  _asetfile(aname,cyclus,drive,' ');
  openr(f_in);

  for i:=0 to 15 do
    if FILNAM[i] = ' ' then
      filename[i] := ENDMARK
    else
      filename[i] := FILNAM[i];
  filename[16] := ENDMARK;
  write(@filename,'.',hexb(FILCYC));
end;

{ ***** readinput ***** }

proc readinput;
var len: integer;
    ateof: boolean;
begin
  openinput;
  ateof := false;
  while not ateof do begin
    len := readline(f_in, line, ateof);

    if (freemem < MINFREE + LINEMAX + 16) or
       (nlines >= MAXLINES) then begin
      writeln('Cannot read more than ',
        MAXLINES,' lines.');
      close(f_in);
      _abort;
    end;

    lineptr[nlines] := allocate(len);
    copy(line, lineptr[nlines]);
    nlines := nlines + 1;
  end;
  close(f_in);
end;

{ ***** setnumlin ***** }

proc setnumlin(l,c:integer);
mem numlin=$1789: integer&;
    numchr=$178a: integer&;
begin
  numlin:=l; numchr:=c;
end;

{ ***** enter56mode ***** }

proc enter56mode;
begin
  setnumlin($10,$37);
  write(HOM,CLRSCR);
end;

{ ***** exit56mode ***** }

proc exit56mode;
begin
  setnumlin($29,$2f);
  write(HOM,CLRSCR);
end;

{ ***** movecursor ***** }

proc movecursor(x, y: integer);
const asetcur = $e2e2;
mem curlin  = $ed: integer&;
    curpos  = $ee: integer&;
begin
  curpos := x;
  curlin := y;
  call(asetcur);
end;

{ ***** hidecursor ***** }

proc hidecursor;
begin
  movecursor(0, PAGELEN + 1);
end;

{ ***** drawstatus ***** }

proc drawstatus;
var i,len: integer;
begin
  movecursor(0,0);
  write(INVVID);

  for i:=1 to 7 do write('        ');

  movecursor(0,0);
  write(topline,'/',nlines);

  movecursor(8,0);
  write(filename);

  movecursor(FINDCOL-1,0);
  write('/');

  len:=strlen(findstr);
  if len>0 then begin
    movecursor(FINDCOL,0);
    write(findstr);
  end;

  write(NORVID);
end;

{ ***** drawpage ***** }

proc drawpage;
var i, lastline, scrline: integer;
begin
  lastline := topline + (PAGELEN - 1);
  if lastline > nlines then
    lastline := nlines;

  scrline := 1;
  for i := topline - 1 to lastline - 1 do begin
    movecursor(0,scrline);
    write(CLRLIN,lineptr[i]);

    if findactive and (i+1 = findline) then begin
      movecursor(findpos-1,scrline);
      write(INVVID,findstr,NORVID);
    end;

    scrline := scrline + 1;
  end;

  while scrline <= PAGELEN do begin
    movecursor(0,scrline);
    write(CLRLIN);
    scrline := scrline + 1;
  end;

  hidecursor;
end;

{ ***** updatescreen ***** }

proc updatescreen;
begin
  drawstatus;
  drawpage;
end;

{ ***** startview ***** }

proc startview;
begin
  enter56mode;
  hidecursor;
  updatescreen;
end;

{ ***** stopview ***** }

proc stopview;
begin
  exit56mode;
end;

{ ***** moveline ***** }

proc moveline(delta: integer);
var lasttop: integer;
begin
  topline := topline + delta;

  lasttop := nlines - PAGELEN + 1;
  if lasttop < 1 then lasttop := 1;
  if topline > lasttop then topline := lasttop;
  if topline < 1 then topline := 1;

  updatescreen;
end;

{ ***** drawfindfield ***** }

proc drawfindfield(pos: integer);
var len,i: integer;
begin
  len := strlen(findstr);

  movecursor(FINDCOL,0);
  write(NORVID);

  i := 0;
  while i < len do begin
    write(findstr[i]);
    i := i + 1;
  end;

  while i < FINDMAX do begin
    write(' ');
    i := i + 1;
  end;

  write(INVVID,' ');
  movecursor(FINDCOL + pos,0);
end;

{ ***** appendfindchar ***** }

proc appendfindchar(ch: char; var len,pos: integer);
begin
  if len < FINDMAX then begin
    findstr[len] := ch;
    len := len + 1;
    pos := len;
    findstr[len] := ENDMARK;
  end;
end;

{ ***** backspacefind ***** }

proc backspacefind(var len,pos: integer);
begin
  if len > 0 then begin
    len := len - 1;
    pos := len;
    findstr[len] := ENDMARK;
  end;
end;

{ ***** editfindfield ***** }

func editfindfield: boolean;
var key0: char;
    len,pos: integer;
    accept, done: boolean;
begin
  copy(findstr,findsav);

  len := strlen(findstr);
  pos := len;
  done := false;
  accept := false;

  drawfindfield(pos);

  while not done do begin
    read(@KEY, key0);

    case key0 of

    KENTER:
      begin
        accept := true;
        done := true;
      end;

    KESC:
      begin
        copy(findsav,findstr);
        accept := false;
        done := true;
      end;

    KBS:
      begin
        backspacefind(len,pos);
        drawfindfield(pos);
      end

    else
      begin
        if (key0 >= ' ') and (key0 <> chr($7f)) then
        begin
          appendfindchar(key0,len,pos);
          drawfindfield(pos);
        end;
      end

    end;
  end;

  drawstatus;
  editfindfield := accept;
end;

{ ***** searchfirst ***** }

func searchfirst: boolean;
var patlen: integer;
    foundline,foundpos: integer;
    startline,startpos: integer;
    lasttop: integer;
begin
  patlen := strlen(findstr);
  if patlen = 0 then begin
    searchfirst := false;
    exit
  end;

  if findactive then begin
    startline := findline;
    startpos  := findpos;
  end
  else begin
    startline := 1;
    startpos  := 1;
  end;

  if findtext(startline,startpos,findstr,patlen,
      true, foundline,foundpos) then begin
    findline := foundline;
    findpos  := foundpos;
    findactive := true;

    topline := findline - (PAGELEN div 2);
    lasttop := nlines - PAGELEN + 1;
    if lasttop < 1 then lasttop := 1;
    if topline < 1 then topline := 1;
    if topline > lasttop then topline := lasttop;

    searchfirst := true;
  end
  else
    searchfirst := false;
end;

{ ***** searchnext ***** }

func searchnext: boolean;
var patlen: integer;
    foundline,foundpos: integer;
    startline,startpos: integer;
    lasttop: integer;
begin
  if not findactive then begin
    searchnext := false;
    exit
  end;

  patlen := strlen(findstr);
  if patlen = 0 then begin
    searchnext := false;
    exit
  end;

  startline := findline;
  startpos  := findpos + 1;

  if findtext(startline,startpos,findstr,patlen,
      true, foundline,foundpos) then begin
    findline := foundline;
    findpos  := foundpos;
    findactive := true;

    topline := findline - (PAGELEN div 2);
    lasttop := nlines - PAGELEN + 1;
    if lasttop < 1 then lasttop := 1;
    if topline < 1 then topline := 1;
    if topline > lasttop then topline := lasttop;

    searchnext := true;
  end
  else
    searchnext := false;
end;

{ ***** shownotfound ***** }

proc shownotfound;
begin
  { placeholder }
end;

{ ***** dofind ***** }

proc dofind;
begin
  if editfindfield then begin
    if searchfirst then updatescreen
    else shownotfound;
  end;
  hidecursor;
end;

{ ***** donextfind ***** }

proc donextfind;
begin
  if findactive then begin
    if searchnext then updatescreen
    else shownotfound;
  end;
end;

{ ***** dohelp ***** }

proc dohelp;
var ch: char;
begin
  movecursor(0,1);
  write(CLRLIN,'VIEW keys');

  movecursor(0,2); write(CLRLIN);

  movecursor(0,3);
  write(CLRLIN,'q  ESC        quit');

  movecursor(0,4);
  write(CLRLIN,'UP  DOWN      move line');

  movecursor(0,5);
  write(CLRLIN,'LEFT RIGHT    page with overlap');

  movecursor(0,6);
  write(CLRLIN,'/  f          find string');

  movecursor(0,7);
  write(CLRLIN,'n             next hit');

  movecursor(0,8);
  write(CLRLIN,'h  ?          help');

  movecursor(0,9); write(CLRLIN);

  movecursor(0,10);
  write(CLRLIN,'Find field keys');
  movecursor(0,11); write(CLRLIN);

  movecursor(0,12);
  write(CLRLIN,'type chars    append');

  movecursor(0,13);
  write(CLRLIN,'BS            delete last char');

  movecursor(0,14);
  write(CLRLIN,'ENTER         accept');

  movecursor(0,15);
  write(CLRLIN,'ESC           cancel');

  hidecursor;
  read(@KEY,ch);
  updatescreen;
end;

{ ***** handlekey ***** }

proc handlekey;
begin
  case key of
  KESC,'q':  stop:=true;
  KUP:       moveline(-1);
  KDOWN:     moveline(+1);
  KLEFT:     moveline(-(2 * PAGELEN) div 3);
  KRIGHT:    moveline(+(2 * PAGELEN) div 3);
  '/','f':   dofind;
  'n':       donextfind;
  'h','?':   dohelp
  else
    { ignore }
  end {case};
end;

{ ***** mainloop ***** }

proc mainloop;
begin
  stop  := false;
  while not stop do begin
    read(@KEY, key);
    handlekey;
  end;
end;

{ ***** main program ***** }

begin
  write(PRTOFF);
  init;
  readinput;
  startview;
  mainloop;
  stopview;
end.
