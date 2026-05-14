{***********************************}
{** LASTVERS - check last version **}
{***********************************}

{$U+}
{$R+}

program lastvers;
uses syslib,arglib,striolib,filelib,strlib,wildlib;

const DEBUG = false;

var force, default, found: boolean;
    name, sname, tname, h: cpnt;
    cyclus, drive, pos, pversion, rversion: integer;

func getlastvers: integer;
var entry, version: integer;
    last: boolean;
begin
  if DEBUG then
    writeln('Find latest version of file ', tname);
  entry := 0;
  last := false;
  version := 0;
  while ((entry < NUMENTRIES) and (not last)) do
  begin
    _sfindentry(tname, drive, entry, found, last);
    if found and (FILCYC > version) then
    begin
      version := FILCYC;
      if DEBUG then
        writeln('e=', entry,
                ' f=', found,
                ' l=', last,
                ' FC=', FILCYC,
                ' v=', version);
    end;
  end;
  getlastvers := version;
end;

begin

  name   := _new;
  sname  := _new;
  tname  := _new;
  h      := _new;
  cyclus := 0;
  drive  := 1;

  _sgetstring(name, _carg, default);
  _agetval(cyclus, default);
  _agetval(drive, default);
  force := option('F');
  if force then
  begin
    _release(h);
    _release(tname);
    _release(sname);
    _release(name);
    exit;
  end;

  { sname has the suntype stripped away }
  _strcpy(name, sname);
  pos := _strpos(':', sname, 0);
  if (pos > 0) then sname[pos] := ENDMARK;
  pos := _strpos(' ', sname, 0);
  if (pos > 0) then sname[pos] := ENDMARK;
  if DEBUG then
    writeln('sname="', sname, '"');
  if (_strlen(sname) < 1) then
  begin
    writeln(INVVID,'Error: No file name', NORVID);
    _abort;
  end;

  { get version of source file to be edited }
  _strcpy(sname, tname);
  _stradd(':P',tname);
  if cyclus = 0 then begin
    pversion := getlastvers;
  end;
  if (pversion = 0) then begin
    writeln(INVVID, 'Source file ',
                    tname,' not found', NORVID);
    _abort;
  end;
  _hexstr(pversion, h);
  writeln('Source file ', tname, '.',h );

  { check object file versions }
  _strcpy(sname, tname);
  _stradd(':R',tname);

  drive := 1;
  rversion := getlastvers;

  if DEBUG then
    writeln('pversion=', pversion,
           ' rversion=', rversion);

  if rversion < pversion then begin
    drive := 0;
    rversion := getlastvers;
  end;

  if (rversion >= pversion) then begin
    _hexstr(pversion, h);
    write(INVVID, 'Error: Object file exists: ');
    writeln(tname, '.', h, ',', drive, NORVID);
    _abort;
  end;

  _release(h);
  _release(tname);
  _release(sname);
  _release(name);
  RUNERR := 0;

end.
