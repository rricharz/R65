{
*************************************
*                                   *
* Copy(filename,source,destination) *
*                                   *
*************************************

            2019 rricharz
}

program copy;
uses syslib,arglib;

const maxlines = 13;

      rdfile=$e815;
      wrfile=$eb2c; {keep date}

      sblock=$5000;
      eblock=topmem;

mem   endstk=$e: integer;
      filflg=$da: char&;
      filerr=$db: char&;
      filsa=$031a,
      filea=$031c,
      filsa1=$0331: integer;
      filtyp=$0300: char&;


var name: array[15] of char;
    fno,ofno: file;
    cyclus,drive,ddrive: integer;
    default: boolean;
    ch,k: char;

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
      writeln('*** Cannot copy ',
        'machine language programs');
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
  filerr:=chr(0);
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
  filerr:=chr(0);
  call(wrfile);
end {blocksave};

{ * error * }

proc error(x:integer);

mem runerr=$0c: integer&;

begin
  writeln;
  writeln('*** File error ',
    (x shr 4),(x and 15));
end {error};

{ * main * }

begin
  cyclus:=0; drive:=0;
  agetstring(name,default,cyclus,drive);
  if (drive<0) or (drive>1) then
    begin
      writeln('Illegal source drive');
      abort;
    end;

  agetval(ddrive,default); {destination drive}
  if default then
    begin
      writeln('Destination drive undefined');
      writeln('Usage: copy name',
        '[,source_drive] dest_drive');
    end;
  if (ddrive<0) or (ddrive>1) then
    begin
      writeln('Illegal destination drive');
      abort;
    end;
  if drive=ddrive then
    begin
      writeln('Source and destination',
       ' drives must be different');
      abort;
    end;

  if isblockf(name) then
    begin
      endstk:=sblock-144; {reserve memory}
      blockload(sblock);
      writeln;
      if ord(filerr)<>0 then
        begin
          error(ord(filerr));
          endstk:=topmem-144; {release memory}
          abort;
        end;
      if filea>=topmem then
        begin
          writeln('*** Error: File too large');
          endstk:=topmem-144; {release memory}
          abort;
        end;
      cyclus:=filcyc;
      fildrv:=ddrive;
      blocksave(sblock,filea);
      if ord(filerr)<>0 then
          error(ord(filerr));
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
    end;
end.

