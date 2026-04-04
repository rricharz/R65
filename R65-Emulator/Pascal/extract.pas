program extract;
uses syslib, arglib, filelib, strlib;

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

      SSTART   = 0;
      SCONST   = 1;
      SMEM     = 2;
      SVAR     = 3;
      SROUT    = 4;
      SSKIP    = 5;
      SBODY    = 6;
      SDONE    = 7;
      SHEAD    = 8;

      DEBUG1   = false;
      DEBUG2   = true;
      INDENT   = '      ';
      IPINDENT = ' 10';

      QUOTE    = chr($27);

var
  f_in, f_out: file;
  line, libname, cname,
    cval, cval2, cval3, addrpad, body: cpnt;
  name: array[15] of char;
  lineno, llen: integer;
  ateof: boolean;
  state, tok, pass: integer;
  seenbegin, ininner: boolean;
  routheader: boolean;
  blocklevel, routlevel: integer;
  parlevel: integer;

proc splitstr(src: cpnt; sep: char; dstl,dstr: cpnt);
{***************************************************}
var i,j: integer;
begin
  dstl[0] := ENDMARK;
  dstr[0] := ENDMARK;

  i := _strpos(sep,src,0);
  if i < 0 then begin
    _strcpy(src, dstl);
    exit;
  end;

  j := 0;
  while j < i do begin
    dstl[j] := src[j];
    j := j+1;
  end;
  dstl[j] := ENDMARK;

  i := i+1;
  while src[i] = ' ' do
    i := i+1;

  j := 0;
  while src[i] <> ENDMARK do begin
    dstr[j] := src[i];
    j := j+1;
    i := i+1;
  end;
  dstr[j] := ENDMARK;
end;

proc padright(src,dst: cpnt; w: integer);
{***************************************}
var i: integer;
begin
  dst[0] := ENDMARK;
  write(@dst, src);
  i := _strlen(src);
  while i < w do begin
    write(@dst, ' ');
    i := i+1;
  end;
end;

proc buildbody(addr,typ,dst: cpnt);
{********************************}
begin
  dst[0] := ENDMARK;
  write(@dst, addr, '  ',typ);
end;



proc updpar(s:cpnt);
{******************}
var i: integer;
begin
  i:=0;
  while s[i]<>ENDMARK do
  begin
    if s[i]='(' then
      parlevel:=parlevel+1;
    if s[i]=')' then
      parlevel:=parlevel-1;
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
      exit;
    end;
    i:=i+1;
  end;
  hassemi:=false;
end;

proc rtrim(s:cpnt);
{*****************}
var i: integer;
begin
  i:=_strlen(s);
  while i>0 do
  begin
    if s[i-1]<>' ' then
    begin
      s[i]:=ENDMARK;
      exit;
    end;
    i:=i-1;
  end;
  s[0]:=ENDMARK;
end;

proc isalnum(ch:char; var yes:boolean);
{*************************************}
begin
  yes:=(((ch>='A') and (ch<='Z')) or
        ((ch>='a') and (ch<='z')) or
        ((ch>='0') and (ch<='9')));
end;

proc matchtok(t:cpnt; s:cpnt; var yes:boolean);
{*********************************************}
var i,j,lt,ls: integer;
    ok: boolean;
begin
  yes:=false;
  lt:=_strlen(t);
  ls:=_strlen(s);

  i:=0;
  while (i<ls) and (s[i]=' ') do
    i:=i+1;

  if i+lt>ls then
    exit;

  j:=0;
  while j<lt do
  begin
    if t[j]<>s[i+j] then
      exit;
    j:=j+1;
  end;

  if i+lt<ls then
  begin
    isalnum(s[i+lt], ok);
    if ok then
      exit;
  end;

  yes:=true;
end;

proc gettok(var tok0:integer);
{****************************}
var yes: boolean;
begin
  tok0:=TOK_OTHER;

  matchtok('const', line, yes);
  if yes then
  begin
    tok0:=TOK_CONST;
    exit;
  end;

  matchtok('mem', line, yes);
  if yes then
  begin
    tok0:=TOK_MEM;
    exit;
  end;

  matchtok('var', line, yes);
  if yes then
  begin
    tok0:=TOK_VAR;
    exit;
  end;

  matchtok('proc', line, yes);
  if yes then
  begin
    tok0:=TOK_PROC;
    exit;
  end;

  matchtok('func', line, yes);
  if yes then
  begin
    tok0:=TOK_FUNC;
    exit;
  end;

  matchtok('begin', line, yes);
  if yes then
  begin
    tok0:=TOK_BEGIN;
    exit;
  end;

  matchtok('case', line, yes);
  if yes then
  begin
    tok0:=TOK_CASE;
    exit;
  end;

  matchtok('end', line, yes);
  if yes then
  begin
    tok0:=TOK_END;
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

