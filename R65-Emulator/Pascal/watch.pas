program watch;
uses syslib,timelib,strlib,ledlib;

const mquit = 0;        { values for mode }
      mtime = 1;
      mstopped = 2;
      mrunning = 3;

mem keypressed=$1785: char&;

var s:cpnt;
    ch: char;
    mode: integer;
    mh,mm,ms,mt: integer;
    sh,sm,ss,st: integer;

proc delay10msec(time:integer);
mem emucom=$1430: integer&;
var i:integer;
begin
  for i:=1 to time do
    emucom:=6;
end;

proc timetostr(c:cpnt; h,m,s,t:integer);
  proc writebcd(i:integer);
  begin
    write(@c,chr((i div 10)+ord('0')));
    write(@c,chr(mod(i,10)+ord('0')));
  end;
begin
  writebcd(h);
  c[1]:=chr(ord(c[1])+128); { bit 8 for dot}
  writebcd(m);
  write(@c,' ');
  writebcd(s);
  c[6]:=chr(ord(c[6])+128);
  write(@c,chr(t div 10 + ord('0')));
end;

begin
  writeln('R65 Watch');
  writeln('  R: Reset stop watch');
  writeln('  S: Start/stop stop watch');
  writeln('  T: Current time');
  writeln('  Q: Quit');
  s:=strnew;
  mh:=0; mm:=0; ms:=0; mt:=0;
  mode:=mtime;
  repeat
    s[0]:=endmark;
    gettime;
    case mode of
      mtime:    timetostr(s,hours,minutes,
                  seconds,tenmillis);
      mstopped: begin
                  timetostr(s,mh,mm,ms,mt);
                end;
      mrunning: begin
                  mh:=hours-sh;
                  mm:=minutes-sm;
                  ms:=seconds-ss;
                  mt:=tenmillis-st;
                  while mt<0 do begin
                    mt:=mt+100; ms:=ms-1;
                  end;
                  while ms<0 do begin
                    ms:=ms+60; mm:=mm-1;
                  end;
                  while mm<0 do begin
                    mm:=mm+60; mh:=mh-1;
                  end;
                  while mt>99 do begin
                    mt:=mt-100; ms:=ms+1;
                  end;
                  while ms>59 do begin
                    ms:=ms-60; mm:=mm+1;
                  end;
                  while mm>59 do begin
                    mm:=mm-60; mh:=mh+1;
                  end;
                  timetostr(s,mh,mm,ms,mt);
                end
      end {case};
    ledstring(s);
    delay10msec(9);
    ch:=keypressed;
    case ch of
      'S': if mode=mrunning then mode:=mstopped
           else begin
             mode:=mrunning;
             sh:=hours-mh; sm:=minutes-mm;
             ss:=seconds-ms; st:=tenmillis-mt;
           end;
      'R': begin
             mh:=0; mm:=0; ms:=0;
             mt:=0; mode:=mstopped;
           end;
      'T': mode:=mtime;
      'Q': mode:=mquit
     end {case};
    keypressed:=chr(0);
  until mode=mquit;
end.