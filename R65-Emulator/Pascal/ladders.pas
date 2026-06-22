{ ***********************************
  *  LADDERS: climb up the ladders  *
  ***********************************

  Demo mode: ladders /D

  2024-2026 rricharz                      }

program ladders;
uses  syslib,plotlib,ledlib,arglib,strlib,
      spritelib, striolib, writelib;

const ERASE         = 0;
      BALL          = $6ff6;

      NFLOORS       = 5;
      VFLOORS       = 20;
      MAXBYSPEED    = 19.0;
      HOLESIZE      = 22;
      HOLEMARGIN    = 4;

      GRAVITY       = -0.25;
      REFLECTION    = -0.85;

      FXSTEPSIZE    = 2.0;

      LADDERSIZE    = 9;  { should be odd }
      MINDIST       = 12; { distance between ladders }
      SNAPWIDTH     = 6.0; { keep walking to ladder }
      LADDTOL       = 2;
      SETPAUSE      = 8; { frames to pause at ladder }

      LOOPSPERFRAME = 2;
      LASTXTIME     = 4; { frames }
      JUMPOFFSPEED  = 2.0;

      XDOORSIZE     = 9; { should be odd }
      YDOORSIZE     = 12;

      EWAIT         = 20; { wait tics at bottom/top }
      ETICS         = 4;  { tics per verical step }

      MAXNGEMS      = 10;

      CLEFT         = chr($03);
      CRIGHT        = chr($16);
      CUP           = chr($1a);
      CDOWN         = chr($18);
      JUMPKEY       = ' ';
      ESC           = chr(0);

var bx,bxspeed,bxs:               integer;
    by, bys, fx,fxs:              real;
    byspeed,fxstep,lastfxstep:    real;
    jump,jumpspeed:               real;
    floor,ffloor,fy,fys,fyspeed:  integer;
    score,loopcounter,level:      integer;
    lastfxtimes, pause:           integer;
    demomode:                     boolean;

    efloor,ex,ey,eys,ecount:      integer;
    ewait,eybottom,eytop,edir:    integer;
    on_elev:                      boolean;

    xdoor,ydoor:          array[2] of integer;
    holes,ladders:        array[NFLOORS] of integer;
    xgem, valgem:         array[NFLOORS] of integer;


{$I IRANDOM:P}

func onfloor(f,y:integer):boolean;
begin
  onfloor:=(f*VFLOORS+1=y);
end;

func onupladder(f:integer;x:real):boolean;
var xi,center:integer;
begin
  xi:=trunc(x);
  if (f<0) or (f>=NFLOORS) then
    onupladder:=false
  else begin
    center:=ladders[f]+LADDERSIZE-8;
    onupladder:=(xi>=center-LADDTOL) and
                (xi<=center+LADDTOL);
  end;
end;

func ondownladder(f:integer;x:real):boolean;
var xi,center:integer;
begin
  xi:=trunc(x);
  if (f<=0) or (f>NFLOORS) then
    ondownladder:=false
  else begin
    center:=ladders[f-1]+LADDERSIZE-8;
    ondownladder:=(xi>=center-LADDTOL) and
                  (xi<=center+LADDTOL);
  end;
end;

func onhole(f:integer;x:real):boolean;
var xc: integer;
begin
  xc := trunc(x) + 4;  { center of 8-pixel sprite }
  onhole := (xc >= holes[f]) and
            (xc <= holes[f] + HOLESIZE);
end;

func balloverlap(x1,x2: integer): boolean;
begin
  { ball is bx..bx+3 }
  { require more than 1 pixel overlap }
  balloverlap := (bx+2 >= x1) and (bx+1 <= x2)
end;

proc showfloor(f:integer);
var y:integer;
begin
  y:=f*VFLOORS;
  _move(0,y);
  _draw(holes[f]-HOLEMARGIN,y,WHITE);
  _move(holes[f]+HOLESIZE+HOLEMARGIN,y);
  _draw(XSIZE,y,WHITE);
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
    for i:=1 to 5 do begin
      _move(x1,y1+4*i-1);
      _draw(x2,y1+4*i-1,WHITE);
    end;
  end;
