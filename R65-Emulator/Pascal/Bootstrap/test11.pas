{ test11.pas }
{ test sequential file write }

program test11;
uses syslib,arglib;

var f: file;
    ch: char;

begin {main}
  writeln('Calling asetfile');
  asetfile('testwrite       ',0,1,'B');
  writeln('Calling openw');
  openw(f);
  ch:='X';
  writeln('Writing to file');
  writeln(@f,'test11 ',99,'  ',ch);
  writeln('Closing file');
  close(f);
  writeln('done');
end.
