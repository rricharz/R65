program grep;
uses syslib,arglib,strlib,filelib,wildlib,writelib;

var pattern, fullname, line: cpnt;
    filespec:                array[15] of char;
    cyclus, drive,
    i, secondarg,entry:      integer;
    default, found, last:    boolean;
    f0:                      file;

func upper(ch1: char): char;
{***************************}
begin
  if (ch1 >= 'a') and (ch1 <= 'z') then
    upper := chr(ord(ch1) - 32)
  else
    upper := ch1;
end;


proc grep_in_file(name: cpnt; f: file );
{**************************************}
var nchar, linecount, stop,
    pattern_length, line_length: integer;
    ateof:                       boolean;

    func find_pattern: boolean;
    var i, j, stop: integer;
        ok: boolean;
    begin
      if pattern_length <= 0 then begin
        find_pattern := false;
        exit;
      end;

      if pattern_length > line_length then begin
        find_pattern := false;
        exit;
      end;

      stop := line_length - pattern_length;

      i := 0;
      while i <= stop do begin
        if upper(line[i]) = pattern[0] then begin
          j := 1;
          ok := true;

          while ok and (j < pattern_length) do begin
            if upper(line[i+j]) <> pattern[j] then
              ok := false
            else
              j := j + 1;
          end;

          if ok then begin

            find_pattern := true;
            exit;
          end;
        end;

        i := i + 1;
      end;

      find_pattern := false;
    end;

begin
  debug(name);
  pattern_length := _strlen(pattern);
  linecount := 1;
  repeat
    line_length := _strread(f, line, ateof);
    if find_pattern then begin
      while line[0]=' ' do _strdelc(0, line);
      writeln(name,'/',linecount,' ', line);
      end;
    linecount := linecount + 1;
  until ateof;
end;

proc default_subtype(var name: array[15] of char;
                                      subtype:char);
{**************************************************}
{ only set subtype if not already there }
var i:integer;
begin
  i:=0;
  repeat
    i:=i+1;
  until (name[i]=':') or
    (name[i]=' ') or (i>=14);
  if name[i]<>':' then begin
    name[i]:=':';
    name[i+1]:=subtype;
    FILSTP:=subtype;
  end else
    FILSTP:=name[i+1];
end;

begin { main }
{************}
  pattern  := _new;
  fullname := _new;
  line     := _new;

  secondarg := 0;
  if ARGTYPE[_carg] = 's' then secondarg := 10;
  if ARGTYPE[_carg] = 'q' then secondarg := 8;

  if (secondarg = 0) then
  begin
    writeln
      ('Wrong arguments, use HELP GREP for details');
    exit;
  end;

  { get pattern from arglist}
  for i := 0 to 15 do
    if ARGLISTS[2 * _carg + i] = ' ' then
      pattern[i] := ENDMARK
    else
      pattern[i] := ARGLISTS[2 * _carg + i];

  debug(pattern);

  { get filespec from arglist, with defaults }
  cyclus := 0;
  drive  := 1;
  _carg  := secondarg;
  _agetstring(filespec, default, cyclus, drive);
  default_subtype(filespec, 'P');

  debug('filespec: ',trim16(filespec),cyclus,drive);

  { loop through directory entries }
  last := false;
  entry := 0;
  while (entry<NUMENTRIES) and not last do begin
    _findentry(filespec, drive, entry, found, last);
    if FILERR<>0 then begin
      writeln('Error while reading directory');
      last:=true;
    end;
    debug(entry, found, last);
    if found and (FILTYP='S') and not last then begin
      fullname[0] := ENDMARK;
      for i := 0 to 15 do
        if FILNAM[i] <> ' ' then
          write(@fullname,FILNAM[i]);
        write(@fullname, '.', hexb(FILCYC));
      for i := 0 to 15 do
        FILNM1[i] := FILNAM[i];
      FILCY1 := FILCYC;
      FILFLG := 0;
      openr(f0);
      if FILERR <> 0 then
        writeln('Cannot open file')
      else begin
        grep_in_file(fullname, f0);
        close(f0);
        end;
    end;
    if _isesc then last := true;
  end;

end.