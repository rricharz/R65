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

    shipx,lastsx,lastsy,birdx,birdy,
    lastbirdx,birdcount,sbird,score,lastscore,dummy,
    lasercount            : integer;
    landed                : boolean;
    shipy,sspeedx,sspeedy : real;

{$I IRANDOM:P}

proc showship;
begin
  if lastsx>=4 then begin
    plotmap(lastsx-4,lastsy,erase);
    plotmap(lastsx,lastsy,erase);
  end;
  if ((shipx>=4) and (shipx<=xsize-4))
    then begin
    lastsy:=trunc(shipy);
    plotmap(shipx-4,lastsy,shipmap[0]);
    plotmap(shipx,lastsy,shipmap[1]);
    lastsx:=shipx;
  end;
end;

proc moveship;
var change: real;
begin
  shipx:=shipx + trunc(sspeedx);
  shipy:=shipy + sspeedy;
  change:=0.05 * conv(xsize div 2 - shipx);
  change:=change * rrandom(-0.3,0.3);
  sspeedx:=sspeedx+change;
  if shipx<4 then begin
    shipx:=4;
    sspeedx:=-sspeedx;
  end;
  if shipx>xsize-4 then begin
    shipx:=xsize-4;
    sspeedx:=-sspeedx;
  end;
  if shipy<=-0.5 then begin
    landed:=true;
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
  landed:=false;
  grinit;
  cleargr;
  move(0,ysize-9);
  write(@plotdev,'USE SPACE BAR   ');
end;

func expaint:boolean;
begin
  if lastscore<>score then showscore;
  if (shipx < 0) and (birdx=-1) then begin
    if random<16 then begin
      shipx:=irandom(5,xsize-5);
      shipy:=conv(ysize-14);
      sspeedx:=rrandom(-2.0,2.0);
      sspeedy:=-0.5;
    end;
  end;

  if shipx>=0 then begin
    moveship;
    showship;
  end;

  if birdx=-1
  then begin
    if random<4 then begin
      birdx:=0;
      birdy:=irandom(ysize div 2,ysize-14);
      sbird:=2;
    end else if random>251 then begin
      birdx:=xsize-4;
      birdy:=irandom(ysize div 2,ysize-14);
      sbird:=-2;
    end
  end;
  if birdx>=0 then begin
    birdx:=birdx+sbird;
    if birdx<0 then birdx:=-1;
    if birdx>xsize-4 then birdx:=-1;
    showbird;
  end;
  if landed then expaint:=true
  else expaint:=false;
end;

func exkey(ch:char):boolean;
begin
  if landed then writeln('landed');
  if ch=' ' then laser;
  exkey := (ch = chr(0));
end;

{$I IANIMATE:P}

begin
  init;
  animate(false);
  splitview;
  if landed then
    writeln('The aliens are landed!');
  writeln('You hit ',score,
      ' alien ships');
end.
