{
        **************************
        *                        *
        *     R65 Tiny Pascal    *
        *  Plot Library Plotlib  *
        *                        *
        **************************

       Version 16 06/02/80 rricharz

}

library plotlib;

const xsize=223;
      ysize=117;
      xwords=28;
      white=0;
      inverse=1;
      black=2;

mem keypressed=$1785: char&;

var xcursor, ycursor: integer;

{ delay10msec: delay 10 msec }
{ process is suspended during delay }

proc delay10msec(time:integer);
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

{ grinit: initialize memory for }
{ alpha/graphics display        }

proc grinit;
const igraph=$e01e;
      icrtgr=$e016;
begin
  call(igraph); call(icrtgr);
end;

{ grend: end of graphics, initialize }
{ memory for alpha display           }

proc grend;
const initcr=$e01b;
mem sflag=$1781: integer&;
begin
  call(initcr);
  sflag:=sflag or 1; {Pascal flag on}
end;

{ cleargr: clear graphics display }

proc cleargr;
const clrgra=$e231; { not a vector! }
begin
  call(clrgra);
end;

{ dgraphics: go to graphics display }

proc dgraphics;
const icrtgr=$e016;
begin
  call(icrtgr);
end;

{ dalpha: go to alpha display }

proc dalpha;
const icrtal=$e015;
begin
  call(icrtal);
end;

{ plot(x,y,c)                }
{ plot a dot at x,y, using c }

proc plot(x,y,c:integer);
const aplot=$c815;
mem grx=$03ae: integer&;
    gry=$03af: integer&;
    grc=$03b0: integer&;
begin
  xcursor:=x;
  ycursor:=y;
  if x<0 then xcursor:=0;
  if x>xsize then xcursor:=xsize;
  if y<0 then ycursor:=0;
  if y>ysize then ycursor:=ysize;
  grx:=x;
  gry:=y;
  grc:=c;
  call(aplot);
end;

{ move(x,y)            }
{ move graphics cursor }

proc move(x,y:integer);
begin
  xcursor:=x;
  ycursor:=y;
  if x<0 then xcursor:=0;
  if x>xsize then xcursor:=xsize;
  if y<0 then ycursor:=0;
  if y>ysize then ycursor:=ysize;
end;

{ draw(x,y,c)          }
{ draw a straight line }
{ end points are clipped to graphics area }

proc draw(x,y,c:integer);
mem grxinc=$03b6: integer;
    gryinc=$03ba: integer;
    grx=$03ae: integer&;
    gry=$03af: integer&;
    grc=$03b0: integer&;
    grn=$03b1: integer;
var xnew,ynew,xstep,ystep,xl,yl,i,cnt:integer;

  proc drawx(x,y,c,n:integer);
  const adrawx=$c81e;
  begin
    grx:=x;
    gry:=y;
    grc:=c;
    grn:=n;
    call(adrawx);
  end;

  proc drawy(x,y,c,n:integer);
  const adrawy=$c821;
  begin
    grx:=x;
    gry:=y;
    grc:=c;
    grn:=n;
    call(adrawy);
  end;

  proc drawxy(x,y,c,n,xi,yi:integer);
  const adrawxy=$c824;
  begin
    grx:=x;
    gry:=y;
    grc:=c;
    grn:=n;
    grxinc:=xi;
    gryinc:=yi
    call(adrawxy);
  end;

begin
  xnew:=x;
  ynew:=y;
  if xnew<0 then xnew:=0;
  if xnew>xsize then xnew:=xsize;
  if ynew<0 then ynew:=0;
  if ynew>ysize then ynew:=ysize;
  { fast horizontal and vertical draw }
  if ynew=ycursor then begin
    if xnew > xcursor then
      drawx(xcursor,ynew,c,xnew-xcursor+1)
    else
      drawx(xnew,ynew,c,xcursor-xnew+1)
  end else if xnew=xcursor then begin
    if ynew > ycursor then
      drawy(xnew,ycursor,c,ynew-ycursor+1)
    else
      drawy(xnew,ynew,c,ycursor-ynew+1)
  end else begin
    {compute abs lenght of longer axis}
    xl:=xnew-xcursor; if xl<0 then xl:=-xl;
    yl:=ynew-ycursor; if yl<0 then yl:=-yl;
    if xl>yl then cnt:=xl
    else cnt:=yl;
    if (cnt>0) then begin
      xstep:=((xnew-xcursor)*128) div cnt;
      ystep:=((ynew-ycursor)*128) div cnt;
      drawxy(xcursor,ycursor,c,
          cnt+1,xstep shl 1,ystep shl 1)
    end
  end;
  xcursor:=xnew; ycursor:=ynew;
end;

{ plotchar(x,y,ch)          }
{ plot character            }

proc plotchar(x,y:integer;ch:char);
const aplotch=$c818;
mem fonttb=$d540: array[191] of integer&;
    grx=$03ae: integer&;
    gry=$03af: integer&;
    grc=$03b0: integer&;
begin
  grx:=x;
  gry:=y;
  if x<0 then grx:=0;
  if x>(xsize-8) then grx:=xsize-8;
  if y<0 then gry:=0;
  if y>(ysize-8) then gry:=ysize-8;
  grc:=ord(ch);
  call(aplotch);
end;

{ plotmap(x,y,map)              }
{ plot 4x4 bitmap               }
{ the top left corner is bit 15 }

proc plotmap(x,y,m:integer);
const abitmap=$c81b;
mem grmap=$03b6: integer;
    grx=$03ae: integer&;
    gry=$03af: integer&;
begin
  grx:=x;
  gry:=y;
  if x<0 then grx:=0;
  if x>(xsize-4) then grx:=xsize-4;
  if y<0 then gry:=0;
  if y>(ysize-4) then gry:=ysize-4;
  grmap:=m;
  call(abitmap);
end;

begin {initialization}
  grinit;
end.
              