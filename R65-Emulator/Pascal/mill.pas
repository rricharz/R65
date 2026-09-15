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

proc drawreserve;
{****************}
var stone,x,y: integer;
begin

  y:=82;
  for stone:=0 to stones[WHITE]-1 do begin
    x:=121+stone*11;
    drawstone(x,y,WHITE);
  end;

  y:=22;
  for stone:=0 to stones[BLACK]-1 do begin
    x:=121+stone*12;
    drawstone(x,y,BLACK);
  end;
end;

proc debugdash(y,player: integer);
{********************************}
var stone, x0, y0: integer;
begin
  _move(DASHX+1,y+NAMEOFF);

  if player=WHITE then
    write(@PLOTDEV,'Player')
  else
    write(@PLOTDEV,'Computer');

  y0:=y+STONEOFF;
  for stone:=0 to stones[player]-1 do begin
    x0:=DASHX+8+stone*10;
    dashstone(x0,y0,player);
  end;

  if player=WHITE then  begin
    _rectangle(DASHX,y,DASHWIDTH,DASHHEIGHT,WHITE);

  end;
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

{ main body }
{***********}

var n1, n2: integer;
    flag: boolean;

begin
  init_canvas;
  init_common;
  init_neighbors;

  writeln(@DEBUG,
    '----------------------------------------------');
  writeln(@DEBUG, 'MILL initialized');

  drawboard;
  drawlabels;
  drawstones;
  { drawreserve; }

  { game loop }
  { debuglabels; }
  debugdash(DASHWHITEY,WHITE);
  debugdash(DASHBLACKY,BLACK);
  getinput(WHITE, n1, n2, flag);
  debug('debugdash', n1,  n2, flag);

end.
