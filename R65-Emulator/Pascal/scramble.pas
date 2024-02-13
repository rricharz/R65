{ scramble: climb up the ladders }

program scramble;
uses syslib,plotlib;

const erase=0; ball=$6ff6;
      nfloors=5; vfloors=19; holesize=22;
      gravity=-0.25; reflection=-0.7;
      laddersize=7;

var bx,by,bxs,bys,bxspeed,byspeed: real;
    floor: integer;
    holes,ladders: array[nfloors] of integer;

{$I IRANDOM:P}

proc showladder;
var i,x1,x2,y1,y2:integer;
begin
  x1:=ladders[floor]; x2:=x1+laddersize;
  y1:=floor*vfloors+1; y2:=y1+vfloors-1;
  move(x1,y1); draw(x1,y2,white);
  move(x2,y1); draw(x2,y2,white);
  i:=1;
  for i:=1 to 4 do begin
    move(x1,y1+4*i); draw(x2,y1+4*i,white);
  end;
end;

func expaint: boolean;
{ paint picture and apply motion }
begin
  { paint }
  expaint:=false;
  plotmap(trunc(bxs),trunc(bys),erase);
  plotmap(trunc(bx),trunc(by),ball);
  if floor<nfloors then showladder;
  bxs:=bx; bys:=by;
  { motion }
  bx:=bx+bxspeed; by:=by+byspeed;
  { check for borders }
  if bx>=conv(xsize-4) then begin
    bx:=conv(xsize-4); bxspeed:=-bxspeed;
  end else if bx<2.0 then begin
    bx:=2.0; bxspeed:=-bxspeed;
  end;
  { check for reflection on ceiling }
  if by>=conv((floor+1)*vfloors-4) then begin
    by:=conv((floor+1)*vfloors-4);
    byspeed:=reflection*byspeed;
  end;
  { check for hole }
  if (bx>=conv(holes[floor])) and
      (bx<=conv(holes[floor]+holesize-4)) and
     (by<=conv(floor*vfloors+1)) then begin
     { fall through hole }
    byspeed:=byspeed+gravity;
    if floor>0 then floor:=floor-1;
  end else if by<conv(floor*vfloors+1) then begin
    { reflection on floor }
    by:=conv(floor*vfloors+2); { jump a bit }
    byspeed:=reflection*byspeed;
  end else
    byspeed:=byspeed+gravity;
  { check for border on bottom floor }
  if (by<4.0) and ((bx<=2.0) or (bx>=conv(xsize-4)))
  then begin
    if bx<2.0 then bx:=2.0
    else if bx>=conv(xsize-4) then bx:=conv(xsize-4);
    by:=conv(nfloors*vfloors+1);
    byspeed:=0.0; floor:=nfloors;
  end;
end;

func exkey(key:char):boolean;
{ check for key typed }
begin
  exkey:=key=chr(0);
end;

proc init;
begin
  cleargr;
  bx:=2.0; by:=conv(nfloors*vfloors+1);
  bxs:=bx; bys:=by;
  bxspeed:=2.0; byspeed:=0.0;
  { make and show holes }
  holes[0]:=-holesize;
  for floor:=1 to nfloors do begin
    holes[floor]:=irandom(1,xsize-holesize-1);
    move(0,floor*vfloors);
    draw(xsize-1,floor*vfloors,white);
    move(holes[floor],floor*vfloors);
    draw(holes[floor]+holesize,floor*vfloors,black);
  end;
  { make and show ladders }
  for floor:=0 to nfloors-1 do begin
    repeat
      ladders[floor]:=irandom(2,xsize-laddersize);
      write('.');
    until ((ladders[floor]+laddersize<holes[floor])
      or (ladders[floor]>holes[floor]+holesize)) and
      ((ladders[floor]+laddersize<holes[floor+1])
      or (ladders[floor]>holes[floor+1]+holesize));
      showladder;
  end;
  ladders[nfloors]:=-laddersize;
  floor:=nfloors;
end;

{$I IANIMATE:P}

begin
  grinit; splitview; init;
  animate(false);
  splitview;
end.