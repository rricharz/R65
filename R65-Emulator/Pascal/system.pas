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
uses syslib, arglib, filelib, strlib, striolib;

{$U+}

const
  MMAXSEQ  = 8;     {max no of sequential files}
  CLRSCR   = chr($11);  {clear to end of screen}
  NHISTORY = 4; { entries in history }
  AUTOPR   = $08;

mem
  BUFFPN   = $0015: integer&;
  FIDRTB   = $0339: array[8] of integer&;
  MAXSEQ   = $0336: integer&;
  VFLAG    = $1780: integer&;

  { persistent SYSTEM memory area }
  HISTMAG  = $df00: integer&; { initialized }
  HISTHEAD = $df01: integer&; { next slot }
  HISTCNT  = $df02: integer&; { current entries }
  { $df03-$dfc7 are used for history strings }

var
  k, m, n,res: integer;
  ch: char;
  ok: boolean;
  argerr: integer;
  runname,aname: array[15] of char;
  drive1,drive2: integer;
  cyclus1,cyclus2: integer;
  gline: cpnt;
  histpos: integer;
  history: array[NHISTORY] of cpnt;
  spos: integer;

proc chainprog(name: array[15] of char;
               cyc: integer; drv: integer);
{*****************************************}
var j: integer;
begin
  for j:=0 to 15 do FILNM1[j]:=name[j];
  FILCY1:=cyc;
  FILDRV:=drv;
  FILFLG:=$40;
  chain
end;

proc next;
{********}
begin
  if gline[spos] = ENDMARK then
    ch := CR
  else begin
    ch := _uppercase(gline[spos]);
    spos := spos + 1;
  end;
end;

proc init_persistent;
{*******************}
var i: integer;
    s: cpnt;
begin
  history[0] := cpnt($df03);
  history[1] := cpnt($df34);
  history[2] := cpnt($df65);
  history[3] := cpnt($df96);
  histpos  := 0;
  if HISTMAG <> $a5 then begin
    HISTMAG  := $a5;
    HISTHEAD := 0;
    HISTCNT  := 0;
    { This initialization should not be required }
    for i := 0 to 3 do begin
      s := history[i];
      s[0] := ENDMARK;
    end;
  end;
end;

proc add_history(line: cpnt);
{***************************}
begin
  _strcpy(line, history[HISTHEAD]);
  HISTHEAD := _mod(HISTHEAD + 1, NHISTORY);
  if HISTCNT < NHISTORY then
    HISTCNT := HISTCNT + 1;
end;

proc up_history(line: cpnt);
{**************************}
var entry: integer;
begin
  if HISTCNT = 0 then
    exit;
  if histpos < HISTCNT then
    histpos := histpos + 1;
  entry := _mod(HISTHEAD - histpos + NHISTORY,
                NHISTORY);
{  writeln('Up history: histpos=', histpos,
          ' entry=', entry); }
  _strcpy(history[entry], line);
end;

proc down_history(line: cpnt);
{****************************}
var entry: integer;
begin
  if histpos > 0 then
    histpos := histpos - 1;

  if histpos = 0 then
    line[0] := ENDMARK
  else begin
    entry := _mod(HISTHEAD - histpos + NHISTORY,
                  NHISTORY);
    _strcpy(history[entry], line);
  end;
end;

proc readline(line: cpnt);
{************************}
const CLEFT       = chr($03);
      CRIGHT      = chr($16);
      CDOWN       = chr($18);
      INSCHR      = chr($15);
      DELCHR      = chr($19);
      RUBOUT      = chr($7f);
      SCRUP       = chr($08); {scroll}
      SCRDOWN     = chr($02);
      GRSIZE      = chr($0c);
      ESC         = chr($00);
      LINELENGTH  = 45;  { 47 - 2 for prompt }
var lch: char;
    pos, len, oldvflag: integer;
