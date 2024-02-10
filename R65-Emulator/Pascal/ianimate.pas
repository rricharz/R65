{ ianimate - run animation in loop
  proc expaint;
    Called to paint one picture and apply motion.
  func exkey(ch:char):boolean;
    Called to check for key and stop loop if true  }

proc animate;
const toggle=chr($0c);
mem sflag=$1781:integer&;
var ch:char;
    dummy:integer;
begin
  repeat
    repeat
      expaint;
      dummy:=syncscreen; { sleep for up to 30 msec }
      ch:=keypressed; { sleep for 10 msec }
      { sflag bit 8 is escape flag. Pass it through }
    until (ord(ch)<>0) or ((sflag and $80)<>0);
    read(@key,ch);
    sflag:=sflag and $7f; { clear escape flag }
    if ch=toggle then write(toggle);
  until exkey(ch);
end;