{*************************************}
{* RESTORE - restores a deleted file *}
{*************************************}

program restore;
uses syslib, arglib, filelib;

const
    aenddo     = $f625;
    putfentp3  = $f583;
    NAMESIZE   = 15;
    NUMENTRIES = 255;

mem FILLNK     = $031e: integer&;
    FILCN1     = $e5: integer&;

var filename: array[NAMESIZE] of char;
    cyclus, drive, entry: integer;
    default, found, last: boolean;
    i: integer;

proc find_deleted(var nm:array[NAMESIZE] of char;
       drv:integer;var ent: integer;
       var fnd,lst:boolean);
{***********************************************}
const aprepdo    = $f4a7;
      agetentx   = $f63a;

mem   filtyp     = $0300: char&;
      fillnk     = $031e: integer&;
      scyfc      = $037c: integer&;
      fildrv     = $00dc: integer&;
      FILNAM=$0301: array[NAMESIZE] of char&;

var   i: integer;

  proc _test(s1:array[NAMESIZE] of char;
        var found:boolean);
  var l1,l2:integer;

    proc findends;
    var k:integer;
    begin
      k:=NAMESIZE;
      while (s1[k]=' ') and (k>0) do k:=k-1;
      l1:=k+1;
      k:=NAMESIZE;
      while (FILNAM[k]=' ') and (k>0) do k:=k-1;
      l2:=k+1;
    end;

    func match(i0,i2:integer): boolean;
    var i1:integer;
        b:boolean;
    begin
      i1:=i0;
      if (i1>=l1) and (i2>=l2) then
        match:=true
      else begin
        if s1[i1]='*' then
          while (i1<l1) and (s1[i1+1]='*') do
            i1:=i1+1;
        if (s1[i1]='*') and (i1<l1-1) and (i2>=l2)
        then match:=false
        else begin
          if (s1[i1]='?') or (s1[i1]=FILNAM[i2]) then
            match:=match(i1+1,i2+1)
          else begin
            if (s1[i1]='*') and (i1<l1) then begin
              b:=match(i1+1,i2);
              if not b then
                b:=match(i1,i2+1);
              match:=b;
            end else begin
              match:=false;
            end;
          end;
        end;
      end;
    end;

  begin {test}
    findends;
    found:=match(0,0);
  end;

  proc checkfilerr;
  mem filerr = $db: integer&;
  begin
    if filerr<>0 then begin
      writeln(INVVID,'Directory read error',NORVID);
      _abort;
    end;
  end;

begin
  fildrv:=drv;
  call(aprepdo);
  checkfilerr;
  repeat
    scyfc:=ent:
    call(agetentx);
    checkfilerr;
    fnd:=true;
    i:=0;
    _test(nm,fnd);
    if (fillnk and $80) = 0 then {not deleted file}
      fnd:=false;
    ent:=ent+1;
    lst:=(filtyp=chr(0));
    until fnd or lst or (ent>=NUMENTRIES);
end;

begin

  cyclus  := 0;
  drive   := 1;
  default := false;
  last    := false;

  if (ARGTYPE[_carg] <> 's') then begin
    writeln(INVVID,'Usage: RESTORE filename',NORVID);
    _abort;
  end;
  _agetstring(filename, default, cyclus, drive);

  entry := 0;
  while not last do begin
    find_deleted(filename, drive, entry, found, last);
    if found and (cyclus <> 0) then
      if FILCYC <> cyclus then found := false;
    if found then begin
      _write_label;
      writeln('+');
    end;

    { clear deleted flag }
    FILLNK := FILLNK and not $80;

    call(putfentp3);
    call(aenddo);
    entry := entry + 1;
  end;

end.