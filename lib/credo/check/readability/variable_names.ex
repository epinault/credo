defmodule Credo.Check.Readability.VariableNames do
  @moduledoc """
  Variable names are always written in snake_case in Elixir.

      # snake_case:

      incoming_result = handle_incoming_message(message)

      # not snake_case

      incomingResult = handle_incoming_message(message)

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]
  @special_var_names [:__CALLER__, :__DIR__, :__ENV__, :__MODULE__]

  alias Credo.Code.Name

  use Credo.Check, base_priority: :high

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:=, _meta, [lhs, _rhs]} = ast, issues, issue_meta) do
    {ast, issues_for_lhs(lhs, issues, issue_meta)}
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  for op <- [:{}, :%{}, :^, :|, :<>] do
    defp issues_for_lhs({unquote(op), _meta, parameters}, issues, issue_meta) do
      issues_for_lhs(parameters, issues, issue_meta)
    end
  end
  defp issues_for_lhs({_name, _meta, nil} = value, issues, issue_meta) do
    case issue_for_name(value, issue_meta) do
      nil -> issues
      new_issue -> [new_issue | issues]
    end
  end
  defp issues_for_lhs(list, issues, issue_meta) when is_list(list) do
    Enum.reduce(list, issues, &issues_for_lhs(&1, &2, issue_meta))
  end
  defp issues_for_lhs(tuple, issues, issue_meta) when is_tuple(tuple) do
    Enum.reduce(tuple |> Tuple.to_list, issues, &issues_for_lhs(&1, &2, issue_meta))
  end
  defp issues_for_lhs(_, issues, _issue_meta) do
    issues
  end

  for name <- @special_var_names do
    defp issue_for_name({unquote(name), _, nil}, _), do: nil
  end
  defp issue_for_name({name, meta, nil}, issue_meta) do
    unless name |> to_string |> Name.snake_case? do
      issue_for(meta[:line], name, issue_meta)
    end
  end

  defp issue_for(line_no, trigger, issue_meta) do
    format_issue issue_meta,
      message: "Variable names should be written in snake_case.",
      trigger: trigger,
      line_no: line_no
  end
end