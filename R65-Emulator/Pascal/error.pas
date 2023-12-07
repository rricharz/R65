{
        *****************
        *               *
        *     ERROR     *
        *               *
        *****************

Displays Pascal error codes as text

Usage: error errnum                    }

program error;
uses syslib,arglib;

var err:integer;
    default:boolean;

begin
  err:=0;
  agetval(err,default);
  write('Error ',err,': ');
  write(invvid);
  case err of
    05: writeln('File type error');
    06: writeln('File not found');
    07: writeln('Disk not ready');
    08: writeln('Directory full');
    23: writeln('Too many open files');
    24: writeln('Direction wrong in sequential R/W');
    25: writeln('File not open');
    26: writeln('Disk full');
    27: writeln('Random access index out of range');
    28: writeln('Illegal drive');
    29: writeln('Random access file not open');
    62: writeln('Not allowed for tape drive');
    81: writeln('Division by zero');
    82: writeln('Stack overflow');
    83: writeln('Index out of bounds');
    84: writeln('Wrong file type');
    85: writeln('Wrong p-code');
    86: writeln('Escape during execution');
    87: writeln('No loader file made');
    88: writeln('Heap overflow');
    89: writeln('Pointer not allocated (nil)');
    90: writeln('Writing to constant string');
    91: writeln('String too long');
    92: writeln('Only last string can be released');
    101: writeln('Argument is not string or default');
    102: writeln('Argument is not number or default');
    103: writeln('Argument is not starting with /');
    104: writeln('Unknown argument');
    105: writeln('Drive is not 0 or 1');
    106: writeln('Argument syntax');
    107: writeln('Too many arguments')
    else writeln('Undefined')
    end;
  write(norvid);
end.
