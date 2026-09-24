{ IMILLAI - Artificial intelligence for MILL game }
{ 2026 rricharz and ChatGPT }

const
  V_MILL        = 100;
  V_NEXTMILL    = 20;
  V_REMILL      = 10;

  V_OWNTHREAT2  = 30;

  V_OPPTHREAT1  = 15;
  V_OPPTHREAT2  = 40;

  V_OWNMILL     = 20;
  V_OPPMILL     = 20;

  V_OWNMOB      = 1;
  V_OPPMOB      = 1;

  MAXLEVEL      = 2;

var maxlevel:integer;

var aitime: real;
    V_OWNTHREAT1: integer;

proc init_ai;
{***********}
var i: integer;
begin
  for i:=0 to 2 do
    emptysquare[i]:=true;
  specialplace:=-1;
end;

func threats(player: integer): integer;
{*************************************}
{ Number of empty positions where PLAYER
  could form a mill by placing one stone. }

var i,count: integer;
begin
  count:=0;
  for i:=0 to 23 do
    if board[i]=EMPTY then begin
      board[i]:=player;
      if ismill(i,player) then
        count:=count+1;
      board[i]:=EMPTY;
    end;
  threats:=count;
end;

func millcount(player: integer): integer;
{***************************************}
var i,j,count: integer;
begin
  count:=0;
  for i:=0 to NMILLS-1 do begin
    j:=3*i;
    if (board[mills[j]]=player)
      and (board[mills[j+1]]=player)
      and (board[mills[j+2]]=player)
    then
      count:=count+1;
  end;
  millcount:=count;
end;

func mobility(player: integer): integer;
{*************************************}
var p,i,n,m: integer;
begin
  m:=0;

  for p:=0 to 23 do
    if board[p]=player then
      for i:=0 to MAXNEIGHBORS-1 do begin
        n:=neighbor[p*MAXNEIGHBORS+i];
        if n>=0 then
          if board[n]=EMPTY then
            m:=m+1;
      end;

  mobility:=m;
end;

func canblock(player,pos: integer): boolean;
{*****************************************}
var i,n: integer;
begin
  canblock:=false;

  { with 3 stones the player can fly }
  if stones[player]=3 then
    canblock:=true
  else begin
    for i:=0 to MAXNEIGHBORS-1 do begin
      n:=neighbor[pos*MAXNEIGHBORS+i];
      if n>=0 then
        if board[n]=player then
          canblock:=true;
    end;
  end;
end;

func boardvalue(player,frompos,topos:integer):integer;
{****************************************************}
var opponent,value,n,
    ownth,oppth,ownmill,oppmill,
    ownmob,oppmob: integer;
    remill: boolean;
begin
  opponent:=otherplayer(player);
  value:=0;
  remill:=false;

  ownth:=threats(player);
  if ownth>=2 then
    value:=value+V_OWNTHREAT2
  else if ownth=1 then
    value:=value+V_OWNTHREAT1;

  oppth:=threats(opponent);
  if oppth>=2 then
    value:=value-V_OPPTHREAT2
  else if oppth=1 then
    value:=value-V_OPPTHREAT1;

  if oppth>0 then
    value:=value-V_NEXTMILL;

  ownmill:=millcount(player);
  oppmill:=millcount(opponent);

  value:=value+V_OWNMILL*ownmill;
  value:=value-V_OPPMILL*oppmill;

  ownmob:=mobility(player);
  oppmob:=mobility(opponent);

  value:=value+V_OWNMOB*ownmob;
  value:=value-V_OPPMOB*oppmob;

  { A MOVE may have opened a reusable mill. }
  if frompos>=0 then begin

    { Reconstruct position before move. }
    board[topos]:=EMPTY;
    board[frompos]:=player;

    if ismill(frompos,player) then
      remill:=true;

    { Restore evaluated position. }
    board[frompos]:=EMPTY;
    board[topos]:=player;

    { Opponent must not be able to occupy
      the vacated mill position. }
    if remill then
      if canblock(opponent,frompos) then
        remill:=false;

    if remill then
      value:=value+V_REMILL;
  end;

  write(@DEBUG, 'EVAL ',
    ' T ',ownth,'/',oppth,
    ' M ',ownmill,'/',oppmill,
    ' F ',ownmob,'/',oppmob,
    ' N ',oppth>0,
    ' R ',remill,
    ' V ',value, ' ');

  boardvalue:=value;
end;

func placevalue(player,pos: integer): integer;
{********************************************}
begin
  board[pos]:=player;
  if ismill(pos,player) then
    placevalue:=V_MILL
  else
    placevalue:=boardvalue(player,-1,pos);
  board[pos]:=EMPTY;
end;

