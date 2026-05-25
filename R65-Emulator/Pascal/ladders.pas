{ ***********************************
  *  LADDERS: climb up the ladders  *
  ***********************************

  Demo mode: ladders /D

  2024-2026 rricharz                      }

program ladders;
uses syslib,plotlib,ledlib,arglib,strlib,spritelib;

const ERASE         = 0;
      BALL          = $6ff6;

      NFLOORS       = 5;
      VFLOORS       = 20;
      HOLESIZE      = 22;

      GRAVITY       = -0.25;
      REFLECTION    = -0.7;

      LADDERSIZE    = 8;
      LOOPSPERFRAME = 2;
      XDOORSIZE     = 8;
      YDOORSIZE     = 12;

      MAXNGEMS      = 10;

      AUTOREPEAT    = false;
      CLEFT         = chr($03);
      CRIGHT        = chr($16);
      CUP           = chr($1a);
      CDOWN         = chr($18);
      ESC           = chr(0);

var bx, by, bxs, bys, fx,fxs:     real;
    bxspeed, byspeed, fxspeed:    real;
    jump,jumpspeed:               real;
    floor,ffloor,fy,fys,fyspeed:  integer;
    score,loopcounter,level:      integer;
    demomode:                     boolean;
    xdoor,ydoor:          array[2] of integer;
    holes,ladders:        array[NFLOORS] of integer;
    xgem, valgem:         array[NFLOORS] of integer;


{$I IRANDOM:P}

func getoption(opt:char):boolean;
var i,dummy,save_carg:integer;
    options:array[15] of char;
    default:boolean;
begin
  save_carg:=_carg; {save for next call to getoption}
  _agetstring(options,default,dummy,dummy);
  getoption:=false;
  if not default then begin
    if options[0]<>'/' then _argerror(103);
    for i:=1 to 15 do
      if options[i]=opt then getoption:=true;
  end;
  _carg:=save_carg;
end;

func onfloor(f,y:integer):boolean;
begin
  onfloor:=(f*VFLOORS+1=y);
end;

func onupladder(f:integer;x:real):boolean;
begin
  onupladder:=(trunc(x)>=ladders[f]+1) and
    (trunc(x)<=ladders[f]+2);
end;

func ondownladder(f:integer;x:real):boolean;
begin
  if f=0 then ondownladder:=false
  else ondownladder:=(trunc(x)>=ladders[f-1]+1) and
    (trunc(x+0.5)<=ladders[f-1]+2);
end;

func onhole(f:integer;x:real):boolean;
begin
  onhole:=(x>=conv(holes[f]-5)) and
      (x<=conv(holes[f]+HOLESIZE+1));
end;

proc showball;
begin
  _plotmap(trunc(bxs),trunc(bys),ERASE);
  _plotmap(trunc(bx),trunc(by),BALL);
end;

proc showplayer;
var fysum, frame, spriteindex:integer;
begin
  frame := loopcounter div LOOPSPERFRAME;
  fysum:=fy+trunc(jump);

  if jump > 0.0 then begin
    if fxspeed > 0.0 then
      spriteindex := S_JUMPR + frame
    else
      spriteindex := S_JUMPL + frame
  end else if fyspeed > 0 then
    spriteindex := S_UP + frame
  else if fyspeed < 0 then
    spriteindex := S_DOWN + frame
  else if fxspeed = 0.0 then
    spriteindex := S_STANDING + frame
  else if fxspeed >0.0 then
    spriteindex := S_RIGHT + frame
  else
    spriteindex := S_LEFT + frame;
  _showsprite(trunc(fxs),fys,S_CLEAR);
  _showsprite(trunc(fx),fysum, spriteindex);
  fxs:=fx; fys:=fysum;
  loopcounter := loopcounter + 1;
  if loopcounter >= (3 * LOOPSPERFRAME) then
    loopcounter := 0;
end;

proc showladder(f:integer);
var i,x1,x2,y1,y2:integer;
begin
  if f<NFLOORS then begin
    x1:=ladders[f];
    x2:=x1+LADDERSIZE;
    y1:=f*VFLOORS+1;
    y2:=y1+VFLOORS-1;
    _move(x1,y1);
    _draw(x1,y2,WHITE);
    _move(x2,y1);
    _draw(x2,y2,WHITE);
    i:=1;
    for i:=1 to 5 do begin
      _move(x1,y1+4*i-1);
      _draw(x2,y1+4*i-1,WHITE);
    end;
  end;
end;

proc showdoor(i: integer);
var x1, y1,x2,y2: integer;
begin
  x1:=xdoor[i];
  x2:=x1+XDOORSIZE;
  y1:=ydoor[i];
  y2:=y1+YDOORSIZE;
  _move(x1,y1);
  _draw(x1,y2,WHITE);
  _draw(x2,y2,WHITE);
  _draw(x2,y1,WHITE);
  _plot(x2-2,y1+5,WHITE);
end;

