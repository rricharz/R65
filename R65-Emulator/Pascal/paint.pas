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
    K              kill program without writing

  2024 rricharz                                   }


program paint;
uses  syslib,arglib,wildlib,plotlib,strlib,filelib,
      mouselib,txtgrlib,writelib,mathlib;

const startcanvas=$700;
      sizecanvas=3304; {224x118/8}
      rdfile=$e815;
      wrfile=$e81b;

      CLEFT       = chr($03);
      CRIGHT      = chr($16);
      CUP         = chr($1a);
      CDOWN       = chr($18);
      RUBOUT      = chr($7f);

      dpoint      = 0;
      dline       = 1;
      drect       = 2;
      dtext       = 3;
      dflood      = 4;
      djoin       = 5;
      derase      = 6;
      dcircle     = 7;

mem   FILFLG=$da:       char&;
      FILSA=$031a:      integer;
      FILEA=$031c:      integer;
      FILSA1=$0331:     integer;
      FILTYP=$0300:     char&;
      MOUSEDRAGX=$170b: integer&;
      MOUSEDRAGY=$170c: integer&;

var cyclus,drive:       integer;
    x,y,cmode:          integer;
    startx,starty:      integer;
    name:               array[15] of char;
    ch,nextch:          char;
    dmode:              integer;


const CANVASSIZE  = 1652;   {words}
      LASTINDEX   = 1651;   {- 1}
mem   canvas      = $700:  array[1652] of integer;
      canvasbytes = $700:array[3304] of integer&;
var   undobuf:     array[1652] of integer;
      undovalid:  boolean;

const STACKSIZE=512;

var stack:array[STACKSIZE] of packed char;
    sp,maxsp,overflows,pushes:integer;

proc initstack;
{*************}
begin
  sp:=0;
  maxsp:=0;
  overflows:=0;
  pushes:=0;
end;

proc push(x,y:integer);
{*********************}
begin
  if sp<STACKSIZE then begin
    stack[sp]:=packed(chr(y),chr(x));
    sp:=sp+1;
    if sp>maxsp then maxsp:=sp;
    pushes:=pushes+1;
  end else
    overflows:=overflows+1;
end;

proc pop(var x,y:integer);
{************************}
begin
  if sp>0 then begin
    sp:=sp-1;
    x:=ord(low(stack[sp]));
    y:=ord(high(stack[sp]));
  end;
end;

proc hline(xl,xr,y,c:integer);
{****************************}
var x:integer;
begin
  _move(xl,y);
  _draw(xr,y,c);
end;

proc findrun(x,y:integer; var xl,xr:integer);
{*******************************************}
var color,full,row,i,mask:integer;
    searching:boolean;
begin
  color:=_getpixel(x,y);
  if color=WHITE then full:=$ff
  else full:=0;

  row:=28*y;
  xl:=x;
  xr:=x;

  { search left }
  i:=x;
  searching:=true;
  while (i>0) and searching do begin
    if (i and 7)=0 then begin
      { previous byte is entirely the same color? }
      if canvasbytes[row+(i shr 3)-1]=full then
        i:=i-8
      else begin
        mask:=$80 shr ((i-1) and 7);
        if (canvasbytes[row+((i-1) shr 3)] and mask)=
           (full and mask) then
          i:=i-1
        else
          searching:=false;
      end;
    end else begin
      mask:=$80 shr ((i-1) and 7);
      if (canvasbytes[row+((i-1) shr 3)] and mask)=
         (full and mask) then
        i:=i-1
      else
        searching:=false;
    end;
  end;
  xl:=i;

  { search right }
  i:=x;
  searching:=true;
  while (i<XSIZE) and searching do begin
    if (i<=XSIZE-8) and ((i and 7)=7) then begin
      { next byte is entirely the same color? }
      if canvasbytes[row+(i shr 3)+1]=full then
        i:=i+8
      else begin
        mask:=$80 shr ((i+1) and 7);
        if (canvasbytes[row+((i+1) shr 3)] and mask)=
           (full and mask) then
          i:=i+1
        else
          searching:=false;
      end;
    end else begin
      mask:=$80 shr ((i+1) and 7);
      if (canvasbytes[row+((i+1) shr 3)] and mask)=
         (full and mask) then
        i:=i+1
      else
        searching:=false;
    end;
  end;
  xr:=i;
