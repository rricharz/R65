{        *****************         }
{        *               *         }
{        *     ERROR     *         }
{        *               *         }
{        *****************         }

{ Displays R65 error codes as text }

{ Usage: error errnum              }

{$U+}

program error;
uses syslib,arglib;

var err:integer;
    default:boolean;

begin
  err:=0;
  _agetval(err,default);
  write('Error ',err,': ');
  write(INVVID);
  case err of
    01,02,03,04:
        writeln('Tape error');
    05: writeln('File type error');
    06: writeln('File not found');
    07: writeln('Disk not ready');
    08: writeln('Directory full');
    09: writeln('Unexpected IRQ');
    10: writeln('Expression missing');
    11: writeln('Memory cell cannot be changed');
    12: writeln('Break table full');
    13: writeln('Illegal memory cell for break');
    14: writeln('Double breakpoint setting');
    15: writeln('End of line expected');
    16: writeln('Register syntax error');
    17: writeln('Breakpoint not found intable');
    18: writeln('Store: syntax wrong');
    19: writeln('File subtype wrong or missing');
    20: writeln('Wrong file type, cannot be run');
    21: writeln('Unknown monitor command');
    22: writeln('Illegal opcode during STEP/TRACE');
    23: writeln('Too many open files');
    24: writeln('Sequential R/W: directory error');
    23: writeln('Too many open files');
    24: writeln('Direction wrong in sequential R/W');
    25: writeln('File not open');
    26: writeln('Disk full');
    27: writeln('Random access index out of range');
    28: writeln('Illegal drive');
    29: writeln('Random access file not open');
    61: writeln('Wildcard not allowed here');
    62: writeln('Only for disk, not for tape');
    63: writeln('Illegal copy');
    64: writeln('File too large');
    65: writeln('Write error');
    66: writeln('Import error');
    67: writeln('Unknown emulator command');
    68: writeln('Unable to run external editor');
    69: writeln('File not changed, no new version');

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
  write(NORVID);
end.
