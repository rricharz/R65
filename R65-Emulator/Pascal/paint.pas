{ paint - paint in a graphics canvas
  usage: paint filename[.cyclus][,drive]

  Paint with following keys:
    right arrow    _move cursor right
    left arror     _move cursor left
    up arrow       _move cursor up
    down arrow     _move cursor down
    C              clear canvas
    p              paint a dot at cursor position

    L              drawing line mode
    R              drawing rectange mode
    S              drawing character mode
    return         _draw object and exit mode
    esc            exit mode without drawing

    W              write canvas to disk
    Q              write canvas to disk and quit
    K              kill program without writing to dis
k

  2024 rricharz                                   }


program paint;
uses  syslib,arglib,wildlib,plotlib,strlib,filelib,
      mouselib,txtgrlib,writelib;

const startcanvas=$700;
      sizecanvas=3304; {224x118/8}
      rdfile=$e815;
      wrfile=$e81b;
      cleft=chr($03);
      cright=chr($16);
      cup=chr($1a);
      cdown=chr($18);
      esc=chr($1b);
      dpoint=0;
      dline=1;
      drect=2;
      dchar=3;

mem   FILFLG=$da:   char&;
      filsa=$031a:  integer;
      filea=$031c:  integer;
      filsa1=$0331: integer;
      filtyp=$0300: char&;

var cyclus,drive:integer;
    x,y,cmode,startx,starty:integer;
    name:array[15] of char;
    ch:char;
    dmode:integer;

proc forcesubtype(subtype:char);
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
    (name[i]=' ') or (i>=14);
  name[i]:=':';
  name[i+1]:=subtype;
end;

proc loadcanvas;
var entry: integer;
    last,found,default:  boolean;
begin
  cyclus:=0; drive:=1;
  _agetstring(name,default,cyclus,drive);
  if default then begin
    _grend;
    writeln(INVVID,'No file specified',NORVID);
    writeln('Usage: PAINT filename');
    _abort;
  end;
  { check whether file exists, wildcards allowed }
  entry:=0;
  forcesubtype('I');
  _findentry(name,drive,entry,found,last);
  if (not found) or last then exit;
  _asetfile(name,cyclus,drive,'I');
  FILFLG:=chr($40); { silent load }
  filsa:=startcanvas;
  filea:=startcanvas+sizecanvas;
  filsa1:=startcanvas;
  filtyp:='I';
  FILERR:=0;
  call(rdfile);
  writeln;
  if FILERR<>0 then
    writeln(INVVID,'File error ',FILERR shr 4,
      FILERR and 15,NORVID);
end;

proc savecanvas;
{ save the canvas on disk }
begin
  _asetfile(name,cyclus,drive,'I');
  FILFLG:=chr($40); { silent store }
  filsa:=startcanvas;
  filea:=startcanvas+sizecanvas;
  filsa1:=startcanvas;
  filtyp:='I';
  FILERR:=0;
  call(wrfile);
  if FILERR<>0 then
    writeln(INVVID,'File error ',FILERR shr 4,
      FILERR and 15,NORVID);
end;

proc showcursor(ax,ay:integer);
var i:integer;
begin
  case dmode of
    dpoint: begin
              _move(ax-2,ay);
              _draw(ax+2,ay,INVERSE);
              _move(ax,ay-2);
              _draw(ax,ay+2,INVERSE);
            end;
    dline:  begin
              _move(startx,starty);
              _draw(x,y,INVERSE);
            end;
    drect:  begin
              _move(startx,starty);
              _draw(x,starty,INVERSE);
              _draw(x,y,INVERSE);
              _draw(startx,y,INVERSE);
              _draw(startx,starty,INVERSE);
            end;
    dchar: begin
               if (x>XSIZE-8) then x:=XSIZE-8;
               if (y<2) then y:=2;
               if (y>YSIZE-9) then y:=y-9;
               _move(x+2,y-2);
               _draw(x+8,y-2,INVERSE);
             end
  end {case};
end;

proc blink;
const bcount=12;
var count,mode,mx,my:integer;
    displayed,found:boolean;
begin
  count:=0;
  displayed:=false;

  repeat
    found:=_getinput(mode,mx,my,ch);

    if _isesc then begin
      ch:=chr($1b);
      found:=true;
    end;

    if not found then begin
      _delay10msec(1);
      count:=count-1;

      if count<=0 then begin
        showcursor(x,y);
        displayed:=not displayed;
        count:=bcount;
      end;
    end;

  until found;

  if displayed then showcursor(x,y);

  if mode=2 then begin
    x:=mx;
    y:=my;
    ch:=chr(0);
  end;
