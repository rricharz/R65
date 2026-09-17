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

func placevalue(player,pos: integer): integer;
{****************************************}
var opponent,value,n: integer;
begin
  opponent:=otherplayer(player);
  value:=0;

  if board[pos]=EMPTY then begin

    { immediate mill }
    board[pos]:=player;

    if ismill(pos,player) then
      value:=100
    else begin
      n:=threats(player);

      if n>=2 then
        value:=value+30
      else if n=1 then
        value:=value+10;
    end;

    { opponent threats after this placement }
    n:=threats(opponent);

    if n>=2 then
      value:=value-40
    else if n=1 then
      value:=value-15;

    board[pos]:=EMPTY;
  end;

  placevalue:=value;
end;

func computertake(player: integer):integer;
{*****************************************}
var p1,opponent: integer;
    allinmills0: boolean;
begin
  opponent:=otherplayer(player);
  allinmills0:=allinmills(opponent);

  repeat
    p1:=_mod(_random,24);
  until (board[p1]=opponent)
    and (not ismill(p1,opponent)
         or allinmills0);

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
  debug('computerplace',player);
  bestpos:=-1;
  bestvalue:=-1;

  for i:=0 to 23 do
    if board[i]=EMPTY then begin
      value:=placevalue(player,i);
      writeln(@DEBUG,'EVAL ',label[i],' ',value);

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
var p1,p2,tk: integer;
begin
  repeat
    p1:=_mod(_random,24);
    p2:=_mod(_random,24);
  until islegalmove(player,p1,p2);

  board[p1]:=EMPTY;
  board[p2]:=player;

  clearstone(p1,player);
  drawstone(p2,player);

  if ismill(p2,player) then
    tk:=computertake(player);
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