proc writehex(f:file; a:integer);
{*******************************}
var h:integer;
  func hexdigit(c:char):char;
  var d:integer;
  begin
    d:=ord(c) and 15;
    if d>9 then
      hexdigit:=chr(d-10+ord('A'))
    else
      hexdigit:=chr(d+ord('0'));
  end;
begin
  h:=a and 255;
  write(@f,hexdigit(chr(h shr 4)));
  write(@f,hexdigit(chr(h and 15)));
end;

proc setsubtype(subtype:char);
{****************************}
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
        (name[i]=' ') or
        (i>=14);
  name[i]:=':';
  name[i+1]:=subtype;
end;

proc initname;
{*************}
var default: boolean;
    cyclus, drive: integer;
begin
  cyclus:=0;
  drive:=1;
  default:=true;
  _agetstring(name, default, cyclus, drive);
end;

proc open_files(outsubtype:char);
{******************************}
var cyclus, drive, vcyclus: integer;
begin
  drive:=1;
  cyclus:=0;
  vcyclus:=FILCYC;

  setsubtype('P');
  _asetfile(name, cyclus, drive, ' ');
  openr(f_in);
  writeln;

  cyclus:=0;
  setsubtype(outsubtype);
  _asetfile(name, cyclus, drive, ' ');
  openw(f_out);

  if DEBUG1 then
  begin
    write(@f_out,'program EXTRACT version ');
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

proc print_rem(kwlen:integer);
{************************}
var i:integer;
begin
  i:=0;
  while line[i]=' ' do
    i:=i+1;

  i:=i+kwlen;
  while line[i]=' ' do
    i:=i+1;

  if line[i]<>ENDMARK then
  begin
    write(@f_out,INDENT);
    while line[i]<>ENDMARK do
    begin
      write(@f_out,line[i]);
      i:=i+1;
    end;
    writeln(@f_out);
  end;
end;

proc getlibname;
{***************}
var i,j: integer;
begin
  i:=0;
  while line[i]=' ' do
    i:=i+1;

  i:=i+7;
  while line[i]=' ' do
    i:=i+1;

  j:=0;
  while (line[i]<>ENDMARK) and
        (line[i]<>';') and
        (line[i]<>' ') do
  begin
    libname[j]:=_uppercase(line[i]);
    i:=i+1;
    j:=j+1;
  end;
  libname[j]:=ENDMARK;
end;

proc stripcomment;
{****************}
var  i: integer;
begin
  i := _strpos('{',line,0);
  if i >= 0 then
    line[i] := ENDMARK;
end;

func isemptyline: boolean;
{************************}
var i: integer;
begin
  i := 0;
  while line[i] <> ENDMARK do begin
    if (line[i] <> ' ') and (line[i] <> TAB8) then
    begin
      isemptyline := false;
      exit;
    end;
    i := i + 1;
  end;
  isemptyline := true;
end;

proc dostart;
{*************}
var i: integer;
begin
  getlibname;
  if isemptyline then exit;

  if pass=1 then
  begin
    i:=0;
    while line[i]<>ENDMARK do
    begin
      if line[i]=';' then
      begin
        write(@f_out,';');
        writeln(@f_out);
        exit;
      end;
      write(@f_out,_uppercase(line[i]));
      i:=i+1;
    end;
    writeln(@f_out);
  end
  else
  begin
    writeln(@f_out,'.TH ',libname,' 1');
    writeln(@f_out);
    writeln(@f_out,'.SH NAME');
    writeln(@f_out,libname,' - library');
  end;
end;

proc doconst(entering:boolean);
{****************************}
begin
  stripcomment;
  if isemptyline then exit;
  if pass=1 then
  begin
    if entering then
    begin
      writeln(@f_out);
      writeln(@f_out, 'CONSTANTS');
      print_rem(5);
    end
    else
      writeln(@f_out, line);
  end
  else
  begin
    if entering then
    begin
      writeln(@f_out);
      writeln(@f_out,'.SH CONSTANTS');
      writeln(@f_out);
    end
    else
    begin
      splitstr(line,'=',cname,cval);
      writeln(@f_out,'.IP ',cname,IPINDENT);
      if cval[0] <> ENDMARK then
        writeln(@f_out,cval);
      writeln(@f_out);
    end
  end;
