{***************************************
 * diff - difference between text file *
 ***************************************

Usage:
  diff filespec version
  diff filespec filespec

  filespec:
    name:subtype.version,srive

    default for subtype:      :P
    default for version:      highest
    default for drive:        1         }

program diff;
uses syslib, arglib, strlib, striolib, writelib;

var file1, file2:     file;
    line1, line2:     integer;
    eof1, eof2:       boolean;

proc init_files;
{**************}
mem FILCYC = $0311: integer&;
var name1, name2:     cpnt;
    cyclus1, drive1:  integer;
    cyclus2, drive2:  integer;

    default:          boolean;
begin
  name1 := _new;
  name2 := _new;
  cyclus1 := 0;
  drive1 := 1;
  line1 := 1;
  line2 := 1;
  default := true;

  { get first filespec }
  _sgetstring(name1, _carg, default);
  if default then begin
    write(INVVID);
    writeln(,'Usage: DIFF filespec [version]');
    writeln('   or   DIFF filespec filespec');
    write(NORVID);
    _abort;
  end;
  _agetval(cyclus1,    default);
  _agetval(drive1,     default);

  _ssetsubtype(name1,'P', false);
  _strfio(name1, cyclus1, drive1);
  openr(file1);
  cyclus1:= FILCYC;
  writeln('DIFF - DIFFERENCE BETWEEN TEXT FILES');
  writeln('File 1: ', name1,'.',
      hexb(cyclus1),'.',drive1);

  { get second argument and convert to filespec }
   case ARGTYPE[_carg] of
    chr(0): begin
              cyclus2 := 0;
              drive2 := drive1;
              _strcpy(name1,name2);
            end;
    'i':    begin
              cyclus2 := 0;
              _agetval(cyclus2, default);

              drive2 := drive1;
              _strcpy(name1,name2);
            end;
    's':    begin
              cyclus2 := 0;
              drive2 := drive1;
              _sgetstring(name2, _carg, default);
              _agetval(cyclus2,    default);
              _agetval(drive2,     default);
            end
    else    begin
              write(INVVID, 'Wrong type ');
              writeln('of second argument');
              writeln(NORVID);
            _abort;
            end
    end;
  _ssetsubtype(name2,'P', false);
  _strfio(name2, cyclus2, drive2);
  openr(file2);
  cyclus2 := FILCYC;
  writeln('File 2: ', name2,'.',
    hexb(cyclus2),'.',drive2);

  { Validation }
  if (_strcmp(name1,name2) = 0)
    and (cyclus1 = cyclus2) and (drive1 = drive2)
  then begin
    write(INVVID, 'Comparing identical files');
    writeln(' not allowed', NORVID);
    _abort;
  end;
  eof1 := false;
  eof2 := false;
end;

const buffer_size = 200;
var buffer1, buffer2: array[buffer_size] of cpnt;
    head1, head2: integer;
    count1, count2: integer;

proc init_buffers;
{****************}
var i: integer;
begin
  if _freepages < ((buffer_size * 2 * 65) shr 8) + 8
  then begin
    writeln('Internal error: reduce buffer_size');
    _abort;
  end;

  for i := 0 to buffer_size - 1 do begin
    buffer1[i] := _new;
    buffer2[i] := _new;
  end;

  head1 := 0;
  head2 := 0;
  count1 := 0;
  count2 := 0;
end;

proc advance(n:integer);
{*********************}
begin
  if n = 1 then begin
    head1 := _mod(head1 + 1, buffer_size);
    count1 := count1 - 1;
    line1 := line1 + 1;
  end
  else begin
    head2 := _mod(head2 + 1, buffer_size);
    count2 := count2 - 1;
    line2 := line2 + 1;
  end;
end;

func getline(n:integer):cpnt;
{*************************}
var p,length:integer;
begin
  if n = 1 then begin
    if count1 = 0 then begin
      p := head1;
      length := _strread(file1,buffer1[p],eof1);
      if not eof1 then count1 := 1;
    end;
    getline := buffer1[head1];
  end
  else begin
    if count2 = 0 then begin
      p := head2;
      length := _strread(file2,buffer2[p],eof2);
      if not eof2 then count2 := 1;
    end;
    getline := buffer2[head2];
  end;
end;

proc skip_equal;
{**************}
var s1, s2: cpnt;
begin
  while not eof1 and not eof2 do begin
    s1 := getline(1);
    s2 := getline(2);

    if _strcmp(s1,s2) <> 0 then
      exit;

    advance(1);
    advance(2);
  end;
end;

begin
  init_files;
  init_buffers;

  skip_equal;
  writeln('line1=', line1, ', line2=',line2);

  close(file1);
  close(file2);
end.
