{
         **************************
         *                        *
         * R65 Pascal Main System *
         *                        *
         **************************

     Based on version 01/08/82 rricharz
     1979-1982  rricharz (r77@bluewin.ch)
     2018       recovered
     2023       last change version 5.4

R65 Pascal System Program. This program is
called, when Pascal is executed. It allows to
call other programs by names and with
arguments.

Examples:
  compile test1:p
  compile test1:p:04,1
  copy test3:P,0,1
  copy test3:P,0 1
  find test*

First tries to run program from drive 1,
unless a drive is specified in the call.
If not found there and not specified,
tries to run in from drive 0.
Default for arguments is drive 1.
}

program system;
uses syslib;

const stopcode=$2010;

var
  i, m, n: integer;
  ch: char;
  ok: boolean;
  argerr: integer;
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
    or (ch='*') or (ch='?') or (ch='/');
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
      argerr:=105;
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
  clearinput; writeln;
  writeln('R65 PASCAL VERSION 5.4');
  ok:=true;

  repeat {main loop (endless)}
    write('P*');
    next;
    if ch=cr then call(stopcode);
    while (ch=' ') or (ch=chr(13)) do next;
    { default for program to run is drive 1,
      if not found, run from drive 0,
      user input is ignored }
    drive1:=0; cyclus1:=0;
    getfname(runname,'R',ok,drive1,cyclus1);
    for i:=0 to 31 do argtype[i]:=chr(0);
    if ok then begin
      numarg:=0; n:=0; argerr:=0;
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
            or (ch='*') or (ch='?') or (ch='/')
              then begin {letter}
              { default for arg is drive 1 }
              drive2:=255; cyclus2:=0;
              getfname(aname,' ',ok,
                drive2,cyclus2);
              if not ok then argerr:=106;
              argtype[n]:='s';
              if n>22 then argerr:=107
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
        until (argerr<>0) or (n>31)
            or ((ch<>' ') and (ch<>','));
        if ch<>cr then argerr:=106;
      end; {arguments}
      if ch<>cr then argerr:=106;
    end {ok}
    else argerr:=106;

    if argerr<>0 then begin
      writeln;
      writeln(invvid,'Argument error ', argerr,norvid);
      clearinput;
    end
    else begin
      clearinput;
      endstk:=topmem-144;
      { try to run program from drive 1 }
      runprog(runname,1,cyclus1);
      if runerr=$84 then begin
        { if failed, run from drive 0 }
        runerr:=0;
        runprog(runname,0,cyclus1);
        if runerr=$84 then begin
          writeln(invvid,'Program not found',norvid);
          runerr:=0;
        end;
      end;
      endstk:=topmem-144;
      iocheck:=true;
      if runerr<>0 then begin
        writeln;
        writeln(invvid,'Program aborted',norvid);
      end
    end
  until false;
end.
