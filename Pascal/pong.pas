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

          rricharz 2018,2019             }

program pong;
uses syslib,plotlib;

const paddlesize = 24;
      xmin = 40;

var i,xball,yball,lastxball,lastyball,
    ypaddle,lastypaddle,maxx,maxy,xspeed,
    yspeed,hit,miss,dummy: integer;

proc showball;
begin
  lastxball:=xball;
  lastyball:=yball;
  plot(xball shr 3, yball shr 3,white);
  plot((xball shr 3)+1, yball shr 3,white);
  plot(xball shr 3, (yball shr 3)+1,white);
  plot((xball shr 3)+1, (yball shr 3)+1,
                          white);
end;

proc eraseball;
begin
  plot(lastxball shr 3,
               lastyball shr 3,black);
  plot((lastxball shr 3)+1,
               lastyball shr 3,black);
  plot(lastxball shr 3,
               (lastyball shr 3)+1,black);
  plot((lastxball shr 3)+1,
               (lastyball shr 3)+1,black);
end;

proc init;
begin
  grinit;
  cleargr;
  move(xmin,0);
  draw(xsize,0,white);
  draw(xsize,ysize,white);
  draw(xmin,ysize,white);
  draw(xmin,0,white);
  maxx:=(xsize-1) shl 3;
  maxy:=(ysize-1) shl 3;
  xball:=xsize shl 2;
  yball:=2 shl 3;
  xspeed:=16 + random shr 3;
  yspeed:=16 + random shr 3;
  ypaddle:=(ysize-paddlesize) div 2;
  lastypaddle:=-1;
  hit:=0;
  miss:=0;
end;

proc showpaddle;
begin
  if lastypaddle = -1 then begin
    move(xsize-3,ypaddle);
    draw(xsize-3, ypaddle+paddlesize,
    white);
  end else begin
    if ypaddle<lastypaddle then begin
      move(xsize-3,ypaddle);
      draw(xsize-3,
        lastypaddle-1,white);
      move(xsize-3,ypaddle+paddlesize+1);
      draw(xsize-3,
        lastypaddle+paddlesize,black);
    end else begin
      move(xsize-3,lastypaddle);
      draw(xsize-3,
        ypaddle-1,black);
      move(xsize-3,
        lastypaddle+paddlesize+1);
      draw(xsize-3,
        ypaddle+paddlesize,white);
    end
  end;
  lastypaddle:=ypaddle;
end;

proc showcount(x,y,count:integer);
var digit: integer;
begin
  digit:=count div 10;
  move(x,y);
  write(@plotdev,chr(ord('0')+digit),
    chr(ord('0')+mod(count,10)));
end;

begin
  init;
  move(1,100);
  write(@plotdev,'Hit ');
  showcount(1,90,hit);
  move(1,70);
  write(@plotdev,'Miss');
  showcount(1,60,miss);
  showball;
  showpaddle;
  repeat
    xball:=xball+xspeed;
    yball:=yball+yspeed;
    if xball<(8*xmin)+9 then begin
      xspeed:=abs(xspeed);
      xball:=8*xmin+9;
    end
    else if (xball>=maxx-32) then begin
      if (yball>=8*(ypaddle-1)) and
        (yball<=8*(ypaddle+paddlesize+1))
      then begin
        hit:=hit+1;
        showcount(1,90,hit);
        xspeed:=-xspeed;
      end
      else begin
        miss:=miss+1;
        showcount(1,60,miss);
        delay10msec(100);
        xspeed:=-16 - random shr 3;
        yspeed:=16 + random shr 3;
      end;
      xball:=maxx-32;
    end;
    if yball<8 then begin
      yspeed:=abs(yspeed);
      yball:=8
    end
    else if yball>=maxy then begin
      yspeed:=-yspeed;
      yball:=maxy-1
    end;
    if (keypressed<>chr(0)) then begin
      if (keypressed = chr($1a)) and
        (ypaddle<(ysize-paddlesize-4))
          then
            ypaddle := ypaddle+4;
      if (keypressed = chr($18)) and
        (ypaddle>4)
          then
            ypaddle := ypaddle-4;
      keypressed:=chr(0);
      if (ypaddle<>lastypaddle) then
        showpaddle;
    end;
    dummy:=syncscreen;
    if (xball<>lastxball) or
       (yball<>lastyball) then begin
      eraseball;
      showball;
    end;
  until (miss>=10) or (hit>=10);
  grend;
  writeln('Score:');
  writeln('Hit  ',hit);
  writeln('Miss ',miss);
end.

