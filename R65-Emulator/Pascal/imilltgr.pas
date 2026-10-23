{ IMILLTGR:P Include file for MILL (graphics) }

const
    { board coordinates }
    CX = 17;
    CY = 7;
    SX = 5;
    SY = 2;

    { dashboard coordinates }
    DASHX      = 36;
    DASHWHITEY = 2;
    DASHBLACKY = 8;
    MSGOFF     = 4;
    INPUTOFF   = 3;
    STONEOFF   = 1;
    NAMEOFF    = 0;

    I_PLACE  = 1;
    I_MOVE   = 2;
    I_TAKE   = 3;
    I_NAME   = 4;

var  markplace,marktake,markmove1,markmove2: integer;

func _escape_pending: boolean;
{****************************}
begin
  _escape_pending := ((mem[$1781] and $80)<>0);
end;

proc init_graphics;
{*****************}
begin
  write(HOM,CSC);
  markplace:=-1;
  marktake:=-1;
  markmove1:=-1;
  markmove2:=-1;
end;

proc init_canvas;
{***************}
begin
  write(HOM,CSC);

  { draw dashboard borders }
  _recttxtgr(DASHX-1,47,
          DASHWHITEY-1,DASHWHITEY+5,CYAN);
  _recttxtgr(DASHX-1,47,
          DASHBLACKY-1,DASHBLACKY+5,CYAN);

  { dashboard titles }
  _setcursor(DASHX,DASHWHITEY+NAMEOFF);
  write('PLAYER');
  _setcursor(DASHX,DASHBLACKY+NAMEOFF);
  write('COMPUTER');
end;

proc message(number: integer; field: packed char;
             player: integer);
{***********************************************}
var y: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY
  else
    y:=DASHBLACKY;

  _setcursor(DASHX,y+MSGOFF);
  write('           ');
  _setcursor(DASHX,y+MSGOFF);

  if (number<>0) and (number<>27) then
    write(INVVID);

  case number of
    0: begin end;
    1: write('Invalid');
    2: write(field,' invalid');
    3: write(field,' empty');
    4: write(field,' white');
    5: write(field,' black');
    6: write(field,' occupied');
    7: write('Bad move');
    8: write(field,' is mill');
   10: write('Looser');
   11: write('Winner');
   12: write('Aborted');
   21: write('Thinking');
   27: write('Saved')
   else write('Error ',number)
  end;

  write(NORVID);
end;

