# Generic Commandline Argument Parser

A small Nim library to make handling commandline arguments easier, with an API loosely based on [TCLAP](http://tclap.sourceforge.net/).

## Accepted Argument Syntax

Two types of arguments are defined: *switch* arguments, which take no value and simply return `true` if they are included, and *value* arguments which accept one or more values.

Both argument types are given both a short (single character) and long name.

*Value* arguments which accept **one** value will be accepted in any of the following forms:

```bash
$ prog --arg=val
$ prog --arg:val
$ prog --arg val
```

*Value* arguments which accept more than one value will only be accepted in the form:

```bash
$ prog --arg val0 val1 val2
```

If you use the `--arg:val` or `--arg=val` syntax, only the first value will be taken.

## Basic Usage

Pass a var for each argument. After parsing they will be filled with the values from the commandline.
Each argument requires a short name, long name, short description, and a boolean flag indicating whether they shoudl be required or not.

Parsing will fail if the data on the commandline can't be parsed into the correct type for each argument or if any required argument is missing.

```nim
import gcap

var i: int
var b: bool

var cmd = newCmdLine("A short sample program", "0.2.4")
cmd.add(newValueArg[int]("i", "myinteger", "Some integer arg", true, i))
cmd.add(newSwitchArg("b", "mybool", "Boolean switch arg", false, b))
cmd.parse()

echo "  i: ", i
echo "  b: ", b

```

## Default values

Simply give your variables a value before calling `parse()`. They will be left untouched if the user does not pass an argument overwriting them.
```nim
import gcap

var i: int
var b: bool

var cmd = newCmdLine("A short sample program", "0.2.4")
cmd.add(newValueArg[int]("i", "myinteger", "Some integer arg", true, i))
cmd.add(newSwitchArg("b", "mybool", "Boolean switch arg", false, b))
cmd.parse()

echo "  i: ", i
echo "  b: ", b

```

## Additional arguments

Pass `parse()` a `seq[string]` if you want to collect additional unnamed arguments.
```nim
import gcap

var additional_args: seq[string] = newSeq[string]()

var cmd = newCmdLine("A short sample program", "0.2.4")
cmd.parse(additional_args)

echo "  Additional Args: ", additional_args

```

## Sequence arguments

gcap can extract lists of arguments into a seq for you

```nim
import gcap

var si: seq[int] = newSeq[int]()

var cmd = newCmdLine("A short sample program", "1.2.4")
cmd.add(newValueArg[seq[int]]("s", "sequence", "An argument accepting a list of ints", true, si))
cmd.parse()

echo " si: ", si
```

```bash
$ test -s 1 2 3
 si: @[1, 2, 3]
```

## Custom Error Handling

By default, if an error is encountered during parsing a help message will be printed detailing the available arguments and the program will exit.

If you wish to do your own handling, in order to print a custom error message or produce a specific return code for example, simply provide a callback to `parse()`

The generated help and version information are also accessible in case you want to use them.

```nim
import gcap

proc onCmdParseFailed(cmd: CmdLine, error: string) =
  echo "omg, you broke the parser D: Please read this and try again:"
  cmd.printHelp()
  quit()

var s: bool
var cmd = newCmdLine("A short sample program", "1.2.4")
cmd.add(newSwitchArg("s", "switch", "A switch arg", true, s))

cmd.parse(onCmdParseFailed)
```