program iotest;
{ Test for STRFIO }
uses syslib, strlib;

var s1: cpnt;
    fout: file;

{$I ISTRFIO:P }

begin
  writeln ('iotest');
  strfio('IOTEST:B',1);
  openw(fout);

  writeln(@fout, 'iotest');

  close(fout);
end.