end;

proc scanruns(xl,xr,y:integer);
{*****************************}
var x,left,right:integer;
begin
  x:=xl;
  while x<=xr do begin
    if _getpixel(x,y)=BLACK then begin
      push(x,y);
    end;
    findrun(x,y,left,right);
    x:=right+1;
  end;
end;

proc fillrun(x,y:integer);
{************************}
var xl,xr:integer;
begin
  if _getpixel(x,y)=BLACK then begin
    findrun(x,y,xl,xr);
    hline(xl,xr,y,WHITE);

    if y<YSIZE then
      scanruns(xl,xr,y+1);

    if y>0 then
      scanruns(xl,xr,y-1);
  end;
end;

proc floodfill(x,y:integer);
{**************************}
var px,py:integer;
begin
  initstack;

  if _getpixel(x,y)=BLACK then begin
    push(x,y);

    while sp>0 do begin
      pop(px,py);
      fillrun(px,py);
    end;
  end;
end;

proc saveundo;
{************}
var i: integer;
begin
  for i:=0 to CANVASSIZE-1 do
    undobuf[i]:=canvas[i];
  undovalid:=true;
end;

proc restoreundo;
{***************}
var i: integer;
begin
  if undovalid then begin
    for i:=0 to CANVASSIZE-1 do
      canvas[i]:=undobuf[i];
    undovalid:=false;
  end;
end;

proc forcesubtype(subtype:char);
{******************************}
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
{**************}
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
  FILSA:=startcanvas;
  FILEA:=startcanvas+sizecanvas;
  FILSA1:=startcanvas;
  FILTYP:='I';
  FILERR:=0;
  call(rdfile);
  writeln;
  if FILERR<>0 then
    writeln(INVVID,'File error ',FILERR shr 4,
      FILERR and 15,NORVID);
end;

proc savecanvas;
{**************}
{ save the canvas on disk }
begin
  _asetfile(name,cyclus,drive,'I');
  FILFLG:=chr($40); { silent store }
  FILSA:=startcanvas;
  FILEA:=startcanvas+sizecanvas;
  FILSA1:=startcanvas;
  FILTYP:='I';
  FILERR:=0;
  call(wrfile);
  if FILERR<>0 then
    writeln(INVVID,'File error ',FILERR shr 4,
      FILERR and 15,NORVID);
end;

proc drawline;
{************}
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
{************}
begin
  _move(x,y); write(@PLOTDEV,ch);
  x:=x+8;
  if (x>XSIZE-8) then begin
    x:=0; y:=y-10;
    if y<2 then y:=YSIZE-10;
  end;
end;

func printable:boolean;
{*********************}
var a:integer;
begin
  a:=ord(ch);
  if (a>ord('Z')) then a:=a-32;
  printable:=(a>=ord('A')) and (a<=ord('Z'));
end;

proc status;
{**********}
begin
  _setcursor(0,15);
  write(CSC);

  case dmode of
    dpoint:  write('POINT  ');
    dline:   write('LINE   ');
    drect:   write('RECT   ');
    dtext:   write('TEXT   ');
    dflood:  write('FLOOD  ');
    djoin:   write('JOIN   ');
    derase:  write('ERASE  ');
    dcircle: write('CIRCLE ')
  end;

  case cmode of
    WHITE:   write('WHITE   ');
    BLACK:   write('BLACK   ');
    INVERSE: write('INVERSE ')
  end;

  _setcursor(18,15);

  case dmode of
    dpoint:  write('Click or drag to paint');
    dline:   write('Drag to draw line');
    drect:   write('Drag to draw rectangle');
    dtext:   write('Type text; ESC exits');
    dflood:  write('Click inside area');
    djoin:   write('Drag connected lines');
    derase:  write('Drag area to erase');
    dcircle: write('Drag radius from center')
  end;

  _parkcursor;
