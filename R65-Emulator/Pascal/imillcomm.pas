{ common section for MILL and TEKMILL }
{#####################################}

const
  LABELS =
  'A1A4A7D7G7G4G1D1B2B4B6D6F6F4F2D2C3C4C5D5E5E4E3D3';

var
  mills:    array[47] of integer;
  neighbor: array[95] of integer;
  { There is no INVERSE stone; BLACK and WHITE used }

proc computerturn(player: integer); forward;
proc init_ai; forward;

func strunc(r: real): integer;
{*************************}
begin
  if r>32767.0 then
    strunc:=32767
  else if r< -32768.0 then
    strunc:=-32768
  else
    strunc:=trunc(r);
end;

proc protocolboard;
{*****************}
var i,row,col,pos: integer;
    r,c,ch: char;
    state:cpnt;
begin

  { machine readable board }
  state:=_new;
  codestate(state,player);
  writeln(@DEBUG,state);
  _release(state);

  { human readable board }
  writeln(@DEBUG,'MATRIX');
  writeln(@DEBUG,'    1 2 3 4 5 6 7');

  for row:=6 downto 0 do begin
    r:=chr(ord('A')+row);
    write(@DEBUG,r,'   ');

    for col:=0 to 6 do begin
      c:=chr(ord('1')+col);
      pos:=findpos(packed(r,c));

      if pos<0 then
        ch:='-'
      else if board[pos]=WHITE then
        ch:='W'
      else if board[pos]=BLACK then
        ch:='B'
      else
        ch:='#';

      write(@DEBUG,ch);
      if col<6 then
        write(@DEBUG,' ');
    end;

    writeln(@DEBUG);
  end;
end;

proc protocolaction(player,pos,pos2,value);
{*****************************************}
var s: cpnt;
begin
  if player=WHITE then
    s:=previousaction
  else
    s:=computeraction;

  s[0]:=ENDMARK;

  write(@s,'ACTION ',action,' ');

  if player=WHITE then
    write(@s,'WHITE ')
  else
    write(@s,'BLACK ');

  if pos2>=0 then
    write(@s,'MOVE ',label[pos],'-',label[pos2])
  else
    write(@s,'PLACE ',label[pos]);

  write(@DEBUG,s);

  if player=BLACK then
    write(@DEBUG,' VALUE ',value);

  writeln(@DEBUG);
end;

proc readtime(var min,sec,tenmillis: integer);
{********************************************}
var dummy: integer;

  func getbcd(address: integer): integer;
  var data: integer;
  begin
    data:=mem[address];
    getbcd:=data-6*(data div 16);
  end;

begin
  { update host clock }
  dummy:=getbcd($17b9);
  tenmillis:=getbcd($17b5);
  sec:=getbcd($17b6);
  min:=getbcd($17b7);
end;

proc starttimer;
{***************}
begin
  readtime(startmin,startsec,starttenmillis);
end;

func elapsed10ms: integer;
{************************}
var min,sec,tenmillis: integer;
    dmin,dsec,dtenmillis: integer;
begin
  readtime(min,sec,tenmillis);

  dmin:=min-startmin;
  dsec:=sec-startsec;
  dtenmillis:=tenmillis-starttenmillis;

  if dtenmillis<0 then begin
    dtenmillis:=dtenmillis+100;
    dsec:=dsec-1;
  end;

  if dsec<0 then begin
    dsec:=dsec+60;
    dmin:=dmin-1;
  end;

  { wrap from 59 to 0 minutes }
  if dmin<0 then
    dmin:=dmin+60;

  elapsed10ms:=6000*dmin+100*dsec+dtenmillis;
end;

proc setmill(mill,p1,p2,p3: integer);
{***********************************}
var millbase: integer;
begin
  millbase:=mill*3;
  mills[millbase]:=p1;
  mills[millbase+1]:=p2;
  mills[millbase+2]:=p3;
end;

proc init_common;
{***************}
var position: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    board[position]:=EMPTY;

  stones[WHITE]:=NSTONES;
  stones[BLACK]:=NSTONES;
  captured[WHITE]:=0;
  captured[BLACK]:=0;

  for position:=0 to NPOSITIONS-1 do
    label[position]:=
      packed(LABELS[2*position],LABELS[2*position+1]);

  { initialize mills }

  { outer square }
  setmill(0,
    findpos('A1'),findpos('A4'),findpos('A7'));
  setmill(1,
    findpos('A7'),findpos('D7'),findpos('G7'));
  setmill(2,
    findpos('G7'),findpos('G4'),findpos('G1'));
  setmill(3,
    findpos('G1'),findpos('D1'),findpos('A1'));

  { middle square }
  setmill(4,
    findpos('B2'),findpos('B4'),findpos('B6'));
  setmill(5,
    findpos('B6'),findpos('D6'),findpos('F6'));
  setmill(6,
    findpos('F6'),findpos('F4'),findpos('F2'));
  setmill(7,
    findpos('F2'),findpos('D2'),findpos('B2'));

  { inner square }
  setmill(8,
    findpos('C3'),findpos('C4'),findpos('C5'));
  setmill(9,
    findpos('C5'),findpos('D5'),findpos('E5'));
  setmill(10,
    findpos('E5'),findpos('E4'),findpos('E3'));
  setmill(11,
    findpos('E3'),findpos('D3'),findpos('C3'));

  { connections between the squares }
  setmill(12,
    findpos('A4'),findpos('B4'),findpos('C4'));
  setmill(13,
    findpos('D7'),findpos('D6'),findpos('D5'));
  setmill(14,
    findpos('G4'),findpos('F4'),findpos('E4'));
  setmill(15,
    findpos('D1'),findpos('D2'),findpos('D3'));

  { initialize neighbor }
end;

proc removeneighbor(position1,position2: integer);
{***********************************************}
var neighbornumber,neighborbase: integer;
begin
  neighborbase:=position1*MAXNEIGHBORS;

  for neighbornumber:=0 to MAXNEIGHBORS-1 do
    if neighbor[neighborbase+neighbornumber]
       =position2 then
      neighbor[neighborbase+neighbornumber]:=-1;
end;

proc init_neighbors;
{*******************}
var position,neighborbase: integer;
    x,y: char;
    p: integer;
begin
  for position:=0 to NPOSITIONS-1 do begin

    neighborbase:=position*MAXNEIGHBORS;

    neighbor[neighborbase]:=-1;
    neighbor[neighborbase+1]:=-1;
    neighbor[neighborbase+2]:=-1;
    neighbor[neighborbase+3]:=-1;

    { up }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (y<'G') and (p<0) do begin
      y:=chr(ord(y)+1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase]:=p;

    { right }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (x<'7') and (p<0) do begin
      x:=chr(ord(x)+1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase+1]:=p;

    { down }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (y>'A') and (p<0) do begin
      y:=chr(ord(y)-1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase+2]:=p;

    { left }
    x:=low(label[position]);
    y:=high(label[position]);
    p:=-1;
    while (x>'1') and (p<0) do begin
      x:=chr(ord(x)-1);
      p:=findpos(packed(y,x));
    end;
    neighbor[neighborbase+3]:=p;

    { no cross in the center }
    removeneighbor(findpos('D3'),findpos('D5'));
    removeneighbor(findpos('D5'),findpos('D3'));
    removeneighbor(findpos('C4'),findpos('E4'));
    removeneighbor(findpos('E4'),findpos('C4'));

  end;
end;

func ismill(position,player: integer): boolean;
{****************************************}
var mill,millbase,i,p: integer;
    found: boolean;
begin
  for mill:=0 to NMILLS-1 do begin
    millbase:=mill*3;

    { is this position in the current mill? }
    if (mills[millbase]=position) or
       (mills[millbase+1]=position) or
       (mills[millbase+2]=position) then begin
      found:=true;
      for i:=0 to 2 do begin
        p:=mills[millbase+i];
        if board[p]<>player then found:=false;
      end;
      if found then begin
        ismill:=true;
       exit;
       end;
    end;
  end;
  ismill:=false;
end;

proc drawreserve(player: integer);
{****************************}
var stone,x,y,color: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY+STONEOFF
  else
    y:=DASHBLACKY+STONEOFF;

  for stone:=0 to 8 do begin
    x:=DASHX+8+stone*10;

    if stone<stones[player] then
      color:=player
    else
      color:=EMPTY;

    if stone>8-captured[player] then begin
      color:=otherplayer(player);
    end;

    if color<>EMPTY then
      dashstone(stone,player,color)
    else
      cleardashstone(stone, player);
  end;
end;

proc selectdashboard(player: integer);
{**********************************}
begin
  { erase both boxes }
  _rectangle(DASHX,DASHWHITEY,
             DASHWIDTH,DASHHEIGHT,BLACK);
  _rectangle(DASHX,DASHBLACKY,
             DASHWIDTH,DASHHEIGHT,BLACK);

  { draw box around active player }
  if player=WHITE then
    _rectangle(DASHX,DASHWHITEY,
               DASHWIDTH,DASHHEIGHT,WHITE)
  else
    _rectangle(DASHX,DASHBLACKY,
               DASHWIDTH,DASHHEIGHT,WHITE);
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

  if player=WHITE then
    write(@previousaction,' TAKE ',label[p1])
  else
    write(@computeraction,' TAKE ',label[p1]);

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

  codestate(previousstate,BLACK);

  board[p1]:=player;
  stones[player]:=stones[player]-1;
  drawstone(p1,player);
  drawreserve(player);
  protocolaction(player,p1,-1,0);

  if ismill(p1,player) then
    takestone(player);

  specialplace:=-1;
  if emptysquare[p1 shr 3] and ((p1 and 1)=0) then
    specialplace:=p1;
  emptysquare[p1 shr 3]:=false;

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

  codestate(previousstate,BLACK);

  board[p2]:=board[p1];
  board[p1]:=EMPTY;

  clearstone(p1,player);
  drawstone(p2,player);

  protocolaction(player,p1,p2,0);

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

proc playerturn(player: integer);
{*******************************}
begin
  selectdashboard(player);

  if automode then begin
    writeln(@DEBUG,'SELFPLAY ',player);
    message(21,'  ',player);
    strmessage('',EMPTY);
    protocolcomputer(player);
    computerturn(player);
  end

  else if DUALPLAYER then begin
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

  if _escape_pending then begin
    gameover:=true;
    exit;
  end;
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

proc main;
{********}

mem ARGLISTS = $0060: array[63] of char&;
var s: cpnt;
    dummy: boolean;
    i: integer;

begin
  s:=_new;
  previousstate:=_new;
  previousstate[0]:=ENDMARK;

  previousaction:=_new;
  previousaction[0]:=ENDMARK;

  computeraction:=_new;
  computeraction[0]:=ENDMARK;

  init_graphics;

  aitime:=0.0;

  DEBUG:=NULLDEV;

  repeat
    init_canvas;
    init_common;
    init_neighbors;
    init_ai;
    drawboard;
    drawlabels;

    action:=0;
    carg:=0;

    if (ARGTYPE[0]='s') and (ARGLISTS[0]<>'/')
    then begin
      loadgame;
      carg:=carg+2; {cyclus, drive }
    end;

    automode:=false;
    debug(carg);
    if ARGTYPE[carg]='s' then begin
      _sgetstring(s,carg,dummy);
      if s[0]='/' then begin
        i:=1;
        repeat
        debug(s,i,s[i]);
          if s[i]='A' then
            automode:=true
          else if s[i]='D' then
            DEBUG:=PRINTER;
        i:=i+1;
        until (s[i]=chr(0)) or (i>3);
      end;
    end;

    drawstones;
    drawreserve(WHITE);
    drawreserve(BLACK);

    player:=WHITE;

    repeat
      action:=action+1;
      playerturn(player);
      protocolboard;
      player:=otherplayer(player);
    until gameover(player);

    if not _escape_pending then begin
      message(10,'  ',player);
      message(11,'  ',otherplayer(player));
    end;

    writeln(@DEBUG,'AI TIME ',strunc(aitime),' S');

  until not automode or _escape_pending;

  quit;
  _release(s);
end;


 