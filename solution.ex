defmodule NonceFinder do
  @target_prefix "000000"
  @base_string "hello world "

  def simple_run(nonce) do
    data = @base_string <> Integer.to_string(nonce)
    hash = :crypto.hash(:sha256, data)
           |> Base.encode16(case: :lower)

    if String.starts_with?(hash, @target_prefix) do
      { nonce, hash }
    else
      simple_run(nonce + 1)
    end
  end

  def multi_run(threads_count) do
    parent = self()

    tasks =
      for thread_id <- 0..(threads_count - 1) do
        Task.async(fn -> worker(thread_id, threads_count, parent) end)
      end

    receive do
      {:nonce_found, nonce, hash} ->
        Enum.each(tasks, &Task.shutdown(&1, :brutal_kill))
        {:ok, nonce, hash}
    after
      60_000 -> # Timeout 60 sec
        Enum.each(tasks, &Task.shutdown(&1, :brutal_kill))
        {:error, :timeout}
    end
  end

  defp worker(start_nonce, step, parent) do
    Stream.iterate(start_nonce, &(&1 + step))
    |> Enum.each(fn nonce ->
      data = @base_string <> Integer.to_string(nonce)
      hash = :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)

      if String.starts_with?(hash, @target_prefix) do
        send(parent, {:nonce_found, nonce, hash})
        throw(:nonce_found)
      end
    end)

  rescue
    :nonce_found -> :ok
  end
end

{mks, {:ok, found, hash}} = :timer.tc(NonceFinder, :multi_run, [4])
IO.puts("(#{mks / 1000}ms) #{found}: #{hash}")
