{ include file for preparing read/write to file }
{ Example:                                      }
{   strfio('TEXT:B,1);                          }
{   openr;                                      }

proc strfio(name:cpnt; device: integer);
var i,j: integer;
begin
  i := 0;
  while (name[i]<>ENDMARK) and (i<=15) do begin
    FILNAM[i] := name[i];
    FILNM1[i] := name[i];
    i := i + 1;
  end;
  for j := i to 15 do begin
    FILNAM[j] := ' ';
    FILNM1[j] := ' ';
  end;
  FILCYC := 0;
  FILCY1 := 0;
  FILDRV := device;
  FILFLG := 0;
  {FILFLG:=$40;} { Do not show file entry }
end;
