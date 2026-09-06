program ft;
uses syslib,ralib,mathlib,ftlib,filelib,arglib;

const maxsize     = 1024;
      tabsize     = 2048; { 2 * maxsize }
      sintabsize  = 512; { maxsize div 2 }

var f: file;
    i: integer;
    v, fs: real;

    data:   array[tabsize] of real;
    sintab: array[sintabsize] of real;

proc getdata;
begin
  f:=_attach('FUNCDATA:X      ',0,1,
                            FWRITE+FSILENT,0,0,'X');
  _getdataheader(f);
  if _n > maxsize then begin
    _abortwith('Max data size exceeded');
  end;
  if not ((_n=128) or (_n=256) or
          (_n=512) or (_n=1024)) then begin
    _abortwith('Invalid FFT data size ');
  end;
  if _domain <> DOMAIN_TIME then
  _abortwith(
  'Domain of data must be TIME, use FUNCTION again');
  for i:=0 to _n - 1 do begin
    _getreal(f, REALBASE + i, v);
    data[i] := v;
  end;
  for i:=0 to _n - 1 do begin
    _getreal(f, COMPLEXBASE + i, v);
    data[_n + i] := v;
  end;
end;

proc putdata;
begin
  for i:=0 to _n-1 do
    _putreal(f,REALBASE+i,data[i]);

  for i:=0 to _n-1 do
    _putreal(f,COMPLEXBASE+i,data[_n+i]);

  _datatype := DATA_COMPLEX;
  _domain := DOMAIN_FREQ;

  { later set _min and _max to frequency limits }

  _putdataheader(f);
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
    bits := trunc(log(conv(_n))/log(2.0)+0.5);

    for i := 0 to _n - 1 do begin
      j := bitreverse(i, bits);

      if j > i then begin

        t := data[i];
        data[i] := data[j];
        data[j] := t;

        t := data[_n+i];
        data[_n+i] := data[_n+j];
        data[_n+j] := t;

      end;
    end;
  end;

  proc butterfly(i,j: integer;
                 cosine,sine: real);
  var ar,ai,br,bi,tr,ti: real;
  begin
    ar:=data[i];
    ai:=data[_n+i];
    br:=data[j];
    bi:=data[_n+j];

    tr:=br*cosine+bi*sine;
    ti:=bi*cosine-br*sine;

    data[i]:=ar+tr;
    data[_n+i]:=ai+ti;

    data[j]:=ar-tr;
    data[_n+j]:=ai-ti;
  end;

begin
  bitreverseperm;

  groupsize := 2;
  halfgroup := 1;
  tabstep := sintabsize;

  while groupsize <= _n do begin

    group := 0;
    while group < _n do begin

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

  { calculate minimum and maximum frequency }
  fs := conv(_n) / (_max - _min);
  _min := -fs / 2.0;
  _max := fs/2.0;
end;

begin
  getdata;
  makesintab;
  fft;
  putdata;
  ARGTYPE[0]  := 's';
  ARGTYPE[1]  := chr(0);
  ARGLISTS[0] := '/';
  ARGLISTS[1] := 'Q';
  _chainprog('GRAPH:R         ', 0, 1);
end.