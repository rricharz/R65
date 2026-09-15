program mill;

uses plotlib, syslib, strlib;

const
  NPOSITIONS   = 24;
  NSTONES      = 9;
  NMILLS       = 16;
  MAXNEIGHBORS = 4;

  EMPTY = 4;

var
  board: array[23] of integer;
  stones: array[BLACK] of integer;
  label:    array[23] of packed char;
  DEBUG: file;

{$I IMILLPLOT}
{$I IMILLCOMM}

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

func otherplayer(player:integer):integer;
{***************************************}
begin
  if player=WHITE then
    otherplayer:=BLACK
  else
    otherplayer:=WHITE;
end;

proc placestone(player:integer);
{*******************************}
var p1,p2,x,y: integer;
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

  x:=X0+(ord(low(label[p1]))-ord('1'))*SPACING;
  y:=Y0+(ord(high(label[p1]))-ord('A'))*SPACING;

  drawstone(x,y,player);
  drawreserve(player);
end;

proc movestone(player:integer);
{******************************}
begin
end;

proc playerturn(player:integer);
{******************************}
begin
  selectdashboard(player);
  if stones[player]>0 then
    placestone(player)
  else
    movestone(player);
end;

func gameover:boolean;
{********************}
begin
  gameover := false;
end;

{ main body }
{***********}

var player: integer;

begin
  init_canvas;
  init_common;
  init_neighbors;

  writeln(@DEBUG,
    '----------------------------------------------');
  writeln(@DEBUG,'MILL initialized');

  drawboard;
  drawlabels;
  drawstones;
  drawreserve(WHITE);
  drawreserve(BLACK);
  _move(DASHX+1,DASHWHITEY+NAMEOFF);
  write(@PLOTDEV,'PLAYER 1');
  _move(DASHX+1,DASHBLACKY+NAMEOFF);
  write(@PLOTDEV,'PLAYER 2');

  player:=WHITE;

  repeat
    playerturn(player);
    player:=otherplayer(player);
  until gameover;

end.
