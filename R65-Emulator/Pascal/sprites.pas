{ ***********************************
  * SPRITES - view and edit sprites *
  ***********************************

  SPRITETABLE:B is stored on disk 0 and is
  used there by the sprite library SPRITELIB

  SPRITES allows to view the sprites in
  SPRITETABLE:B, to show animations of sprites
  and to copy and edit sprites.

  If sprites are edited, a new copy of
  SPRITETABLE:B is made on disk 0
                                              }


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
      NBLINKS   = 10;  {no of loops until bink}
      LOOPS     = 10;  {no of loops until next frame}
      STATUSLN  = 36;
      DISK      = 0;

mem sflag=$1781: integer&;

var selected, lastselected: integer;
    frames, framecounter:   integer;
    in, editbit:            integer;
    isedited, editflag:     boolean;
    ch:                     char;
    blink, elapsed:         integer;
    copied_sprites:         array[3] of integer;

proc writetable;
var i, j, cyclus, drive, index: integer;
    f: file;
begin
  cyclus := 0;
  drive  := DISK;
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
  _rectangle(xoff - 1, yoff - 1,
                NPIXELS + 1, NPIXELS + 1, BLACK);
  coordinates(current);
  _rectangle(xoff - 1, yoff - 1,
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

proc toggle(index: integer);
var base, part, bitno, mask, bx, by: integer;
begin
  base := 4 * index;
  by := editbit div 8;
  bx := editbit - by * 8;

  if by < 4 then
    part := 2
  else
    part := 0;
  if bx >= 4 then
    part := part + 1;

  bitno := _mod(7 - by, 4) * 4 + _mod(bx, 4);
  mask := $8000 shr bitno;

  sprites[base + part] :=
    sprites[base + part] xor mask;

  isedited := true;

end;

proc showlarge(index: integer);
var x, y, bx, by, color, margin, size: integer;
begin
  size := 8 * LARGEPIX;
  margin := ((YSIZE + 1) - size) div 2;
  x := XSIZE - size - margin;
  y := margin;
  _rectangle(x - 1, y - 1, size + 2, size + 2, WHITE);

  for by := 0 to 7 do
    for bx := 0 to 7 do begin

      if getbit(index, bx, by) <> 0 then
        color := WHITE
      else
        color := BLACK;

      filled_rectangle(x + LARGEPIX * bx,
                       y + LARGEPIX * by,
                       LARGEPIX, LARGEPIX, color);
    end;
end;

proc showcursor;
var x, y, bx, by, color, margin, size: integer;
begin
  if editflag then begin
    by := editbit div 8;
    bx := editbit - by * 8;
    size := 8 * LARGEPIX;
    margin := ((YSIZE + 1) - size) div 2;
    x := XSIZE - size - margin;
    y := margin;
    if (blink < NBLINKS) then
      color := BLACK
    else
      color := WHITE;
    _rectangle(x + LARGEPIX * bx,
               y + LARGEPIX * by,
               LARGEPIX - 1, LARGEPIX - 1, color);
    blink := blink + 1;
    if blink >= 2 * NBLINKS then blink := 0;
  end;
end;

proc showframe(index: integer);
const xoff = 83;
var framenumber, yoff : integer;
begin
  yoff := STATUSLN;
  if framecounter = -1 then begin
    _move(5, 22);
    write(@PLOTDEV, 'Frames', frames: 5);
    _rectangle(xoff - 1, yoff - 1, 9, 9, WHITE);
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
}

proc copy(fromindex: integer);
var i, base: integer;
begin
  base := 4 * fromindex;
  for i := 0 to 3 do
    copied_sprites[i] := sprites[base + i];
end;

proc paste(toindex: integer);
var i, base: integer;
begin
  base := 4 * toindex;
  for i := 0 to 3 do
    sprites[base + i] := copied_sprites[i];
end;


begin
  _grinit;
  _fullview;
  _cleargr;
  writeln(
'Q:   Save and quit   K:     Quit without saving');
  writeln(
'E:   Start Edit mode BLANK: Toggle pixel');
  writeln(
'C:   Copy sprite     V:     Paste sprite');
  writeln(
'1..4 Animate frames  ESC:   Leave edit mode');
  lastselected := 0;
  selected := 0;
  frames := 0;
  framecounter := -1;
  isedited := false;
  editflag := false;
  editbit := 0;
  blink := 0;
  spritetable(lastselected, selected);
  showlarge(selected);
  _move(5,STATUSLN); write(@PLOTDEV,'VIEW');

  repeat { main loop }
    repeat { wait for key pressed }
      ch := KEYPRESSED;
      { sflag bit 8 is escape flag. Pass it through }
      showframe(selected);
      showcursor;
      elapsed := _syncscreen;
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
      'Q':    begin
                if isedited then
                  writetable;
              end;
      'E':    begin
                _move(5,STATUSLN);
                write(@PLOTDEV,'EDIT');
                editflag := true;
                frames := 0;
              end;
      ' ':    toggle(selected);
      'C':    copy(selected);
      'V':    paste(selected);
      ESC:    if editflag then begin
                _move(5,STATUSLN);
                write(@PLOTDEV,'VIEW');
                editflag := false;
                ch := 'C'; { do not exit }
                if isedited then
                  writetable;
              end;
      CRIGHT: if editflag then
                editbit := editbit + 1
              else
                selected := selected + 1;
      CLEFT:  if editflag then
                editbit := editbit - 1
              else
                selected := selected - 1;
      CUP:    if editflag then
                editbit := editbit + 8
              else
                selected := selected - NX;
      CDOWN:  if editflag then
                editbit := editbit - 8
              else
                selected := selected + NX
    end {case};

    if selected < 0 then
      selected := 0;
    if selected > NSPRITES - frames - 1 then
      selected := NSPRITES - frames - 1;
    if editbit < 0 then
      editbit := 0;
    if editbit > 63 then
      editbit := 63;

    spritetable(lastselected, selected);
    showlarge(selected);
    lastselected := selected;
    framecounter := -1;
  until (ch='Q') or (ch='K') or (ch=ESC);
  _grend;
end.