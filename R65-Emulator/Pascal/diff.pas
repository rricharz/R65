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
uses syslib, arglib, strlib, striolib;

{$U+}

mem FILCYC = $0311: integer&;

var name1, name2:     cpnt;
    ch:               char;
    cyclus1, drive1:  integer;
    cyclus2, drive2:  integer;
    file1, file2:     file;
    line1, line2:     integer;
    default:          boolean;

begin
  name1 := _new;
  name2:= _new;
  cyclus1   := 0;
  drive1    := 1;
  line1      := 0;
  default   := true;

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
  writeln('File 1: ', name1,'.',cyclus1,'.',drive1);

  { get second argument and convert to filespec }
  debug(_carg,ARGTYPE[_carg]);
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
  writeln('File 2: ', name2,'.',cyclus2,'.',drive2);

  { Validation }
  if (_strcmp(name1,name2) = 0)
    and (cyclus1 = cyclus2) and (drive1 = drive2)
  then begin
    write(INVVID, 'Comparing identical files');
    writeln(' not allowed', NORVID);
    _abort;
  end;

  close(file1);
  close(file2);
end.