func takevalue(player,pos: integer): integer;
{*******************************************}
var opponent: integer;
begin
  opponent:=otherplayer(player);
  board[pos]:=EMPTY;
  takevalue:=boardvalue(player,-1,pos);
  board[pos]:=opponent;
end;

func movevalue(player,p1,p2: integer): integer;
{*********************************************}
begin
  board[p1]:=EMPTY;
  board[p2]:=player;
  if ismill(p2,player) then
    movevalue:=V_MILL
  else
    movevalue:=boardvalue(player,p1,p2);
  board[p2]:=EMPTY;
  board[p1]:=player;
end;

func computertake(player: integer):integer;
{*****************************************}
var p1,bestpos,bestvalue,value,
    opponent: integer;
    allinmills0: boolean;
begin
  writeln(@DEBUG,'COMPUTERTAKE');
  opponent:=otherplayer(player);
  allinmills0:=allinmills(opponent);

  bestpos:=-1;

  for p1:=0 to 23 do
    if board[p1]=opponent then
      if (not ismill(p1,opponent))
        or allinmills0 then begin

        value:=takevalue(player,p1);

        writeln(@DEBUG,
          'TAKE  ',label[p1],' ',value);

        if (bestpos<0)
          or (value>bestvalue)
          or ((value=bestvalue)
          and (_mod(_random,2)=0))
        then begin
          bestvalue:=value;
          bestpos:=p1;
        end;
      end;

  p1:=bestpos;

  board[p1]:=EMPTY;
  clearstone(p1,player);
  captured[player]:=captured[player]+1;
  drawreserve(player);

  computertake:=p1;
end;

proc tryplace(player,p: integer;
              var bestpos,bestvalue: integer);
{********************************************}
var value: integer;
begin
  value:=placevalue(player,p);
  writeln(@DEBUG,'PLACE ',label[p],' ',value);

  if (bestpos<0)
    or (value>bestvalue)
    or ((value=bestvalue)
    and (_mod(_random,2)=0))
  then begin
    bestvalue:=value;
    bestpos:=p;
  end
end;

proc computerplace(player: integer);
{**********************************}
var i,p,base,opposite,bestpos,bestvalue,tk: integer;
  s: cpnt;
begin
  writeln(@DEBUG,'COMPUTERPLACE');

  s:=_new;
  bestpos:=-1;
  bestvalue:=-1;

  if specialplace>=0 then begin
    writeln(@DEBUG,'SPECIAL PLACE ',
      label[specialplace]);

      base:=specialplace and $fff88;
      opposite:=base+((specialplace+4) and 7);

      for i:=base to base+7 do
        if ((i and 1)=1) or (i=opposite) then
          tryplace(player,i,bestpos,bestvalue)
  end else
    for i:=0 to 23 do
      if board[i]=EMPTY then
        tryplace(player,i,bestpos,bestvalue);

  p:=bestpos;

  board[p]:=player;
  stones[player]:=stones[player]-1;

  drawstone(p,player);
  drawreserve(player);
  protocolaction(player,bestpos,-1,bestvalue);

  if ismill(p,player) then begin
    tk:=computertake(player);
    write(@s,label[p],'/',label[tk]);
  end else
    write(@s,label[p]);

  strmessage(s,EMPTY);
  _release(s);

  emptysquare[p shr 3]:=false;
end;

proc computermove(player: integer);
{*******************************}
var p1,p2,tk,bestp1,bestp2,bestvalue,value: integer;
    s: cpnt;
begin
  writeln(@DEBUG,'COMPUTERMOVE');
  s:=_new;

  bestp1:=-1;
  p1:=0;
  p2:=-1;

  while findlegalmove(player,p1,p2) do begin

    value:=movevalue(player,p1,p2);
    writeln(@DEBUG,'MOVE ',
            label[p1],'-',label[p2],' ',value);

    if (bestp1<0)
      or (value>bestvalue)
      or ((value=bestvalue)
      and (_mod(_random,2)=0))
    then begin
      bestvalue:=value;
      bestp1:=p1;
      bestp2:=p2;
    end;

  end;

  p1:=bestp1;
  p2:=bestp2;

  board[p1]:=EMPTY;
  board[p2]:=player;

  clearstone(p1,player);
  drawstone(p2,player);

  protocolaction(player,bestp1,bestp2,bestvalue);

  if ismill(p2,player) then begin
    tk:=computertake(player);
    write(@s,label[p1],'-',label[p2],'/',label[tk]);
  end else
    write(@s,label[p1],'-',label[p2]);
  strmessage(s,EMPTY);
  _release(s);
end;

func canbridge(player: integer): boolean;
{****************************************}
var p1,p2,i,n: integer;
  found: boolean;