proc strmessage(s:cpnt; player: integer);
{***************************************}
var y: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY+MSGOFF
  else if player=BLACK then
    y:=DASHBLACKY+MSGOFF
  else
    { computer's last move }
    y:=DASHBLACKY+INPUTOFF;

  _setcursor(DASHX,y);
  write('           ');
  _setcursor(DASHX,y);
  write(s);
end;

func findpos(labelvalue: packed char): integer;
{*********************************************}
var position: integer;
begin
  position:=0;
  while (position<NPOSITIONS) and
        (labelvalue<>label[position]) do
    position:=position+1;

  if position<NPOSITIONS then
    findpos:=position
  else
    findpos:=-1;
end;

proc getinput(player, request0: integer;
              var p1,p2: integer);
{**************************************}

const TOGGLE    = chr(12);
      BACKSPACE = chr(127);

var s: cpnt;
    x,y,len,maxlen, request, oldrequest: integer;
    valid: boolean;

  proc prompt;
  begin
    _setcursor(DASHX,y);
    write(INVVID);

    case request of
      I_PLACE:
        begin
          write('Place?');
          x:=DASHX+6;
        end;
      I_MOVE:
        begin
          write('Move?');
          x:=DASHX+5;
        end;
      I_TAKE:
        begin
          write('Take?');
          x:=DASHX+5;
        end;
      I_NAME:
        begin
          write('Name?');
          x:=DASHX+5;
        end
    end;

    write(NORVID);
  end;

  proc editinput;
  var c: char;

    proc redraw;
    var j: integer;
    begin
      { clear complete input line }
      _setcursor(DASHX,y);
      write('           ');

      { redraw prompt }
      prompt;

      { redraw input }
      _setcursor(x,y);
      for j:=0 to len-1 do
        write(s[j]);

      { position blinking cursor }
      _setcursor(x+len,y);
    end;

  begin
    len:=0;
    s[0]:=ENDMARK;

    if request=I_MOVE then
      maxlen:=5
    else
      maxlen:=4;

    redraw;

    repeat
      repeat
        c:=KEYPRESSED;
        if c=chr(0) then
          _delay10msec(3);
      until c<>chr(0);

      KEYPRESSED:=chr(0);

      if c=BACKSPACE then begin
        if len>0 then begin
          len:=len-1;
          s[len]:=ENDMARK;
          redraw;
        end
      end

      else if c=TOGGLE then
        write(TOGGLE)

      else if c<>CR then begin
        if len<maxlen then begin
          s[len]:=c;
          len:=len+1;
          s[len]:=ENDMARK;
          redraw;
        end
      end

    until c=CR;

    { clear complete input line }
    _setcursor(DASHX,y);
    write('           ');
  end;

begin { getinput }

  request:=request0;
  s:=_new;
  s[0]:=ENDMARK;

  if player=BLACK then
    y:=DASHBLACKY+INPUTOFF
  else
    y:=DASHWHITEY+INPUTOFF;

  repeat

    oldrequest:=request;
    valid:=false;
    p1:=-1;
    p2:=-1;

    editinput;

    writeln(@PROTOCOL,'COMMAND ',s);

    if _strcmp(s,'QUIT')=0 then begin
      message(12,'  ',player);
      quit;
      _abort;
    end;

    if _strcmp(s,'SAVE')=0 then begin
      request:=I_NAME;
      editinput;
      writeln(@PROTOCOL,'NAME ',s);
      savegame(s, player);
      message(27,'  ',player);
      { return to the original request }
      request:=oldrequest;
    end else begin;

      valid:=false;
      p1:=-1;
      p2:=-1;

      case request of

        I_PLACE,I_TAKE:
          begin
            if len=2 then begin
              p1:=findpos(packed(s[0],s[1]));

              if p1>=0 then
                valid:=true
                else
                message(2,packed(s[0],s[1]),player);
              end else
                message(1,'  ',player);
              end;


        I_MOVE:
          begin
            if (len=5) and (s[2]='-') then begin
              p1:=findpos(packed(s[0],s[1]));

              if p1<0 then
                message(2,packed(s[0],s[1]),player)

              else begin
                p2:=findpos(packed(s[3],s[4]));

                if p2<0 then
                  message(2,packed(s[3],s[4]),player)

                else
                  valid:=true;
              end
            end
          else
            message(1,'  ',player)
        end
      end;

    end;

  until valid;

  message(0,'  ',player);
  _release(s);
end;

proc drawstone(pos, player: integer);
{**********************************}
var x,y,code,color: integer;
    marked: boolean;
begin
  x:=CX+(ord(high(label[pos]))-ord('D'))*SX;
  y:=CY-(ord(low(label[pos]))-ord('4'))*SY;

  marked:=false;

  if marks then
    marked:=(pos=markplace) or
            (pos=marktake) or
            (pos=markmove1) or
            (pos=markmove2);

  writeln(@PROTOCOL,
    'DRAWSTONE pos=',pos,
    ' player=',player,
    ' marks=',marks,
    ' place=',markplace,
    ' take=',marktake,
    ' move1=',markmove1,
    ' move2=',markmove2,
    ' marked=',marked);

  if player=WHITE then code:=$10
  else code:=$11;

  if marked then color:=YELLOW else color:=CYAN;
  _txtgr(x,y,code,color);
end;

proc drawboard;
{*************}
var i,x1,y1,x2,y2: integer;

  proc square(n: integer);
  var
    x1,x2,y1,y2: integer;
  begin
    x1:=CX-n*SX;
    x2:=CX+n*SX;
    y1:=CY-n*SY;
    y2:=CY+n*SY;
    _recttxtgr(x1,x2,y1,y2,CYAN);
  end;

begin
  { three concentric squares }
  square(1);
  square(2);
  square(3);

  { connections between squares }
  _htxtgr(CX-3*SX,CX-SX,CY,CYAN);
  _htxtgr(CX+SX,CX+3*SX,CY,CYAN);

  _vtxtgr(CX,CY-3*SY,CY-SY,CYAN);
  _vtxtgr(CX,CY+SY,CY+3*SY,CYAN);
end;

proc drawmark(pos, player: integer);
{**********************************}
var x,y,code: integer;
begin
  x:=CX+(ord(high(label[pos]))-ord('D'))*SX;
  y:=CY-(ord(low(label[pos]))-ord('4'))*SY;

  if player=WHITE then code:=$12
  else code:=$13;

  _txtgr(x,y,code,YELLOW);
end;

proc drawstones;
{**************}
var position: integer;
begin
  for position:=0 to NPOSITIONS-1 do
    if board[position]<>EMPTY then
      drawstone(position,board[position]);
end;

proc drawmarkedstones(player: integer);
{*************************************}
begin
  drawstones;

  if marks then begin
    if markmove1>=0 then
      drawmark(markmove1,player);

    if marktake>=0 then
      drawmark(marktake,otherplayer(player));
  end;
end;

proc clearstone(stone,player: integer);
{************************************}
begin
  drawboard;
  drawmarkedstones(player);
end;

proc drawlabels;
{**************}
var i: integer;
begin
  { column labels A-G }
  for i:=0 to 6 do
    _txtgr(CX+(i-3)*SX,14,ord('A')+i,CYAN);

  { row labels 1-7 }
  for i:=0 to 6 do
    _txtgr(0,CY+(3-i)*SY,ord('1')+i,CYAN);
end;

proc cleardashstone(stone, player: integer);
{******************************************}
var x,y: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY+STONEOFF
  else
    y:=DASHBLACKY+STONEOFF;

  if stone<5 then
    x:=DASHX+1+2*stone
  else begin
    x:=DASHX+1+2*(stone-5);
    y:=y+1;
  end;

  _setcursor(x,y);
  write(' ');
end;

proc dashstone(stone,player,color: integer);
{******************************************}
var x,y: integer;
begin
  if player=WHITE then
    y:=DASHWHITEY+STONEOFF
  else
    y:=DASHBLACKY+STONEOFF;

  if stone<5 then
    x:=DASHX+1+2*stone
  else begin
    x:=DASHX+1+2*(stone-5);
    y:=y+1;
  end;

  _setcursor(x,y);

  if color=WHITE then
    _writetxtgr($10)
  else
    _writetxtgr($11);
end;

proc drawreserve(player: integer);
{****************************}
var stone,color: integer;
begin
  for stone:=0 to 8 do begin
    if stone<stones[player] then
      color:=player
    else
      color:=EMPTY;

    if stone>8-captured[player] then
      color:=otherplayer(player);

    if color<>EMPTY then
      dashstone(stone,player,color)
    else
      cleardashstone(stone,player);
  end;
end;

proc selectdashboard(player: integer);
{**********************************}
begin
  { player title }
  _setcursor(DASHX,DASHWHITEY+NAMEOFF);
  if player=WHITE then write(INVVID);
  write('PLAYER');
  write(NORVID);

  { computer title }
  _setcursor(DASHX,DASHBLACKY+NAMEOFF);
  if player=BLACK then write(INVVID);
  write('COMPUTER');
  write(NORVID);
end;

proc quit;
{********}
begin
  _setcursor(0,15);
end;

proc clearmarks;
{***************}
var p1,p2,p3,p4: integer;

  proc restore(p: integer);
  begin
    if (p>=0) and (board[p]<>EMPTY) then
      drawstone(p,board[p]);
  end;

begin
  p1:=markplace;
  p2:=marktake;
  p3:=markmove1;
  p4:=markmove2;

  markplace:=-1;
  marktake:=-1;
  markmove1:=-1;
  markmove2:=-1;

  if marks then begin
    restore(p1);
    restore(p2);
    restore(p3);
    restore(p4);
  end;
end;

proc screenmessage(s:cpnt);
{*************************}
begin
  _setcursor(0,15);
  write(CSC);
  write(s);
end;