end;

proc domem(entering:boolean);
{**************************}
begin
  stripcomment;
  if isemptyline then exit;
  if pass=1 then
  begin
    if entering then
    begin
      writeln(@f_out);
      writeln(@f_out,'MEMORY');
      print_rem(5);
    end
    else
      writeln(@f_out,line);
  end
  else
  begin
    if entering then
    begin
      writeln(@f_out);
      writeln(@f_out,'.SH MEMORY');
      writeln(@f_out);
    end
    else
    begin
      splitstr(line,'=',cname,cval);
      splitstr(cval,':',cval2,cval3);
      padright(cval2,addrpad,8);
      buildbody(addrpad,cval3,body);
      writeln(@f_out,'.IP ',cname,' ',IPINDENT);
      writeln(@f_out,QUOTE,body,QUOTE);
    end;
  end;
end;

proc dovar(entering:boolean);
{**************************}
begin
  stripcomment;
  if isemptyline then exit;
  if pass=1 then
  begin
    if entering then
    begin
      writeln(@f_out);
      writeln(@f_out, 'VARIABLES');
      print_rem(3);
    end
    else
      writeln(@f_out, line);
  end
  else
  begin
    if entering then
    begin
      writeln(@f_out);
      writeln(@f_out,'.SH VARIABLES');
      writeln(@f_out);
    end
    else
      writeln(@f_out, line);
  end;
end;

proc dorout(entering:boolean);
{***************************}
begin
  if pass=1 then
  begin
    if entering and not routheader then
    begin
      writeln(@f_out);
      writeln(@f_out, 'ROUTINES');
      routheader:=true;
    end;
    writeln(@f_out, line);
  end
  else
  begin
    if entering and not routheader then
    begin
      writeln(@f_out);
      writeln(@f_out,'.SH ROUTINES');
      writeln(@f_out);
      routheader:=true;
    end;
    writeln(@f_out, line);
  end;
end;

proc debugline;
{**************}
begin
  if DEBUG1 then
  begin
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
end;

proc debugstate;
{***************}
begin
  if DEBUG1 then
  begin
    write('     newstate=');
    printstate(state);
    writeln;
  end;
end;

