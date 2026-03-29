program extract;
uses syslib, arglib, strlib;

{$R+}
{$U+}

const TOK_OTHER = 0;
      TOK_CONST = 1;
      TOK_MEM   = 2;
      TOK_VAR   = 3;
      TOK_PROC  = 4;
      TOK_FUNC  = 5;
      TOK_BEGIN = 6;
      TOK_CASE  = 7;
      TOK_END   = 8;

      SSTART = 0;
      SCONST = 1;
      SMEM   = 2;
      SVAR   = 3;
      SROUT  = 4;
      SSKIP  = 5;
      SBODY  = 6;
      SDONE  = 7;
      SHEAD  = 8;

      DEBUG1 = false;

      INDENT = '      ';

var
  f_in, f_out: file;
  line:       cpnt;
  name:       array[15] of char;
  lineno:     integer;
  ateof:      boolean;
  llen:       integer;

  state:      integer;
  tok  :      integer;
  seenbegin:  boolean;
  blocklevel: integer;
  routlevel:  integer;
  ininner  :  boolean;
  pass:       integer; { 1 > :H file, 2 > :N file }
  routheader: boolean;
  parlevel:   integer;

proc updpar(s:cpnt);
{******************}
var i: integer;
begin
  i:=0;
  while s[i]<>ENDMARK do
  begin
    if s[i]='(' then begin
      parlevel:=parlevel+1;
    end;
    if s[i]=')' then begin
      parlevel:=parlevel-1;
    end;
    i:=i+1;
  end;
end;

func hassemi(s:cpnt): boolean;
{************************}
var i: integer;
begin
  i:=0;
  while s[i]<>ENDMARK do
  begin
    if s[i]=';' then
    begin
      hassemi:=true;
      if DEBUG1 then
        writeln('hassemi = true');
      exit;
    end;
    i:=i+1;
  end;
  hassemi:=false;
  if DEBUG1 then
    writeln('hassemi = false');
end;

proc rtrim(s:cpnt);
{*****************}
var i: integer;
begin
  i := _strlen(s);
  while i > 0 do
  begin
    if s[i-1] <> ' ' then
    begin
      s[i] := ENDMARK;
      exit;
    end;
    i := i - 1;
  end;
  s[0] := ENDMARK;
end;

proc outln(s:cpnt);
{****************}
var i: integer;
    ch: char;
begin
  if pass <> 1 then
    exit;
  { skip leading blanks }
  i := 0;
  while s[i] = ' ' do
    i := i + 1;
  ch := s[i];
  { skip empty lines }
  if ch = ENDMARK then
    exit;
  { skip comment-only lines }
  if ch = '{' then
    exit;
  { output original line (not shifted!) }
  writeln(@f_out, s);
end;

proc outtxt(t:cpnt);
{******************}
begin
  if pass=1 then
    writeln(@f_out,t);
end;

proc isalnum(ch:char; var yes:boolean);
{*************************************}
begin
  yes := (((ch>='A') and (ch<='Z')) or
          ((ch>='a') and (ch<='z')) or
          ((ch>='0') and (ch<='9')));
end;

proc matchtok(t:cpnt; s:cpnt; var yes:boolean);
{*********************************************}
var i,j,lt,ls: integer;
    ok: boolean;
begin
  yes := false;
  lt := _strlen(t);
  ls := _strlen(s);

  i := 0;
  while (i<ls) and (s[i]=' ') do
    i := i + 1;

  if i+lt > ls then
    exit;

  j := 0;
  while j<lt do
  begin
    if t[j] <> s[i+j] then
      exit;
    j := j + 1;
  end;

  if i+lt < ls then
  begin
    isalnum(s[i+lt], ok);
    if ok then
      exit;
  end;

  yes := true;
end;

proc gettok(var tok0:integer);
{****************************}
var yes: boolean;
begin
  tok0 := TOK_OTHER;

  matchtok('const', line, yes);
  if yes then
  begin
    tok0 := TOK_CONST;
    exit;
  end;

  matchtok('mem', line, yes);
  if yes then
  begin
    tok0 := TOK_MEM;
    exit;
  end;

  matchtok('var', line, yes);
  if yes then
  begin
    tok0 := TOK_VAR;
    exit;
  end;

  matchtok('proc', line, yes);
  if yes then
  begin
    tok0 := TOK_PROC;
    exit;
  end;

  matchtok('func', line, yes);
  if yes then
  begin
    tok0 := TOK_FUNC;
    exit;
  end;

  matchtok('begin', line, yes);
  if yes then
  begin
    tok0 := TOK_BEGIN;
    exit;
  end;

  matchtok('case', line, yes);
  if yes then
  begin
    tok0 := TOK_CASE;
    exit;
  end;

  matchtok('end', line, yes);
  if yes then
  begin
    tok0 := TOK_END;
    exit;
  end;