end;

proc showshaft;
begin
  _move(ex,eybottom);
  _draw(ex,eytop,WHITE);
  _move(ex+LADDERSIZE,eybottom);
  _draw(ex+LADDERSIZE,eytop,WHITE);
end;

proc showelevator;
begin
  if eys>eybottom then begin
    _move(ex+1,eys);
    _draw(ex+LADDERSIZE-1,eys,BLACK);
  end;
  _move(ex+1,ey);
  _draw(ex+LADDERSIZE-1,ey,WHITE);
  eys:=ey;
  { show floor element above }
  _move(ex,(efloor+1)*VFLOORS);
  _draw(ex+LADDERSIZE,(efloor+1)*VFLOORS,WHITE);
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
  else if
    valgem[f]=30 then sprite:=S_GEMS+2
  else
    sprite:=S_GEMS+1;
  _showsprite(xgem[f],f*VFLOORS+1,sprite);
end;

proc repairladder(f, xmin, xmax: integer);
begin
  if (ladders[f] < xmax) and
         (ladders[f] + LADDERSIZE > xmin) then begin
    if f <> efloor then
      showladder(f)
    else
      showshaft;
  end;
end;

proc repairdoor(f,xmin,xmax: integer);
var i,x1,x2: integer;
begin
  if f=0 then
    i:=0
  else if f=NFLOORS then
    i:=1
  else
    exit;
  x1:=xdoor[i];
  x2:=x1+XDOORSIZE;
  if (x1 <= xmax) and (x2 >= xmin) then
    showdoor(i);
end;

proc cleargem(f: integer);
begin
  if (f>=0) and (f<=NFLOORS) then
    _showsprite(xgem[f],f*VFLOORS+1,S_CLEAR);
end;

proc repairgem(f,xmin,xmax: integer);
var gx1,gx2: integer;
begin
  if (f>=0) and (f<=NFLOORS) then
    if valgem[f]<>0 then begin
      gx1:=xgem[f];
      gx2:=gx1+7;
      if (gx1 <= xmax) and (gx2 >= xmin) then
        showgem(f);
    end;
end;

proc repair(f,x1,x2: integer);
var xmin,xmax: integer;
begin
  if x1 < x2 then begin
    xmin := x1 - 1;
    xmax := x2 + 8;
  end else begin
    xmin := x2 - 1;
    xmax := x1 + 8;
  end;
  repairladder(f, xmin, xmax);
  repairdoor(f, xmin, xmax);
  repairgem(f, xmin, xmax);
end;

proc showplayer;
var fysum, frame, spriteindex:integer;
begin
  frame := loopcounter div LOOPSPERFRAME;
  fysum:=fy+trunc(jump);

  if jump > 0.0 then begin
    if fxstep > 0.0 then
      spriteindex := S_JUMPR + frame
    else
      spriteindex := S_JUMPL + frame
  end else if fyspeed > 0 then
    spriteindex := S_UP + frame
  else if fyspeed < 0 then
    spriteindex := S_DOWN + frame
  else if fxstep = 0.0 then
    spriteindex := S_STANDING
  else if fxstep >0.0 then
    spriteindex := S_RIGHT + frame
  else
    spriteindex := S_LEFT + frame;
  _showsprite(trunc(fxs),fys,S_CLEAR);
  _showsprite(trunc(fx),fysum, spriteindex);
  repair(ffloor, trunc(fxs), trunc(fx));
  fxs:=fx; fys:=fysum;
  loopcounter := loopcounter + 1;
  if loopcounter >= (3 * LOOPSPERFRAME) then
    loopcounter := 0;
end;

proc moveelevator;
begin
  if ewait > 0 then begin
    ewait:=ewait-1;
    exit
  end;
  ecount:=ecount+1;
  if ecount >= ETICS then begin
    ecount := 0;
    ey := ey + edir;
    if ey >= eytop then begin
      ey := eytop;
      edir := -1;
      ewait := EWAIT
    end
    else if ey <= eybottom then begin
      ey := eybottom;
      edir := 1;
      ewait := EWAIT
    end
  end;
end;