end;

proc initpanel;
{*************}
begin
  _setcursor(0,11);
  write(CSC);

  _setcursor(0,11);
  write(INVVID,'P',NORVID,'oint');
  _setcursor(10,11);
  write(INVVID,'L',NORVID,'ine');
  _setcursor(20,11);
  write(INVVID,'J',NORVID,'oin');
  _setcursor(30,11);
  write(INVVID,'R',NORVID,'ect');
  _setcursor(40,11);
  write(INVVID,'O',NORVID,'circle');

  _setcursor(0,12);
  write(INVVID,'T',NORVID,'ext');
  _setcursor(10,12);
  write(INVVID,'F',NORVID,'lood');
  _setcursor(20,12);
  write(INVVID,'E',NORVID,'rase');
  _setcursor(30,12);
  write(INVVID,'C',NORVID,'lear');
  _setcursor(40,12);
  write(INVVID,'M',NORVID,'ode');

  _setcursor(0,13);
  write(INVVID,'ESC',NORVID,':Exit');
  _setcursor(10,13);
  write(INVVID,'DEL',NORVID,':Undo');
  _setcursor(20,13);
  write(INVVID,'W',NORVID,':Save');
  _setcursor(30,13);
  write(INVVID,'Q',NORVID,':Quit');
  _setcursor(40,13);
  write(INVVID,'K',NORVID,':Kill');

  _htxtgr(0,47,14,CYAN);
end;

proc eraserect(x,y,sx,sy:integer);
{********************************}
var xmin,xmax,ymin,ymax,yy:integer;
begin
  if sx>=0 then begin
    xmin:=x;
    xmax:=x+sx;
  end else begin
    xmin:=x+sx;
    xmax:=x;
  end;

  if sy>=0 then begin
    ymin:=y;
    ymax:=y+sy;
  end else begin
    ymin:=y+sy;
    ymax:=y;
  end;

  for yy:=ymin to ymax do begin
    _move(xmin,yy);
    _draw(xmax,yy,BLACK);
  end;
end;

proc drawshape(mode:integer);
{***************************}
var dx,dy,r:integer;
begin
  if dmode=dcircle then begin
    dx:=x-startx;
    dy:=y-starty;
    r:=floor(sqrt(conv(dx*dx+dy*dy)+0.5));
    _circle(startx,starty,r,mode);
  end else
    _rectangle(startx,starty,
      x-startx,y-starty,mode);
end;

proc shapemode;
{*************}
var mode,mx,my:integer;
    key:char;
    found, visible:boolean;
begin
  if _isesc then begin end;
  saveundo;
  repeat
    if _isesc then exit;
    mode:=0;
    found:=_getinput(mode,mx,my,key);

    if found then begin
      if mode=2 then begin
        startx:=mx;
        starty:=my;
      end;

      if key<>chr(0) then begin
        nextch:=key;
        exit;
      end;
    end else
      _delay10msec(1);
  until mode=2;

  { Drag rectangle }
  visible:=false;

  mx:=MOUSEDRAGX;
  my:=MOUSEDRAGY;
  while (mx<>$ff) and (my<>$ff)
  do begin
    if _isesc then begin
      { Remove the current XOR preview }
      if visible then
        drawshape(INVERSE);
      exit;
    end;

    if (not visible) or (mx<>x) or (my<>y) then begin

      { Erase previous XOR rectangle }
      if visible then
        drawshape(INVERSE);

      x:=mx;
      y:=my;

      { Draw new XOR rectangle }
      drawshape(INVERSE);
      visible:=true;
    end;
    mx:=MOUSEDRAGX;
    my:=MOUSEDRAGY;
  end;

  { Erase the temporary XOR rectangle }
  if visible then
    drawshape(INVERSE);

  { Draw permanent rectangle or erase area }
  if visible then begin
    if dmode=derase then
      eraserect(startx,starty,x-startx,y-starty)
    else
      drawshape(cmode);
  end;
end;

proc linemode(join:boolean);
{***************************}
var mode,mx,my:integer;
    key:char;
    found,visible,first:boolean;
