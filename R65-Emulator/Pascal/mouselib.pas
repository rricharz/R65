{ MOUSELIB - Keyboard and mouse input

 _getinput(mode,x,y,key): non-blocking input
   Returns true if keyboard or mouse input exists.
 _waitinput(mode,x,y,key): blocking input
   Waits for keyboard, mouse, or ESC.

 mode: 0=no mouse, 1=mouse text, 2=mouse graphics
 x,y: mouse coordinates;
 key: keyboard character
 ESC flag is not cleared by either routine.
 Use _isesc from SYSLIB to test and clear ESC.
}

library mouselib;

func _getinput(var mode,x,y: integer;
                   var key: char): boolean;
mem
  MOUSEMODE  = $1708: integer&;
  MOUSEX     = $1709: integer&;
  MOUSEY     = $170a: integer&;
  KEYPRESSED = $1785: char&;
var key0: char;
begin
  mode:=MOUSEMODE;
  x:=MOUSEX;
  y:=MOUSEY;

  key0:=KEYPRESSED;
  key:=key0;
  if key0<>chr(0) then
    KEYPRESSED:=chr(0);

  _getinput:=(mode<>0) or (key<>chr(0));
end;

proc _waitinput(var mode,x,y: integer;
                var key: char);
mem
  EMUCOM = $1430:integer&;
  SFLAG  = $1781:integer&;
var found:boolean;
begin
  repeat
    found:=_getinput(mode,x,y,key);
    if not found then begin
      found:=(SFLAG and $80)<>0;
      if not found then EMUCOM:=6;
    end;
  until found;
end;

begin
end. 