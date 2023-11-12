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

var x,y,xspeed,yspeed: real;
    xi,yi,xl,yl,keycode: integer;
    stop:boolean;

begin
  stop:=false;
  grinit;
  cleargr;
  xspeed:=conv(random)/256.0+0.25;
  yspeed:=conv(random)/128.0+0.5;
  x:=1.5;
  y:=conv(ysize)/2.0;
  xl:=trunc(x);
  yl:=trunc(y);

  move(0,ysize);
  draw(0,0,white);
  draw(xsize,0,white);
  draw(xsize,ysize,white);
  move(6,ysize-10);
  write(@plotdev,
    'Use arrows to change speed');
  move(6,ysize-20);
  write(@plotdev,
    '       or E to exit');

  repeat { main loop }
    yspeed:=yspeed-gravity;
    x:=x+xspeed;
    y:=y+yspeed;
    if x<1.5 then begin
      x:=1.5;
      xspeed:=-xspeed;
    end else if x>conv(xsize-1) then begin
      x:=conv(xsize-1);
      xspeed:=-xspeed;
    end;
    if y<1.5 then begin
      y:=1.5;
      yspeed:=-yspeed+0.5*gravity;
    end;
    xi:=trunc(x);
    yi:=trunc(y);
    if yl<=ysize-21 then
      plot(xl,yl,black);
    if yi<ysize-21 then
      plot(xi,yi,white);
    xl:=xi;
    yl:=yi;
    keycode:=ord(keypressed);
    if keycode<>0 then keypressed:=chr(0);
    end;
    case keycode of
      26: yspeed:=yspeed*keyfactor;
      03: xspeed:=xspeed/keyfactor;
      22: xspeed:=xspeed*keyfactor;
      24: yspeed:=yspeed/keyfactor;
      69: stop:=true { E }
      end;
  until stop;
  grend;
end.