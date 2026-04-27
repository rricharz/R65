{ *************************************** }
{ *                                     * }
{ * COPY filename, source, destination) * }
{ *                                     * }
{ *************************************** }

{  2019 rricharz                        }
{  2023 RR: Added wildcard handling     }
{  2024-2026 RR: small improvements     }

{  COPY fixes the following problems silently:    }
{  Old style EOF ($1F) is replaced with new ($7F) }
{  $00 is removed                                 }

{$U+}

program copy;
uses syslib, arglib, wildlib, filelib;

const MAXLINES = 13;
      rdfile=$e815;
      wrfile=$eb2c; {keep date}
      sblock=$6000;
      eblock=TOPMEM;

mem   filerr=$db: integer&;
      filsa=$031a,
      filea=$031c,
      filsa1=$0331: integer;
      filtyp=$0300: char&;

var name,savename: array[15] of char;
    ii,fcount:integer;
    fno,ofno: file;
    cyclus,scyclus,drive,ddrive: integer;
    default: boolean;
    ch,k: char;
    entry: integer;
    last, found: boolean;

{ **** isblockf **** }

func isblockf(nm: array[15] of char): boolean;
var j: integer;
begin
  j:=0;
  while (nm[j]<>':') and (j<14) do j:=j+1;
  if nm[j]=':' then
    begin
      if nm[j+1]='R' then isblockf:=true
      else isblockf:=false
    end
  else
    begin
      writeln(INVVID,'Cannot copy',NORVID);
      _abort;
    end;
end;

{ **** blockload ***** }

proc blockload(lowlim: integer);
var i: integer;
begin
  _asetfile(name,cyclus,drive,' ');
  FILFLG:=$40;
  filsa:=lowlim;
  filsa1:=lowlim;
  filtyp:='B';
  filerr:=0;
  FILFLG := $40;
  call(rdfile);
end {blockload};

{ **** blocksave ***** }

proc blocksave(lowlim,highlim: integer);
var i: integer;
begin
  _asetfile(name,cyclus,ddrive,' ');
  FILFLG:=$40;
  filsa:=lowlim;
  filea:=highlim;
  filsa1:=lowlim;
  filtyp:='B';
  filerr:=0;
  call(wrfile);
end {blocksave};

{ ***** error ***** }

proc error(x:integer);
begin
  writeln;
  writeln(INVVID,'COPY: file error ',
    (x shr 4),(x and 15),NORVID);
end {error};

{ **** copyfile ***** }

proc copyfile;
begin
  if isblockf(name) then
    begin
      ENDSTK:=sblock-144; {reserve memory}
      blockload(sblock);
      _write_label;
      write('=');
      if ord(filerr)<>0 then
        begin
          error(filerr);
          ENDSTK:=TOPMEM-144; {_release memory}
          _abort;
        end;
      if filea>=TOPMEM then
        begin
          writeln('Error: File too large');
          ENDSTK:=TOPMEM-144; {_release memory}
          _abort;
        end;
      cyclus:=FILCYC;
      FILDRV:=ddrive;
      blocksave(sblock,filea);
      if ord(filerr)<>0 then
          error(filerr);
      ENDSTK:=TOPMEM-144; {_release memory}
      writeln;
    end

  else
    begin
      _asetfile(name,cyclus,drive,' ');
      openr(fno);
      _write_label;
      writeln('=');
      FILCY1:=FILCYC;
      FILDRV:=ddrive;
      openw(ofno);
      { write('.'); }
      repeat
        read(@fno,ch);
{chr(31) for compatibility with old files; and fix it}
        if (ch<>chr(31)) and (ch<>chr(0)) then
          write(@ofno,ch);
        until (ch=EOF) or (ch=chr(31));
      write(@ofno,EOF);
      close(ofno);
      close(fno);
    end;
end;

func haswildcard(nm1:array[15] of char): boolean;
var kk:integer;
begin
  haswildcard:=false;
  for kk:=0 to 15 do
    if (nm1[kk]='*') or (nm1[kk]='?') then
      haswildcard:=true;
end;

{ **** main **** }

begin
  cyclus:=0;
  _agetstring(name,default,cyclus,drive);
  scyclus:=cyclus;
  if (drive<0) or (drive>1) then
    begin
      writeln(INVVID,
        'Specify source drive (0 or 1)',NORVID);
      _abort;
    end;

  _agetval(ddrive,default); {destination drive}
  if default then
    begin
      writeln(INVVID,
        'Specify destination drive (0 or 1)');
      writeln('Usage: copy name',
        '[,source_drive] dest_drive',NORVID);
      _abort;
    end;
  if (ddrive<0) or (ddrive>1) then
    begin
      writeln(INVVID,
        'Destination drive must be 0 or 1',NORVID);
      _abort;
    end;
  if drive=ddrive then
    begin
      writeln(INVVID,'Source and destination',
       ' drives must be different',NORVID);
      _abort;
    end;

  if haswildcard(name) then begin
    fcount:=0; last:=false; entry:= 0;
    while (entry<NUMENTRIES) and not last do begin
      cyclus:=scyclus;
      _findentry(name,drive,entry,found,last);
      if found and (not last) and
        ((scyclus=0) or (scyclus=FILCYC)) then begin
        for ii:=0 to 15 do begin
          savename[ii]:=name[ii];
          name[ii]:=FILNAM[ii];
        end;
        cyclus:=FILCYC;
        copyfile;
        fcount:=fcount+1;
        for ii:=0 to 15 do
          name[ii]:=savename[ii];
      end;
    end;
      if fcount=0 then writeln('No files copied')
      else writeln(fcount, ' files copied');
  end else
    copyfile;
end.

