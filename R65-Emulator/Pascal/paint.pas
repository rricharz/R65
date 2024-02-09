{ paint - paint in a graphics canvas
  usage: paint filename[.cyclus][,drive]

  Paint with following keys:
    right arrow    move cursor right
    left arror     move cursor left
    up arrow       move cursor up
    down arrow     move cursor down
    C              clear canvas
    p              paint a dot at cursor position

    L              drawing line mode
    R              drawing rectange mode
    S              drawing character mode
    return         draw object and exit mode
    esc            exit mode without drawing

    W              write canvas to disk
    Q              write canvas to disk and quit
    K              kill program without writing to disk

  2024 rricharz                                   }

program paint;
uses syslib,arglib,wildlib,plotlib,strlib;

const startcanvas=$700; sizecanvas=3304; {224x118/8}
      rdfile=$e815; wrfile=$e81b;
      toggle=chr($0c); {ctrl-l}
      cleft=chr($03); cright=chr($16);
      cup=chr($1a); cdown=chr($18); esc=chr(0);
      dreset=0; dline=1; drect=2; dchar=3;

mem   filflg=$da:   char&;
      filerr=$db:   integer&;
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
  agetstring(name,default,cyclus,drive);
  if default then begin
    grend;
    writeln(invvid,'No file specified',norvid);
    write('Usage: paint filename[.cyclus][,drive]');
    abort;
  end;
  { check whether file exists, wildcards allowed }
  entry:=0;
  forcesubtype('I');
  findentry(name,drive,entry,found,last);
  if (not found) or last then exit;
  asetfile(name,cyclus,drive,'I');
  filflg:=chr(0);
  filsa:=startcanvas;
  filea:=startcanvas+sizecanvas;
  filsa1:=startcanvas;
  filtyp:='I';
  filerr:=0;
  call(rdfile);
  writeln;
  if filerr<>0 then
    writeln(invvid,'File error ',filerr shr 4,
      filerr and 15,norvid);
end;

proc savecanvas;
{ save the canvas on disk }
begin
  asetfile(name,cyclus,drive,'I');
  filsa:=startcanvas;
  filea:=startcanvas+sizecanvas;
  filsa1:=startcanvas;
  filtyp:='I';
  filerr:=0;
  call(wrfile);
  if filerr<>0 then
    writeln(invvid,'File error ',filerr shr 4,
      filerr and 15,norvid);
end;

proc showcursor(ax,ay:integer);
var i:integer;
begin
  case dmode of
    dreset: begin
              plot(ax,ay,inverse);
            end;
    dline:  begin
              move(startx,starty); draw(x,y,inverse);
            end;
    drect:  begin
              move(startx,starty);
              draw(x,starty,inverse);
              draw(x,y,inverse);
              draw(startx,y,inverse);
              draw(startx,starty,inverse);
            end;
    dchar: begin
               if (x>xsize-8) then x:=xsize-8;
               if (y<2) then y:=2;
               if (y>ysize-9) then y:=y-9;
               move(x+2,y-2);
               draw(x+8,y-2,inverse);
             end
  end {case};
end;

proc blink;
const bcount=50; { 50x10 msec interval for blinking }
mem sflag=$1781:integer&;
var count:integer;
    displayed:boolean;
begin
  count:=0; { start with cursor on }
  displayed:=false;
  repeat
    ch:=keypressed; { sleeps for 10 msec }
    count:=count-1;
    if count<=0 then begin
      showcursor(x,y);
      displayed:=not displayed;
      count:=bcount;
    end;
  { sflag bit 8 is escape flag. Pass it through }
  until (ord(ch)<>0) or ((sflag and $80)<>0);
  read(@key,ch);
  sflag:=sflag and $7f; { clear escape flag }
  if displayed then showcursor(x,y);
end;

proc drawline;
begin
  move(startx,starty); draw(x,y,cmode);
  startx:=x; starty:=y;
end;

proc drawrect;
begin
   move(startx,starty); draw(x,starty,cmode);
   draw(x,y,cmode); draw(startx,y,cmode);
   draw(startx,starty,cmode);
end;

proc drawchar;
begin
  move(x,y); write(@plotdev,ch);
  x:=x+8;
  if (x>xsize-8) then begin
    x:=0; y:=y-10;
    if y<2 then y:=ysize-10;
  end;
end;

func printable:boolean;
var a:integer;
begin
  a:=ord(ch);
  if (a>ord('Z')) then a:=a-32;
  printable:=(a>=ord('A')) and (a<=ord('Z'));
end;

proc paint;
{ This is the main painting loop }
begin
  x:=xsize div 2; y:=ysize div 2;
  cmode:=white; dmode:=dreset;
  writeln('Drawing point mode');
  repeat
    blink; { blink cursor and get next key }
    if (dmode=dchar) and printable then drawchar
    else case ch of
      toggle: write(ch);
      cleft:  if x>0 then x:=x-1;
      cright: if x<xsize then x:=x+1;
      cup:    if (y<ysize) then y:=y+1;
      cdown:  if (y>0) then y:=y-1;
      'C':    cleargr;
      'M':    begin
                cmode:=cmode+1;
                if cmode>2 then cmode:=0;
                case cmode of
                  white: writeln('Drawing white');
                  black: writeln('Drawing black');
                  inverse: writeln('Drawing inverse')
                end {case};
              end;
      'P':    begin
                writeln('Drawing point mode');
                plot(x,y,cmode);
                x:=x+1;
                if x>xsize then x:=0;
              end;
      'L':    begin
                writeln('Drawing line mode');
                if dmode=dline then drawline;
                startx:=x; starty:=y;
                dmode:=dline;
                x:=x+4; {minimum size for visibility}
                y:=y+4;
                if x>xsize then x:=x-4;
                if y>ysize then y:=y-4;
              end;
      'R':    begin
                writeln('Drawing rectange mode');
                if dmode=drect then drawrect;
                startx:=x; starty:=y;
                dmode:=drect;
                x:=x+4; {minimum size for visibility}
                y:=y+4;
                if x>xsize then x:=xsize-4;
                if y>ysize then y:=ysize-4;
              end;
      'S':    begin
                writeln('Drawing character mode');
                dmode:=dchar;
                startx:=x; starty:=y;
              end;
      cr:     begin
                 case dmode of
                   dline:   drawline;
                   drect:   drawrect;
                   dchar:   drawchar
                end {case};
                dmode:=dreset;
                writeln('Drawing point mode');
             end;
      esc:   dmode:=dreset;
      'W','Q':  begin
                writeln('saving canvas');
                savecanvas;
             end
    end; {case}
  until (ch='Q') or (ch='K');
end;

begin
  grinit; cleargr; fullview;
  loadcanvas;
  paint;
  grend;
end.