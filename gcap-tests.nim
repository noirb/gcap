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

  test "Simple switch args":
    var b: bool

    var cmd = newCmdLine("Simple switch test", "0.0.1")
    cmd.add(newSwitchArg("b", "bool", "switch arg", false, b))

    cmd.parse(argv = @["-b"])

    check(b == true)

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


