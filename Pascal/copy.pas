{
*************************************
*                                   *
* Copy(filename,source,destination) *
*                                   *
*************************************
 
  2019 rricharz
  2023 Added wildcard handling
 
}
 
program copy;
uses syslib,arglib,wildlib;
 
const maxlines = 13;
      rdfile=$e815;
      wrfile=$eb2c; {keep date}
      sblock=$5000;
      eblock=topmem;

 
mem   endstk=$e: integer;
      filflg=$da: char&;
      filerr=$db: integer&;
      filsa=$031a,
      filea=$031c,
      filsa1=$0331: integer;
      filtyp=$0300: char&;
 
var name,savename: array[15] of char;
    i,fcount:integer;
    fno,ofno: file;
    cyclus,scyclus,drive,ddrive: integer;
    default: boolean;
    ch,k: char;
    entry: integer;
    last, found: boolean;
{ * isblockf * }
 
func isblockf(nm: array[15] of char): boolean;
var j: integer;
begin
  j:=0;
  while (name[j]<>':') and (j<14) do j:=j+1;
  if name[j]=':' then
    begin
      if name[j+1]='R' then isblockf:=true
      else isblockf:=false
    end
  else
    begin
      writeln('Cannot copy this file type');
      abort;
    end;
end;
 
{ * blockload * }
 
proc blockload(lowlim: integer);
 
var i: integer;
 
begin
  asetfile(name,cyclus,drive,' ');
  filflg:=chr(0);
  filsa:=lowlim;
  filsa1:=lowlim;
  filtyp:='B';
  filerr:=0;
  call(rdfile);
end {blockload};
 
 
{ * blocksave * }
 
proc blocksave(lowlim,highlim: integer);
 
var i: integer;
 
begin
  asetfile(name,cyclus,ddrive,' ');
  filflg:=chr(0);
  filsa:=lowlim;
  filea:=highlim;
  filsa1:=lowlim;
  filtyp:='B';
  filerr:=0;
  call(wrfile);
end {blocksave};
 
{ * error * }
 
proc error(x:integer);
 
mem runerr=$0c: integer&;
 
begin
  writeln;
  writeln('File error ',
    (x shr 4),(x and 15));
end {error};
 
{ * copyfile * }
 
proc copyfile;
begin
  if isblockf(name) then
    begin
      endstk:=sblock-144; {reserve memory}
      blockload(sblock);
      writeln;
      if ord(filerr)<>0 then
        begin
          error(filerr);
          endstk:=topmem-144; {release memory}
          abort;
        end;
      if filea>=topmem then
        begin
          writeln('Error: File too large');
          endstk:=topmem-144; {release memory}
          abort;
        end;
      cyclus:=filcyc;
      fildrv:=ddrive;
      blocksave(sblock,filea);
      if ord(filerr)<>0 then
          error(filerr);
      endstk:=topmem-144; {release memory}
    end
 
  else
    begin
      asetfile(name,cyclus,drive,' ');
      openr(fno);
      filcy1:=filcyc;
      fildrv:=ddrive;
      writeln;
      openw(ofno);
      repeat
        read(@fno,ch);
        write(@ofno,ch);
        if ch=cr then write('.');
        until ch=eof;
      write(@ofno,eof);
      close(ofno);
      close(fno);
      writeln;
    end;
end;
 
func haswildcard(nm1:array[15] of char): boolean;
var k:integer;
begin
  haswildcard:=false;
  for k:=0 to 15 do
    if (nm1[k]='*') or (nm1[k]='?') then
      haswildcard:=true;
end;
{
 * main * }
 
begin
  cyclus:=0;
  agetstring(name,default,cyclus,drive);
  scyclus:=cyclus;
  if (drive<0) or (drive>1) then
    begin
      writeln('Specify source drive (0 or 1)');
      abort;
    end;
 
  agetval(ddrive,default); {destination drive}
  if default then
    begin
      writeln('Specify destination drive (0 or 1)');
      writeln('Usage: copy name',
        '[,source_drive] dest_drive');
    end;
  if (ddrive<0) or (ddrive>1) then
    begin
      writeln('Destination drive must be 0 or 1');
      abort;
    end;
  if drive=ddrive then
    begin
      writeln('Source and destination',
       ' drives must be different');
      abort;
    end;
 
  if haswildcard(name) then begin
    fcount:=0; last:=false; entry:= 0;
    while (entry<numentries) and not last do begin
      cyclus:=scyclus;
      findentry(name,drive,entry,found,last);
      if found and (not last) and
        ((scyclus=0) or (scyclus=filcyc)) then begin
        for i:=0 to 15 do begin
          savename[i]:=name[i];
          name[i]:=filnam[i];
        end;
        copyfile;
        fcount:=fcount+1;
        for i:=0 to 15 do
          name[i]:=savename[i];
      end;
    end;
      if fcount=0 then writeln('no files found')
      else writeln(fcount, ' files copied');
  end else
    copyfile;
end.
 