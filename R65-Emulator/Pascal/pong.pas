{
                ************* *
                *             *
                *   P O N G   *
                *             *
                ***************

This is the pong game for the R65 computer
system. I wrote the original version 1978,
first in Basic, and then in Tiny Pascal.
Unfortunately the original code has been
lost. This is a recreation written 2018 out
of memory to demonstrate the capabilities
of the R65 computer system.

          rricharz 2018,2019,2024,2026        }

program pong;
uses syslib,plotlib,ledlib,writelib,strlib,mathlib;

const paddlesize  = 18;
      erase       = 0;

      ball        = $6ff6;
      paddleend   = $6ff6;

      cup         = chr($1a);
      cdown       = chr($18);

      startspeed  = 2.5;
      autorepeat  = true;


      MAXBALLTIME=1000; { approximately 33 seconds }
      FLASHTIME=33;     { approximately 1 second }

var i,ypaddle,
      lastypaddle:  integer;
    score:          integer;
    xspeed,yspeed,
      xball,yball:  real;
    lastxball,
      lastyball:    real;

    ytarget:        integer;
    paddlespeed:    integer;
    xpaddle:        integer;

    s:cpnt;


    balltime,
      flashtime:    integer;
    ballspeed:      real;

{$I IRANDOM:P}

proc showball;
{************}
begin
  _plotmap(floor(lastxball),floor(lastyball),erase);
  _plotmap(floor(xball),floor(yball),ball);
  lastxball:=xball;
  lastyball:=yball;
end;

proc newball;
{***********}
begin
  xball:=1.0;
  yball:=conv(YSIZE div 2 - 2);
  lastxball:=xball;
  lastyball:=yball;
  xspeed:=rrandom(1.0,startspeed);
  yspeed:=rrandom(1.0,startspeed);
  ballspeed:=sqrt(xspeed*xspeed+yspeed*yspeed);
end;

proc flashball;
{*************}
begin
  if (_mod(flashtime,5))<3 then
    _plotmap(floor(xball),floor(yball),ball)
  else
    _plotmap(floor(xball),floor(yball),erase);
end;

proc showpaddle;
{**************}
begin
  if lastypaddle<>-1 then begin
    _move(xpaddle,lastypaddle+2);
    _draw(xpaddle,lastypaddle+paddlesize-2,BLACK);
    _plotmap(xpaddle-1,lastypaddle,erase);
    _plotmap(xpaddle-1,lastypaddle+paddlesize-4,
      erase);
  end;

  _move(xpaddle,ypaddle+2);
  _draw(xpaddle,ypaddle+paddlesize-2,WHITE);
  _plotmap(xpaddle-1,ypaddle,paddleend);
  _plotmap(xpaddle-1,ypaddle+paddlesize-4,paddleend);

  lastypaddle:=ypaddle;
end;

proc showscore;
{*************}
begin
  if score>9999 then score:=9999;
  if score<0 then score:=0;
  s[0]:=ENDMARK;
  write(@s,10000+score:6);
  s[1]:=' ';
  _ledstring(s);
end;

proc wallcorrection;
{******************}
const
  correction=0.05;
  randomness=0.02;
var
  ax,ay,d,f:real;
begin
  ax:=fabs(xspeed);
  ay:=fabs(yspeed);

  { Gradually bring the components closer together }
  d:=correction*(ay-ax);
  ax:=ax+d;
  ay:=ay-d;

  { Add a small random variation }
  ax:=ax+rrandom(-randomness,randomness);
  ay:=ay+rrandom(-randomness,randomness);

  { Prevent zero or negative components }
  if ax<0.1 then ax:=0.1;
  if ay<0.1 then ay:=0.1;

  { Restore the original ball speed }
  f:=ballspeed/sqrt(ax*ax+ay*ay);

  if xspeed<0.0 then
    xspeed:=-ax*f
  else
    xspeed:=ax*f;

  if yspeed<0.0 then
    yspeed:=-ay*f
  else
    yspeed:=ay*f;
end;

proc mousepaddle;
{***************}
mem dragy=$170c:integer&;
var y:integer;
begin
  y:=dragy;
  if y<>255 then begin
    ytarget:=y-paddlesize div 2;
    if ytarget<0 then ytarget:=0;
    if ytarget>YSIZE-paddlesize-1 then
      ytarget:=YSIZE-paddlesize-1;
  end;
end;

