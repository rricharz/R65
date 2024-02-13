{ scramble: climb up the ladders }

program scramble;
uses syslib,plotlib;

const erase=0; ball=$6ff6;
      nfloors=5; vfloors=19; holesize=20;
      gravity=-0.25; reflection=-0.4;

var bx,by,bxs,bys,bxspeed,byspeed: real;
    floor: integer;
    holes: array[nfloors] of integer;

{$I IRANDOM:P}

func expaint: boolean;
{ paint picture and apply motion }
begin
  { paint }
  expaint:=false;
  plotmap(trunc(bxs),trunc(bys),erase);
  plotmap(trunc(bx),trunc(by),ball);
  bxs:=bx; bys:=by;
  { motion }
  bx:=bx+bxspeed; by:=by+byspeed;
  if bx>=conv(xsize-4) then begin
    bx:=conv(xsize-4); bxspeed:=-bxspeed;
  end else if bx<2.0 then begin
    bx:=2.0; bxspeed:=-bxspeed;
  end;
  if (bx>=conv(holes[floor])) and
      (bx<=conv(holes[floor]+holesize-4)) then begin
    byspeed:=byspeed+gravity;
    if floor>0 then floor:=floor-1;
  end else if by<=conv(floor*vfloors+1) then begin
    by:=conv(floor*vfloors+2);
    byspeed:=reflection*byspeed;
    if byspeed>4.0 then byspeed:=4.0;
  end else byspeed:=byspeed+gravity;
  if (by<2.5) and ((bx<=2.0) or (bx>=conv(xsize-4)))
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
  holes[0]:=-holesize;
  for floor:=1 to nfloors do begin
    holes[floor]:=irandom(1,xsize-holesize-1);
    move(0,floor*vfloors);
    draw(xsize-1,floor*vfloors,white);
    move(holes[floor],floor*vfloors);
    draw(holes[floor]+holesize,floor*vfloors,black);
  end;
  floor:=nfloors;
end;

{$I IANIMATE:P}

begin
  grinit; splitview; init;
  animate(false);
  splitview;
end.