proc showgem(f: integer);
var sprite: integer;
begin
  if valgem[f]=0 then sprite:=S_CLEAR
  else sprite:=S_GEMS+valgem[f]-1;
  _showsprite(xgem[f],f*VFLOORS+1,sprite);
end;

proc flashplayer;
var i,time: integer;
begin
  for i:= 1 to 10 do begin
    _showsprite(trunc(fxs),fys,S_STANDING);
    showdoor(1);
    time:=_syncscreen;
    time:=_syncscreen;
    _showsprite(trunc(fxs),fys,S_CLEAR);
    showdoor(1);
    time:=_syncscreen;
    time:=_syncscreen;
  end;
end;

proc init; forward;

proc showresult;
var s:cpnt;
begin
  s:=_new;
  write(@s,level:1,score:7);
  _ledstring(s);
  _release(s);
end;

proc ladderup;
begin
  if (ffloor<NFLOORS) and onupladder(ffloor,fx)
  then begin
    fx:=conv(ladders[ffloor]+1);
    fyspeed:=1; fxspeed:=0.0;
  end;
end;

proc newball;
begin
  bx:=2.0;
  by:=conv(NFLOORS*VFLOORS-6);
  showball;
  bxs:=bx;
  bys:=by;
  bxspeed:=2.0; byspeed:=0.0;
  floor:=NFLOORS;
end;

func expaint: boolean;
{ paint picture and apply motion }
var f,distx,fxt:integer;
    s:cpnt;

  proc nextround;
  begin
    if (score >= 100*level) then begin
      level:=level+1;
    end;
    fx:=3.0; fy:=1;
    fxspeed:=0.0; ffloor:=0;
    fyspeed:=0;
    showresult;
    flashplayer;
    init;
  end;

begin
  if score>32000 then begin
    expaint:=true;
    exit;
  end;
  if demomode and (jump<0.01) then begin
    if valgem[ffloor]>0 then begin
      { first collect gem }
      if xgem[ffloor]<trunc(fx) then
        fxspeed:=-2.0
      else
        fxspeed:=2.0;
    end else begin
      if ffloor=NFLOORS then fxspeed:=2.0 else
      if (ffloor<NFLOORS) and onupladder(ffloor,fx)
      then ladderup
      else if onfloor(ffloor,fy) then  begin
        if (trunc(fx)>=ladders[ffloor]+1) then begin
          if fxspeed>1.0 then fxspeed:=0.0
          else fxspeed:=-2.0;
        end else begin
          if fxspeed<-1.0 then fxspeed:=0.0
          else fxspeed:=2.0
        end;
      end;
    end;
  end;
  expaint:=false;
  { check for exit on top floor }
  if (ffloor=NFLOORS) and (trunc(fx)>=XSIZE-9) then
  begin
    score:=score+10;
    fx:=conv(XSIZE-9);
    nextround;
    exit;
  end;
  { check for next floor on ladder }
  if ffloor<NFLOORS then
    if onfloor(ffloor+1,fy) then begin
      ffloor:=ffloor+1; fyspeed:=0;
    end;
  if ffloor>0 then
    if onfloor(ffloor-1,fy) then begin
      ffloor:=ffloor-1; fyspeed:=0;
    end;
  { move player horizontally }
  fx:=fx+fxspeed; fy:=fy+fyspeed;
  if fx>conv(XSIZE-8) then begin
    fx:=conv(XSIZE-8); fxspeed:=0.0;
  end;
  if (fx<1.0) then begin
    fx:=1.0; fxspeed:=-0.0;
  end;
  { check for player hitting gem }
  distx:=_abs(trunc(fx)-xgem[ffloor]);
  if (distx<8) then begin
    score:=score+valgem[ffloor];
    showresult;
    valgem[ffloor]:=0;
  end;
  { check for player at ladder }
  if onupladder(ffloor,fx) or ondownladder(ffloor,fx)
    then fxspeed:=0.0;
  { check for hole and jump over it }
  if (jump<=0.01) and onhole(ffloor,fx) then begin
    jumpspeed:=1.3; jump:=jump+jumpspeed;
  end else if jump>0.0 then begin
    jump:=jump+jumpspeed;
    jumpspeed:=jumpspeed+GRAVITY;
  end;
  if jump<=0.0 then jump:=0.0;
  { move ball }
  bxs:=bx; bys:=by;
  bx:=bx+bxspeed; by:=by+byspeed;
  { check for borders }
  if bx>=conv(XSIZE-4) then begin
    bx:=conv(XSIZE-4); bxspeed:=-bxspeed;
  end else if bx<2.0 then begin
    bx:=2.0; bxspeed:=-bxspeed;
  end;
  { check for REFLECTION on ceiling }
  if by>=conv((floor+1)*VFLOORS-4) then begin
    by:=conv((floor+1)*VFLOORS-4);
    byspeed:=REFLECTION*byspeed;
  end;
  { check for hole (ball) }
  if (bx>=conv(holes[floor])) and
      (bx<=conv(holes[floor]+HOLESIZE-4)) and
     (by<=conv(floor*VFLOORS+1)) then begin
     { fall through hole }
    byspeed:=byspeed+GRAVITY;
    if floor>0 then floor:=floor-1;
  end else if by<conv(floor*VFLOORS+1) then begin
    { REFLECTION on floor }
    by:=conv(floor*VFLOORS+2); { jump a bit }
    byspeed:=REFLECTION*byspeed;
  end else
    byspeed:=byspeed+GRAVITY;
  { check for border on bottom floor }
  if (by<8.0) and ((bx<=2.0) or (bx>=conv(XSIZE-4)))
  then begin
    newball;
  end;
  { check for hit }
  if (bx>=fx-4.0) and (bx<=fx+8.0) and
     (trunc(by)>=fy-4) and (trunc(by)<=fy+8)
    then begin
      score:=score-10;
      if score<0 then score:=0;
      nextround;
    end;
  showdoor(0);
  showdoor(1);
  { paint ball }
  showball;
  { paint player }
  showplayer;
  { paint ladders and gems }
  for f:=0 to NFLOORS do begin
    showladder(f);
    showgem(f);
  end;
