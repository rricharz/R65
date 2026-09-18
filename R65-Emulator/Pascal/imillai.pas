{ IMILLAI - Artificial intelligence for MILL game }
{ 2026 rricharz and ChatGPT }

const
  V_MILL        = 100;

  V_OWNTHREAT1  = 10;
  V_OWNTHREAT2  = 30;

  V_OPPTHREAT1  = 15;
  V_OPPTHREAT2  = 40;

  V_OWNMILL     = 20;
  V_OPPMILL     = 20;

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

func boardvalue(player: integer): integer;
{***************************************}
var opponent,value,n,
    ownth,oppth,ownmill,oppmill: integer;
begin
  opponent:=otherplayer(player);
  value:=0;

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

  ownmill:=millcount(player);
  oppmill:=millcount(opponent);

  value:=value+V_OWNMILL*ownmill;
  value:=value-V_OPPMILL*oppmill;

  write(@DEBUG, 'EVAL ',
    ' T ',ownth,'/',oppth,
    ' M ',ownmill,'/',oppmill,
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
    placevalue:=boardvalue(player);
  board[pos]:=EMPTY;
end;

func takevalue(player,pos: integer): integer;
{*******************************************}
var opponent: integer;
begin
  opponent:=otherplayer(player);
  board[pos]:=EMPTY;
  takevalue:=boardvalue(player);
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
    movevalue:=boardvalue(player);
  board[p2]:=EMPTY;
  board[p1]:=player;
end;

func computertake(player: integer):integer;
{*****************************************}
var p1,bestpos,bestvalue,value,
    opponent: integer;
    allinmills0: boolean;
begin
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

proc computerplace(player: integer);
{**********************************}
var i,p,bestpos,bestvalue,value,tk: integer;
  s: cpnt;
begin
  s:=_new;
  bestpos:=-1;
  bestvalue:=-1;

  for i:=0 to 23 do
    if board[i]=EMPTY then begin
      value:=placevalue(player,i);
      writeln(@DEBUG,'PLACE ',label[i],' ',value);

      if (bestpos<0)
        or (value>bestvalue)
        or ((value=bestvalue)
        and (_mod(_random,2)=0))
      then begin
        bestvalue:=value;
        bestpos:=i;
      end;
    end;

  p:=bestpos;

  board[p]:=player;
  stones[player]:=stones[player]-1;

  drawstone(p,player);
  drawreserve(player);
  protocolplace(player,bestpos,bestvalue,elapsed10ms);

  if ismill(p,player) then begin
    tk:=computertake(player);
    write(@s,label[p],'/',label[tk]);
  end else
    write(@s,label[p]);
  strmessage(s,EMPTY);
  _release(s);
end;

proc computermove(player: integer);
{*******************************}
var p1,p2,tk,bestp1,bestp2,bestvalue,value: integer;
    s: cpnt;
begin
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

  if ismill(p2,player) then begin
    tk:=computertake(player);
    write(@s,label[p1],'-',label[p2],'/',label[tk]);
  end else
    write(@s,label[p1],'-',label[p2]);
  strmessage(s,EMPTY);
  _release(s);
end;

proc computerturn(player: integer);
{*******************************}
var s:cpnt;
begin
  starttimer;
  if stones[player]>0 then
    computerplace(player)
  else
    computermove(player);
  s:=_new;
  write(@s,elapsed10ms,'0 MS');
  strmessage(s,player);
  _release(s);
end;