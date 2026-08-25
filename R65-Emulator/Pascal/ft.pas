program ft;
uses syslib,ralib,mathlib,writelib;

const maxsize = 1024;
      tabsize = 2048; { 2 * maxsize }

var f: file;
    i, size: integer;
    xmin, xmax, fmin, fmax, v: real;
    data: array[tabsize] of real;

proc getdata;
begin
  f:=_attach('TABLE:X         ',0,1,FREAD,0,0,'X');
  _getword(f,0,size);
  if size > maxsize then begin
    writeln(INVVID, 'Max data size of ', maxsize,
                    ' exceeded', NORVID);
    _abort;
  end;
  writeln;
  writeln('Elements: ', size);
  _getreal(f,1,xmin);
  _getreal(f,2,xmax);
  writeln('Xmin:   ',xmin);
  writeln('Xmax:   ',xmax);
  for i:=0 to size - 1 do begin
    _getreal(f, i + 3, v);
    data[i] := v;
    data[size + i] := 0.0; { set imaginary data to 0 }
  end;
end;

proc putdata;
begin
  f:=_attach('TABLE:X         ',0,1,FWRITE,0,0,'X');
  _putword(f,0,size);
  _putreal(f,1,xmin);
  _putreal(f,2,xmax);
  for i:= 0 to 2 * xsize - 1 do
    _putreal(f, i+3, data[i]);
end;

proc ft;
begin
  fmin := 0.0;  { minimum and maximum frequency }
  fmax := conv(xsize);
  {just for testing, make a pulse }
  for i:= 128 to xsize - 1 do
    data[i] := 0.0;
end;

begin
  getdata;
  ft;
  putdata;
end. 