proc init;
{********}
begin
  s:=_new;
  _grinit;
  _cleargr;
  xpaddle:=XSIZE-6;
  newball;
  ypaddle:=(YSIZE-paddlesize) div 2;
  lastypaddle:=-1;
  ytarget:=ypaddle;
  paddlespeed:=2;
end;

proc movepaddle;
{**************}
begin
  if ypaddle<ytarget then begin
    ypaddle:=ypaddle+paddlespeed;
    if ypaddle>ytarget then ypaddle:=ytarget;
  end else if ypaddle>ytarget then begin
    ypaddle:=ypaddle-paddlespeed;
    if ypaddle<ytarget then ypaddle:=ytarget;
  end;
end;

proc rightreflection;
{*******************}
var
  bx,by,cx,cy,dx,dy,d2,dot,f,l:real;
  oldbx:real;
  reflected:boolean;
begin
  if xspeed<=0.0 then exit;

  { Ball centre, before and after movement }
  bx:=xball+1.5;
  by:=yball+1.5;
  oldbx:=bx-xspeed;

  reflected:=false;

  { Straight section of paddle }
  if (oldbx<conv(xpaddle)-2.5) and
     (bx>=conv(xpaddle)-2.5) and
     (by>=conv(ypaddle)+1.5) and
     (by<=conv(ypaddle+paddlesize)-2.5) then begin
    xspeed:=-xspeed;
    xball:=conv(xpaddle)-4.0;
    reflected:=true;
  end;

  { Rounded ends }
  if not reflected then begin

    cx:=conv(xpaddle)+0.5;

    if by<conv(ypaddle+paddlesize div 2) then
      cy:=conv(ypaddle)+1.5
    else
      cy:=conv(ypaddle+paddlesize)-2.5;

    dx:=bx-cx;
    dy:=by-cy;
    d2:=dx*dx+dy*dy;

    if (d2<=16.0) and (d2>0.0) then begin
      dot:=xspeed*dx+yspeed*dy;

      if dot<0.0 then begin
        f:=2.0*dot/d2;
        xspeed:=xspeed-f*dx;
        yspeed:=yspeed-f*dy;

        { Move ball back to surface }
        l:=sqrt(d2);
        bx:=cx+4.0*dx/l;
        by:=cy+4.0*dy/l;

        xball:=bx-1.5;
        yball:=by-1.5;

        reflected:=true;
      end;
    end;
  end;

  if reflected then begin
    score:=score+100;
    showscore;
  end else if xball>=conv(XSIZE-2) then begin
    score:=score-25;
    if score<0 then score:=0;
    showscore;
    xspeed:=-xspeed;
    xball:=conv(XSIZE-2);
  end;
end;

func expaint: boolean;
{********************}
begin
  expaint:=false;

  mousepaddle;
  movepaddle;
  showpaddle;

  if flashtime>0 then begin
    flashtime:=flashtime-1;
    flashball;
    if flashtime=0 then begin
      _plotmap(floor(xball),floor(yball),erase);
      newball;
      showball;
      balltime:=0;
    end;
    exit;
  end;

  balltime:=balltime+1;

  if balltime>MAXBALLTIME then begin
    flashtime:=FLASHTIME;
    exit;
  end;

  xball:=xball+xspeed;
  yball:=yball+yspeed;

  if xball<2.0 then begin
    xspeed:=-xspeed;
    xball:=2.0;
    wallcorrection;
    balltime:=0;
  end;

  rightreflection;

  if yball<2.0 then begin
    yspeed:=-yspeed;
    yball:=2.0;
    wallcorrection;
  end else if yball>=conv(YSIZE-2) then begin
    yspeed:=-yspeed;
    yball:=conv(YSIZE-2);
    wallcorrection;
  end;

  showball;
end;

func exkey(KEY:char):boolean;
{***************************}
var ymax:integer;
begin
  ymax:=YSIZE-paddlesize-2;
  if KEY=cup then begin
    ytarget:=ytarget+2;
    if ytarget>ymax then ytarget:=ymax;
  end else if KEY=cdown then begin
    ytarget:=ytarget-2;
    if ytarget<5 then ytarget:=5;
  end else if KEY=CR then init;
  exkey:=KEY=chr(0);
end;

proc exmouse(mode,x,y:integer);
{*****************************}
begin
end;

{$I IANIMATE:P}

begin
  init;
  balltime:=0;
  flashtime:=0;
  score:=0;
  showscore;
  writeln('Type RETURN to start a new game.');
  animate(autorepeat);
  _splitview;
  _release(s);
end.
