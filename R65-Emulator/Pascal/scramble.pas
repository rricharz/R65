{ scramble: climb up the ladders }

program scramble;
uses syslib,plotlib;

const erase=0; ball=$6ff6;
      nfloors=5; vfloors=20; holesize=22;
      gravity=-0.25; reflection=-0.7;
      laddersize=8; autorepeat=false;
      cleft=chr($03); cright=chr($16);
      cup=chr($1a); cdown=chr($18); esc=chr(0);
      face1=$8b43; face2=$2a48;
      face3=$034a; face4=$084a;

var bx,by,bxs,bys,bxspeed,byspeed,fx,fxs: real;
    fxspeed,jump: real;
    floor,ffloor,fy,fys,fyspeed: integer;
    holes,ladders: array[nfloors] of integer;

{$I IRANDOM:P}

func onfloor(f,y:integer):boolean;
begin
  onfloor:=(f*vfloors+1=y);
end;

func onupladder(f:integer;x:real):boolean;
begin
  onupladder:=(trunc(x)>=ladders[f]+1) and
    (trunc(x)<=ladders[f]+2);
end;

func ondownladder(f:integer;x:real):boolean;
begin
  ondownladder:=(trunc(x+0.5)>=ladders[f-1]+2) and
    (trunc(x+0.5)<=ladders[f-1]+4);
end;

func onhole(f:integer;x:real):boolean;
begin
  onhole:=(x>=conv(holes[f]+2)) and
      (x<=conv(holes[f]+holesize-6));
end;

proc showface;
var fysum:integer;
begin
  fysum:=fy+trunc(jump);
  plotmap(trunc(fxs),fys,erase);
  plotmap(trunc(fxs)+4,fys,erase);
  plotmap(trunc(fxs),fys+4,erase);
  plotmap(trunc(fxs)+4,fys+4,erase);
  plotmap(trunc(fx),fysum,face1);
  plotmap(trunc(fx)+4,fysum,face2);
  plotmap(trunc(fx),fysum+4,face3);
  plotmap(trunc(fx)+4,fysum+4,face4);
  fxs:=fx; fys:=fysum;
end;

proc showladder(f:integer);
var i,x1,x2,y1,y2:integer;
begin
  if f<nfloors then begin
    x1:=ladders[f]; x2:=x1+laddersize;
    y1:=f*vfloors+1; y2:=y1+vfloors-1;
    move(x1,y1); draw(x1,y2,white);
    move(x2,y1); draw(x2,y2,white);
    i:=1;
    for i:=1 to 5 do begin
      move(x1,y1+4*i-1); draw(x2,y1+4*i-1,white);
    end;
  end;
end;

func expaint: boolean;
{ paint picture and apply motion }
var f:integer;
begin
  expaint:=false;
  { check for next floor on ladder }
  if ffloor<nfloors then
    if onfloor(ffloor+1,fy) then begin
      ffloor:=ffloor+1; fyspeed:=0;
    end;
  if ffloor>0 then
    if onfloor(ffloor-1,fy) then begin
      ffloor:=ffloor-1; fyspeed:=0;
    end;
  { paint face }
  showface;
  { paint ball }
  plotmap(trunc(bxs),trunc(bys),erase);
  plotmap(trunc(bx),trunc(by),ball);
  for f:=0 to nfloors-1 do showladder(f);
  bxs:=bx; bys:=by;
  { move face }
  fx:=fx+fxspeed; fy:=fy+fyspeed;
  if fx>conv(xsize-8) then begin
    fx:=conv(xsize-8); fxspeed:=0.0;
  end;
  if (fx<1.0) then begin
    fx:=1.0; fxspeed:=-0.0;
  end;
  { check for ladder }
  if onupladder(ffloor,fx) or ondownladder(ffloor,fx)
    then fxspeed:=0.0;
  { check for hole (face) }
  if (jump<=0.0) and onhole(ffloor,fx) then jump:=4.5
  else jump:=jump-0.3;
  if jump<=0.0 then jump:=0.0;
  { move ball }
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
  { check for hole (ball) }
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
  { check for hit }
  if (bx>=fx-4.0) and (bx<=fx+8.0) and
     (trunc(by)>=fy-4) and (trunc(by)<=fy+8)
    then begin
     writeln('Hit');
     expaint:=true;
    end;
end;

proc ladderup;
begin
  if (ffloor<nfloors) and onupladder(ffloor,fx)
  then begin
    fyspeed:=1; fxspeed:=0.0;
  end;
end;

proc ladderdown;
begin
  if (ffloor>0) and ondownladder(ffloor,fx)
  then begin
    fyspeed:=-1; fxspeed:=0.0;
  end;
end;

func exkey(key:char):boolean;
{ check for key typed }
begin
  exkey:=(key=esc);
  case key of
   ' ':    write('*');
   cup:    ladderup;
   cdown:  ladderdown;
   cleft:  if onfloor(ffloor,fy) then fxspeed:=-2.0;
   cright: if onfloor(ffloor,fy) then fxspeed:=2.0
   end {case};
end;

proc init;
begin
  cleargr;
  bx:=2.0; by:=conv(nfloors*vfloors+1);
  bxs:=bx; bys:=by;
  bxspeed:=2.0; byspeed:=0.0;
  fx:=1.0; fy:=1; jump:=0.0;
  fxs:=fx; fys:=fy;
  fxspeed:=0.0; fyspeed:=0;
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
    until ((ladders[floor]+laddersize<holes[floor])
      or (ladders[floor]>holes[floor]+holesize)) and
      ((ladders[floor]+laddersize<holes[floor+1])
      or (ladders[floor]>holes[floor+1]+holesize));
      showladder(floor);
  end;
  ladders[nfloors]:=-laddersize;
  floor:=nfloors;
  ffloor:=0;
end;

{$I IANIMATE:P}

begin
  grinit; fullview; init;
  animate(autorepeat);
  splitview;
end.