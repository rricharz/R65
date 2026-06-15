
{         ****************              }
{         *     help     *              }
{         ****************              }

{    2026 rricharz (r77@bluewin.ch)     }
{    new version using VIEW             }

{    Usage:  help subject               }

program help;
uses syslib,arglib,filelib,strlib,wildlib,striolib;

var
    fname, diskname: cpnt;
    drive,  entry: integer;
    default, found, last, changed:  boolean;
    hfile: file;

proc init;
{********}
begin
  fname    := _new;
  diskname := _new;
  _sgetstring(fname, _carg, default);
  _ssetsubtype(fname, 'H', true); { force set }
end;

proc copyback;
{************}
{ copy exact file name found back into argument }
var i: integer;
begin
  ARGTYPE[0] := 's';
  for i:= 0 to 15 do
    ARGLISTS[i] := FILNAM[i];
  ARGTYPE[8] := 'i';
  ARGLIST[8] := 0;
  ARGTYPE[9] := 'd';
  ARGLIST[9] := 1;
end;

begin
  init;

  { try to open help file on drive 1 }
  changed := false;
  drive := 1;
  entry := 0;
  _sfindentry(fname, drive, entry, found, last);
  if not found then begin
    _getdiskname(diskname, 1);
    { change disk on drive 1 to HELP }
    _change_disk('HELP', 1);
    changed := true;
    { try to open help file on HELP }
    drive:=1; entry:=0;
    _sfindentry(fname, drive, entry, found, last);
  end;

  debug(fname,found);

  if found then begin
    copyback;
    _s_runprog('VIEW:R', 0, 0);
  end else
    writeln(INVVID,
      'No help file for this topic available',
      NORVID);

  if changed then begin
    _change_disk(diskname, 1);
   end;

end.
