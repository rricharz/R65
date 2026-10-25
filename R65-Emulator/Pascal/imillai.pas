{ IMILLAI - Artificial intelligence for MILL/TEKMILL }
{ 2026 rricharz and ChatGPT }

const
  V_MILL        = 100;
  V_NEXTMILL    = 20;
  V_REMILL      = 10;

  V_OWNTHREAT1  = 5;
  V_OWNTHREAT2  = 30;

  V_OPPTHREAT1  = 15;
  V_OPPTHREAT2  = 40;

  V_OWNMILL     = 20;
  V_OPPMILL     = 20;

  V_OWNMOB      = 1;
  V_OPPMOB      = 1;

  MAXLEVEL      = 2;

  SEARCHTIME    = 700; { 7 seconds }

  AIPROTOCOL    = NULLDEV;

var maxlevel:integer;
    safeplace: array[23] of boolean;
    searchtimeout: boolean;

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

func reachablethreats(player: integer): integer;
{***********************************************}
var p1,p2,i,n,count,t: integer;
    reachable: boolean;
    opponent: integer;
begin
  t:=threats(player);

  { No need for further checking if fewer
    than two threats exist. }
  if t<2 then begin
    reachablethreats:=t;
    exit;
  end;

  opponent:=otherplayer(player);

  { In PLACE and FLY every empty position
    can be reached. }
  if (stones[player]>0) or
     (captured[opponent]=6) then begin
    reachablethreats:=t;
    exit;
  end;

  { MOVE: count distinct threat positions
    which can actually be reached. }
  count:=0;

  p2:=0;
  while (p2<24) and (count<2) do begin
    if board[p2]=EMPTY then begin
      reachable:=false;

      p1:=0;
      while (p1<24) and not reachable do begin
        if board[p1]=player then begin
          i:=0;
          while (i<MAXNEIGHBORS) and
                not reachable do begin
            n:=neighbor[p1*MAXNEIGHBORS+i];

            if n=p2 then begin
              { Try the actual move. }
              board[p1]:=EMPTY;
              board[p2]:=player;

              if ismill(p2,player) then
                reachable:=true;

              board[p2]:=EMPTY;
              board[p1]:=player;
            end;

            i:=i+1;
          end;
        end;
        p1:=p1+1;
      end;

      if reachable then
        count:=count+1;
    end;

    p2:=p2+1;
  end;

  reachablethreats:=count;
end;

func doublethreat(player: integer): boolean;
{******************************************}
var p1,p2,i,n,opponent: integer;
    found: boolean;
