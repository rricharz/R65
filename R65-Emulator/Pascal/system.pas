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
  COMPILE TEST1:P
  COMPILE TEST1:P.1F,1
  COMPILE TEST1
  COPY TEST3,0,1
  FIND TEST*
  GREP "abcd" TEST:P

First tries to run program from drive 1,
unless a drive is specified in the call.
If not found there and not specified,
tries to run it from drive 0. User input
of drive in the command is ignored       }

program system;
uses syslib;

const
  title='R65 PASCAL VERSION 6.0';
  STOPCODE = $2010;
  MMAXSEQ  = 8;         {max no of seq. files}

mem
  BUFFPN   = $0015: integer&;
  FILERR   = $00db: integer&;
  FILNAM   = $0301: array[15] of char&;
  FIDRTB   = $0339: array[8] of integer&;
  NUMARG   = $005f: integer&;
  FILDRV   = $00dc: integer&;
  FILFLG   = $00da: integer&;
  MAXSEQ   = $0336: integer&;
  ARGLIST  = $0060: array[10] of integer;
  ARGLISTS = $0060: array[63] of char&;
  ARGTYPE  = $00a0: array[31] of char&;
  FILNM1   = $0320: array[15] of char&;
  FILCY1   = $0330: integer&;

var
  i, m, n: integer;
  ch: char;
  ok: boolean;
  argerr: integer;
  runname,aname: array[15] of char;
  drive1,drive2: integer;
  cyclus1,cyclus2: integer;

{ * runprog * }

proc chainprog
  (name: array[15] of char;
   drv: integer; cyc: integer);
var j: integer;
begin
  for j:=0 to 15 do FILNM1[j]:=name[j];
  FILCY1:=cyc;
  FILDRV:=drv;
  FILFLG:=$40;
  chain
end;

{ * _uppercase * }

func _uppercase(ch1: char): char;

begin
  if (ch1 >= 'a') and (ch1 <= 'z') then
    _uppercase := chr(ord(ch1) - 32)
  else
    _uppercase := ch1;
end;

{ * next * }

proc next;

begin
  read(@INPUT,ch);
  ch:=_uppercase(ch);
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
   ptype: char; var isok: boolean;
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
      isok:=false;
    nexthexdigit:=0;
    end;
  end;

begin
  isok:=((ch>='A') and (ch<='Z'))
    or (ch='*') or (ch='?') or (ch='/');
  i:=0;
  repeat
    name[i]:=ch; i:=succ(i);
    next
    until (i>12) or (ch=' ') or (ch=CR) or
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
  BUFFPN:=-1;
end;

{ * check for errors * }

proc checkrunerr;
begin
  write(INVVID);
  case RUNERR of
    $81: writeln('Division by zero');
    $82: writeln('Stack overflow');
    $83: writeln('Index out of bounds');
    $84: writeln('Program not found');
    $85: writeln('P-code not implemented');
    $88: writeln('Heap overflow');
    $89: writeln('Pointer not allocated (NIL)');
    $90: writeln('Writing to constant string');
    $91: writeln('String too long');
    $92: writeln('String cannot be released');
    $01: writeln('File read/write');
    $03: writeln('Escape during read/write');
    $04: writeln('Wrong record number');
    $05: writeln('Wrong file type');
    $06: writeln('File not found');
    $07: writeln('Disk not ready');
    $08: writeln('Directory full, not stored');
    $23: writeln('Too many open files');
    $24: writeln('Directory error');
    $25: writeln('Wrong file number, file not open');
    $26: writeln('Disk full, not stored')
  end {case}
  write(NORVID);
  ENDSTK:=TOPMEM-144;
  IOCHECK:=true;
  RUNERR:=0;
end;

{ * main * }

begin {main}
  checkrunerr;

  MAXSEQ := MMAXSEQ - 1;
  for i:=0 to MMAXSEQ-1 do FIDRTB[i]:=0;
  clearinput;
  ok:=true;

  write('P*');
  next;
  while ch=CR do begin
    write('P*');
    next;
  end;
  while (ch=' ') do next;

  drive1:=1;
  cyclus1:=0;
  getfname(runname,'R',ok,drive1,cyclus1);

  for i:=0 to 31 do ARGTYPE[i]:=chr(0);

  if ok then begin
    NUMARG:=0;
    n:=0;
    argerr:=0;
    if ch=' ' then begin  {arguments}
      repeat
        next;

        { quoted argument }
        if ch='"' then begin
          ARGTYPE[n]:='q';
          if n>23 then argerr:=107
          else begin
            for i:=0 to 15 do aname[i]:=' ';
            i:=0;
            next;
            while (ch<>'"') and (ch<>CR) do begin
              if i<=15 then begin
                aname[i]:=ch;
                i:=succ(i);
              end else
                argerr:=106;
              next;
            end;
            if ch<>'"' then
              argerr:=106
            else
              next;
            for i:=0 to 7 do
              ARGLIST[n+i]:=
                  ord(packed(aname[2*i+1],
                  aname[2*i]));
            n:=n+7;
          end
        end

        { number }
        else if (ch>='0') and (ch<='9') then begin
          getnum(m);
          ARGLIST[n]:=m;
          ARGTYPE[n]:='i';
        end

        { letter or equivalent }
        else if ((ch>='A') and (ch<='Z'))
            or (ch='*') or (ch='?') or (ch='/')
            then begin {letter}
          drive2:=255; cyclus2:=0;
          getfname(aname,' ',ok,drive2,cyclus2);
          if not ok then argerr:=106;
          ARGTYPE[n]:='s';
          if n>22 then argerr:=107
          else begin
            for i:=0 to 7 do
              ARGLIST[n+i]:=
                    ord(packed(aname[2*i+1],
                    aname[2*i]));
            n:=n+7;
          end;
          ARGLIST[n+1]:=cyclus2;
          ARGTYPE[n+1]:='i';
          if drive2=255 then begin {default}
            ARGLIST[n+2]:=1;
            ARGTYPE[n+2]:='d';
          end else begin
            ARGLIST[n+2]:=drive2;
            ARGTYPE[n+2]:='i';
          end;
          n:=n+2;
        end

        { default drive number }
        else begin
          ARGLIST[n]:=0;
          ARGTYPE[n]:='d';
        end;

        n:=n+1;
        NUMARG:=NUMARG+1;

      until (argerr<>0) or (n>31)
            or ((ch<>' ') and (ch<>','));
      if ch<>CR then argerr:=106;
    end; {arguments}
    if ch<>CR then argerr:=106;
  end {ok}
    else argerr:=106;

  if argerr<>0 then begin
    write(INVVID);
    case argerr of
        105: writeln('Unknown drive in argument');
        106: writeln('Argument syntax error');
        107: writeln('Too many arguments')
        end {case};
    write(NORVID)
  end else begin
    clearinput;
    ENDSTK:=TOPMEM-144;
    chainprog(runname,drive1,cyclus1);
  end;
end.
