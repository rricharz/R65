{ throwsim.pas }

{ trajectory simulation }

program shrowsim;
uses syslib,mathlib,plotlib;

var angle,speed,xspeed,yspeed: real;
    i: integer;
    x,y: real;
    ch: char;

begin
  grinit;
  cleargr;
  speed:=1.0;
  for i:=1 to 11 do begin
    angle:=7.5*conv(i);
    xspeed:=speed*cos(angle);
    yspeed:=speed*sin(angle);
    x:=0.0; y:=0.0;
    repeat
      if (trunc(y)<ysize) then
        plot(trunc(x),trunc(y),white);
      x:=x+xspeed;
      y:=y+yspeed;
      yspeed:=yspeed-0.005;
    until (trunc(x)>xsize) or (trunc(y)<0);
  end;
  read(@key,ch);
  grend;
end.
 