begin
  line[0] := ENDMARK;
  pos := 0;
  len := 0;

  oldvflag := VFLAG;
  if (VFLAG and AUTOPR) <> 0 then
    VFLAG := VFLAG - AUTOPR;   { clear bit 3 }

  write(NORVID,'P*',CLRLIN);

  repeat
    read(@KEY,lch); { raw read character }

    if (ord(lch)>=$20) and (ord(lch)<=$7e) then begin
      if len < LINELENGTH then begin
        _strinsc(lch,pos,line);
        len := len + 1;
        write(INSCHR,lch);
        pos := pos + 1;
      end;
    end else begin
      case lch of

        CLEFT:
          begin
            if pos > 0 then begin
              write(CLEFT);
              pos := pos - 1;
            end;
          end;

        CRIGHT:
          begin
            if pos < len then begin
              write(CRIGHT);
              pos := pos + 1;
            end;
          end;

        RUBOUT:
          begin
            if pos > 0 then begin
              pos := pos - 1;
              _strdelc(pos,line);
              len := len - 1;
              write(CLEFT,DELCHR);
            end;
          end;

        ESC:
          begin
            while pos > 0 do begin
              write(CLEFT);
              pos := pos - 1;
              end;
            line[0] := ENDMARK;
            pos := 0;
            len := 0;
            write(CLRLIN);
          end;

        CUP:
          begin
            up_history(line);
            while pos > 0 do begin
              write(CLEFT);
              pos := pos - 1;
              end;
            write(CLRLIN, line);
            len := _strlen(line);
            pos := len;
          end;

        CDOWN:
          begin
            down_history(line);
            while pos > 0 do begin
              write(CLEFT);
              pos := pos - 1;
              end;
            write(CLRLIN, line);
            len := _strlen(line);
            pos := len;
          end;

        CR:
          begin
          if line[0] <> ENDMARK then
            add_history(line);
          end;

        SCRUP, SCRDOWN, GRSIZE:
          write(lch) { pass through }

        else
          begin
            { ignore all other control characters }
          end

      end {case};
    end;
  until lch=CR;

  write(CLRSCR);

  if (oldvflag and AUTOPR) <> 0 then
    write(@PRINTER, 'P*', line);
  VFLAG := oldvflag;

  writeln;
end;

proc getnum(var num: integer);
{****************************}
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

proc getfname
  (var name: array[15] of char;
   ptype: char; var isok: boolean;
   var drv: integer; var cyc: integer);
{*************************************}
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

proc clearinput;
{**************}
begin
  BUFFPN:=-1;
end;

proc checkrunerr;
{***************}
begin
  write(INVVID);
  case RUNERR of
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
    $26: writeln('Disk full, not stored');
    $65: writeln('Argument is not string or default');
    $66: writeln('Argument is not number or default');
    $67: writeln('Argument is not starting with /');
    $68: writeln('Drive is not 0 or 1');
    $69: writeln('Argument syntax error');
    $6a: writeln('Too many arguments');
    $81: writeln('Division by zero');
    $82: writeln('Stack overflow');
    $83: writeln('Index out of bounds');
    $84: writeln('Program not found');
    $85: writeln('P-code not implemented');
    $88: writeln('Heap overflow');
    $89: writeln('Pointer not allocated (NIL)');
    $90: writeln('Writing to constant string');
    $91: writeln('String too long');
    $92: writeln('String cannot be released')
  end {case}
  write(NORVID);
  ENDSTK:=TOPMEM-144;
  IOCHECK:=true;
  RUNERR:=0;
end;

begin {main}
{**********}
  checkrunerr;
  gline := _new;
  init_persistent;

  MAXSEQ := MMAXSEQ - 1;
  for k:=0 to MMAXSEQ-1 do FIDRTB[k]:=0;
  clearinput;
  ok:=true;
  res :=_emulator(12); { force end raw mode }

  spos := 0;
  readline(gline);
  next;

  while ch=CR do begin
    spos := 0;
    readline(gline);
    next;
  end;
  while (ch=' ') do next;

  drive1:=1;
  cyclus1:=0;
  getfname(runname,'R',ok,drive1,cyclus1);

  { erase all arguments }
  for k:=0 to 31 do ARGTYPE[k]:=chr(0);
  NUMARG:=0;

  if ok then begin
    n:=0;
    argerr:=0;
    if ch=' ' then begin  {arguments}
      repeat
        next;
        if ch=' ' then
          argerr:=106

        { quoted argument }
        else if ch='"' then begin
          ARGTYPE[n]:='q';
          if n>23 then argerr:=107
          else begin
            for k:=0 to 15 do aname[k]:=' ';
            k:=0;
            next;
            while (ch<>'"') and (ch<>CR) do begin
              if k<=15 then begin
                aname[k]:=ch;
                k:=succ(k);
              end else
                argerr:=106;
              next;
            end;
            if ch<>'"' then
              argerr:=106
            else
              next;
            for k:=0 to 7 do
              ARGLIST[n+k]:=
                  ord(packed(aname[2*k+1],
                  aname[2*k]));
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
            for k:=0 to 7 do
              ARGLIST[n+k]:=
                    ord(packed(aname[2*k+1],
                    aname[2*k]));
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
    res := _emulator(12); { force end raw mode }
  end else begin
    clearinput;
    ENDSTK:=TOPMEM-144;
    chainprog(runname, cyclus1, drive1);
  end;
end.
