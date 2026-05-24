program sprites;
uses syslib,strlib,striolib,plotlib,filelib,spritelib;

{$R+}
{$U+}

const NX        = 12;
      NPIXELS   = 8;
      LARGEPIX  = 12;
      CLEFT     = chr($03);
      CRIGHT    = chr($16);
      CDOWN     = chr($18);
      ESC       = chr(0);
      TOGGLE    = chr($0c);
      LOOPS     = 5;  { no of loops until next frame }

mem sflag=$1781: integer&;

var selected, lastselected: integer;
    frames, framecounter:   integer;
    in, scyclus:            integer;
    ch: char;

proc writetable(cyc: integer);
var i, j, cyclus, drive, index: integer;
    f: file;
begin
  cyclus := cyc;
  drive  := 1;
  _strfio('SPRITETABLE:B', cyclus, drive);
  openw(f);
  index := 0;

  for j:= 0 to NSPRITES - 1 do begin
    for i:= 0 to 2 do begin
      write(@f,sprites[index],',');
      index := index + 1;
    end;
    writeln(@f,sprites[index]);
    index := index + 1;
  end;

  close(f);
end;

proc rectangle(x, y, xs, ys, color: integer);
begin
  _move(x, y);
  _draw(x + xs, y, color);
  _draw(x + xs, y + ys, color);
  _draw(x, y + ys, color);
  _draw(x, y, color);
end;

proc spritetable(last, current: integer);
var j, xoff, yoff: integer;

  proc coordinates(i);
  var xi, yi: integer;
  begin
    yi := i div NX;
    xi := i - (yi * NX);
    yoff := YSIZE - (NPIXELS * (yi + 1) + 10);
    xoff := NPIXELS * xi + 10;
  end;

begin
  _move(5,10);
  write(@PLOTDEV, 'Sprite # ', selected:2);
  for j := 0 to NSPRITES - 1 do begin
    coordinates(j);
    _showsprite(xoff, yoff, j);
  end;
  coordinates(last);
  rectangle(xoff - 1, yoff - 1,
                NPIXELS + 1, NPIXELS + 1, BLACK);
  coordinates(current);
  rectangle(xoff - 1, yoff - 1,
                NPIXELS + 1, NPIXELS + 1, WHITE);
end;

proc filled_rectangle(x, y, xs, ys, color: integer);
var v,h: integer;
begin
    for v := y to y + ys do begin
      _move(x, v);
      _draw(x + xs, v, color);
    end;
end;

func getbit(index, bx, by: integer): integer;
var base, part, bitno, mask: integer;
begin
  base := 4 * index;

  if by < 4 then
    part := 2
  else
    part := 0;

  if bx >= 4 then
    part := part + 1;

  bitno := _mod(7 - by, 4) * 4 + _mod(bx, 4);
  mask := $8000 shr bitno;

  if (sprites[base + part] and mask) <> 0 then
    getbit := 1
  else
    getbit := 0;
end;

proc showlarge(index: integer);
var x, y, bx, by, color, margin, size: integer;
begin
  size := 8 * LARGEPIX;
  margin := ((YSIZE + 1) - size) div 2;
  x := XSIZE - size - margin;
  y := margin;
  rectangle(x - 1, y - 1,
            8 * LARGEPIX + 2,
            8 * LARGEPIX + 2, WHITE);

  for by := 0 to 7 do
    for bx := 0 to 7 do begin

      if getbit(index, bx, by) <> 0 then
        color := WHITE
      else
        color := BLACK;

      filled_rectangle(x + LARGEPIX * bx,
                       y + LARGEPIX * by,
                       LARGEPIX, LARGEPIX,
                       color);
    end;
end;

proc showframe(index: integer);
const xoff = 48;
      yoff = 36;
var framenumber : integer;
begin
  if framecounter = -1 then begin
    _move(5, 22);
    write(@PLOTDEV, 'Frames', frames: 5);
    rectangle(xoff - 1, yoff - 1, 10, 10, WHITE);
    _showsprite(xoff, yoff, index);
    framecounter := 0;
  end;

  if frames > 0 then begin
    framenumber :=
      _mod(framecounter div LOOPS, frames);
    _showsprite(xoff, yoff, index + framenumber);
    framecounter := framecounter + 1;
  end;

  if framecounter >= (frames * LOOPS) then
    framecounter := 0;
end;

{
func mirror4(v: integer): integer;
begin
  mirror4 :=
      ((v and $8888) shr 3)
    + ((v and $4444) shr 1)
    + ((v and $2222) shl 1)
    + ((v and $1111) shl 3);
end;

proc hmirror(fromindex, toindex: integer);
var fbase, tbase: integer;
begin
  fbase := 4 * fromindex;
  tbase := 4 * toindex;

  sprites[tbase + 0] := mirror4(sprites[fbase + 1]);
  sprites[tbase + 1] := mirror4(sprites[fbase + 0]);

  sprites[tbase + 2] := mirror4(sprites[fbase + 3]);
  sprites[tbase + 3] := mirror4(sprites[fbase + 2]);
end;

proc copy(fromindex, toindex: integer);
var i, fbase, tbase: integer;
begin
  fbase := 4 * fromindex;
  tbase := 4 * toindex;
  for i := 0 to 3 do
    sprites[tbase + i] := sprites[fbase + i];
end;
}

begin
  _grinit;
  _fullview;
  _cleargr;
  writeln('W: write SPRITETABLE:B');
  scyclus := FILCYC;
  lastselected := 0;
  selected := 0;
  frames := 0;
  framecounter := -1;
  spritetable(lastselected, selected);
  showlarge(selected);
  repeat { main loop }
    repeat { wait for key pressed }
      ch := KEYPRESSED;
      { sflag bit 8 is escape flag. Pass it through }
      showframe(selected);
    until (ord(ch)<>0) or ((sflag and $80)<>0);
    read(@KEY,ch);
    sflag:=sflag and $7f; { clear escape flag }
    case ch of
      TOGGLE: write(TOGGLE);
      '0':    frames := 0;
      '1':    frames := 1;
      '2':    frames := 2;
      '3':    frames := 3;
      '4':    frames := 4;
      'W':    begin
                writeln('write SPRITETABLE:B');
                writetable(scyclus + 1);
              end;
      CRIGHT: selected := selected + 1;
      CLEFT:  selected := selected - 1;
      CUP:    selected := selected - NX;
      CDOWN:  selected := selected + NX
    end; { case }
    if selected < 0 then
      selected := 0;
    if selected > NSPRITES - frames - 1 then
      selected := NSPRITES - frames - 1;

    spritetable(lastselected, selected);
    showlarge(selected);
    lastselected := selected;
    framecounter := -1;
  until (ch='Q') or (ch='K') or (ch=ESC);
end.