end;

proc drawline;
begin
  _move(startx,starty); _draw(x,y,cmode);
  startx:=x; starty:=y;
end;

proc drawrect;
begin
   _move(startx,starty);
   _draw(x,starty,cmode);
   _draw(x,y,cmode);
   _draw(startx,y,cmode);
   _draw(startx,starty,cmode);
end;

proc drawchar;
begin
  _move(x,y); write(@PLOTDEV,ch);
  x:=x+8;
  if (x>XSIZE-8) then begin
    x:=0; y:=y-10;
    if y<2 then y:=YSIZE-10;
  end;
end;

func printable:boolean;
var a:integer;
begin
  a:=ord(ch);
  if (a>ord('Z')) then a:=a-32;
  printable:=(a>=ord('A')) and (a<=ord('Z'));
end;

proc status;
begin
  _setcursor(0,15);

  case dmode of
    dpoint: write('POINT  ');
    dline:  write('LINE   ');
    drect:  write('RECT   ');
    dchar:  write('CHAR   ')
  end;

  case cmode of
    WHITE:   write('WHITE   ');
    BLACK:   write('BLACK   ');
    INVERSE: write('INVERSE ')
  end;

  _setcursor(32,15);
  write('X:',x:3,' Y:',y:3);

  _parkcursor;
end;

proc initpanel;
begin
  _setcursor(0,12);
  write(CSC);

  write(INVVID,'C',NORVID,'lear  ',
        INVVID,'M',NORVID,'ode  ',
        INVVID,'P',NORVID,'oint  ',
        INVVID,'L',NORVID,'ine  ',
        INVVID,'R',NORVID,'ect  ',
        INVVID,'S',NORVID,'ymbol');

  _setcursor(0,13);
  write(INVVID,'RET',NORVID,':Draw  ',
        INVVID,'ESC',NORVID,':Cancel  ',
        INVVID,'W',NORVID,':Save  ',
        INVVID,'Q',NORVID,':Quit  ',
        INVVID,'K',NORVID,':Kill');

  _htxtgr(0,47,14,CYAN);
end;

proc paint;
{ This is the main painting loop }
begin
  x:=XSIZE div 2;
  y:=YSIZE div 2;
  cmode:=WHITE;
  dmode:=dpoint;
  initpanel;
  status;
  repeat
    blink;
    if (dmode=dchar) and printable then drawchar
    else case ch of
      cleft:  if x>0 then x:=x-1;
      cright: if x<XSIZE then x:=x+1;
      cup:    if (y<YSIZE) then y:=y+1;
      cdown:  if (y>0) then y:=y-1;
      'C':    _cleargr;
      'M':    begin
                cmode:=cmode+1;
                if cmode>2 then cmode:=0;
              end;
      'P':    begin
                _plot(x,y,cmode);
                x:=x+1;
                if x>XSIZE then x:=0;
              end;
      'L':    begin
                if dmode=dline then drawline;
                startx:=x; starty:=y;
                dmode:=dline;
                x:=x+4; {minimum size for visibility}
                y:=y+4;
                if x>XSIZE then x:=x-4;
                if y>YSIZE then y:=y-4;
              end;
      'R':    begin
                if dmode=drect then drawrect;
                startx:=x; starty:=y;
                dmode:=drect;
                x:=x+4; {minimum size for visibility}
                y:=y+4;
                if x>XSIZE then x:=XSIZE-4;
                if y>YSIZE then y:=YSIZE-4;
              end;
      'S':    begin
                dmode:=dchar;
                startx:=x; starty:=y;
              end;
      CR:     begin
                 case dmode of
                   dpoint: _plot(x,y,cmode);
                   dline:   drawline;
                   drect:   drawrect;
                   dchar:   drawchar
                end {case};
                dmode:=dpoint;
             end;
      esc:   dmode:=dpoint;
      'W','Q': begin
                 savecanvas;
                 _setcursor(2,14);
                 write('SAVED         ');
              end
    end; {case}
    if (ch<>'W') and (ch<>'Q') then status;
  until (ch='Q') or (ch='K');
end;

begin
  _grinit; _cleargr; _fullview;
  loadcanvas;
  paint;
  _grend;
end.
