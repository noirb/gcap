import os, uri, strutils, sequtils, parseopt2, typetraits

type
  CmdLineArg = ref object of RootObj
    shortname:   string
    longname:    string
    description: string
    required:    bool
    found:       bool
  
  CmdLineValueArg[T] = ref object of CmdLineArg
    val: ptr T

  CmdLineSwitchArg = ref object of CmdLineArg
    val: ptr bool

  CmdLine* = ref object of RootObj
    parser:      OptParser
    description: string
    version:     string
    args:        seq[CmdLineArg]

template argUsage(argName, argType: string): untyped =
  if argType.contains("seq"):
    (argName & " <" & argType.replace("ptr ").replace("seq", "List of ") & ">")
  else:
    (argName & "=<" & argType.replace("ptr ") & ">")

method longDesc(this: CmdLineArg) : string {.base.} =
  ("-" & this.shortName & ", --" & this.longname)

method shortDesc(this: CmdLineArg) : string {.base.} =
  "-" & this.shortName

method longDesc[T](this: CmdLineValueArg[T]) : string =
  ("-" & argUsage(this.shortName, this.val.type.name) & " " &
   "--" & argUsage(this.longName , this.val.type.name))

method shortDesc[T](this: CmdLineValueArg[T]) : string =
  "-" & argUsage(this.shortName, this.val.type.name)

method parseArg(this: CmdLineArg, arg: string): bool {.base.} =
  return false

method parseArg[T](this: CmdLineValueArg[T], arg: string): bool =
  if arg.len < 1:
    return false

  this.found = true
  when T is int:
    this.val[] = parseInt(arg)
  elif T is seq[int]:
    this.val[].add(parseInt(arg))
  elif T is uint:
    this.val[] = parseUInt(arg)
  elif T is seq[uint]:
    this.val[].add(parseUInt(arg))
  elif T is float:
    this.val[] = parseFloat(arg)
  elif T is seq[float]:
    this.val[].add(parseFloat(arg))
  elif T is bool:
    this.val[] = parseBool(arg)
  elif T is seq[bool]:
    this.val[].add(parseBool(arg))
  elif T is string:
    this.val[] = arg
  elif T is seq[string]:
    this.val[].add(arg)
  else:
    this.found = false

  return this.found

method parseArg(this: CmdLineSwitchArg, arg: string): bool =
  if this.val != nil:
    this.val[] = true
  this.found = true
  return true

proc newValueArg*[T](shortname: string, longname: string, description: string, required: bool, val: var T): CmdLineValueArg[T] =
  new(result)
  result.shortname   = shortname
  result.longname    = longname
  result.description = description
  result.val         = addr(val)
  result.required    = required
  result.found       = false

proc newSwitchArg*(shortname: string, longname: string, description: string, required: bool): CmdLineSwitchArg =
  new(result)
  result.shortname   = shortname
  result.longname    = longname
  result.description = description
  result.val         = nil
  result.required    = required
  result.found       = false

proc newSwitchArg*(shortname: string, longname: string, description: string, required: bool, val: var bool): CmdLineSwitchArg =
  new(result)
  result.shortname   = shortname
  result.longname    = longname
  result.description = description
  result.val         = addr(val)
  result.required    = required
  result.found       = false

method add*(this: CmdLine, arg: CmdLineArg) {.base.} =
  this.args.insert(arg, max(0, len(this.args)-2)) # keep help & version flags at the end

proc newCmdLine*(cmd_desc: string, version = ""): CmdLine =
  new(result)
  result.description = cmd_desc
  result.version     = version
  result.parser      = initOptParser()
  result.args        = newSeq[CmdLineArg](0)
  result.add(newSwitchArg("h", "help", "Displays usage information", false))
  result.add(newSwitchArg("v", "version", "Displays version information", false))

method printHelp*(this: CmdLine) {.base.} =
  echo "\n"
  echo extractFilename(getAppFilename()), if len(this.version) > 0: "  -- version "&this.version else: ""

  # usage
  echo "\nUSAGE:\n"
  var usagestr = "    " & extractFilename(getAppFilename()) & "  "
  for i,v in this.args:
    usagestr = usagestr & (if v.required: " " & v.shortDesc() else: " [" & v.shortDesc() & "]")
  echo usagestr

  # parameter explanation
  echo "\nWhere:\n"
  for i,v in this.args:
    echo "  ", v.longDesc()
    echo "    ", v.description
    echo "\n"
  echo this.description, "\n"

method printVersion*(this: CmdLine) {.base.} =
  echo "\n"
  echo extractFilename(getAppFilename()), if len(this.version) > 0: "  -- version "&this.version else: ""
  echo this.description, "\n"

# Default error handler
method onParseFailure(this: CmdLine, errormsg: string) {.base.} =
  echo "PARSE ERROR:\n\t", errormsg
  this.printHelp()
  quit()

method parse(this: CmdLine, additional_args: ptr seq[string] = nil, onFailure: proc(cmd: CmdLine = this, errormsg: string) = onParseFailure, argv: seq[string] = nil) {.base.} =
  this.parser = initOptParser(argv)
  var curr = -1

  for kind, key, val in getopt(this.parser):
    try:
      case kind
      of cmdArgument:
        if curr >= 0:
          if not this.args[curr].parseArg(key):
            curr = -1
        elif additional_args != nil:
          additional_args[].add(key)
      of cmdLongOption, cmdShortOption:
        case key
        of "help", "h":
          this.printHelp()
          quit(QuitSuccess)
        of "version", "v":
          this.printVersion()
          quit(QuitSuccess)
        var found = false
        for i,v in this.args:
          if key == v.longname or key == v.shortname:
            found = true
            if not v.parseArg(val):
              curr = i
            else:
              curr = -1
            break
        if not found and curr >= 0:
          discard this.args[curr].parseArg("-" & key)
        elif additional_args != nil:
          additional_args[].add(key)
          if len(val) > 0:
            additional_args[].add(val)
      of cmdEnd:
        break # end of cmdline

    except ValueError:
      onFailure(this, "Could not parse value: '" & key & "'")
    except:
      onFailure(this, "Unknown error occurred while parsing commandline")

  # check that all required params are present
  for i,v in this.args:
    if v.required and not v.found:
      onFailure(this, "Required argument '" & v.longname & "' is missing!")

method parse*(this: CmdLine, onFailure: proc(cmd: CmdLine = this, errormsg: string) = onParseFailure, argv: seq[string] = nil) {.base.} =
  this.parse(nil, onFailure, argv)

method parse*(this: CmdLine, additional_args: var seq[string], onFailure: proc(cmd: CmdLine = this, errormsg: string) = onParseFailure, argv: seq[string] = nil) {.base.} =
  this.parse(addr(additional_args), onFailure, argv)
