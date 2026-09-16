{ common section for MILL and TEKMILL }
{#####################################}

const
  LABELS =
  'A1A4A7D7G7G4G1D1B2B4B6D6F6F4F2D2C3C4C5D5E5E4E3D3';

var
  mills:    array[47] of integer;
  neighbor: array[95] of integer;
  { There is no INVERSE stone; BLACK and WHITE used }

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

func otherplayer(player:integer):integer;
{***************************************}
begin
  if player=WHITE then
    otherplayer:=BLACK
  else
    otherplayer:=WHITE;
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

 