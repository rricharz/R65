{ ianimate - run animation in loop                  }
{  proc expaint;                                    }
{    Called to paint one picture and apply motion.  }
{  func exkey(ch:char):boolean;                     }
{    Called to check for KEY and stop loop if true  }

proc animate(arepeat:boolean);
{ arepeat: auto repeat cursor keys without _delay }
const toggle=chr($0c);
      cleft=chr($03); cright=chr($16);
      cup=chr($1a); cdown=chr($18); esc=chr(0);
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
      { sflag bit 8 is escape flag. Pass it through }
    until (ord(ch)<>0) or ((sflag and $80)<>0)
      or stop;
    if not(((ch=cup) or (ch=cdown) or (ch=cleft) or
       (ch=cright)) and
       ((emuflags and 1)<>0) and arepeat) then
       { cursor keys auto repeat without _delay }
       KEYPRESSED := chr(0);
    sflag:=sflag and $7f; { clear escape flag }
    if ch=toggle then write(toggle);
  until exkey(ch) or stop;
end;