proc flashplayer;
var i,j,f,time: integer;
begin
  for i:=1 to 4 do begin
    _showsprite(trunc(fxs),fys,S_STANDING);
    repair(ffloor,trunc(fxs), trunc(fxs));
    for j:= 0 to 2 do
        time:=_syncscreen;
    _showsprite(trunc(fxs),fys,S_CLEAR);
    repair(ffloor,trunc(fxs), trunc(fxs));
    for j:= 0 to 2 do
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

proc tryladderup;
begin
  if (ffloor<NFLOORS) and (ffloor<>efloor) and
     onupladder(ffloor,fx)
  then begin
    fx:=conv(ladders[ffloor]+1);
    fyspeed:=1;
    fxstep:=0.0;
    lastfxstep:=0.0;
  end;
end;

proc tryladderdown;
begin
  if (ffloor>0) and (ffloor<>efloor+1) and
     ondownladder(ffloor,fx)
  then begin
    floor:=ffloor-1;
    fx:=conv(ladders[ffloor-1]+1);
    fyspeed:=-1;
    fxstep:=0.0;
    lastfxstep:=0.0;
  end;
end;

proc showball;
begin
  _plotmap(bxs,trunc(bys),ERASE);
  _plotmap(bx,trunc(by),BALL);
  repair(floor,bxs,bx);
end;

proc eraseball;
begin
  _plotmap(bxs,trunc(bys),ERASE);
  repair(floor,bxs,bx);
end;

proc newball;
begin
  bx:=2;
  floor:=NFLOORS;
  by:=conv((floor+1)*VFLOORS-6);
  showball;
  bxs:=bx;
  bys:=by;
  bxspeed:=2; byspeed:=0.0
end;

func crossup(yline: real): boolean;
begin
  crossup := (bys < yline) and (by >= yline)
end;

func crossdown(yline: real): boolean;
begin
  crossdown := (bys > yline) and (by <= yline)
end;

proc hreflect(xline: integer);
begin
  if (bxs < xline) and (bx >= xline) then begin
    bx := xline - 1;
    bxspeed := -bxspeed
  end
  else if (bxs > xline) and (bx <= xline) then begin
    bx := xline + 1;
    bxspeed := -bxspeed
  end
end;

proc nextround;
begin
  eraseball;
  flashplayer;
  fx:=conv(xdoor[0]+XDOORSIZE-8);
  fy:=ydoor[0];
  fxstep:=0.0;
  ffloor:=0;
  fyspeed:=0;
  showresult;
  newball;
end;

func airborne(f:integer; fy:integer): boolean;
begin
  airborne := (not onfloor(f, fy)) or (jump > 0.01);
end;

proc checkcrossing(f: integer; var x: real);
var center: real;

  proc checkcenter(c: real);
  begin
    if fxstep > 0.0 then begin
      if (x < c) and (x + fxstep >= c) then begin
        x := c;
        fxstep := 0.0;
        pause := SETPAUSE;
      end;
    end else if fxstep < 0.0 then begin
      if (x > c) and (x + fxstep <= c) then begin
        x := c;
        fxstep := 0.0;
        pause := SETPAUSE;
      end;
    end;
  end;

begin
  if pause > 0 then
    pause := pause - 1
  else begin
    if (f >= 0) and (f < NFLOORS) then begin
      center := conv(ladders[f] + LADDERSIZE - 8);
      checkcenter(center);
    end;

    if (pause = 0) and (f > 0) then begin
      center := conv(ladders[f-1] + LADDERSIZE - 8);
      checkcenter(center);
    end;
  end;
end;

func expaint: boolean;
{ paint picture and apply motion }
var f,distx,fxt:integer;
    yline:real;
    s:cpnt;

  func holeahead(f:integer; x,xstep:real):boolean;
  var xc,nextxc: integer;
  begin
    if xstep = 0.0 then
      holeahead:=false
    else begin
      xc:=trunc(x)+4;
      nextxc:=trunc(x + 3.0*xstep)+4;
      if xstep > 0.0 then
        holeahead:=(xc < holes[f]) and
                    (nextxc >= holes[f])
      else
         holeahead:=(xc > holes[f]+HOLESIZE) and
                    (nextxc <= holes[f]+HOLESIZE);
    end;
  end;

