Code.require_file "../test_helper", __FILE__

defmodule KernelTest do
  defmodule Conversions do
    use ExUnit.Case, async: true

    test :atom_to_binary_defaults_to_utf8 do
      expected  = atom_to_binary :some_binary, :utf8
      actual    = atom_to_binary :some_binary

      assert actual == expected
      assert atom_to_binary(:another_atom) == "another_atom"
    end

    test :binary_to_atom_defaults_to_utf8 do
      expected  = binary_to_atom "some_binary", :utf8
      actual    = binary_to_atom "some_binary"

      assert actual == expected
      assert binary_to_atom("another_binary") == :another_binary
    end

    test :binary_to_existing_atom_defaults_to_utf8 do
      expected = binary_to_atom "existing_atom", :utf8
      actual   = binary_to_existing_atom "existing_atom"

      assert actual == expected

      :existing_atom
      assert binary_to_existing_atom("existing_atom") == :existing_atom

      assert_raise ArgumentError, fn ->
        binary_to_existing_atom "nonexisting_atom"
      end
    end
  end

  defmodule Function do
    use ExUnit.Case, async: true

    test :retrieve_remote_function do
      assert is_function(function(:erlang, :atom_to_list, 1))
      assert :erlang.fun_info(function(:erlang, :atom_to_list, 1), :arity) == {:arity, 1}
      assert function(:erlang, :atom_to_list, 1).(:a) == 'a'
    end

    test :retrieve_local_function do
      assert is_function(function(:atl, 1))
      assert :erlang.fun_info(function(:atl, 1), :arity) == {:arity, 1}
      assert function(:atl, 1).(:a) == 'a'
    end

    test :retrieve_imported_function do
      assert is_function(function(:atom_to_list, 1))
      assert :erlang.fun_info(function(:atom_to_list, 1), :arity) == {:arity, 1}
      assert function(:atom_to_list, 1).(:a) == 'a'
    end

    test :retrieve_dynamic_function do
      a = :erlang
      b = :atom_to_list
      c = 1

      assert is_function(function(a, b, c))
      assert :erlang.fun_info(function(a, b, c), :arity) == {:arity, 1}
      assert function(a, b, c).(:a) == 'a'
    end

    test :function do
      f = function do
        x, y when y > 0 -> x + y
        x, y -> x - y
      end

      assert f.(1, 2)  == 3
      assert f.(1, -2) == 3
    end

    defp atl(arg) do
      :erlang.atom_to_list arg
    end
  end

  defmodule DefDelegate do
    use ExUnit.Case, async: true

    defdelegate [my_flatten: 1], to: List, as: :flatten
    defdelegate [map: 2], to: :lists, append_first: true

    test :defdelegate_with_function do
      assert my_flatten([[1]]) == [1]
    end

    test :defdelegate_with_appended_handle do
      assert map([1], fn(x) -> x + 1 end) == [2]
    end
  end

  defmodule PipelineOp do
    use ExUnit.Case, async: true

    test :simple do
      assert [1,[2],3] /> List.flatten == [1,2,3]
    end

    test :nested do
      assert [1,[2],3] /> List.flatten /> Enum.map(&1 * 2) == [2,4,6]
    end

    test :local do
      assert [1,[2],3] /> List.flatten /> local == [2,4,6]
    end

    test :map do
      assert Enum.map([1,2,3], &1 /> twice /> twice) == [4,8,12]
    end

    test :atom do
      assert __MODULE__ /> :constant == 13
    end

    def constant, do: 13

    defp twice(a), do: a * 2

    defp local(list) do
      Enum.map(list, &1 * 2)
    end
  end

  defmodule MatchOp do
    use ExUnit.Case, async: true

    test :match do
      assert "abcd" =~ %r/c(d)/
      refute "abcd" =~ %r/e/
    end
  end

  defmodule InOp do
    use ExUnit.Case

    test :in do
      assert x(1)
      refute x(4)
      refute x([])
    end

    defp x(value) when value in [1,2,3], do: true
    defp x(_),                           do: false
  end

  defmodule Bang do
    use ExUnit.Case

    test :bang do
      assert bang(1)     == :truthy
      assert bang(true)  == :truthy
      assert bang(nil)   == :falsy
      assert bang(false) == :falsy
    end

    test :bangbang do
      assert bangbang(1)     == :truthy
      assert bangbang(true)  == :truthy
      assert bangbang(nil)   == :falsy
      assert bangbang(false) == :falsy
    end

    defp bangbang(value) when !!value, do: :truthy
    defp bangbang(_), do: :falsy

    defp bang(value) when !value, do: :falsy
    defp bang(_), do: :truthy
  end

  defmodule Destructure do
    use ExUnit.Case, async: true

    test :less do
      destructure [x,y,z], [1,2,3,4,5]
      assert x == 1
      assert y == 2
      assert z == 3
    end

    test :more do
      destructure [a,b,c,d,e], [1,2,3]
      assert a == 1
      assert b == 2
      assert c == 3
      assert d == nil
      assert e == nil
    end

    test :equal do
      destructure [a,b,c], [1,2,3]
      assert a == 1
      assert b == 2
      assert c == 3
    end

    test :none do
      destructure [a,b,c], []
      assert a == nil
      assert b == nil
      assert c == nil
    end

    test :match do
      destructure [1,b,_], [1,2,3]
      assert b == 2
    end

    test :nil do
      destructure [a,b,c], a_nil
      assert a == nil
      assert b == nil
      assert c == nil
    end

    test :invalid_match do
      a = 3
      assert_raise CaseClauseError, fn ->
        destructure [^a,b,c], a_list
      end
    end

    defp a_list, do: [1,2,3]
    defp a_nil, do: nil
  end
end