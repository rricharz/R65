program mill;

uses plotlib, syslib, strlib, striolib;

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

  startsec,starttenmillis: integer;

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
var i: integer;
    c: char;

begin
  { format:
    MILL1 W 0 0 ------------------------
    0123456789012
                ^ board starts here
  }

  if _strlen(s)<>36 then begin
    writeln('BAD STATE LENGTH');
    _abort;
  end;

  if not strbegins(s,'MILL2 ') then begin
    writeln('BAD MILL STATE');
    _abort;
  end;

  if s[6]='W' then
    player:=WHITE
  else if s[6]='B' then
    player:=BLACK
  else begin
    writeln('BAD PLAYER');
    _abort;
  end;

  if (s[8]<'0') or (s[8]>'9')
    or (s[10]<'0') or (s[10]>'9') then begin
    writeln('BAD RESERVE');
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

  codestate(line, player);
  writeln(@f,line);

  close(f);
  _release(filename);
  _release(line);
end;

proc loadgame;
{************}
var name,fullname,line: cpnt;
    carg,length: integer;
    dummy: boolean;
    f: file;
    ateof: boolean;
begin
  name:=_new;
  fullname:=_new;
  line:=_new;

  carg:=0;
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
    _abort;
  end;

  decodestate(line,player);

  close(f);
  _release(line);
  _release(fullname);
  _release(name);
end;

{$I IMILLPLOT}
{$I IMILLCOMM}

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

proc debuglabels;
{****************}
var position,neighbornumber,neighborbase: integer;
    nextposition: integer;
begin
  writeln(@DEBUG);
  writeln(@DEBUG,'Board positions and neighbors');
  writeln(@DEBUG);

  for position:=0 to NPOSITIONS-1 do begin
    write(@DEBUG, label[position], ': ');

    neighborbase:=position*MAXNEIGHBORS;

    for neighbornumber:=0 to MAXNEIGHBORS-1 do begin
      nextposition:=
        neighbor[neighborbase+neighbornumber];

      if nextposition>=0 then
        write(@DEBUG, label[nextposition], ' ');
    end;

    writeln(@DEBUG);
  end;
end;

func allinmills(player: integer): boolean;
{*************************************}
var i: integer;
begin
  allinmills:=true;
  for i:=0 to 23 do
    if board[i]=player then
      if not ismill(i,player) then begin
        allinmills:=false;
        exit;
      end;
end;

proc takestone(player: integer);
{******************************}
var p1,p2,opponent: integer;
    valid: boolean;
begin
  opponent:=otherplayer(player);

  repeat
    getinput(player,I_TAKE,p1,p2);

    valid:=false;

    if board[p1]<>opponent then begin
      if board[p1]=EMPTY then
        message(3,label[p1],player)
      else
        message(4,label[p1],player);
    end

    else if ismill(p1,opponent) and
            not allinmills(opponent) then
      message(8,label[p1],player)

    else
      valid:=true;

  until valid;

  board[p1]:=EMPTY;
  clearstone(p1,player);
  captured[player]:=captured[player]+1;
  drawreserve(player);
end;

proc placestone(player:integer);
{*******************************}
var p1, p2: integer;
    valid: boolean;
begin
  repeat
    getinput(player,I_PLACE,p1,p2);

    valid:=board[p1]=EMPTY;

    if not valid then
      message(6,label[p1],player);

  until valid;

  board[p1]:=player;
  stones[player]:=stones[player]-1;
  drawstone(p1,player);
  drawreserve(player);
  protocolplace(player,p1,0,0)

  if ismill(p1,player) then
    takestone(player);
end;

func islegalmove(player,p1,p2: integer): boolean;
{**********************************************}
begin
  islegalmove:=false;

  if board[p1]<>player then
    exit;

  if board[p2]<>EMPTY then
    exit;

  if boardstones(player)=3 then begin
    islegalmove:=true;
    exit;
  end;

  if isneighbor(p1,p2) then
    islegalmove:=true;
end;

proc movestone(player:integer);
{******************************}
var p1,p2: integer;
    valid: boolean;

begin
  repeat
    getinput(player,I_MOVE,p1,p2);
    valid:=false;

    if board[p1]=EMPTY then
      message(3,label[p1],player)

    else if board[p1]<>player then begin
      if player=WHITE then
        message(5,label[p1],player)
      else
        message(4,label[p1],player);

    end else if board[p2]<>EMPTY then
      message(6,label[p2],player)

    else if (boardstones(player)>3)
                 and not isneighbor(p1,p2) then
      message(7,'  ',player)

    else
      valid:=true;

  until valid;

  board[p2]:=board[p1];
  board[p1]:=EMPTY;

  clearstone(p1,player);
  drawstone(p2,player);

  if ismill(p2,player) then
    takestone(player);
end;

func findlegalmove(player: integer;
                   var p1,p2: integer): boolean;
{***************************************************}
{ Enumerates all legal moves of PLAYER.
  Used by gameover and by the computer player.

  Initialize, set

      p1 := 0;
      p2 := -1;

  before the first call.

  Each successful call returns the next legal move
  in P1,P2. FALSE indicates that there are no more
  legal moves.                                      }

begin
  repeat
    p2:=p2+1;

    if p2>23 then begin
      p2:=0;
      p1:=p1+1;
    end;

    if p1>23 then begin
      findlegalmove:=false;
      exit;
    end;

  until islegalmove(player,p1,p2);

  findlegalmove:=true;
end;

{$I IMILLAI:P}

proc playerturn(player: integer);
{*******************************}
begin
  selectdashboard(player);

  if DUALPLAYER then begin
    protocolhuman(player);
    if stones[player]>0 then
      placestone(player)
    else
      movestone(player);
  end
  else begin
    if player=WHITE then begin
      protocolhuman(player);
      if stones[player]>0 then
        placestone(player)
      else
        movestone(player);
    end
    else begin
      message(21,'  ',player);
      strmessage('',EMPTY);
      protocolcomputer(player);
      computerturn(player);
    end;
  end;
end;

func gameover(player: integer): boolean;
{*************************************}
{ A player can only lose after all his stones have
  been placed. He loses with fewer than three stones
  or when no legal move exists. }

var p1,p2: integer;
begin
  if stones[player]>0 then begin
    gameover:=false;
    exit;
  end;

  if boardstones(player)<3 then begin
    gameover:=true;
    exit;
  end;

  p1:=0;
  p2:=-1;
  gameover:=not findlegalmove(player,p1,p2);
end;

{ main body }
{***********}

begin
  init_canvas;
  init_common;
  init_neighbors;

  writeln(@DEBUG,
    '----------------------------------------------');
  writeln(@DEBUG,'MILL initialized');

  drawboard;
  drawlabels;

  if ARGTYPE[0]='s' then loadgame;

  drawstones;
  drawreserve(WHITE);
  drawreserve(BLACK);
  _move(DASHX+1,DASHWHITEY+NAMEOFF);
  write(@PLOTDEV,'PLAYER');
  _move(DASHX+1,DASHBLACKY+NAMEOFF);
  write(@PLOTDEV,'COMPUTER');

  player:=WHITE;
  action:=0;
  repeat
    action:=action+1;
    playerturn(player);
    protocolboard;
    player:=otherplayer(player);
    if gameover(player) then begin
      message(10,'  ',player);
      message(11,'  ',otherplayer(player));
      _abort;
    end;
  until false;

end.
