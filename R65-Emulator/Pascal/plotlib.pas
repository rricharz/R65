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

const XSIZE=223;
      YSIZE=117;
      XWORDS=28;
      WHITE=0;
      INVERSE=1;
      BLACK=2;
      PLOTDEV=@128;

mem KEYPRESSED=$1785: char&;

var _xcursor, _ycursor: integer;

{ delay10msec: delay 10 msec }
{ process is suspended during delay }

proc _delay10msec(time:integer);
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

func _syncscreen;
{ synchronize screen and sleep
  up to 30 msec since last sync.
  returns sleep time in msec    }
mem emucom=$1430: integer&;
    emures=$1431: integer&;
begin
  emucom := 7;
  _syncscreen := emures;
end;

{ grinit: initialize memory for }
{ alpha/graphics display        }

proc _grinit;
const igraph=$e01e;
      icrtgr=$e016;
begin
  call(igraph); call(icrtgr);
  writeln('CTRT-L to toggle canvas size,',
   'GREND to close it');
end;

{ grend: end of graphics, initialize }
{ memory for alpha display           }

proc _grend;
const initcr=$e01b;
mem sflag=$1781: integer&;
begin
  call(initcr);
  sflag:=sflag or 1; {Pascal flag on}
end;

{ cleargr: clear graphics display }

proc _cleargr;
const clrgra=$e231; { not a vector! }
begin
  call(clrgra);
end;

{ fullview: go to full screen graphics display }

proc _fullview;
const icrtgr=$e016;
begin
  call(icrtgr);
end;

{ splitview: go to splitted graphics display }

proc _splitview;
const icrtal=$e015;
begin
  call(icrtal);
end;

{ plot(x,y,c)                }
{ plot a dot at x,y, using c }

proc _plot(x,y,c:integer);
const aplot=$c815;
mem grx=$03ae: integer&;
    gry=$03af: integer&;
    grc=$03b0: integer&;
begin
  _xcursor:=x;
  _ycursor:=y;
  if x<0 then _xcursor:=0;
  if x>XSIZE then _xcursor:=XSIZE;
  if y<0 then _ycursor:=0;
  if y>YSIZE then _ycursor:=YSIZE;
  grx:=x;
  gry:=y;
  grc:=c;
  call(aplot);
end;

{ move(x,y)            }
{ move graphics cursor }

proc _move(x,y:integer);
mem grx=$03ae: integer&;
    gry=$03af: integer&;
begin
  _xcursor:=x;
  _ycursor:=y;
  if x<0 then _xcursor:=0;
  if x>XSIZE then _xcursor:=XSIZE;
  if y<0 then _ycursor:=0;
  if y>YSIZE then _ycursor:=YSIZE;
  grx:=_xcursor;
  gry:=_ycursor;
end;

{ draw(x,y,c)          }
{ draw a straight line }
{ end points are clipped to graphics area }

proc _draw(x,y,c:integer);
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
  if xnew>XSIZE then xnew:=XSIZE;
  if ynew<0 then ynew:=0;
  if ynew>YSIZE then ynew:=YSIZE;
  { fast horizontal and vertical draw }
  if ynew=_ycursor then begin
    if xnew > _xcursor then
      drawx(_xcursor,ynew,c,xnew-_xcursor+1)
    else
      drawx(xnew,ynew,c,_xcursor-xnew+1)
  end else if xnew=_xcursor then begin
    if ynew > _ycursor then
      drawy(xnew,_ycursor,c,ynew-_ycursor+1)
    else
      drawy(xnew,ynew,c,_ycursor-ynew+1)
  end else begin
    {compute abs lenght of longer axis}
    xl:=xnew-_xcursor; if xl<0 then xl:=-xl;
    yl:=ynew-_ycursor; if yl<0 then yl:=-yl;
    if xl>yl then cnt:=xl
    else cnt:=yl;
    if (cnt>0) then begin
      xstep:=((xnew-_xcursor)*128) div cnt;
      ystep:=((ynew-_ycursor)*128) div cnt;
      drawxy(_xcursor,_ycursor,c,
          cnt+1,xstep shl 1,ystep shl 1)
    end
  end;
  _xcursor:=xnew; _ycursor:=ynew;
end;

{ plotmap(x,y,map)              }
{ plot 4x4 bitmap               }
{ the top left corner is bit 15 }

proc _plotmap(x,y,m:integer);
const abitmap=$c81b;
mem grmap=$03b6: integer;
    grx=$03ae: integer&;
    gry=$03af: integer&;
begin
  grx:=x;
  gry:=y;
  if x<0 then grx:=0;
  if x>(XSIZE-4) then grx:=XSIZE-4;
  if y<0 then gry:=0;
  if y>(YSIZE-4) then gry:=YSIZE-4;
  grmap:=m;
  call(abitmap);
end;

{ waitforkey                    }
{ wait for a key to be typed    }

proc _waitforkey;
const key=@1;
      toggle=chr($0c);
var ch:char;
begin
  repeat
    read(@key,ch);
    if ch=toggle then write(ch);
  until ch<>toggle;
end;

begin {initialization}
end.
