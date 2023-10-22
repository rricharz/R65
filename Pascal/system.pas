{
         **************************
         *                        *
         * R65 Pascal Main System *
         *                        *
         **************************

     Based on version 01/08/82 rricharz
     cc 1979-1982     rricharz,rbaumann

Recovered 2018 by rricharz (r77@bluewin.ch)

R65 Pascal System Program. This program is
called, when Pascal is executed. It allows to
call other programs by names and with
arguments.

Examples:
  compile test1:p
  compile test1:p:04,1
  show test3:P 1

Default for program to run is drive 0
Default for arguments is drive 1
}

program system;
uses syslib;

var
  i, m, n: integer;
  ch: char;
  ok: boolean;
  synerr: integer;
  runname,aname: array[15] of char;
  drive1,drive2: integer;
  cyclus1,cyclus2: integer;

{ * runprog * }

proc runprog
  (name: array[15] of char;
   drv: integer; cyc: integer);

var i: integer;

begin
  for i:=0 to 15 do filnm1[i]:=name[i];
  filcy1:=cyc; fildrv:=drv; filflg:=$40;
  run
end;

{ * uppercase * }

func uppercase(ch1: char): char;

begin
  if (ch1 >= 'a') and (ch1 <= 'z') then
    uppercase := chr(ord(ch1) - 32)
  else
    uppercase := ch1;
end;

{ * next * }

proc next;

begin
  read(@input,ch);
  ch:=uppercase(ch);
end;

{ * getnum * }

proc getnum
  (var num: integer);

var sign: integer;

begin
  sign:=1; num:=0;
  case ch of
    '+': next;
    '-':  begin sign:=-1; next end
  end; {case}
  ok:=ok and ((ch>='0') and (ch<='9'));
  while (ch>='0') and (ch<='9') do begin
    num:=10*num+ord(ch)-ord('0');
    next
  end;
  num:=sign*num
end;

{ * getfname * }

proc getfname
  (var name: array[15] of char;
   ptype: char; var ok: boolean;
   var drv: integer; var cyc: integer);

var i, j: integer;

  func nexthexdigit: integer;

  var d: integer;

  begin
    next;
    if (ch>='0') and (ch<='9') then
      nexthexdigit:= ord(ch)-ord('0')
    else if (ch>='A') and (ch<='Z') then
      nexthexdigit:= ord(ch)-ord('A')+10
    else begin
      ok:=false;
    nexthexdigit:=0;
    end;
  end;

begin
  ok:=((ch>='A') and (ch<='Z'))
    or (ch='*') or (ch='?');
  i:=0;
  repeat
    name[i]:=ch; i:=succ(i);
    next
    until (i>12) or (ch=' ') or (ch=cr) or
      (ch=',') or (ch=':') or (ch='.');
  for j:=i to 15 do name[j]:=' ';
  if ch=':' then begin
    next;
    name[i]:=':';
    name[i+1]:=ch;
    next
  end
  else if ptype <> ' ' then begin
    name[i]:=':';
    name[i+1]:=ptype
  end;
  if (ch='.') then begin
    cyc:=nexthexdigit*16+nexthexdigit;
    next;
  end
  if (ch=',') then begin
    next;
    getnum(drv);
    if (drv<0) or (drv>1) then
      synerr:=6;
  end
end;

{ * clearinput * }

proc clearinput;

begin
  buffpn:=-1;
end;

{ * main * }

begin {main}
  maxseq:=mmaxseq-1;
  for i:=0 to mmaxseq-1 do fidrtb[i]:=0;
  clearinput;
  write('R65 Pascal System (22/10/23)');
  ok:=true;

  repeat {main loop (endless)}
    writeln;
    write('P*');
    next;
    while (ch=' ') or (ch=chr(13)) do next;
    { default for program to run is drive 0}
    drive1:=0; cyclus1:=0;
    getfname(runname,'R',ok,drive1,cyclus1);
    for i:=0 to 31 do argtype[i]:=chr(0);
    if ok then begin

      numarg:=0; n:=0; synerr:=0;
      if ch=' ' then begin  {arguments}
        repeat
          next;
          if (ch>='0') and (ch<='9') then
          begin {number}
            getnum(m);
            arglist[n]:=m;
            argtype[n]:='i';
          end {number}
          else if ((ch>='A') and (ch<='Z'))
            or (ch='*') or (ch='?') then begin {letter}
              { default for arg is drive 1 }
              drive2:=255; cyclus2:=0;
              getfname(aname,' ',ok,
                drive2,cyclus2);
              if not ok then synerr:=1;
              argtype[n]:='s';
              if n>22 then synerr:=2
              else begin
                for i:=0 to 7 do
                  arglist[n+i]:=
                    ord(packed(aname[2*i+1],
                    aname[2*i]));
                n:=n+7;
              end;
            arglist[n+1]:=cyclus2;
            argtype[n+1]:='i';
            if drive2=255 then begin {default}
              arglist[n+2]:=1;
              argtype[n+2]:='d';
            end else begin
              arglist[n+2]:=drive2;
              argtype[n+2]:='i';
            end;
            n:=n+2;
          end {letter}
          else begin
            arglist[n]:=0;
            argtype[n]:='d';
          end;
          n:=n+1; numarg:=numarg+1;
        until (synerr<>0) or (n>31)
            or ((ch<>' ') and (ch<>','));
        if ch<>cr then synerr:=3;
      end; {arguments}
      if ch<>cr then synerr:=4;
    end {ok}
    else synerr:=5;

    if synerr<>0 then begin
      writeln;
      write('Syntax error ', synerr);
      clearinput;
    end
    else begin
      clearinput;
      endstk:=topmem-144;
      runprog(runname,drive1,cyclus1);
      endstk:=topmem-144;
      iocheck:=true;
      if runerr<>0 then begin
        writeln;
        write('Program aborted');
      end
    end
  until false;
end.
 