begin
  canbridge:=false;
  found:=false;

  p1:=0;
  while p1<24 do begin
    if board[p1]=player then begin

      if stones[player]=3 then begin
        { FLY }
        p2:=0;
        while p2<24 do begin
          if board[p2]=EMPTY then begin
            board[p1]:=EMPTY;
            board[p2]:=player;

            if ismill(p2,player) then begin
              found:=true;
              canbridge:=true;
              writeln(@DEBUG,'  BRIDGE',label[n]);

            end;

            board[p2]:=EMPTY;
            board[p1]:=player;

            if found then
              exit;
          end;
          p2:=p2+1;
        end;

      end else begin
        { MOVE }
        i:=0;
        while i<MAXNEIGHBORS do begin
          n:=neighbor[p1*MAXNEIGHBORS+i];

          if (n>=0) and (board[n]=EMPTY) then begin
            board[p1]:=EMPTY;
            board[n]:=player;

            if ismill(n,player) then begin
              found:=true;
              canbridge:=true;
              writeln(@DEBUG,'  BRIDGE ',label[n]);

            end;

            board[n]:=EMPTY;
            board[p1]:=player;

            if found then
              exit;
          end;

          i:=i+1;
        end;
      end;
    end;

    p1:=p1+1;
  end;
end;

func nextlevel(player,level: integer): boolean;
    forward;

func iterate(player,frompos,topos;
                            level: integer): boolean;
{***************************************************}
{ TRUE if every legal opponent reply
  leaves player a forced bridge.
  Board is unchanged on return. }
var opponent,p1,p2,i,n: integer;
    reply,good: boolean;
begin
  writeln(@DEBUG,'LEVEL ',level,
          ' TRY ',label[frompos],'-',label[topos]);

  opponent:=otherplayer(player);
  good:=true;
  reply:=false;

  p1:=0;
  while (p1<24) and good do begin
    if board[p1]=opponent then begin

      if stones[opponent]=3 then begin
        { opponent FLY }

        p2:=0;
        while (p2<24) and good do begin
          if board[p2]=EMPTY then begin
            reply:=true;

            writeln(@DEBUG,'  TEST USER REPLY ',
              label[p1],'-',label[p2]);

            { make opponent move }
            board[p1]:=EMPTY;
            board[p2]:=opponent;

            if ismill(p2,opponent) then begin
              writeln(@DEBUG,'  OPPONENT BRIDGE');
              good:=false;
            end else if canbridge(player) then begin
              { immediate bridge possible }
            end else if level<maxlevel then begin
              if not nextlevel(player,level+1) then
              begin
                writeln(@DEBUG,'  NO BRIDGE');
                good:=false;
              end;
            end else begin
              writeln(@DEBUG,'  NO BRIDGE');
              good:=false;
            end;

            { undo opponent move }
            board[p2]:=EMPTY;
            board[p1]:=opponent;
          end;

          p2:=p2+1;
        end;

      end else begin
        { opponent MOVE }

        i:=0;
        while (i<MAXNEIGHBORS) and good do begin
          n:=neighbor[p1*MAXNEIGHBORS+i];

          if (n>=0) and (board[n]=EMPTY) then begin
            reply:=true;

            writeln(@DEBUG,'  TEST USER REPLY ',
              label[p1],'-',label[n]);

            { make opponent move }
            board[p1]:=EMPTY;
            board[n]:=opponent;

            if ismill(n,opponent) then begin
              writeln(@DEBUG,'  OPPONENT BRIDGE');
              good:=false;
            end else if canbridge(player) then begin
              { immediate bridge possible }
            end else if level<maxlevel then begin
              if not nextlevel(player,level+1) then
              begin
                writeln(@DEBUG,'  NO BRIDGE');
                good:=false;
              end;
            end else begin
              writeln(@DEBUG,'  NO BRIDGE');
              good:=false;
            end;

            { undo opponent move }
            board[n]:=EMPTY;
            board[p1]:=opponent;
          end;

          i:=i+1;
        end;
      end;
    end;

    p1:=p1+1;
  end;

  iterate:=good and reply;
end;

func nextlevel(player,level: integer): boolean;
{********************************************}
{ Try all legal moves for PLAYER at LEVEL.
  TRUE if one move leads to a forced bridge.
  Board is unchanged on return. }
var p1,p2,i,n: integer;
    found: boolean;
