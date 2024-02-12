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
  plotmap(trunc(lastxball),trunc(lastyball),erase);
  plotmap(trunc(xball),trunc(yball),ball);
  lastxball:=xball;
  lastyball:=yball;
end;

proc showpaddle;
begin
  if lastypaddle<>-1 then begin
    move(xsize-3,lastypaddle);
    draw(xsize-3, lastypaddle+paddlesize, black);
  end;
  move(xsize-3,ypaddle);
  draw(xsize-3, ypaddle+paddlesize, white);
  lastypadde:=ypaddle;
end;

proc showcount(x,y,count:integer);
var digit: integer;
begin
  digit:=count div 10;
  move(x,y);
  write(@plotdev,chr(ord('0')+digit),
    chr(ord('0')+mod(count,10)));
end;

{$I IRANDOM:P}

proc init;
begin
  grinit;
  cleargr;
  move(xmin,0);
  draw(xsize,0,white);
  draw(xsize,ysize,white);
  draw(xmin,ysize,white);
  draw(xmin,0,white);
  xball:=1.0;
  yball:=conv(ysize div 2 - 2);
  lastxball:=xball;
  lastyball:=yball;
  xspeed:=rrandom(1.0, startspeed);
  yspeed:=rrandom(1.0,startspeed);
  ypaddle:=(ysize-paddlesize) div 2;
  lastypaddle:=-1;
  hit:=0;
  miss:=0;
  move(1,100);
  write(@plotdev,'Hit ');
  showcount(1,90,hit);
  move(1,70);
  write(@plotdev,'Miss');
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
    if xball>=conv(xsize-7) then begin
      hit:=hit+1;
      showcount(1,90,hit);
      xspeed:=-xspeed;
      xball:=conv(xsize-7);
    end;
  end else begin
    if xball>=conv(xsize-4) then begin
      miss:=miss+1;
      showcount(1,60,miss);
      xspeed:=-xspeed;
      xball:=conv(xsize-4);
    end;
  end;
  if yball<2.0 then begin
    yspeed:=-yspeed;
    yball:=2.0
  end else if yball>=conv(ysize-4) then begin
    yspeed:=-yspeed;
    yball:=conv(ysize-4);
  end;
  showball;
end;

func exkey(key:char):boolean;
var ymax:integer;
begin
  ymax:=ysize-paddlesize-4;
  if (key=cup) and (ypaddle<ymax)  then
    ypaddle := ypaddle+2
  else if (key=cdown) and (ypaddle>5) then
    ypaddle := ypaddle-2
  else if key=cr then init;
  exkey := key=chr(0);
end;

{$I IANIMATE:P}

begin
  init;
  writeln('Type RETURN to start new game.');
  animate(autorepeat);
  splitview;
end.