end;

proc printtok(tok0:integer);
{**************************}
begin
  case tok0 of
    TOK_CONST: write('CONST');
    TOK_MEM  : write('MEM');
    TOK_VAR  : write('VAR');
    TOK_PROC : write('PROC');
    TOK_FUNC : write('FUNC');
    TOK_BEGIN: write('BEGIN');
    TOK_CASE : write('CASE');
    TOK_END  : write('END')
  else
    write('OTHER')
  end;
end;

proc printstate(st:integer);
{**************************}
begin
  case st of
    SSTART: write('SSTART');
    SCONST: write('SCONST');
    SMEM  : write('SMEM');
    SVAR  : write('SVAR');
    SROUT : write('SROUT');
    SSKIP : write('SSKIP');
    SBODY : write('SBODY');
    SDONE : write('SDONE');
    SHEAD : write('SHEAD')
  else
    write('???')
  end;
end;

proc print_remainder(line0:cpnt; kwlen:integer);
{**********************************************}
var i:integer;
begin
  i := 0;

  { skip leading spaces }
  while line0[i] = ' ' do
    i := i + 1;

  { skip keyword }
  i := i + kwlen;

  { skip spaces after keyword }
  while line0[i] = ' ' do
    i := i + 1;

  { anything left? write it }
  if line[i] <> ENDMARK then
  begin
    write(@f_out, INDENT);   { indentation }
    while line[i] <> ENDMARK do
    begin
      write(@f_out, line[i]);
      i := i + 1;
    end;
    writeln(@f_out);
  end;
end;

proc doSSTART;
{************}
var i:      integer;
    next:   char;
    strout: cpnt;
begin
  i := 0;
  strout := _new;

  repeat
    strout[i] := _uppercase(line[i]);
    i := i + 1;

    if i >= STRSIZE-1 then
    begin
      strout[i] := ENDMARK;
      outln(strout);
      _release(strout);
      exit;
    end;

    next := line[i];
  until (next=';') or (next=ENDMARK);

  strout[i] := ENDMARK;
  outln(strout);
  _release(strout);
end;

proc doCONST;
{************}
begin
  writeln(@f_out);
  outtxt('CONST');
  print_remainder(line, 5);
end;

proc doMEM;
{**********}
begin
  writeln(@f_out);
  outtxt('MEM');
  print_remainder(line, 3);
end;

proc doVAR;
{**********}
begin
  writeln(@f_out);
  outtxt('VAR');
  print_remainder(line, 3);
end;

