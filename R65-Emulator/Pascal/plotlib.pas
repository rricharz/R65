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

{ _delay10msec: _delay 10 msec }
{ process is suspended during _delay }

proc _delay10msec(time:integer);
mem
{$I IHIDDENMEM}
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

func _syncscreen;
{ synchronize screen and sleep
  up to 30 msec since last sync.
  returns sleep time in msec   }
mem
{$I IHIDDENMEM}
begin
  emucom := 7;
  _syncscreen := emures;
end;

{ _grinit: initialize memory for }
{ alpha/graphics display        }

proc _grinit;
const igraph=$e01e;
      iCRtgr=$e016;
begin
  call(igraph); call(iCRtgr);
  writeln('CTRT-L to toggle canvas size,',
   'GREND to close it');
end;

{ _grend: end of graphics, initialize }
{ memory for alpha display           }

proc _grend;
const initCR=$e01b;
mem sflag=$1781: integer&;
begin
  call(initCR);
  sflag:=sflag or 1; {Pascal flag on}
end;

{ _cleargr: clear graphics display }

proc _cleargr;
const clrgra=$e231; { not a vector! }
begin
  call(clrgra);
end;

{ _fullview: go to full sCReen graphics display }

proc _fullview;
const iCRtgr=$e016;
begin
  call(iCRtgr);
end;

{ _splitview: go to splitted graphics display }

proc _splitview;
const iCRtal=$e015;
begin
  call(iCRtal);
end;

{ _plot(x,y,c)                }
{ _plot a dot at x,y, using c }

proc _plot(x,y,c:integer);
const a_plot=$c815;
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
  call(a_plot);
end;

{ _move(x,y)            }
{ _move graphics cursor }

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

{ _draw(x,y,c)          }
{ _draw a straight line }
{ end points are clipped to graphics area }

proc _draw(x,y,c:integer);
mem grxinc=$03b6: integer;
    gryinc=$03ba: integer;
    grx=$03ae: integer&;
    gry=$03af: integer&;
    grc=$03b0: integer&;
    grn=$03b1: integer;

var x_new,y_new,xstep,ystep,xl,yl,i,cnt:integer;

  proc _drawx(x0,y0,c0,n:integer);
  const a_drawx=$c81e;
  begin
    grx:=x0;
    gry:=y0;
    grc:=c0;
    grn:=n;
    call(a_drawx);
  end;

  proc _drawy(x0,y0,c0,n:integer);
  const a_drawy=$c821;
  begin
    grx:=x0;
    gry:=y0;
    grc:=c0;
    grn:=n;
    call(a_drawy);
  end;

  proc _drawxy(x0,y0,c0,n,xi,yi:integer);
  const a_drawxy=$c824;
  begin
    grx:=x0;
    gry:=y0;
    grc:=c0;
    grn:=n;
    grxinc:=xi;
    gryinc:=yi
    call(a_drawxy);
  end;

begin
  x_new:=x;
  y_new:=y;
  if x_new<0 then x_new:=0;
  if x_new>XSIZE then x_new:=XSIZE;
  if y_new<0 then y_new:=0;
  if y_new>YSIZE then y_new:=YSIZE;
  { fast horizontal and vertical _draw }
  if y_new=_ycursor then begin
    if x_new > _xcursor then
      _drawx(_xcursor,y_new,c,x_new-_xcursor+1)
    else
      _drawx(x_new,y_new,c,_xcursor-x_new+1)
  end else if x_new=_xcursor then begin
    if y_new > _ycursor then
      _drawy(x_new,_ycursor,c,y_new-_ycursor+1)
    else
      _drawy(x_new,y_new,c,_ycursor-y_new+1)
  end else begin
    {compute _abs lenght of longer axis}
    xl:=x_new-_xcursor; if xl<0 then xl:=-xl;
    yl:=y_new-_ycursor; if yl<0 then yl:=-yl;
    if xl>yl then cnt:=xl
    else cnt:=yl;
    if (cnt>0) then begin
      xstep:=((x_new-_xcursor)*128) div cnt;
      ystep:=((y_new-_ycursor)*128) div cnt;
      _drawxy(_xcursor,_ycursor,c,
          cnt+1,xstep shl 1,ystep shl 1)
    end
  end;
  _xcursor:=x_new; _ycursor:=y_new;
end;

{ _plotmap(x,y,map)              }
{ _plot 4x4 bitmap               }
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

{ waitforKEY                    }
{ wait for a KEY to be typed    }

proc _waitforKEY;
const KEY=@1;
      toggle=chr($0c);
var ch:char;
begin
  repeat
    read(@KEY,ch);
    if ch=toggle then write(ch);
  until ch<>toggle;
end;

{ plotif(x,y,mode)         }
{ pot within canvas limits }

proc _plotif(x,y,mode: integer);
begin
  if (x >= 0) and (x <= XSIZE) and
     (y >= 0) and (y <= YSIZE) then
    _plot(x, y, mode);
end;

{ circle(cx,cy,r,mode)     }
{ draw a circle            }

proc _circle(cx,cy,r,mode: integer);
var x, y, d: integer;

  proc put8(x,y: integer);
  begin
    _plotif(cx + x, cy + y, mode);
    _plotif(cx - x, cy + y, mode);
    _plotif(cx + x, cy - y, mode);
    _plotif(cx - x, cy - y, mode);
    _plotif(cx + y, cy + x, mode);
    _plotif(cx - y, cy + x, mode);
    _plotif(cx + y, cy - x, mode);
    _plotif(cx - y, cy - x, mode);
  end;

begin
  x := 0;
  y := r;
  d := 3 - 2 * r;
  while x <= y do begin
    put8(x, y);
    if d < 0 then
      d := d + 4 * x + 6
    else begin
      d := d + 4 * (x - y) + 10;
      y := y - 1;
    end;
    x := x + 1;
  end;
end;

proc _rectangle(x, y, sx, sy, mode: integer);
begin
  _move(x, y);
  _draw(x + sx, y, mode);
  _draw(x + sx, y + sy, mode);
  _draw(x, y + sy, mode);
  _draw(x, y, mode);
end;

begin {initialization}
end.
