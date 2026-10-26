{ ianimate - run animation in loop                  }
{  proc expaint;                                    }
{    Called to paint one picture and apply motion.  }
{  func exkey(ch:char):boolean;                     }
{    Called to check for KEY and stop loop if true  }
{  proc exmouse(mode,x,y:integer);                  }
{    Called when a mouse event is received.         }

proc animate(arepeat:boolean);
{ arepeat: auto repeat cursor keys without delay }
const toggle=chr($0c);
      cleft=chr($03); cright=chr($16);
      cup=chr($1a); cdown=chr($18); esc=chr(0);
mem   sflag=$1781:integer&;
      emuflags=$1707:integer&;

      mousemode=$1708:integer&;
      mousex=$1709:integer&;
      mousey=$170a:integer&;

var   ch:char;
      mode,x,y:integer;
      dummy0:integer;
      stop:boolean;
begin
  repeat
    repeat
      mode:=mousemode;
      x:=mousex;
      y:=mousey;
      if mode<>0 then exmouse(mode,x,y);
      stop:=expaint;
      dummy0:=_syncscreen; { sleep for up to 30 msec }
      ch:=KEYPRESSED;
      { sflag bit 8 is escape flag. Pass it through }
    until (ord(ch)<>0) or ((sflag and $80)<>0)
      or stop;
    if not(((ch=cup) or (ch=cdown) or (ch=cleft) or
       (ch=cright)) and
       ((emuflags and 1)<>0) and arepeat) then
       { cursor keys auto repeat without delay }
       KEYPRESSED := chr(0);
    sflag:=sflag and $7f; { clear escape flag }
    if ch=toggle then write(toggle);
  until exkey(ch) or stop;
end;