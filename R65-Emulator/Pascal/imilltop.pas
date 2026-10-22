{ IMILLTOP:P Common include file for MILL/TEKMILL }

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
  PROTOCOL: file;
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
  carg: integer;
  firstredraw: boolean;
  marks:boolean;
  neighbor: array[95] of integer;

proc quit;forward;

proc setemptysquares;
{*******************}
var sq,i,base: integer;
    empty: boolean;
begin
  for sq:=0 to 2 do begin
    base:=sq shl 3;
    empty:=true;

    for i:=base to base+7 do
      if board[i]<>EMPTY then
        empty:=false;

    emptysquare[sq]:=empty;
  end;
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
  writeln(@PROTOCOL);
  if player=WHITE then
    writeln(@PROTOCOL,'HUMAN TURN WHITE')
  else
    writeln(@PROTOCOL,'HUMAN TURN BLACK');
end;

proc protocolcomputer(player: integer);
{**************************************}
begin
  writeln(@PROTOCOL);
  if player=WHITE then
    writeln(@PROTOCOL,'COMPUTER TURN WHITE')
  else
    writeln(@PROTOCOL,'COMPUTER TURN BLACK');
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
    _abort;
  end;

  if not strbegins(s,'MILL2 ') then begin
    writeln(INVVID,'Bad MILL state',NORVID);
    quit;
    _abort;
  end;

  if not strbegins(s,'MILL2 B') then begin
    writeln(INVVID,'Next turn is not PLAYER');
    writeln('Paste a state starting with MILL2 B',
        NORVID);
    quit;
    _abort;
  end;

  if s[6]='W' then
    player:=WHITE
  else if s[6]='B' then
    player:=BLACK
  else begin
    writeln('BAD PLAYER');
    quit;
    _abort;
  end;

  player:=otherplayer(player);

  if (s[8]<'0') or (s[8]>'9')
    or (s[10]<'0') or (s[10]>'9') then begin
    writeln('BAD RESERVE');
    quit;
    _abort;
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
        _abort;
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

proc screenmessage(s:cpnt); forward;

proc loadgame;
{************}
var name,fullname,line: cpnt;
    msg,last1,last2: cpnt;
    i,length,resume: integer;
    dummy: boolean;
    f: file;
    ateof: boolean;

  proc compact(s,dest:cpnt);
  {************************}
  var i: integer;
  begin
    dest[0]:=ENDMARK;

    { skip ACTION }
    i:=7;

    { copy action number }
    while (s[i]>='0') and (s[i]<='9') do begin
      write(@dest,s[i]);
      i:=i+1;
    end;

    { skip spaces }
    while s[i]=' ' do i:=i+1;

    { copy player initial }
    write(@dest,' ',s[i]);

    { skip player name }
    while (s[i]<>' ') and
          (s[i]<>ENDMARK) do i:=i+1;
    while s[i]=' ' do i:=i+1;

    { skip PLACE or MOVE }
    while (s[i]<>' ') and
          (s[i]<>ENDMARK) do i:=i+1;
    while s[i]=' ' do i:=i+1;

    { copy position or move }
    write(@dest,' ');
    while (s[i]<>' ') and
          (s[i]<>ENDMARK) do begin
      write(@dest,s[i]);
      i:=i+1;
    end;

    { optional TAKE }
    if s[i]=' ' then begin
      while s[i]=' ' do i:=i+1;

      if (s[i]='T') and (s[i+1]='A') then begin
        { skip TAKE }
        while (s[i]<>' ') and
              (s[i]<>ENDMARK) do i:=i+1;
        while s[i]=' ' do i:=i+1;

        write(@dest,'/');
        while (s[i]<>' ') and
              (s[i]<>ENDMARK) do begin
          write(@dest,s[i]);
          i:=i+1;
        end;
      end;
    end;
  end;

begin
  name:=_new;
  fullname:=_new;
  line:=_new;
  msg:=_new;
  last1:=_new;
  last2:=_new;

  name[0]:=ENDMARK;
  fullname[0]:=ENDMARK;
  msg[0]:=ENDMARK;
  last1[0]:=ENDMARK;
  last2[0]:=ENDMARK;

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
    screenmessage('Empty MILL file');
    quit;
    _abort;
  end;

  while strbegins(line,'ACTION ') do begin
    { retain the last two actions }
    last1[0]:=ENDMARK;
    write(@last1,last2);
    compact(line,last2);

    length:=_strread(f,line,ateof);

    if length=0 then begin
      screenmessage('Missing MILL state');
      quit;
      _abort;
    end;
  end;

  resume:=-1;

  if strbegins(line,'RESUME ') then begin
    action:=0;
    i:=7;
    while (line[i]>='0') and
          (line[i]<='9') do begin
      action:=10*action+ord(line[i])-ord('0');
      i:=i+1;
    end;

    resume:=action;
    length:=_strread(f,line,ateof);
    action:=action-1;
  end;

  if not strbegins(line,'MILL2 ') then begin
    screenmessage('Bad MILL state');
    quit;
    _abort;
  end;

  decodestate(line,player);
  setemptysquares;

  { construct compact loading information }
  if last1[0]<>ENDMARK then
    write(@msg,last1,' -> ');

  if last2[0]<>ENDMARK then
    write(@msg,last2);

  if resume>=0 then
    write(@msg,'  RESUME ',resume);

  screenmessage(msg);

  close(f);
  _release(last2);
  _release(last1);
  _release(msg);
  _release(line);
  _release(fullname);
  _release(name);
end;

func isneighbor(p1,p2: integer): boolean;
{*************************************}
var i,base: integer;
begin
  base:=p1*MAXNEIGHBORS;

  for i:=0 to MAXNEIGHBORS-1 do
    if neighbor[base+i]=p2 then begin
      isneighbor:=true;
      exit;
    end;

  isneighbor:=false;
end;

 