end;

proc ladderdown;
begin
  if (ffloor>0) and ondownladder(ffloor,fx)
  then begin
    fx:=conv(ladders[ffloor-1]+1);
    fyspeed:=-1; fxspeed:=0.0;
  end;
end;

func exkey(key:char):boolean;
{ check for key typed }
begin
  exkey:=(key=ESC);
  case key of
   CUP:    ladderup;
   CDOWN:  ladderdown;
   CLEFT:  if onfloor(ffloor,fy) then
             if fxspeed>1.0 then fxspeed:=0.0
             else fxspeed:=-2.0;
   CRIGHT: if onfloor(ffloor,fy) then
             if fxspeed<-1.0 then fxspeed:=0.0
             else fxspeed:=2.0
   end {case};
end;

proc init;
var f:integer;
begin
  _cleargr;
  showresult;
  { initialize ball }
  bxs:=2.0; bys:=conv(NFLOORS*VFLOORS-10);
  newball;
  { initialize player }
  fx:=3.0; fy:=1; jump:=0.0;  jumpspeed:=0.0;
  fxs:=fx; fys:=fy;
  fxspeed:=0.0; fyspeed:=0;
  { make and show holes }
  holes[0]:=-50;
  _move(0,0); _draw(XSIZE,0,WHITE);
  for floor:=1 to NFLOORS do begin
    holes[floor]:=
      irandom(XDOORSIZE+2,XSIZE-HOLESIZE-1-XDOORSIZE);
    _move(0,floor*VFLOORS);
    _draw(XSIZE-1,floor*VFLOORS,WHITE);
    _move(holes[floor],floor*VFLOORS);
    _draw(holes[floor]+HOLESIZE,floor*VFLOORS,BLACK);
  end;
  { make ladders }
  for floor:=0 to NFLOORS-1 do begin
    repeat
      ladders[floor]:=irandom(2,XSIZE-LADDERSIZE-2);
    until ((ladders[floor]+LADDERSIZE<holes[floor])
      or (ladders[floor]>holes[floor]+HOLESIZE)) and
      ((ladders[floor]+LADDERSIZE<holes[floor+1])
      or (ladders[floor]>holes[floor+1]+HOLESIZE));
    if (floor=0) then
      if (ladders[0] < XDOORSIZE+10) then
        ladders[0]:=XDOORSIZE+10;
  end;
  ladders[NFLOORS]:=-LADDERSIZE;
  floor:=NFLOORS;
  ffloor:=0;
  { make and show doors }
  xdoor[0]:=2;
  ydoor[0]:=0;
  xdoor[1]:=XSIZE-XDOORSIZE-2;
  ydoor[1]:=VFLOORS*NFLOORS;
  showdoor(0);
  showdoor(1);
  { make gems }
  for f:= 0 to NFLOORS do begin
    xgem[f]:=irandom(1,XSIZE-9);
    { make sure gem is not at same place as ladder }
    while (xgem[f]>ladders[f]-9) and
          (xgem[f]<ladders[f]+9) do
      xgem[f]:=irandom(1,XSIZE-9);
    valgem[f]:=1;
  end;
  valgem[irandom(0,NFLOORS)]:=3; { one coin }
  { show ladders and gems }
  for f:=0 to NFLOORS do begin
    showladder(f);
    showgem(f);
  end;
end;

{$I IANIMATE:P}

begin
  score:=0;
  level:=1;
  loopcounter:=0;
  if option('H') then begin
    writeln('/D   endless demo mode');
    exit;
  end;
  demomode:=option('D');
  if demomode then writeln('Demo mode');
  _grinit; _fullview;
  writeln('Reach the exit on the top floor.');
  writeln('Collect gems and avoid the ball.');
  init;
  animate(AUTOREPEAT);
  _splitview;
  showresult;
  writeln('Final score ',score);
end.