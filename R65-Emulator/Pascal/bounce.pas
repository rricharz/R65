{
        *****************
        *               *
        *     BOUNCE    *
        *               *
        *****************

A bouncing ball simulation for the
R65 Graphics display

    Original    1979 rricharz
    New version 2019 rricharz
                                }

program bounce;
uses syslib,plotlib;

const gravity=0.15;
      keyfactor=1.05;
      erase=0; ball=$6ff6;

var x,y,xspeed,yspeed: real;
    xi,yi,xl,yl,keycode: integer;

proc expaint;
begin
  yspeed:=yspeed-gravity;
  x:=x+xspeed;
  y:=y+yspeed;
  if x<1.5 then begin
    x:=1.5;
    xspeed:=-xspeed;
  end else if x>conv(xsize-4) then begin
    x:=conv(xsize-4);
    xspeed:=-xspeed;
  end;
  if y<1.5 then begin
    y:=1.5;
    yspeed:=-yspeed+0.5*gravity;
  end else if y>conv(ysize-18) then begin
    yspeed:=-0.95*yspeed;
    y:=conv(ysize-18);
  end;

  xi:=trunc(x);
  yi:=trunc(y);
  plotmap(xl,yl,erase);
  plotmap(xi,yi,ball);
  xl:=xi;
  yl:=yi;
end;

func exkey(ch:char):boolean;
begin
  exkey:=false
  case ord(ch) of
    26: yspeed:=yspeed*keyfactor;
    03: xspeed:=xspeed/keyfactor;
    22: xspeed:=xspeed*keyfactor;
    24: yspeed:=yspeed/keyfactor;
    0:  exkey:=true
  end {case};
  if xspeed>4.0 then xspeed:=4.0
  else if xspeed<-4.0 then xspeed:=-4.0;
  if yspeed>6.0 then yspeed:=6.0
  else if yspeed<-6.0 then yspeed:=-6.0;
end;

{$I IANIMATE:P}

begin
  grinit;
  cleargr;
  xspeed:=4.0*conv(random)/conv(xsize)+0.25;
  yspeed:=conv(random)/(conv(ysize))+0.5;
  x:=1.5;
  y:=conv(ysize)/2.0;
  xl:=trunc(x);
  yl:=trunc(y);

  move(0,ysize);
  draw(0,0,white);
  draw(xsize,0,white);
  draw(xsize,ysize,white);
  draw(0,ysize,white);
  move(0,ysize-14);
  draw(xsize,ysize-14,white);

  move(6,ysize-11);
  write(@plotdev,
    'Use arrows to change speed');

  animate;
  splitview;
end.
