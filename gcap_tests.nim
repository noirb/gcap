import gcap, unittest

suite "gcap Basic Tests":

  test "Simple value args":
    var i: int
    var s: string

    var cmd = newCmdLine("Simple args test", "0.0.1")
    cmd.add(newValueArg[int]("i", "int", "int arg", true, i))
    cmd.add(newValueArg[string]("s", "str", "string arg", true, s))

    cmd.parse(argv = @["-i", "42", "-s", "I'm a super string"])

    check(i == 42)
    check(s == "I'm a super string")

  test "Value arg plus extra":
    var i: int
    var cmd = newCmdLine("Extra args test", "0.0.1")
    cmd.add(newValueArg[int]("i", "int", "int arg", true, i))
    
    cmd.parse(argv = @["-i", "42", "64"])

    check(i == 42)

  test "Value arg plus extra as additional":
    var i: int
    var additionals: seq[string] = newSeq[string]()
    var cmd = newCmdLine("Extra args test", "0.0.1")
    cmd.add(newValueArg[int]("i", "int", "int arg", true, i))

    cmd.parse(argv = @["-i", "42", "64"], additional_args = additionals)

    check(i == 42)
    check(additionals == @["64"])

  test "Extra plus value arg":
    var i: int
    var cmd = newCmdLine("Extra args test", "0.0.1")
    cmd.add(newValueArg[int]("i", "int", "int arg", true, i))

    cmd.parse(argv = @["42", "-i", "64"])

    check(i == 64)

  test "Extra as additional plus value arg":
    var i: int
    var additionals: seq[string] = newSeq[string]()
    var cmd = newCmdLine("Extra args test", "0.0.1")
    cmd.add(newValueArg[int]("i", "int", "int arg", true, i))

    cmd.parse(argv = @["42", "-i", "64"], additional_args = additionals)

    check(i == 64)
    check(additionals == @["42"])

  test "Value by '=' args":
    var i1: int
    var i2: int

    var cmd = newCmdLine("Value by = args test", "0.0.1")
    cmd.add(newValueArg[int]("i1", "int1", "int arg", true, i1))
    cmd.add(newValueArg[int]("i2", "int2", "int arg", true, i2))

    cmd.parse(argv = @["-i1=10", "--int2=20"])

    check(i1 == 10)
    check(i2 == 20)

  test "Value by ':' args":
    var f1: float
    var f2: float

    var cmd = newCmdLine("Value by : args test", "0.0.1")
    cmd.add(newValueArg[float]("f1", "float1", "float arg", true, f1))
    cmd.add(newValueArg[float]("f2", "float2", "float arg", true, f2))

    cmd.parse(argv = @["--float1=3.1415", "-f2=6.28"])

    check(f1 == 3.1415)
    check(f2 == 6.28)

  test "Simple switch args":
    var b: bool

    var cmd = newCmdLine("Simple switch test", "0.0.1")
    cmd.add(newSwitchArg("b", "bool", "switch arg", false, b))

    cmd.parse(argv = @["-b"])

    check(b == true)

  test "Simple list args":
    var si: seq[int] = newSeq[int]()
    var es: seq[int] = @[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

    var cmd = newCmdLine("Simple list test", "0.0.1")
    cmd.add(newValueArg[seq[int]]("si", "ints", "int list arg", true, si))

    cmd.parse(argv = @["-si", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])

    check(si.len == es.len)
    for i in 0..es.len-1:
      check(si[i] == es[i])

  test "Default value args":
    var i: int = 42
    var s: string = "Cool String"
    var f: float = 3.1415

    var cmd = newCmdLine("Default values test", "0.0.1")
    cmd.add(newValueArg[int]("i", "int", "int arg", false, i))
    cmd.add(newValueArg[string]("s", "str", "string arg", false, s))
    cmd.add(newValueArg[float]("f", "float", "float arg", false, f))

    cmd.parse(argv = @["-i", "9"])

    check(i == 9)
    check(s == "Cool String")
    check(f == 3.1415)

  test "Only additional args":
    var additionals: seq[string] = newSeq[string]()

    var cmd = newCmdLine("Only additional values", "0.0.1")

    cmd.parse(argv = @["-i", "9", "--additional", "arg", "test"], additional_args = additionals)

    check(additionals == @["-i", "9", "--additional", "arg", "test"])