defmodule KindaExampleTest do
  use ExUnit.Case

  alias KindaExample.{NIF, Native}

  test "add in c" do
    assert 3 ==
             NIF.kinda_example_add(1, 2) |> Native.to_term()

    assert match?(
             %Kinda.CallError{message: "Fail to fetch argument #2", error_return_trace: _},
             catch_error(NIF.kinda_example_add(1, "2"))
           )
  end

  test "custom make" do
    assert 100 ==
             Native.forward(NIF.CInt, :make, [100])
             |> NIF."Elixir.KindaExample.NIF.CInt.primitive"()

    e = catch_error(NIF."Elixir.KindaExample.NIF.StrInt.make"(1))
    assert Exception.message(e) =~ "Function clause error\n#{IO.ANSI.reset()}"

    err = catch_error(NIF."Elixir.KindaExample.NIF.StrInt.make"(1))
    # only test this on macOS, it will crash on Linux
    txt = Exception.message(err)

    if System.get_env("KINDA_DUMP_STACK_TRACE") == "1" do
      assert txt =~ "src/beam.zig"
      assert txt =~ "kinda_example/native/zig-src/main.zig"
    else
      assert txt =~ "to see the full stack trace, set KINDA_DUMP_STACK_TRACE=1"
    end

    assert match?(%Kinda.CallError{message: "Function clause error", error_return_trace: _}, err)

    assert 1 ==
             NIF."Elixir.KindaExample.NIF.StrInt.make"("1")
             |> NIF."Elixir.KindaExample.NIF.CInt.primitive"()

    %NIF.StrInt{ref: ref} = NIF.StrInt.make("1")
    assert 1 == ref |> NIF."Elixir.KindaExample.NIF.CInt.primitive"()
  end
end