proc runpass(outsubtype:char);
{****************************}
var islib: boolean;
begin
  open_files(outsubtype);

  lineno:=0;
  state:=SSTART;
  seenbegin:=false;
  ininner:=false;
  blocklevel:=0;
  routlevel:=0;
  parlevel:=0;
  routheader:=false;

  repeat
    llen:=_strread(f_in, line, ateof);
    rtrim(line);
    lineno:=lineno+1;

    if llen>0 then
    begin
      write('.');
      gettok(tok);
      debugline;
      matchtok('library', line, islib);

      case state of

        SSTART:
          begin
            if islib then
              dostart
            else if tok=TOK_CONST then
            begin
              doconst(true);
              state:=SCONST;
            end
            else if tok=TOK_MEM then
            begin
              domem(true);
              state:=SMEM;
            end
            else if tok=TOK_VAR then
            begin
              dovar(true);
              state:=SVAR;
            end
            else if (tok=TOK_PROC) or
                    (tok=TOK_FUNC) then
            begin
              dorout(true);
              parlevel:=0;
              updpar(line);
              if (parlevel=0) and hassemi(line) then
              begin
                state:=SSKIP;
                seenbegin:=false;
                blocklevel:=0;
                routlevel:=0;
                ininner:=false;
              end
              else
                state:=SHEAD;
            end
            else if tok=TOK_BEGIN then
            begin
              state:=SBODY;
              blocklevel:=1;
            end;
          end;

        SCONST:
          begin
            if tok=TOK_MEM then
            begin
              domem(true);
              state:=SMEM;
            end
            else if tok=TOK_VAR then
            begin
              dovar(true);
              state:=SVAR;
            end
            else if (tok=TOK_PROC) or
                    (tok=TOK_FUNC) then
            begin
              dorout(true);
              parlevel:=0;
              updpar(line);
              if (parlevel=0) and hassemi(line) then
              begin
                state:=SSKIP;
                seenbegin:=false;
                blocklevel:=0;
                routlevel:=0;
                ininner:=false;
              end
              else
                state:=SHEAD;
            end
            else if tok=TOK_BEGIN then
            begin
              state:=SBODY;
              blocklevel:=1;
            end
            else
              doconst(false);
          end;

        SMEM:
          begin
            if tok=TOK_VAR then
            begin
              dovar(true);
              state:=SVAR;
            end
            else if (tok=TOK_PROC) or
                    (tok=TOK_FUNC) then
            begin
              dorout(true);
              parlevel:=0;
              updpar(line);
              if (parlevel=0) and hassemi(line) then
              begin
                state:=SSKIP;
                seenbegin:=false;
                blocklevel:=0;
                routlevel:=0;
                ininner:=false;
              end
              else
                state:=SHEAD;
            end
            else if tok=TOK_BEGIN then
            begin
              state:=SBODY;
              blocklevel:=1;
            end
            else
              domem(false);
          end;

        SVAR:
          begin
            if tok=TOK_OTHER then
              dovar(false)
            else if (tok=TOK_PROC) or
                    (tok=TOK_FUNC) then
            begin
              dorout(true);
              parlevel:=0;
              updpar(line);
              if (parlevel=0) and hassemi(line) then
              begin
                state:=SSKIP;
                seenbegin:=false;
                blocklevel:=0;
                routlevel:=0;
                ininner:=false;
              end
              else
                state:=SHEAD;
            end
            else if tok=TOK_BEGIN then
            begin
              state:=SBODY;
              blocklevel:=1;
            end;
          end;

        SROUT:
          begin
            if (tok=TOK_PROC) or
               (tok=TOK_FUNC) then
            begin
              dorout(true);
              parlevel:=0;
              updpar(line);
              if (parlevel=0) and hassemi(line) then
              begin
                state:=SSKIP;
                seenbegin:=false;
                blocklevel:=0;
                routlevel:=0;
                ininner:=false;
              end
              else
                state:=SHEAD;
            end
            else if tok=TOK_BEGIN then
            begin
              state:=SBODY;
              blocklevel:=1;
            end;
          end;

        SHEAD:
          begin
            dorout(false);
            updpar(line);
            if (parlevel=0) and hassemi(line) then
            begin
              state:=SSKIP;
              seenbegin:=false;
              blocklevel:=0;
              routlevel:=0;
              ininner:=false;
            end;
          end;

        SSKIP:
          begin
            if not seenbegin then
            begin
              if ininner then
              begin
                if (tok=TOK_BEGIN) or
                   (tok=TOK_CASE) then
                  blocklevel:=blocklevel+1;

                if tok=TOK_END then
                begin
                  blocklevel:=blocklevel-1;
                  if blocklevel=0 then
                  begin
                    ininner:=false;
                    routlevel:=routlevel-1;
                  end;
                end;
              end
              else
              begin
                if (tok=TOK_PROC) or
                   (tok=TOK_FUNC) then
                  routlevel:=routlevel+1
                else if tok=TOK_BEGIN then
                begin
                  if routlevel>0 then
                  begin
                    ininner:=true;
                    blocklevel:=1;
                  end
                  else
                  begin
                    seenbegin:=true;
                    blocklevel:=1;
                  end;
                end;
              end;
            end
            else
            begin
              if (tok=TOK_BEGIN) or
                 (tok=TOK_CASE) then
                blocklevel:=blocklevel+1;

              if tok=TOK_END then
                blocklevel:=blocklevel-1;

              if blocklevel=0 then
                state:=SROUT;
            end;
          end;

        SBODY:
          begin
            if (tok=TOK_BEGIN) or
               (tok=TOK_CASE) then
              blocklevel:=blocklevel+1;

            if tok=TOK_END then
              blocklevel:=blocklevel-1;

            if blocklevel=0 then
              state:=SDONE;
          end

      end;

      debugstate;
    end;

  until ateof or (state=SDONE);

  close_files;
end;

{ main program }
{**************}
begin
  write(PRTON);

  line    := _new;
  libname := _new;
  cname   := _new;
  cval    := _new;
  cval2   := _new;
  cval3   := _new;
  addrpad := _new;
  body    := _new;

  initname;

  pass:=1;
  runpass('H');

  pass:=2;
  runpass('N');

  _release(body);
  _release(addrpad);
  _release(cval3);
  _release(cval2);
  _release(cval);
  _release(cname);
  _release(libname);
  _release(line);

  writeln;
  write(PRTOFF);
end.