begin
  found:=false;
  opponent:=otherplayer(player);

  if stones[player]>0 then begin
    { PLACE }
    p2:=0;
    while p2<24 do begin
      if board[p2]=EMPTY then begin
        board[p2]:=player;
        stones[player]:=stones[player]-1;

        if reachablethreats(player)>=2 then begin
          found:=true;
        end;

        stones[player]:=stones[player]+1;
        board[p2]:=EMPTY;

        if found then begin
          doublethreat:=true;
          exit;
        end;
      end;
      p2:=p2+1;
    end;

  end else if captured[opponent]=6 then begin
    { FLY }
    p1:=0;
    while p1<24 do begin
      if board[p1]=player then begin
        p2:=0;
        while p2<24 do begin
          if board[p2]=EMPTY then begin
            board[p1]:=EMPTY;
            board[p2]:=player;

            if reachablethreats(player)>=2 then begin
              found:=true;
            end;

            board[p2]:=EMPTY;
            board[p1]:=player;

            if found then begin
              doublethreat:=true;
              exit;
            end;
          end;
          p2:=p2+1;
        end;
      end;
      p1:=p1+1;
    end;

  end else begin
    { MOVE }
    p1:=0;
    while p1<24 do begin
      if board[p1]=player then begin
        i:=0;
        while i<MAXNEIGHBORS do begin
          n:=neighbor[p1*MAXNEIGHBORS+i];

          if (n>=0) and (board[n]=EMPTY) then begin
            board[p1]:=EMPTY;
            board[n]:=player;

            if reachablethreats(player)>=2 then begin
              writeln(@AIPROTOCOL,'DOUBLE MOVE ',
                    label[p1],'-',label[n]);
              found:=true;
            end;

            board[n]:=EMPTY;
            board[p1]:=player;

            if found then begin
              doublethreat:=true;
              exit;
            end;
          end;

          i:=i+1;
        end;
      end;
      p1:=p1+1;
    end;
  end;

  doublethreat:=false;
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
var i,n,opponent: integer;
begin
  canblock:=false;
  opponent:=otherplayer(player);
  { with 3 stones the player can fly }
  if captured[opponent]=6 then
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

  write(@AIPROTOCOL, 'EVAL ',
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
  writeln(@AIPROTOCOL,'COMPUTERTAKE');
  opponent:=otherplayer(player);
  allinmills0:=allinmills(opponent);

  bestpos:=-1;

  for p1:=0 to 23 do
    if board[p1]=opponent then
      if (not ismill(p1,opponent))
        or allinmills0 then begin

        value:=takevalue(player,p1);

        writeln(@AIPROTOCOL,
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
  marktake:=p1;

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
  writeln(@AIPROTOCOL,'PLACE ',label[p],' ',value);

  if (bestpos<0)
    or (value>bestvalue)
    or ((value=bestvalue)
    and (_mod(_random,2)=0))
  then begin
    bestvalue:=value;
    bestpos:=p;
  end
end;

func blockdouble(player: integer): boolean;
{****************************************}
{ Block a double mill threat during PLACE.
  MOVE and FLY may be added if needed. }
var p,bestpos,bestvalue,opponent,tk: integer;
    s: cpnt;
begin
  blockdouble:=false;
  opponent:=otherplayer(player);

  if not doublethreat(opponent) then
    exit;

  bestpos:=-1;
  bestvalue:=-32767;

  if stones[player]=0 then begin
    if captured[opponent]=6 then begin
      writeln(@AIPROTOCOL,
              'DOUBLE THREAT FLY NOT IMPLEMENTED')
    end else begin
      writeln(@AIPROTOCOL,
              'DOUBLE THREAT MOVE NOT IMPLEMENTED');
    end;
    exit;
  end;

  { PLACE }
  p:=0;
  while p<24 do begin
    if board[p]=EMPTY then begin
      { Try this position. }
      board[p]:=player;
      stones[player]:=stones[player]-1;

      if not doublethreat(opponent) then begin
        writeln(@AIPROTOCOL,
            'BLOCK DOUBLE PLACE ',label[p]);

        { Restore before evaluating. }
        stones[player]:=stones[player]+1;
        board[p]:=EMPTY;

        tryplace(player,p,bestpos,bestvalue);
      end else begin
        stones[player]:=stones[player]+1;
        board[p]:=EMPTY;
      end;
    end;

    p:=p+1;
  end;

  if bestpos>=0 then begin
    p:=bestpos;
    blockdouble:=true;

    board[p]:=player;
    stones[player]:=stones[player]-1;
    markplace:=p;

    drawstone(p,player);
    drawreserve(player);
    protocolaction(player,p,-1,bestvalue);

    s:=_new;
    if ismill(p,player) then begin
      tk:=computertake(player);
      write(@s,label[p],'/',label[tk]);
    end else
      write(@s,label[p]);

    strmessage(s,EMPTY);
    _release(s);

    emptysquare[p shr 3]:=false;
  end;
end;

proc computermove(player: integer);
{*******************************}
var p1,p2,tk,bestp1,bestp2,bestvalue,value: integer;
    s: cpnt;
begin
  writeln(@AIPROTOCOL,'COMPUTERMOVE');
  s:=_new;

  bestp1:=-1;
  p1:=0;
  p2:=-1;

  while findlegalmove(player,p1,p2) do begin

    value:=movevalue(player,p1,p2);
    writeln(@AIPROTOCOL,'MOVE ',
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

  markmove1:=p1;
  markmove2:=p2;

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

func canbridge(player: integer): integer;
{****************************************}
var p1,p2,i,n,opponent: integer;
  found: boolean;
begin
  canbridge:=-1;
  found:=false;
  opponent:=otherplayer(player);

  p1:=0;
  while p1<24 do begin
    if board[p1]=player then begin

      if captured[opponent]=6 then begin
        { FLY }
        p2:=0;
        while p2<24 do begin
          if board[p2]=EMPTY then begin
            board[p1]:=EMPTY;
            board[p2]:=player;

            if ismill(p2,player) then begin
              found:=true;
              canbridge:=p2;
              writeln(@AIPROTOCOL,'  BRIDGE',label[p2]
);

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
              canbridge:=n;
              writeln(@AIPROTOCOL,'  BRIDGE ',label[n]
);

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
  if frompos<0 then
    writeln(@AIPROTOCOL,'LEVEL ',level,
          ' TRY PLACE ',label[topos])
  else
    writeln(@AIPROTOCOL,'LEVEL ',level,
          ' TRY ',label[frompos],'-',label[topos]);

  opponent:=otherplayer(player);
  good:=true;
  reply:=false;

  if stones[opponent]>0 then begin
    { opponent PLACE }

    p2:=0;
    while (p2<24) and good do begin

      { Check time between opponent replies. }
      if elapsed10ms>=SEARCHTIME then begin
        searchtimeout:=true;
        good:=false;
      end

      else if board[p2]=EMPTY then begin
        reply:=true;

        writeln(@AIPROTOCOL,'  TEST USER REPLY PLACE '
,
          label[p2]);

        { make opponent placement }
        board[p2]:=opponent;
        stones[opponent]:=stones[opponent]-1;

        if ismill(p2,opponent) then begin
          writeln(@AIPROTOCOL,'  OPPONENT BRIDGE');
          good:=false;
        end
        else if canbridge(player)>=0 then begin
          { immediate bridge possible }
        end else if level<maxlevel then begin
          if not nextlevel(player,level+1) then
          begin
            writeln(@AIPROTOCOL,'  NO BRIDGE');
            good:=false;
          end;
        end else begin
          writeln(@AIPROTOCOL,'  NO BRIDGE');
          good:=false;
        end;

        { undo opponent placement }
        stones[opponent]:=stones[opponent]+1;
        board[p2]:=EMPTY;
      end;

      p2:=p2+1;
    end;

  end else begin

    p1:=0;
    while (p1<24) and good do begin
      if board[p1]=opponent then begin

        if captured[player]=6 then begin
          { opponent FLY }

          p2:=0;
          while (p2<24) and good do begin

            { Check time between opponent replies. }
            if elapsed10ms>=SEARCHTIME then begin
              searchtimeout:=true;
              good:=false;
            end

            else if board[p2]=EMPTY then begin
              reply:=true;

              writeln(@AIPROTOCOL,'  TEST USER REPLY '
,
                label[p1],'-',label[p2]);

              { make opponent move }
              board[p1]:=EMPTY;
              board[p2]:=opponent;

              if ismill(p2,opponent) then begin
                writeln(@AIPROTOCOL,
                        '  OPPONENT BRIDGE');
                good:=false;
              end
              else if canbridge(player)>=0 then begin
                { immediate bridge possible }
              end else if level<maxlevel then begin
                if not nextlevel(player,level+1) then
                begin
                  writeln(@AIPROTOCOL,'  NO BRIDGE');
                  good:=false;
                end;
              end else begin
                writeln(@AIPROTOCOL,'  NO BRIDGE');
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

            { Check time between opponent replies. }
            if elapsed10ms>=SEARCHTIME then begin
              searchtimeout:=true;
              good:=false;
            end else begin

              n:=neighbor[p1*MAXNEIGHBORS+i];

              if (n>=0)and(board[n]=EMPTY) then begin
                reply:=true;

              writeln(@AIPROTOCOL,'  TEST USER REPLY '
,
                            label[p1],'-',label[n]);

                { make opponent move }
                board[p1]:=EMPTY;
                board[n]:=opponent;

                if ismill(n,opponent) then begin
                  writeln(@AIPROTOCOL,
                    '  OPPONENT BRIDGE');
                  good:=false;
                end
                else if canbridge(player)>=0 then
                begin
                  { immediate bridge possible }
                end else if level<maxlevel then begin
                  if not nextlevel(player,level+1)
                  then begin
                    writeln(@AIPROTOCOL,'  NO BRIDGE')
;
                    good:=false;
                  end;
                end else begin
                  writeln(@AIPROTOCOL,'  NO BRIDGE');
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
      end;

      p1:=p1+1;
    end;
  end;

  iterate:=good and reply;
end;

func nextlevel(player,level: integer): boolean;
{********************************************}
{ Try all legal actions for PLAYER at LEVEL.
  TRUE if one action leads to a forced bridge.
  Board is unchanged on return. }
var opponent,p1,p2,i,n: integer;
    found: boolean;
begin
  found:=false;
  opponent:=otherplayer(player);

  if stones[player]>0 then begin

    { PLACE }

    p2:=0;
    while (p2<24) and not found do begin

      if board[p2]=EMPTY then begin

        { make trial placement }
        board[p2]:=player;
        stones[player]:=stones[player]-1;

        if ismill(p2,player) then
          found:=true
        else if iterate(player,-1,p2,level) then
          found:=true;

        { always undo trial placement }
        stones[player]:=stones[player]+1;
        board[p2]:=EMPTY;
      end;

      p2:=p2+1;
    end;

  end else begin

    p1:=0;
    while (p1<24) and not found do begin

      if board[p1]=player then begin

        if captured[opponent]=6 then begin

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
          while (i<MAXNEIGHBORS) and not found
                                            do begin
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
  end;

  nextlevel:=found;
end;

func searchlevel(player): boolean;
{********************************}
{ Search for a forced bridge.
  TRUE  = first action found and executed.
  FALSE = board unchanged. }
var opponent,p1,p2,i,n,tk,
    bestp1,bestp2: integer;
    found: boolean;
    s: cpnt;
begin
  writeln(@AIPROTOCOL,'SEARCHLEVEL');

  searchlevel:=false;
  found:=false;
  bestp1:=-1;
  bestp2:=-1;
  opponent:=otherplayer(player);

  if stones[player]>0 then begin

    { PLACE }

    p2:=0;
    while (p2<24) and not found do begin

      { Check search time between candidates. }
      if elapsed10ms>=SEARCHTIME then begin
        searchtimeout:=true;
        writeln(@AIPROTOCOL,'SEARCH TIMEOUT');
        exit;
      end;

      if board[p2]=EMPTY then begin

        { make trial placement }
        board[p2]:=player;
        stones[player]:=stones[player]-1;

        if ismill(p2,player) then begin
          bestp1:=-1;
          bestp2:=p2;
          found:=true;
        end

        else if maxlevel>0 then
          if iterate(player,-1,p2,1) then begin
            bestp1:=-1;
            bestp2:=p2;
            found:=true;
          end;

        { always undo trial placement }
        stones[player]:=stones[player]+1;
        board[p2]:=EMPTY;
      end;

      p2:=p2+1;
    end;

  end else begin

    { no first placement in MOVE/FLY phase }

    p1:=0;
    while (p1<24) and not found do begin

      { Check search time between candidates. }
      if elapsed10ms>=SEARCHTIME then begin
        searchtimeout:=true;
        writeln(@AIPROTOCOL,'SEARCH TIMEOUT');
        exit;
      end;

      if board[p1]=player then begin

        if captured[opponent]=6 then begin

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
          while (i<MAXNEIGHBORS) and not found
                                            do begin
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
  end;

  if found then begin

    if bestp1<0 then
      writeln(@AIPROTOCOL,'SUCCESS PLACE ',
        label[bestp2])
    else
      writeln(@AIPROTOCOL,'SUCCESS ',
        label[bestp1],'-',label[bestp2]);

    if bestp1<0 then
      markplace:=bestp2
    else begin
      markmove1:=bestp1;
      markmove2:=bestp2;
    end;

    { Execute the selected first action. }

    p2:=bestp2;

    if bestp1<0 then begin

      { PLACE }
      board[p2]:=player;
      stones[player]:=stones[player]-1;

      drawstone(p2,player);

      s:=_new;

      if ismill(p2,player) then begin
        tk:=computertake(player);
        write(@s,label[p2],'/',label[tk]);
      end else
        write(@s,label[p2]);

      strmessage(s,EMPTY);
      _release(s);

    end else begin

      { MOVE or FLY }
      p1:=bestp1;

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
    end;

    searchlevel:=true;

  end else
    writeln(@AIPROTOCOL,
      'SEARCHLEVEL: NO BRIDGE FOUND');
end;

func searchbridge(player: integer): boolean;
{******************************************}
var i:integer;
begin
  searchbridge:=false;

  maxlevel:=0;
  if searchlevel(player) then begin
    writeln(@AIPROTOCOL,'SEARCHBRIDGE SUCCESS LEVEL ',
                                          maxlevel);
    searchbridge:=true;
    exit;
  end;

  { Do not continue after a timeout. }
  if searchtimeout then
    exit;

  maxlevel:=1;
  while maxlevel<=MAXLEVEL do begin
    writeln(@AIPROTOCOL,'SEARCH LEVEL ',maxlevel);

    if searchlevel(player) then begin
      writeln(@AIPROTOCOL,
        'SEARCHBRIDGE SUCCESS LEVEL',maxlevel);
      searchbridge:=true;
      exit;
    end;

    { Do not start another search level
      after a timeout. }
    if searchtimeout then
      exit;

    maxlevel:=maxlevel+1;
  end;
end;

func survive(player: integer): boolean;
{***********************************}
{ With three stones, block an
  immediate opponent bridge if
  this avoids immediate loss. }
var opponent,threat,p1: integer;
    found: boolean;
begin
  survive:=false;
  opponent:=otherplayer(player);

  if captured[opponent]<>6 then exit;

  threat:=canbridge(opponent);

  if threat<0 then exit;

  found:=false;
  p1:=0;

  while (p1<24) and not found do begin
    if board[p1]=player then begin

      { try flying to threatened position }
      board[p1]:=EMPTY;
      board[threat]:=player;

      if canbridge(opponent)<0 then
        found:=true;

      { undo trial move }
      board[threat]:=EMPTY;
      board[p1]:=player;
    end;

    if not found then
      p1:=p1+1;
  end;

  if found then begin
    writeln(@AIPROTOCOL,'SURVIVE ',
      label[p1],'-',label[threat]);
    markmove1:=p1;
    markmove2:=threat;

    board[p1]:=EMPTY;
    board[threat]:=player;

    clearstone(p1,player);
    drawstone(threat,player);

    protocolaction(player,p1,threat,0);

    { same message/mark handling as an ordinary
      computer move will be needed here }

    survive:=true;
  end;
end;

proc computerplace(player: integer);
{**********************************}
var i,p,base,opposite,bestpos,bestvalue,tk: integer;
  s: cpnt;
begin
  writeln(@AIPROTOCOL,'COMPUTERPLACE');

  s:=_new;
  bestpos:=-1;
  bestvalue:=-1;

  if specialplace>=0 then begin
    writeln(@AIPROTOCOL,'SPECIAL PLACE ',
      label[specialplace]);

      base:=specialplace and $fff8;
      opposite:=base+((specialplace+4) and 7);

      for i:=base to base+7 do
        if (board[i]=EMPTY) and
           (((i and 1)=1) or (i=opposite)) then
          tryplace(player,i,bestpos,bestvalue)
  end else
    for i:=0 to 23 do
      if board[i]=EMPTY then
        tryplace(player,i,bestpos,bestvalue);

  p:=bestpos;

  board[p]:=player;
  stones[player]:=stones[player]-1;
  markplace:=p;

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

proc computerturn(player: integer);
{*******************************}
var s:cpnt;
    found:boolean;
    e: integer;
begin
  starttimer;
  searchtimeout:=false;
  clearmarks;
  found:=false;

  writeln(@PROTOCOL,'STONES W/B ',stones[WHITE],' ',
      stones[BLACK], ' CAPTURED W/B ',captured[WHITE],
      ' ',captured[BLACK]);

  { With only three stones left, first try
    to block an immediate losing bridge. }
  if stones[player]=0 then
    found:=survive(player);

  { Search for a forced bridge.
    In PLACE phase only search late in the phase. }
  if not found then
    if (stones[player]=0) or
          ((stones[WHITE]+stones[BLACK])<6) then
      found:=searchbridge(player);

  { Block a double mill threat. }
  if not found then
    found:=blockdouble(player);

  { else fall back to heuristic turn selection. }
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
  writeln(@AIPROTOCOL,'TIME ',s);
  _release(s);
end;