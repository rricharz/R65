proc silent(b: boolean);
{**********************}
begin
  if b then
    FILFLG := FILFLG or $40      { set bit 6 }
  else
    FILFLG := FILFLG and not $40 { clear bit 6 }
end;

func is_silent: boolean;
{**********************}
begin
  is_silent := (FILFLG and $40) = $40;
end;


 