begin
  if score>=10000 then begin
    expaint:=true;
    exit;
  end;
  expaint:=false;

  { ***** HANDLE DEMO MODE ***** }

  if  demomode and (jump<0.01) then begin
    if valgem[ffloor]>0 then begin
      { first collect gem }
      if xgem[ffloor]<trunc(fx) then
        fxstep := -FXSTEPSIZE
      else
        fxstep := FXSTEPSIZE;
    end else begin
      if ffloor=NFLOORS then fxstep := FXSTEPSIZE
      else if (ffloor<NFLOORS) and
                            onupladder(ffloor,fx)
      then tryladderup
      else if onfloor(ffloor,fy) then  begin
        if (trunc(fx)>=ladders[ffloor]+1) then begin
          if fxstep>1.0 then fxstep:=0.0
          else fxstep:=-FXSTEPSIZE;
        end else begin
          if fxstep<-1.0 then fxstep:=0.0
          else fxstep := FXSTEPSIZE
        end;
      end;
    end;
    if (jump < 0.01) and onfloor(ffloor,fy) then
      if holeahead(ffloor,fx,fxstep) then begin
        jumpspeed := JUMPOFFSPEED;
        jump := 0.01;
      end;
    if pause > 0 then fxstep := 0.0;
  end;

  { ***** HANDLE MOOVING OBJECTS ***** }

  moveelevator;

  { ***** HANDLE THE PLAYER ***** }

  { remember fxstep for airborne state }
  if not airborne(ffloor, fy) then begin
    if fxstep <> 0.0 then begin
      lastfxstep := fxstep;
      lastfxtimes := LASTXTIME;
    end else begin
      if lastfxtimes > 0 then
        lastfxtimes := lastfxtimes - 1
      else
        lastfxstep := 0.0;
    end;
  end;
  { check for exit on top floor }
  if (ffloor=NFLOORS) and
     (trunc(fx) >= xdoor[1]) then begin
    score:=score+100;
    { align player with door before flashing/reset }
    fx:=conv(xdoor[0]+XDOORSIZE-8);
    fy:=ydoor[1];
    nextround;
    init;
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
  { ride elevator }
  if on_elev then begin
    fx:=conv(ex+1);
    fy:=ey+1;
    if (ey<>eytop) and (ey<>eybottom) then
      fxstep:=0.0
    else if fxstep<>0.0 then begin
      on_elev:=false;
      fx:=fx+fxstep; { move off already a bit }
    end;
    fyspeed:=0;
    if ey=eytop then
      ffloor:=efloor+1
    else if ey=eybottom then
      ffloor:=efloor
      end;
  if not on_elev then begin
    { move player }
    checkcrossing(ffloor, fx);
    if airborne(ffloor, fy) then
      fx := fx + lastfxstep
    else
      fx := fx + fxstep;
    fy:=fy+fyspeed;
    if fx>conv(XSIZE-8) then begin { right wall }
      fx:=conv(XSIZE-8); fxstep:=0.0;
    end;
    if (fx<1.0) then begin { left wall }
      fx:=1.0; fxstep:=-0.0;
    end;
    { check for player hitting gem }
    distx:=_abs(trunc(fx)-xgem[ffloor]);
    if (distx<8) then begin
      score:=score+valgem[ffloor];
      showresult;
      cleargem(ffloor);
      valgem[ffloor]:=0;
    end;
    { jump }
    jump:=jump+jumpspeed;
    jumpspeed:=jumpspeed+GRAVITY;
    if jump <= 0.0 then begin
      if onhole(ffloor,fx) then begin
        { continue falling to next floor }
        ffloor := ffloor - 1;
        jump := jump + conv(VFLOORS);
        fy := ffloor * VFLOORS + 1;
      end
      else begin
        { normal landing }
        jump := 0.0;
        jumpspeed := 0.0;
      end;
    end;
  end;

  { ***** HANDLE THE BALL ***** }

  { move ball }
  bxs:=bx; bys:=by;
  bx:=bx+bxspeed; by:=by+byspeed;
  { check for wall }
  if bx>=XSIZE-4 then begin
    bx:=XSIZE-4; bxspeed:=-bxspeed;
  end else if bx<1 then begin
    bx:=1; bxspeed:=-bxspeed;
  end;
  { check for reflection on ceiling }
  yline := conv((floor+1)*VFLOORS-4);
  if crossup(yline) then begin
    by := yline;
    byspeed := REFLECTION*byspeed
  end;
  { check for reflection on the floor }
  yline := conv(floor*VFLOORS+1);
  if (balloverlap(holes[floor],
          holes[floor]+HOLESIZE-1))
          and (by<=yline) then begin
    { fall through hole hole }
    if floor>0 then floor:=floor-1;
  end else if (by<yline) or crossdown(yline) then
  begin
    { reflection on floor }
    by:=yline+1.0; { jump a bit }
    byspeed:=REFLECTION*byspeed;
  end;
  byspeed:=byspeed+GRAVITY;
  if byspeed > MAXBYSPEED then
    byspeed := MAXBYSPEED
  else if byspeed < -MAXBYSPEED then
    byspeed := -MAXBYSPEED;
  { check for border on bottom floor }
  if (by<8.0) and ((bx<=2) or (bx>=XSIZE-4))
  then begin
    newball;
  end;

  { *** check for hit *** }
  if (bx>=trunc(fx)-4) and (bx<=trunc(fx)+8) and
     (trunc(by)>=fy-4) and (trunc(by)<=fy+8)
    then begin
      nextround;
      { avoid endless loop in demo mode }
      if demomode then begin
        init;
        exit;
      end;
    end;

  { ***** paint ***** }

  { paint ball }
  showball;
  { paint player }
  if fyspeed<>0 then
    if trunc(fx)<>ladders[ffloor]+1 then
      writeln('bad climb x ',trunc(fx),
              ' should ',ladders[ffloor]+1,
              ' floor ',ffloor);
  showplayer;
  { paint moving elevator }
  showelevator;
  { ride elevator }
  if not on_elev then begin
    if (ffloor=efloor) and (ey=eybottom) and
       onupladder(ffloor,fx) then begin
      on_elev:=true;
      fxstep:=0.0;
      fyspeed:=0;
    end
  end;
  fyspeed:=0;
  if not airborne(ffloor,fy) then
    if pause = 0 then
      fxstep := 0.0;
