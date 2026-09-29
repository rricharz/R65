const
  DUALPLAYER   = false;
  NPOSITIONS   = 24;
  NSTONES      = 9;
  NMILLS       = 16;
  MAXNEIGHBORS = 4;
  EMPTY = 4;

mem
  ARGTYPE = $00a0: array[31] of char&;

var
  board: array[23] of integer;
  stones, captured: array[BLACK] of integer;
  label:    array[23] of packed char;
  DEBUG: file;
  player,action: integer;

  startmin,startsec,starttenmillis: integer;

  emptysquare: array[2] of boolean;
  lastplace, specialplace: integer;

  previousstate: cpnt;
  previousaction: cpnt;
  computeraction: cpnt;
  aitime: real;
  i: integer;
  test: integer;
  automode: boolean;
  carg: integer;

proc quit;
{********}
var result: integer;
const C_SHELL = 10;
      C_FLUSHPRINT = 13;
      C_NEWPRINT = 14;

  proc shell(s: cpnt);
  { uses flp scratch register to transfer pointer }
  mem   str    = $0004: cpnt;
  var result:   integer;
  begin
    str := s;
    result:=_emulator(C_SHELL);
  end;

begin
  if DEBUG<>NULLDEV then begin
    result := _emulator(C_FLUSHPRINT);
    shell('./backup_print mill');
    result := _emulator(C_NEWPRINT);
  end;
  _abort;
end;

func otherplayer(player:integer):integer;
{***************************************}
begin
  if player=WHITE then
    otherplayer:=BLACK
  else
    otherplayer:=WHITE;
end;

proc protocolhuman(player: integer);
{***********************************}
begin
  writeln(@DEBUG);
  writeln(@DEBUG,
    '==============================================');

  if player=WHITE then
    writeln(@DEBUG,'HUMAN TURN WHITE')
  else
    writeln(@DEBUG,'HUMAN TURN BLACK');

  { later: write canonical STATE line here }
end;

proc protocolcomputer(player: integer);
{**************************************}
begin
  writeln(@DEBUG);

  if player=WHITE then
    writeln(@DEBUG,'COMPUTER TURN WHITE')
  else
    writeln(@DEBUG,'COMPUTER TURN BLACK');
end;

func strbegins(s,prefix:cpnt):boolean;
{************************************}
begin
  strbegins:=_strncmp(s,prefix,_strlen(prefix))=0;
end;

func digit(c:char):integer;
{*************************}
begin
  digit:=ord(c)-ord('0');
end;

func boardstones(player: integer): integer;
{*****************************************}
var i, count: integer;
begin
  count:=0;
  for i:=0 to 23 do
    if board[i]=player then count:=count+1;
  boardstones:=count;
end;

proc codestate(s: cpnt; player: integer);
{***************************************}
{ player identifies the side whose turn has just
  been completed.  Restartable MILL games use
  MILL2 B, since play always resumes with WHITE. }
var i: integer;
begin
  s[0]:=ENDMARK;

  write(@s,'MILL2 ');

  if player=WHITE then
    write(@s,'W ')
  else
    write(@s,'B ');

  write(@s,stones[WHITE],' ',
           stones[BLACK],' ');

  for i:=0 to 23 do
    if board[i]=WHITE then
      write(@s,'W')
    else if board[i]=BLACK then
      write(@s,'B')
    else
      write(@s,'-');
end;

proc decodestate(s: cpnt; var player: integer);
{*********************************************}
var i,len: integer;
    c: char;

