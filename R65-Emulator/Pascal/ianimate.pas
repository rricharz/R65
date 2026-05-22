{ ianimate - run animation in loop                  }
{  proc expaint;                                    }
{    Called to paint one picture and apply motion   }
{  func exkey(ch:char):boolean;                     }
{    Called to check for KEY and stop loop if true  }

proc animate(arepeat:boolean);
{ arepeat: auto repeat cursor keys without _delay }
const TOGGLE=chr($0c);
      CLEFT=chr($03); CRIGHT=chr($16);
      CUP=chr($1a); CDOWN=chr($18); ESC=chr(0);
mem   sflag=$1781:integer&;
      emuflags=$1707:integer&;
var   ch:char;
      dummy0:integer;
      stop:boolean;
begin
  repeat
    repeat
      stop:=expaint;
      dummy0:=_syncscreen; { sleep for up to 30 msec }
      ch:=KEYPRESSED; { sleep for 10 msec }
      { sflag bit 8 is ESCape flag. Pass it through }
    until (ord(ch)<>0) or ((sflag and $80)<>0)
      or stop;
    if not(((ch=CUP) or (ch=CDOWN) or (ch=CLEFT) or
       (ch=CRIGHT)) and
       ((emuflags and 1)<>0) and arepeat) then
       { cursor keys auto repeat without _delay }
       KEYPRESSED := chr(0);
    sflag:=sflag and $7f; { clear ESCape flag }
    if ch=TOGGLE then write(TOGGLE);
  until exkey(ch) or stop;
end;