end;

proc savescore;
var f:file;
begin
  _strfio('LADDERSCORE:B',0,1);
  openw(f);
  writeln(@f,score);
  close(f);
end;

proc loadscore;
var f:file;
begin
  IOCHECK := false;
  FILERR := 0;
  _strfio('LADDERSCORE:B',0,1);
  openr(f);
  if (FILERR<>0) then
  writeln(INVVID,'No stored score available',NORVID)
  else if not _readint(f,score) then score:=0;
  close(f);
  IOCHECK := true;
end;

func exkey(key:char):boolean;
{ check for key typed }

  func canwalk:boolean;
  begin
    canwalk := (pause = 0) and onfloor(ffloor,fy)
               and (jump<=0.01)
  end;

begin
  exkey := (key = ESC);
  case key of
    CUP:      tryladderup;
    CDOWN:    tryladderdown;
    CLEFT:    if canwalk then
                fxstep := -FXSTEPSIZE;
    CRIGHT:   if canwalk then
               fxstep := FXSTEPSIZE;
    JUMPKEY:  begin
                if (not airborne(ffloor, fy)) and
                  (not onhole(ffloor, fx)) then begin
                  jumpspeed := JUMPOFFSPEED;
                  { jump a bit further }
                  fxstep := lastfxstep;
                end;
              end;
    'L':    begin
              loadscore;
              showresult;
            end;
    '!':    begin
              score:=score+500; { cheat key }
              showresult;
              init;
            end
   end {case};
end;

