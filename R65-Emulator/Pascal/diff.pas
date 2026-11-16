{
 ****************************************
 * DIFF - difference between text files *
 ****************************************

Usage:
  DIFF filespec version
  DIFF filespec filespec

  filespec:
    name:subtype.version,srive

    default for subtype:      :P
    default for version:      highest
    default for drive:        1

Special cases:
  DIFF abc      Difference between second last and
                last version of abc
  DIFF abc.5    Difference between version 5 and
                last version

{ String length optimization:
  R65 strings have STRSIZE+1 bytes (0..STRSIZE).
  The actual string ends with ENDMARK.
  Since text lines are limited to 56 characters,
  the last byte s[STRSIZE] is unused.

  DIFF stores the string length in this last byte
  when reading a line with append_line.

  same_line first compares these lengths, then
  compares characters only if the lengths match.
  This speeds up synchronization searches without
  requiring any additional memory.
}

program diff;
uses syslib, arglib, strlib, striolib, writelib;

const SYNC_LINES = 3;

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
    writeln('Usage: DIFF filespec [version]');
    writeln('   or   DIFF filespec filespec');
    write(NORVID);
    _abort;
  end;
  _agetval(cyclus1,    default);
  _agetval(drive1,     default);

  _ssetsubtype(name1,'P', false);
  _strfio(name1, cyclus1, drive1);
  openr(file1);
  if (cyclus1=0) and (ARGTYPE[_carg]=chr(0)) then
  begin
    close(file1);
    cyclus1 := FILCYC - 1; { second last version }
    _strfio(name1, cyclus1, drive1);
    openr(file1);
  end;
  cyclus1:= FILCYC;
  writeln('--- ', name1,'.',
      hexb(cyclus1),',',drive1);

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
  writeln('+++ ', name2,'.',
    hexb(cyclus2),',',drive2);

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

const BUFFER_SIZE = 200;

var buffer1, buffer2: array[BUFFER_SIZE] of cpnt;
    head1, head2:   integer;
    count1, count2: integer;
    sync1, sync2:   integer;

proc init_buffers;
{****************}
var i: integer;
begin
  if _freepages < ((BUFFER_SIZE * 2 * 65) shr 8) + 8
  then begin
    writeln('Internal error: reduce BUFFER_SIZE');
    _abort;
  end;

  for i := 0 to BUFFER_SIZE - 1 do begin
    buffer1[i] := _new;
    buffer2[i] := _new;
  end;

  head1 := 0;
  head2 := 0;
  count1 := 0;
  count2 := 0;
end;

func bufindex(head,p:integer):integer;
{************************************}
var i:integer;
begin
  i := head + p;
  if i >= BUFFER_SIZE then
    i := i - BUFFER_SIZE;
  bufindex := i;
end;

proc advance(n:integer);
{*********************}
begin
  if n = 1 then begin
    head1 := bufindex(head1,1);
    count1 := count1 - 1;
    line1 := line1 + 1;
  end
  else begin
    head2 := bufindex(head2,1);
    count2 := count2 - 1;
    line2 := line2 + 1;
  end;
end;

func append_line(n:integer):boolean;
{**********************************}
var p,length:integer;
    b:cpnt;
begin
  append_line := false;

  if _isesc then begin
    writeln('DIFF aborted by ESC');
    _abort;
  end;

  if n = 1 then begin
    if eof1 or (count1 = BUFFER_SIZE) then exit;

    p := bufindex(head1,count1);
    b := buffer1[p];
    length := _strread(file1,b,eof1);
    if eof1 then exit;

    b[STRSIZE] := chr(length);
    count1 := count1 + 1;
  end
  else begin
    if eof2 or (count2 = BUFFER_SIZE) then exit;

    p := bufindex(head2,count2);
    b := buffer2[p];
    length := _strread(file2,b,eof2);
    if eof2 then exit;

    b[STRSIZE] := chr(length);
    count2 := count2 + 1;
  end;

  append_line := true;
end;

func getline(n:integer):cpnt;
{*************************}
var success:boolean;
begin
  if n = 1 then begin
    if count1 = 0 then success := append_line(1);
    getline := buffer1[head1];
  end
  else begin
    if count2 = 0 then success := append_line(2);
    getline := buffer2[head2];
  end;
end;

func same_line(s1,s2:cpnt):boolean;
{********************************}
var i,n:integer;
begin
  same_line := false;

  { compare lengths first }
  if s1[STRSIZE] <> s2[STRSIZE] then exit;

  n := ord(s1[STRSIZE]);
  i := 0;
  while i < n do begin
    if s1[i] <> s2[i] then exit;
    i := i + 1;
  end;

  same_line := true;
end;

proc skip_equal;
{**************}
var s1, s2: cpnt;
begin
  while true do begin
    if eof1 and (count1 = 0) then exit;
    if eof2 and (count2 = 0) then exit;

    s1 := getline(1);
    s2 := getline(2);

    if (eof1 and (count1 = 0)) or
       (eof2 and (count2 = 0)) then exit;

    if not same_line(s1,s2) then exit;

    advance(1);
    advance(2);
  end;
end;

func buffer_line(n,p:integer):cpnt;
{********************************}
begin
  if n = 1 then
    buffer_line := buffer1[bufindex(head1,p)]
  else
    buffer_line := buffer2[bufindex(head2,p)];
end;

func match_sync(p1,p2:integer):boolean;
{*************************************}
var i:integer;
    s1,s2:cpnt;
begin
  match_sync := false;

  if (p1 < SYNC_LINES - 1) or
      (p2 < SYNC_LINES -1) then exit;

  for i := 0 to SYNC_LINES - 1 do begin
    s1 := buffer_line(1,p1-i);
    s2 := buffer_line(2,p2-i);
    if not same_line(s1,s2) then exit;
  end;

  match_sync := true;
end;

func check_new_line(n:integer):boolean;
{***********************************}
var p,i:integer;
begin
  check_new_line := false;

  if (count1 < SYNC_LINES)
      or (count2 < SYNC_LINES) then exit;

  if n = 1 then begin
    p := count1-1;
    for i := SYNC_LINES - 1 to count2-1 do begin
      if match_sync(p,i) then begin
        sync1 := p - SYNC_LINES + 1;
        sync2 := i - SYNC_LINES + 1;
        check_new_line := true;
        exit;
      end;
    end;
  end
  else begin
    p := count2-1;
    for i := SYNC_LINES - 1 to count1-1 do begin
      if match_sync(i,p) then begin
        sync1 := i - SYNC_LINES + 1;
        sync2 := p - SYNC_LINES + 1;
        check_new_line := true;
        exit;
      end;
    end;
  end;
end;

func find_sync:boolean;
{**********************}
var success:boolean;
begin
  find_sync := false;

  while true do begin

    { read from file 1 }
    success := append_line(1);
    if success then begin
      if check_new_line(1) then begin
        find_sync := true;
        exit;
      end;
    end;

    { read from file 2 }
    success := append_line(2);
    if success then begin
      if check_new_line(2) then begin
        find_sync := true;
        exit;
      end;
    end;

    { stop if neither file can supply another line }
    if ((eof1 or (count1 = BUFFER_SIZE)) and
        (eof2 or (count2 = BUFFER_SIZE))) then exit;

    { stop if either buffer is full }
    if (count1 = BUFFER_SIZE) or
       (count2 = BUFFER_SIZE) then exit;

  end;
end;

proc finish_diff;
{****************}
var b:cpnt;
    length:integer;
begin
  { Report all remaining lines from file 1 }
  while count1>0 do begin
    writeln('-',buffer_line(1,0));
    advance(1);
  end;

  { Report all remaining lines from file 2 }
  while count2>0 do begin
    writeln('+',buffer_line(2,0));
    advance(2);
  end;

  { Read any additional lines from file 1 }
  while not eof1 do begin
    b:=buffer1[head1];
    length:=_strread(file1,b,eof1);
    if not eof1 then begin
      writeln('-',b);
      line1:=line1+1;
    end;
  end;

  { Read any additional lines from file 2 }
  while not eof2 do begin
    b:=buffer2[head2];
    length:=_strread(file2,b,eof2);
    if not eof2 then begin
      writeln('+',b);
      line2:=line2+1;
    end;
  end;
end;

proc show_different;
{******************}
var found:boolean;
    i:integer;
begin
  found:=find_sync;

  if found then begin
    writeln(INVVID,'@@ -',line1,',',sync1,
            ' +',line2,',',sync2,' @@',NORVID);

    for i:=0 to sync1-1 do
      writeln('-',buffer_line(1,i));

    for i:=0 to sync2-1 do
      writeln('+',buffer_line(2,i));

    for i:=1 to sync1 do advance(1);
    for i:=1 to sync2 do advance(2);
  end else begin
    if eof1 and eof2 then
      finish_diff
    else begin
      writeln(INVVID,
        'DIFF: synchronization buffer full',NORVID);
      _abort;
    end;
  end;
end;

var i: integer;

begin
  init_files;
  init_buffers;

  while not (eof1 and eof2 and
           (count1 = 0) and (count2 = 0)) do begin
    skip_equal;

    if not (eof1 and eof2 and
          (count1 = 0) and (count2 = 0)) then
      show_different;
  end;
  close(file1);
  close(file2);
end.
