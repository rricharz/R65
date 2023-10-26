{
        ******************
        *                *
        *  ALIEN INVADER *
        *                *
        ******************

This is the ALIEN game for the R65
computer system. I wrote the original
version 1978, first in Basic, and then
in Tiny Pascal. Unfortunately the original
code has been lost. This is a recreation
written 2018 out of memory to demonstrate
the capabilities of the R65 computer
system.

          rricharz 2018,2019             }

program alien;
uses syslib,plotlib;

const erase=0;

var shipmap: array[1] of integer;
    birdmap: array[3] of integer;

    shipx,shipy,sspeedx,sspeedy,
    lastsx,lastsy,birdx,birdy,
    lastbirdx,birdcount,sbird,
    score,lastscore,dummy,
    lasercount          : integer;

    exit,landed         : boolean;

proc showship;
begin
  if lastsx>=4 then begin
    plotmap(lastsx-4,lastsy,erase);
    plotmap(lastsx,lastsy,erase);
  end;
  if ((shipx>=4)and(shipx<=(xsize-4)))
    then begin
    plotmap(shipx-4,shipy,shipmap[0]);
    plotmap(shipx,shipy,shipmap[1]);
    lastsx:=shipx;
    lastsy:=shipy;
  end;
end;

proc moveship;
var change: integer;
begin
  shipx:=shipx+sspeedx;
  shipy:=shipy+sspeedy;
  change:=(xsize div 2) - shipx;
  change:=change div 16;
  change:=change+(random div 16)-8;
  sspeedx:=(4*(sspeedx+change)) div 5;
  if shipx<4 then begin
    shipx:=4;
    sspeedx:=random and 7;
  end;
  if shipx>xsize-4 then begin
    shipx:=xsize-4;
    sspeedx:=-(random and 7);
  end;
  if shipy<=0 then begin
    exit:=true; landed:=true;
    move(0,ysize-9);
    write(@plotdev,'ALIENS LANDED   ');
  end;
end;

proc showbird;
begin
  if lastbirdx>=0 then
    plotmap(lastbirdx,birdy,erase);
  if birdx>=0 then begin
    plotmap(birdx,birdy,
      birdmap[(birdcount shr 1) and 3]);
    lastbirdx:=birdx;
    birdcount:=birdcount+1;
  end;
end;

proc showscore;
begin
  move(xsize-17,ysize-9);
  write(@plotdev,
    chr(score div 10 + ord('0')),
    chr(mod(score,10) + ord('0')));
end;

proc hitbird;
begin
  move(0,ysize-9);
  write(@plotdev,'YOU HIT A BIRD! ');
  score:=0;
  birdx:=-1;
  showbird;
end;

proc hitship;
begin
  move(0,ysize-9);
  write(@plotdev,'YOU HIT A SHIP! ');
  score:=score+1;
  shipx:=-1;
  showship;
end;

proc laser;
var laserx: integer;
begin
  showship;
  if lasercount>=0 then begin
    laserx:=xsize div 2;
    move(laserx,1);
    draw(laserx,ysize-8,white);
    delay10msec(5);
    if (laserx>=(shipx-4)) and
       (laserx<=(shipx+3)) then
       hitship
    else if (laserx>=birdx) and
       (laserx<=(birdx+3)) then
       hitbird
    else begin
       move(0,ysize-9);
       write(@plotdev,'                ');
    end;
    move(laserx,1);
    draw(laserx,ysize-8,black);
    lasercount:=50;
  end else
    lasercount:=lasercount-1;
end;

proc init;
begin
  shipmap[0]:=$3f71;
  shipmap[1]:=$cfe8;
  birdmap[0]:=$9600;
  birdmap[1]:=$0f00;
  birdmap[2]:=$0690;
  birdmap[3]:=$0f00;
  shipx:=-1; lastsx:=-1;
  birdx:=-1; lastbirdx:=-1;
  birdcount:=0; lasercount:=0;
  score:=0; lastscore:=-1;
  exit:=false; landed:=false;
  grinit;
  cleargr;
  move(0,ysize-9);
  write(@plotdev,'USE SPACE BAR   ');
end;

begin
  init;
  repeat
    if lastscore<>score then showscore;

    if (shipx=-1) and (birdx=-1)
    then begin
      if random<8 then begin
        shipx:=random;
        if shipx<4 then shipx:=4;
        if shipx>xsize-4 then
          shipx:=xsize-4;
        shipy:=ysize-14;
        sspeedx:=((random-128) div 64);
        sspeedy:=-1;
      end;
    end;
    if shipx>=0 then begin
      moveship;
      showship;
    end;

    if (birdx=-1) and (shipy<(ysize-32))
    then begin
      if random<4 then begin
        birdx:=0;
        birdy:=ysize-(random div 16)-14;
        sbird:=2;
      end else if random>251 then begin
        birdx:=xsize-4;
        birdy:=ysize-(random div 16)-14;
        sbird:=-2;
      end
    end;
    if birdx>=0 then begin
      birdx:=birdx+sbird;
      if birdx<0 then birdx:=-1;
      if birdx>xsize-4 then birdx:=-1;
      showbird;
    end;

    dummy:=syncscreen;
    delay10msec(5);
    if (keypressed<>chr(0)) then begin
      if keypressed=' ' then laser
      else exit:=true;
      keypressed:=chr(0);
    end;
    until exit or (score>99);
  delay10msec(100);
  grend;
  if landed then
    writeln('The aliens have landed!');
  writeln('You hit ',score,
      ' alien ships');
end.
