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
  DEBUG: file;

{ section for MILL on onbard screen }
{ ##################################}

const
  SPACING = 16;
  X0 = 15;
  Y0 = 15;

proc init_canvas;
{***************}
begin
  DEBUG := PRINTER;
  _grinit;
  _splitview;
  _cleargr;
  end;

proc vector(x1,y1,x2,y2, color: integer);
{***************************************}
begin
  _move(x1,y1);
  _draw(x2,y2,color);
end;

proc endpoints(x1,y1,x2,y2: integer);
begin
  _plot(x1,y1,WHITE);
  _plot(x2,y2,WHITE);
end;

proc drawstone(x,y,player: integer);
begin
  vector(x-1, y-5, x+1, y-5, WHITE);
  vector(x-1, y+5, x+1, y+5, WHITE);

  if player=WHITE then begin
    vector(x-3, y-4, x+3, y-4, WHITE);
    vector(x-3, y+4, x+3, y+4, WHITE);

    vector(x-4, y-3, x+4, y-3, WHITE);
    vector(x-4, y+3, x+4, y+3, WHITE);

    vector(x-5, y-2, x+5, y-2, WHITE);
    vector(x-5, y-1, x+5, y-1, WHITE);
    vector(x-5, y,   x+5, y,   WHITE);
    vector(x-5, y+1, x+5, y+1, WHITE);
    vector(x-5, y+2, x+5, y+2, WHITE)
  end else begin
    vector(x-3, y-4, x-2, y-4, WHITE);
    vector(x+2, y-4, x+3, y-4, WHITE);
    vector(x-3, y+4, x-2, y+4, WHITE);
    vector(x+2, y+4, x+3, y+4, WHITE);

    endpoints(x-4, y-3, x+4, y-3);
    endpoints(x-4, y+3, x+4, y+3);

    endpoints(x-5, y-2, x+5, y-2);
    endpoints(x-5, y-1, x+5, y-1);
    endpoints(x-5, y,   x+5, y);
    endpoints(x-5, y+1, x+5, y+1);
    endpoints(x-5, y+2, x+5, y+2);

    vector(x,   y-4, x,   y+4, BLACK);
    vector(x-4, y,   x+4, y,   BLACK)
  end;
end;

proc drawlabels;
{**************}
var i: integer;
    c: char;
begin
  { 1..7 below the board }
  for i:=0 to 6 do begin
    c:=chr(ord('1')+i);
    _move(X0+i*SPACING-5, 0);
    write(@PLOTDEV,c);
  end;

  { A..G left of the board }
  for i:=0 to 6 do begin
    c:=chr(ord('A')+i);
    _move(0, Y0+i*SPACING-4);
    write(@PLOTDEV,c);
  end;
end;

proc drawreserve;
{****************}
var stone,x,y: integer;
begin
  _move(121,95);
  write(@PLOTDEV,'Player');

  y:=82;
  for stone:=0 to stones[WHITE]-1 do begin
    x:=121+stone*12;
    drawstone(x,y,WHITE);
  end;

  _move(121,35);
  write(@PLOTDEV,'Computer');

  y:=22;
  for stone:=0 to stones[BLACK]-1 do begin
    x:=121+stone*12;
    drawstone(x,y,BLACK);
  end;
end;

{ common section for MILL and TEKMILL }
{#####################################}

const
  YLABEL = 'AAADGGGDBBBDFFFDCCCDEEED';
  XLABEL = '147774112466642234555433';

var
  mills:    array[47] of integer;
  neighbor: array[95] of integer;
  { There is no INVERSE stone; BLACK and WHITE used }

proc init_common;
{***************}
var position: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    board[position]:=EMPTY;

  stones[WHITE]:=NSTONES;
  stones[BLACK]:=NSTONES;


  { initialize mills }

  { initialize neighbor }
end;

proc drawboard;
{*************}
var i,x1,y1,x2,y2: integer;

begin

  { three nested squares }
  for i:=0 to 2 do begin
    x1 := X0 + i*SPACING;
    y1 := Y0 + i*SPACING;
    x2 := X0 + (6-i)*SPACING;
    y2 := Y0 + (6-i)*SPACING;
    vector(x1,y1,x2,y1,WHITE);
    vector(x2,y1,x2,y2,WHITE);
    vector(x2,y2,x1,y2,WHITE);
    vector(x1,y2,x1,y1,WHITE);
  end;

  { connections between the squares }
  vector(X0+3*SPACING,Y0,
         X0+3*SPACING,Y0+2*SPACING,WHITE);
  vector(X0+3*SPACING,Y0+4*SPACING,
         X0+3*SPACING,Y0+6*SPACING,WHITE);
  vector(X0,Y0+3*SPACING,
         X0+2*SPACING,Y0+3*SPACING,WHITE);
  vector(X0+4*SPACING,Y0+3*SPACING,
         X0+6*SPACING,Y0+3*SPACING,WHITE);
end;

proc drawstones;
{**************}
var position,x,y: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    if board[position]<>EMPTY then begin
      x:=X0+
        (ord(XLABEL[position])-ord('1'))*SPACING;
      y:=Y0+
        (ord(YLABEL[position])-ord('A'))*SPACING;
      drawstone(x,y,board[position]);
    end;
end;

proc debuglabels;
{****************}
var position: integer;
begin
  writeln(@DEBUG);
  writeln(@DEBUG,'Board positions');
  writeln(@DEBUG);

  for position:=0 to NPOSITIONS-1 do begin
    write(@DEBUG,
      YLABEL[position],
      XLABEL[position],
      ': ');
    writeln(@DEBUG);
  end;
end;

begin {main}
  init_canvas;
  init_common;

  writeln(@DEBUG,
    '----------------------------------------------');
  writeln(@DEBUG, 'MILL initialized');

  drawboard;
  drawlabels;
  drawstones;
  drawreserve;
  debuglabels;
end.
