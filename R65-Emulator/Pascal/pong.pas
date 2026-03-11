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

          rricharz 2018,2019,2024        }

program pong;
uses syslib,plotlib;

const paddlesize = 24;
      xmin = 40;
      erase = 0; ball = $6ff6;
      cup= chr($1a); cdown = chr($18);
      startspeed = 2.5;
      autorepeat = true;

var i,ypaddle,lastypaddle:integer;
    hit,miss: integer;
    xspeed,yspeed,xball,yball:real;
    lastxball,lastyball:real;

proc showball;
begin
  _plotmap(trunc(lastxball),trunc(lastyball),erase);
  _plotmap(trunc(xball),trunc(yball),ball);
  lastxball:=xball;
  lastyball:=yball;
end;

proc showpaddle;
begin
  if lastypaddle<>-1 then begin
    _move(XSIZE-3,lastypaddle);
    _draw(XSIZE-3, lastypaddle+paddlesize, BLACK);
  end;
  _move(XSIZE-3,ypaddle);
  _draw(XSIZE-3, ypaddle+paddlesize, WHITE);
  lastypadde:=ypaddle;
end;

proc showcount(x,y,count:integer);
var digit: integer;
begin
  digit:=count div 10;
  _move(x,y);
  write(@PLOTDEV,chr(ord('0')+digit),
    chr(ord('0')+_mod(count,10)));
end;

{$I IRANDOM:P}

proc init;
begin
  _grinit;
  _cleargr;
  _move(xmin,0);
  _draw(XSIZE,0,WHITE);
  _draw(XSIZE,YSIZE,WHITE);
  _draw(xmin,YSIZE,WHITE);
  _draw(xmin,0,WHITE);
  xball:=1.0;
  yball:=conv(YSIZE div 2 - 2);
  lastxball:=xball;
  lastyball:=yball;
  xspeed:=rrandom(1.0, startspeed);
  yspeed:=rrandom(1.0,startspeed);
  ypaddle:=(YSIZE-paddlesize) div 2;
  lastypaddle:=-1;
  hit:=0;
  miss:=0;
  _move(1,100);
  write(@PLOTDEV,'Hit ');
  showcount(1,90,hit);
  _move(1,70);
  write(@PLOTDEV,'Miss');
  showcount(1,60,miss);
end;

func expaint: boolean;
begin
  expaint:=false;
  showpaddle;
  xball:=xball+xspeed;
  yball:=yball+yspeed;
  if xball<conv(xmin+2) then begin
    xspeed:=-xspeed;
    xball:=conv(xmin+2);
  end;

  if (yball<=conv(ypaddle+paddlesize+2)) and
    (yball>=conv(ypaddle)) then begin
    if xball>=conv(XSIZE-7) then begin
      hit:=hit+1;
      showcount(1,90,hit);
      xspeed:=-xspeed;
      xball:=conv(XSIZE-7);
    end;
  end else begin
    if xball>=conv(XSIZE-4) then begin
      miss:=miss+1;
      showcount(1,60,miss);
      xspeed:=-xspeed;
      xball:=conv(XSIZE-4);
    end;
  end;
  if yball<2.0 then begin
    yspeed:=-yspeed;
    yball:=2.0
  end else if yball>=conv(YSIZE-4) then begin
    yspeed:=-yspeed;
    yball:=conv(YSIZE-4);
  end;
  showball;
end;

func exkey(KEY:char):boolean;
var ymax:integer;
begin
  ymax:=YSIZE-paddlesize-4;
  if (KEY=cup) and (ypaddle<ymax)  then
    ypaddle := ypaddle+2
  else if (KEY=cdown) and (ypaddle>5) then
    ypaddle := ypaddle-2
  else if KEY=CR then init;
  exkey := KEY=chr(0);
end;

{$I IANIMATE:P}

begin
  init;
  writeln('Type RETURN to start _new game.');
  animate(autorepeat);
  _splitview;
end.
