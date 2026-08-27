program ft;
uses syslib,ralib,mathlib,writelib;

const maxsize     = 1024;
      tabsize     = 2048; { 2 * maxsize }
      sintabsize  = 512; { maxsize div 2 }

var f: file;
    i, size: integer;
    xmin, xmax, fmin, fmax, v: real;

    data:   array[tabsize] of real;
    sintab: array[sintabsize] of real;

proc getdata;
begin
  f:=_attach('TABLE:X         ',0,1,FREAD,0,0,'X');
  _getword(f,0,size);
  if size > maxsize then begin
    writeln(INVVID, 'Max data size of ', maxsize,
                    ' exceeded', NORVID);
    _abort;
  end;
  if not ((size=128) or (size=256) or
          (size=512) or (size=1024)) then begin
    writeln(INVVID,'Invalid FFT size ',size,NORVID);
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
  close(f);
end;

proc putdata;
begin
  f:=_attach('TABLE:X         ',0,1,FNEW,
                              8*size+12,0,'X');
  _putword(f,0,size);
  _putreal(f,1,fmin);
  _putreal(f,2,fmax);
  for i:= 0 to 2 * size - 1 do
    _putreal(f, i+3, data[i]);
  close(f);
end;

proc makesintab;
var j: integer;
    s: real;
begin
  for j:=0 to sintabsize div 2 do begin
    s:=sin(180.0*conv(j)/conv(sintabsize));
    sintab[j]:=s;
    sintab[sintabsize-j]:=s;
  end;
end;

proc fft;
var
  i, group, groupsize, halfgroup: integer;
  sinindex, tabstep: integer;
  sine, cosine: real;

  func bitreverse(i, bits: integer): integer;
  var j, k, n: integer;
  begin
    n := i;
    j := 0;
    for k := 1 to bits do begin
      j := j shl 1;
      if (n and 1) <> 0 then
        j := j + 1;
      n := n shr 1;
    end;
    bitreverse := j;
  end;

  proc bitreverseperm;
  var i,j,bits: integer;
      t: real;
  begin
    bits := trunc(log(conv(size))/log(2.0)+0.5);

    for i := 0 to size - 1 do begin
      j := bitreverse(i, bits);

      if j > i then begin

        t := data[i];
        data[i] := data[j];
        data[j] := t;

        t := data[size+i];
        data[size+i] := data[size+j];
        data[size+j] := t;

      end;
    end;
  end;

  proc butterfly(i,j: integer;
                 cosine,sine: real);
  var ar,ai,br,bi,tr,ti: real;
  begin
    ar:=data[i];
    ai:=data[size+i];
    br:=data[j];
    bi:=data[size+j];

    tr:=br*cosine+bi*sine;
    ti:=bi*cosine-br*sine;

    data[i]:=ar+tr;
    data[size+i]:=ai+ti;

    data[j]:=ar-tr;
    data[size+j]:=ai-ti;
  end;

begin
  bitreverseperm;

  groupsize := 2;
  halfgroup := 1;
  tabstep := sintabsize;

  while groupsize <= size do begin

    group := 0;
    while group < size do begin

      sinindex := 0;

      for i := 0 to halfgroup-1 do begin

        sine := sintab[sinindex];

        if sinindex <= 256 then
          cosine := sintab[256-sinindex]
        else
          cosine := -sintab[sinindex-256];

        butterfly(group+i,
                  group+i+halfgroup,
                  cosine,sine);

        sinindex := sinindex+tabstep;
      end;

      group := group+groupsize;
    end;

    groupsize := groupsize shl 1;
    halfgroup := halfgroup shl 1;
    tabstep := tabstep shr 1;
  end;

  fmin := 0.0;  { minimum and maximum frequency }
  fmax := conv(size) / (2.0 * (xmax - xmin));
end;

begin
  getdata;
  makesintab;
  fft;
  putdata;
end. 