begin
  found:=false;

  p1:=0;
  while (p1<24) and not found do begin

    if board[p1]=player then begin

      if stones[player]=3 then begin

        { FLY }

        p2:=0;
        while (p2<24) and not found do begin

          if board[p2]=EMPTY then begin

            { make trial move }
            board[p1]:=EMPTY;
            board[p2]:=player;

            if ismill(p2,player) then
              found:=true
            else if iterate(player,p1,p2,level) then
              found:=true;

            { always undo trial move }
            board[p2]:=EMPTY;
            board[p1]:=player;
          end;

          p2:=p2+1;
        end;

      end else begin

        { MOVE }

        i:=0;
        while (i<MAXNEIGHBORS) and not found do begin
          n:=neighbor[p1*MAXNEIGHBORS+i];

          if (n>=0) and (board[n]=EMPTY) then begin

            { make trial move }
            board[p1]:=EMPTY;
            board[n]:=player;

            if ismill(n,player) then
              found:=true
            else if iterate(player,p1,n,level) then
              found:=true;

            { always undo trial move }
            board[n]:=EMPTY;
            board[p1]:=player;
          end;

          i:=i+1;
        end;

      end;
    end;

    p1:=p1+1;
  end;

  nextlevel:=found;
end;

func searchlevel(player): boolean;
{********************************}
{ Search for a forced bridge.
  TRUE  = first action found and executed.
  FALSE = board unchanged. }
var p1,p2,i,n,tk,
    bestp1,bestp2: integer;
    found: boolean;
    s: cpnt;
begin
  writeln(@DEBUG,'SEARCHLEVEL');

  searchlevel:=false;
  found:=false;
  bestp1:=-1;
  bestp2:=-1;

  p1:=0;
  while (p1<24) and not found do begin

    if board[p1]=player then begin

      if stones[player]=3 then begin

        { FLY }

        p2:=0;
        while (p2<24) and not found do begin

          if board[p2]=EMPTY then begin

            { make trial move }
            board[p1]:=EMPTY;
            board[p2]:=player;

            if ismill(p2,player) then begin
              bestp1:=p1;
              bestp2:=p2;
              found:=true;
            end

            else if maxlevel>0 then
              if iterate(player,p1,p2,1) then begin
              bestp1:=p1;
              bestp2:=p2;
              found:=true;
            end;

            { always undo trial move }
            board[p2]:=EMPTY;
            board[p1]:=player;
          end;

          p2:=p2+1;
        end;

      end else begin

        { MOVE }

        i:=0;
        while (i<MAXNEIGHBORS) and not found do begin
          n:=neighbor[p1*MAXNEIGHBORS+i];

          if (n>=0) and (board[n]=EMPTY) then begin

            { make trial move }
            board[p1]:=EMPTY;
            board[n]:=player;

            if ismill(n,player) then begin
              bestp1:=p1;
              bestp2:=n;
              found:=true;
            end

            else if maxlevel>0 then
              if iterate(player,p1,n,1) then begin
              bestp1:=p1;
              bestp2:=n;
              found:=true;
            end;

            { always undo trial move }
            board[n]:=EMPTY;
            board[p1]:=player;
          end;

          i:=i+1;
        end;

      end;
    end;

    p1:=p1+1;
  end;

  if found then begin
    writeln(@DEBUG,'SUCCESS ',
                label[bestp1],'-',label[bestp2]);

    { Execute the selected first action. }

    p1:=bestp1;
    p2:=bestp2;

    board[p1]:=EMPTY;
    board[p2]:=player;

    clearstone(p1,player);
    drawstone(p2,player);

    s:=_new;

    if ismill(p2,player) then begin
      tk:=computertake(player);
      write(@s,label[p1],'-',label[p2],
        '/',label[tk]);
    end else
      write(@s,label[p1],'-',label[p2]);

    strmessage(s,EMPTY);
    _release(s);

    searchlevel:=true;

  end else
    writeln(@DEBUG,
      'SEARCHLEVEL: NO BRIDGE FOUND');
end;

func searchbridge(player: integer): boolean;
{******************************************}
begin
  searchbridge:=false;

  maxlevel:=0;
  if searchlevel(player) then begin
    searchbridge:=true;
    exit;
  end;

  maxlevel:=1;
  while maxlevel<=MAXLEVEL do begin
    writeln(@DEBUG,'SEARCH LEVEL ',maxlevel);
    if searchlevel(player) then begin
      searchbridge:=true;
      exit;
    end;

    maxlevel:=maxlevel+1;
  end;
end;

proc computerturn(player: integer);
{*******************************}
var s:cpnt;
    found:boolean;
    e: integer;
begin
  starttimer;
  found:=false;

  { Search only in MOVE/FLY phase. }
  if stones[player]=0 then
    found:=searchbridge(player);

  { Fall back to current evaluation strategy. }
  if not found then begin
    if stones[player]>0 then
      computerplace(player)
    else
      computermove(player);
  end;

  s:=_new;
  e:=elapsed10ms;

  aitime := aitime + conv(e) / 100.0;

  write(@s,e,'0 MS');
  strmessage(s,player);
  writeln(@DEBUG,'TIME ',s);
  _release(s);
end;