proc init;
var f:integer;

  func nearladder(f,x:integer):boolean;
  begin
    if f<=0 then
      nearladder:=false
    else
      nearladder:=_abs(x-ladders[f-1]) <= MINDIST;
  end;

  func nearhole(f,x:integer):boolean;
  begin
    nearhole :=
      (x + LADDERSIZE >= holes[f] - HOLEMARGIN) and
      (x <= holes[f] + HOLESIZE + HOLEMARGIN);
  end;

  func ladderok(f,x:integer):boolean;
  begin
    ladderok := not nearhole(f,x) and
                not nearhole(f+1,x);
  end;

  func gemok(f,x:integer):boolean;
  begin
    gemok:=true;

    { avoid upward ladder starting on this floor }
    if f<NFLOORS then
      if _abs(x-ladders[f]) <= 9 then
        gemok:=false;

    { avoid downward ladder arriving on this floor }
    if f>0 then
      if _abs(x-ladders[f-1]) <= 9 then
        gemok:=false;

    { avoid visible hole on this floor }
    if f>0 then
      if (x >= holes[f]-HOLEMARGIN-8) and
         (x <= holes[f]+HOLESIZE+HOLEMARGIN) then
        gemok:=false;

    { avoid bottom door }
    if f=0 then
      if x < XDOORSIZE+10 then
        gemok:=false;

    { avoid top door }
    if f=NFLOORS then
      if x > XSIZE-XDOORSIZE-10 then
        gemok:=false;
  end;

begin
  pause := 0;
  on_elev:=false;
  _cleargr;
  level:=score div 1000+1;
  if level>9 then level:=9;
  showresult;
  if (level>2) and (not demomode) then begin
    savescore;
    writeln('Level 2 Complete');
    _abort;
  end;
  { initialize ball }
  bxs:=2; bys:=conv(NFLOORS*VFLOORS-10);
  newball;
  { initialize player }
  fx:=3.0; fy:=1; jump:=0.0;  jumpspeed:=0.0;
  fxs:=fx; fys:=fy;
  fxstep:=0.0; fyspeed:=0;
  { make and show holes }
  holes[0]:=-50;
  _move(0,0); _draw(XSIZE,0,WHITE);
  for floor:=1 to NFLOORS do begin
    holes[floor]:=
      irandom(XDOORSIZE+4+HOLEMARGIN,
              XSIZE-HOLESIZE-3-XDOORSIZE-HOLEMARGIN);
    showfloor(floor);
  end;
  { make ladders }
  for floor:=0 to NFLOORS-1 do begin
    repeat
      ladders[floor]:=irandom(2,XSIZE-LADDERSIZE-2);

      if floor=0 then
        if ladders[0] < XDOORSIZE+10 then
          ladders[0]:=XDOORSIZE+10;

    until ladderok(floor,ladders[floor]) and
          not nearladder(floor,ladders[floor]);
  end;
  ladders[NFLOORS]:=-LADDERSIZE;
  floor:=NFLOORS;
  ffloor:=0;
  { make and show doors }
  xdoor[0]:=2;
  ydoor[0]:=1;
  xdoor[1]:=XSIZE-XDOORSIZE-2;
  ydoor[1]:=VFLOORS*NFLOORS+1;
  showdoor(0);
  showdoor(1);
  { make gems }
  for f:=0 to NFLOORS do begin
    repeat
      xgem[f]:=irandom(1,XSIZE-9);
    until gemok(f,xgem[f]);
    valgem[f]:=10;
  end;
  { one coin worth 30 points }
  valgem[irandom(0,NFLOORS)]:=30;
  { make elevator for level 2 }
  ecount:=0;

  if level>=2 then begin
    efloor:=irandom(0,NFLOORS-1);
    ex:=ladders[efloor];
  end else begin
    efloor:=NFLOORS+1; { move off floors }
    ex:=300;           { move off screen }
  end;
  eybottom:=efloor*VFLOORS;
  eytop:=eybottom+VFLOORS;
  ey:=eybottom;
  eys:=eytop;
  edir:=1;
  ewait:=EWAIT;
  { show ladders, elevator and gems }
  for f:=0 to NFLOORS-1 do begin
    if f<>efloor then
      showladder(f);
    showgem(f);
  end;
  showshaft;
  showgem(NFLOORS);
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
  writeln('L load saved score, <arrow> move player');
  init;
  animate(true);
  _splitview;
  showresult;
  writeln('Final score ',score);
  savescore;
end.