proc processline;
{***************}
begin
  if DEBUG1 then begin
    write('line ');
    write(lineno);
    write(': state=');
    printstate(state);
    write(' tok=');
    printtok(tok);
    write(' text="');
    write(line);
    writeln('"');
    writeln;
  end;

  case state of

    SSTART:
      begin
        if tok = TOK_CONST then begin
          doCONST;
          state := SCONST;
        end else
          doSSTART;
      end;

    SCONST:
      begin
        if tok = TOK_MEM then begin
         doMEM;
         state := SMEM;
        end
        else
          outln(line);
      end;

    SMEM:
      begin
        if tok = TOK_VAR then begin
        doVAR;
        state := SVAR;
        end
        else
        outln(line);
      end;

    SVAR:
      begin
        if tok = TOK_OTHER then
          outln(line);
        if (tok = TOK_PROC) or (tok = TOK_FUNC) then
        begin
          if not routheader then
            begin
              writeln(@f_out);
              outtxt('ROUTINES');
              routheader := true;
            end;

          outln(line);

          parlevel := 0;
          updpar(line);

          if (parlevel = 0) and hassemi(line) then
          begin
            state := SSKIP;
            seenbegin := false;
            blocklevel := 0;
            routlevel := 0;
            ininner := false;
          end
         else
            state := SHEAD;
        end
        else if tok = TOK_BEGIN then
        begin
          state := SBODY;
          blocklevel := 1;
        end;
      end;

     SHEAD:
       begin
         outln(line);
         updpar(line);

         if (parlevel = 0) and hassemi(line) then
         begin
           state := SSKIP;
           seenbegin := false;
           blocklevel := 0;
           routlevel := 0;
           ininner := false;
         end;
       end;

    SROUT:
      begin
        if (tok = TOK_PROC) or (tok = TOK_FUNC) then
        begin
          if not routheader then
            begin
              outtxt('ROUTINES');
              routheader := true;
            end;

          outln(line);
          parlevel := 0;
          updpar(line);


          if (parlevel = 0) and hassemi(line) then
          begin
            state := SSKIP;
            seenbegin := false;
            blocklevel := 0;
            routlevel := 0;
            ininner := false;
          end
          else
            state := SHEAD;
        end
        else if tok = TOK_BEGIN then begin
          state := SBODY;
          blocklevel := 1;
        end;
      end;

    SSKIP:
      begin

        if not seenbegin then
        begin
          if ininner then
          begin
            if (tok=TOK_BEGIN) or (tok=TOK_CASE) then
            begin
              blocklevel := blocklevel + 1;
            end;

            if tok = TOK_END then
            begin
              blocklevel := blocklevel - 1;

              if blocklevel = 0 then
              begin
                ininner := false;
                routlevel := routlevel - 1;
              end;
            end;
          end

          else
          begin
            if (tok=TOK_PROC) or (tok=TOK_FUNC) then
            begin
              routlevel := routlevel + 1;
            end

            else if tok = TOK_BEGIN then
            begin
              if routlevel > 0 then
              begin
                ininner := true;
                blocklevel := 1;
              end
              else
              begin
               seenbegin := true;
                blocklevel := 1;
              end;
            end;
          end;
        end

        else
        begin
          if (tok=TOK_BEGIN) or (tok=TOK_CASE) then
          begin
            blocklevel := blocklevel + 1;
          end;

          if tok = TOK_END then
          begin
            blocklevel := blocklevel - 1;
          end;

          if blocklevel = 0 then
          begin
             state := SROUT;
          end;
        end;
      end;

    SBODY:
      begin
        if (tok = TOK_BEGIN) or (tok = TOK_CASE) then
          blocklevel := blocklevel + 1;

        if tok = TOK_END then
          blocklevel := blocklevel - 1;

        { write('  main blocklevel='); }
        { writeln(blocklevel);         }

        if blocklevel = 0 then
          state := SDONE;
      end

  end {case};
  if DEBUG1 then begin
    write('     newstate=');
    printstate(state);
    writeln;
  end
end;

proc setsubtype(subtype:char);
{****************************}
{ set subtype in name }
var i:integer;
begin
  i := 0;
  repeat
    i:=i + 1;
  until (name[i]=':') or
    (name[i] = ' ') or (i >= 14);
  name[i] := ':';
  name[i+1]:=subtype;
end;

proc writehex(f:file; a:integer);
{*******************************}
var h:integer;
  func hexdigit(c:char):char;
  var d:integer;
  begin
    d:=ord(c) and 15;
    if d>9 then hexdigit:=chr(d-10+ord('A'))
    else hexdigit:=chr(d+ord('0'));
  end;
begin
  h:=a and 255;
  write(@f,hexdigit(chr(h shr 4)));
  write(@f,hexdigit(chr(h and 15)));
end;

proc open_files(outsubtype: char);
{********************************}
var default: boolean;
    i, cyclus, drive, vcyclus: integer;

begin
  drive   := 1;
  cyclus  := 0;
  default := true;

  { print version number of current EXTRACT }

  vcyclus := FILCYC;

  { open input file, must be :P }
  _agetstring(name, default, cyclus, drive);
  setsubtype('P');
  _asetfile(name, cyclus, drive, ' ');
  openr(f_in);
  writeln; { required if openr is not silent }

  { open output file }
  cyclus := 0;
  setsubtype(outsubtype);
  _asetfile(name, cyclus, drive, ' ');
  openw(f_out);

  if DEBUG1 then begin
    write(@f_out, 'program EXTRACT version ');
    writehex(f_out,vcyclus);
    writeln(@f_out);
  end;

end;

proc close_files;
{***************}
begin
  close(f_in);
  close(f_out);
end;

{ main program }
{**************}
begin
  write(PRTON);

  open_files('H');

  line := _new;
  lineno := 0;
  state := SSTART;
  seenbegin := false;
  blocklevel := 0;
  pass := 1;
  routheader := false;

  repeat
    llen := _strread(f_in, line, ateof);
    rtrim(line);
    lineno := lineno + 1;

    if llen > 0 then
    begin
      write('.');

      gettok(tok);
      processline;
    end;

  until ateof;

  close_files;
  _release(line);
  writeln;
  write(PRTOFF);
end.