begin
  if _isesc then begin end;
  saveundo;
  first:=true;

  repeat

    { Wait for mouse click }
    repeat
      if _isesc then exit;
      mode:=0;
      found:=_getinput(mode,mx,my,key);

      if found then begin
        if mode=2 then begin
          if first then begin
            startx:=mx;
            starty:=my;
          end;
        end;

        if key<>chr(0) then begin
          nextch:=key;
          exit;
        end;
      end else
        _delay10msec(1);
    until mode=2;

    { Drag line }
    visible:=false;

    mx:=MOUSEDRAGX;
    my:=MOUSEDRAGY;
    while (mx<>$ff) and (my<>$ff) do begin
      if _isesc then begin
        { Remove current XOR preview }
        if visible then begin
          _move(startx,starty);
          _draw(x,y,INVERSE);
        end;
        exit;
      end;

      if (not visible) or (mx<>x) or (my<>y)
      then begin

        { Erase previous XOR line }
        if visible then begin
          _move(startx,starty);
          _draw(x,y,INVERSE);
        end;

        x:=mx;
        y:=my;

        { Draw new XOR line }
        _move(startx,starty);
        _draw(x,y,INVERSE);

        visible:=true;
      end;

      mx:=MOUSEDRAGX;
      my:=MOUSEDRAGY;
    end;

    { Erase temporary XOR line }
    if visible then begin
      _move(startx,starty);
      _draw(x,y,INVERSE);
    end;

    { Draw permanent line }
    if visible then begin
      _move(startx,starty);
      _draw(x,y,cmode);

      { Endpoint becomes start of next segment }
      startx:=x;
      starty:=y;
    end;

    first:=false;

  until not join;
end;

proc pointmode(mx,my:integer);
{***************************}
var nx,ny:integer;
begin
  saveundo;

  { Draw the first point }
  _plot(mx,my,cmode);
  x:=mx;
  y:=my;

  if cmode=INVERSE then exit;

  { Follow the mouse while the button is down }
  nx:=MOUSEDRAGX;
  ny:=MOUSEDRAGY;

  while (nx<>$ff) and (ny<>$ff) do begin
    if (nx<>x) or (ny<>y) then begin
      _move(x,y);
      _draw(nx,ny,cmode);
      x:=nx;
      y:=ny;
    end;

    nx:=MOUSEDRAGX;
    ny:=MOUSEDRAGY;
  end;
end;

proc textmode;
{*************}
const LEFTMARGIN   = 2;
      RIGHTMARGIN  = 216;
      TOPMARGIN    = 108;
      BOTTOMMARGIN = 2;
      CHARWIDTH    = 8;
      CHARHEIGHT   = 8;

var mode,mx,my:   integer;
    ch:           char;
    found,visible:boolean;
    count:        integer;
    textstartx:   integer;
