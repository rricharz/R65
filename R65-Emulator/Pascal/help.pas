
{         ****************              }
{         *     help     *              }
{         ****************              }

{    2026 rricharz (r77@bluewin.ch)     }
{    new version using VIEW             }

{    Usage:  help subject               }

program help;
uses syslib, strlib, wildlib, striolib;

const
    debug = true;

var
    fname, diskname: cpnt;
    cyclus, drive,  entry: integer;
    default, found, last, changed:  boolean;
    hfile: file;

proc init;
begin
  fname    := _new;
  diskname := _new;
  cyclus := 0;
  _sgetstring(fname, default, cyclus, drive);
  _ssetsubtype(fname, 'H', true); { force set }
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
  writeln('found =', found, ', changed=', changed);

  if changed then _change_disk(diskname, 1);
  _release(diskname);
  _release(fname);
end.
