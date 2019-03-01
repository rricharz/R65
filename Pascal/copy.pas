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

var name: array[15] of char;
    fno,ofno: file;
    cyclus,drive,ddrive: integer;
    default: boolean;
    ch,k: char;

{ * main * }

begin
  agetstring(name,default,cyclus,drive);
  if (drive<0) or (drive>1) then begin
    writeln('Illegal source drive');
    abort;
    end;
  asetfile(name,cyclus,drive,' ');
  if drive>0 then ddrive:=0
  else ddrive:=1;
  writeln('Copy from drive ',drive,
    ' to drive ',ddrive);
  openr(fno);
  filcy1:=filcyc;
  fildrv:=ddrive;
  openw(ofno);
  repeat
    read(@fno,ch);
    write(@ofno,ch);
    if ch=cr then write('.');
    until ch=eof;
  write(@ofno,eof);
  close(ofno);
  close(fno);
end.