begin
  if _isesc then begin end;
  saveundo;

  { Keep the initial position within the margins }
  if x<LEFTMARGIN then x:=LEFTMARGIN;
  if x>RIGHTMARGIN then x:=RIGHTMARGIN;
  if y<BOTTOMMARGIN then y:=BOTTOMMARGIN;
  if y>TOPMARGIN then y:=TOPMARGIN;
  textstartx:=x;

  visible:=false;
  count:=0;

  repeat
    mode:=0;
    found:=_getinput(mode,mx,my,ch);

    if found then begin

      { Remove cursor }
      if visible then begin
        _move(x+1,y);
        _draw(x+5,y,INVERSE);
        visible:=false;
      end;

      { RUBOUT exits TEXT and requests Undo }
      if ch=RUBOUT then begin
        nextch:=ch;
        exit;
      end;

      { Mouse selects new text position }
      if mode=2 then begin
        x:=mx;
        y:=my;
        if x<LEFTMARGIN then x:=LEFTMARGIN;
        if x>RIGHTMARGIN then x:=RIGHTMARGIN;
        if y<BOTTOMMARGIN then y:=BOTTOMMARGIN;
        if y>TOPMARGIN then y:=TOPMARGIN;
        textstartx:=x;
      end;

      { Cursor movement and character input }
      case ch of

        CLEFT:
          if x>=LEFTMARGIN+CHARWIDTH then
            x:=x-CHARWIDTH;

        CRIGHT:
          if x<=RIGHTMARGIN-CHARWIDTH then
            x:=x+CHARWIDTH;

        CUP:
          if y<=TOPMARGIN-CHARHEIGHT then
            y:=y+CHARHEIGHT;

        CDOWN:
          if y>=BOTTOMMARGIN+CHARHEIGHT then
            y:=y-CHARHEIGHT;

        CR:
          begin
            x:=textstartx;
            if y>=BOTTOMMARGIN+CHARHEIGHT then
            y:=y-CHARHEIGHT;
          end

        else
          if (ch>=' ') and (ch<='~') then begin
            _move(x-2,y);
            write(@PLOTDEV,ch);

            if x<=RIGHTMARGIN-CHARWIDTH then
              x:=x+CHARWIDTH;
          end
      end;

      count:=0;

    end else begin
      _delay10msec(1);
      count:=count+1;

      if count>=30 then begin
        _move(x+1,y);
        _draw(x+5,y,INVERSE);
        visible:=not visible;
        count:=0;
      end;
    end;

  until _isesc;

  { Remove cursor before leaving }
  if visible then begin
    _move(x+1,y);
    _draw(x+5,y,INVERSE);
  end;

end;

proc floodmode;
{*************}
var mode,mx,my:integer;
    key:char;
    found:boolean;
begin
  if _isesc then begin end;

  repeat
    if _isesc then exit;
    mode:=0;
    found:=_getinput(mode,mx,my,key);

    if found then begin
      if mode=2 then begin
        saveundo;
        floodfill(mx,my);
        exit;
      end;

      if key<>chr(0) then begin
        nextch:=key;
        exit;
      end;
    end else
      _delay10msec(1);
  until false;
end;

proc paint;
{*********}
{ This is the main painting loop }
var mode,mx,my:integer;
    found:boolean;
begin
  x:=XSIZE div 2;
  y:=YSIZE div 2;
  cmode:=WHITE;
  dmode:=dpoint;
  initpanel;
  status;
  nextch:=chr(0);
  repeat
    if nextch<>chr(0) then begin
      ch:=nextch;
      nextch:=chr(0);
    end else begin
      repeat
        found:=_getinput(mode,mx,my,ch);
        if not found then _delay10msec(1);
        until found;
    end;

    if (mode=2) and (dmode=dpoint) then
      pointmode(mx,my);

      case ch of

      'C':    begin
                saveundo;
                _cleargr;
              end;

      'M':    begin
                cmode:=cmode+1;
                if cmode>2 then cmode:=0;
              end;

      'P':    begin
                dmode:=dpoint;
              end;

      'L':    begin
                dmode:=dline;
                status;
                linemode(false);
                dmode:=dpoint;
              end;

      'F':    begin
                dmode:=dflood;
                status;
                floodmode;
                dmode:=dpoint;
              end;

      'R':    begin
                dmode:=drect;
                status;
                shapemode;
                dmode:=dpoint;
              end;

      'E':    begin
                dmode:=derase;
                status;
                shapemode;
                dmode:=dpoint;
              end;

      'O':    begin
                dmode:=dcircle;
                status;
                shapemode;
                dmode:=dpoint;
              end;

      'J':    begin
                dmode:=djoin;
                status;
                linemode(true);
                dmode:=dpoint;
              end;

      'T':    begin
                dmode:=dtext;
                status;
                textmode;
                dmode:=dpoint;
              end;

      'S':    savecanvas;

      RUBOUT: restoreundo;

      'W','Q': begin
                 savecanvas;
                 _setcursor(2,14);
              end
    end; {case}
    if (ch<>'W') and (ch<>'Q') then status;
  until (ch='Q') or (ch='K');
end;

begin
  _grinit; _cleargr; _fullview;
  undovalid:=false;
  loadcanvas;
  paint;
  _grend;
end.