begin
  { format:
    MILL1 W 0 0 ------------------------
    0123456789012
                ^ board starts here
  }

  len:=_strlen(s);
  while (len>0) and (s[len-1]=' ') do begin
    len:=len-1;
    s[len]:=ENDMARK;
  end;

  if _strlen(s)<>36 then begin
    writeln(INVVID,'Bad state length',NORVID);
    quit;
  end;

  if not strbegins(s,'MILL2 ') then begin
    writeln(INVVID,'Bad MILL state',NORVID);
    quit;
  end;

  if not strbegins(s,'MILL2 B') then begin
    writeln(INVVID,'Next turn is not PLAYER');
    writeln('Paste a state starting with MILL2 B',
        NORVID);
    quit;
  end;

  if s[6]='W' then
    player:=WHITE
  else if s[6]='B' then
    player:=BLACK
  else begin
    writeln('BAD PLAYER');
    quit;
  end;

  if (s[8]<'0') or (s[8]>'9')
    or (s[10]<'0') or (s[10]>'9') then begin
    writeln('BAD RESERVE');
    quit;
  end;

  stones[WHITE]:=digit(s[8]);
  stones[BLACK]:=digit(s[10]);

  for i:=0 to 23 do begin
    c:=s[12+i];

    case c of
      'W': board[i]:=WHITE;
      'B': board[i]:=BLACK;
      '-': board[i]:=EMPTY
    else
      begin
        writeln('BAD BOARD');
        quit;
      end
    end
  end;

  { captured[player] means opponent stones
    already captured by PLAYER }
  captured[WHITE]:=
    9-stones[BLACK]-boardstones(BLACK);

  captured[BLACK]:=
    9-stones[WHITE]-boardstones(WHITE);
end;

proc savegame(name: cpnt; player: integer);
{*****************************************}
var f: file;
    filename, line: cpnt;
    i: integer;
    c: char;
begin
  line:=_new;
  filename:=_new;
  filename[0]:=ENDMARK;

  i:=0;
  while name[i]<>ENDMARK do begin
    c:=name[i];
    if not (((c>='A') and (c<='Z')) or
           ((c>='0') and (c<='9'))) then
      name[i]:='X';
    i:=i+1;
  end;
  write(@filename,'MILL',name,':B');

  _strfio(filename,0,1);
  openw(f);

  if previousaction[0]<>ENDMARK then
    writeln(@f,previousaction);
  if computeraction[0]<>ENDMARK then
    writeln(@f,computeraction);
  writeln(@f,'RESUME ',action);
  codestate(line, otherplayer(player));
  writeln(@f,line);

  close(f);

  if previousstate[0]<>ENDMARK then begin
    filename[0]:=ENDMARK;
    write(@filename,'MILL',name,'P:B');

    _strfio(filename,0,1);
    openw(f);
    if previousaction[0]<>ENDMARK then
      writeln(@f,previousaction);
    if computeraction[0]<>ENDMARK then
      writeln(@f,computeraction);
    writeln(@f,'RESUME ',action-2);

    writeln(@f,previousstate);
    close(f);
  end;

  _release(filename);
  _release(line);
end;

proc loadgame;
{************}
var name,fullname,line: cpnt;
    i,length: integer;
    dummy: boolean;
    f: file;
    ateof: boolean;
begin
  name:=_new;
  fullname:=_new;
  line:=_new;

  _sgetstring(name,carg,dummy);

  if strbegins(name,'MILL') then
    write(@fullname,name)
  else
    write(@fullname,'MILL',name);

  _ssetsubtype(fullname,'B',true);
  _strfio(fullname,0,1);
  openr(f);

  length:=_strread(f,line,ateof);

  if length=0 then begin
    writeln('Empty MILL file');
    quit;
  end;

  while strbegins(line,'ACTION ') do begin
    writeln(line);
    length:=_strread(f,line,ateof);

    if length=0 then begin
      writeln(INVVID,'Missing MILL state',NORVID);
      quit;
    end;
  end;

  if strbegins(line,'RESUME ') then begin
    action:=0;
    i:=7;
    while (line[i]>='0') and (line[i]<='9') do begin
      action:=10*action+ord(line[i])-ord('0');
      i:=i+1;
    end;
    length:=_strread(f,line,ateof);
    writeln('RESUME ',action);
    action:=action-1;
  end;

  if not strbegins(line,'MILL2 ') then begin
    writeln(INVVID,'Bad MILL state',NORVID);
    quit;
  end;

  decodestate(line,player);

  close(f);
  _release(line);
  _release(fullname);
  _release(name);
end;
 