defmodule ProcesadorArchivos.Coordinator do
  @moduledoc """
  Coordinador de procesos para procesamiento paralelo.
  Administra workers y recolecta resultados.
  """

  def start(files, show_progress \\ true) do
    # PID del proceso actual (coordinador)
    coordinator_pid = self()

    # Crear un worker para cada archivo
    # Esto muestra claramente el spawning de procesos
    pids = Enum.map(files, fn file_path ->
      ProcesadorArchivos.Worker.start(file_path, coordinator_pid)
    end)

    # Mostrar progreso inicial
    if show_progress do
      IO.puts("Starting #{length(files)} worker processes...")
      IO.puts("Workers PIDs: #{inspect(pids)}")
    end

    # Recolectar resultados de todos los workers
    results = collect_results(files, length(files), show_progress)

    # Convertir resultados a mapa para compatibilidad
    Enum.zip(files, results)
    |> Enum.into(%{})
  end

  # Función privada para recolectar resultados
  defp collect_results(_files, total_count, show_progress) do
    Enum.map(1..total_count, fn index ->
      receive do
        {:result, worker_pid, file_path, result} ->
          # Enviar confirmación al worker
          send(worker_pid, {:ack, self()})

          # Mostrar progreso
          if show_progress do
            IO.puts("[#{index}/#{total_count}] #{Path.basename(file_path)} processed by #{inspect(worker_pid)}")
          end

          result

        # Manejar timeout después de 15 segundos
        after 15_000 ->
          if show_progress do
            IO.puts("[#{index}/#{total_count}]Timeout waiting for worker")
          end
          %{status: :error, error: "Worker timeout"}
      end
    end)
  end
end
