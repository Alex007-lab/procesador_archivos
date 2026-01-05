defmodule ProcesadorArchivos.Worker do
  @moduledoc """
  Worker process for parallel file processing.
  """

  def start(file_path, coordinator_pid) do
    # Crear un nuevo proceso (spawning)
    spawn(fn ->
      # Mostrar información del worker (para depuración)
      IO.puts("Worker #{inspect(self())} started for #{Path.basename(file_path)}")

      # Procesar el archivo
      result = process_file(file_path)

      # Enviar resultado al coordinador
      send(coordinator_pid, {:result, self(), file_path, result})

      # Esperar confirmación del coordinador
      receive do
        {:ack, ^coordinator_pid} ->
          # Confirmación recibida, worker puede terminar
          IO.puts("Worker #{inspect(self())} finished")
          :ok
      after
        5000 -> # Timeout de 5 segundos
          IO.puts("Worker #{inspect(self())} timeout")
      end
    end)
  end

  defp process_file(file_path) do
    case Path.extname(file_path) do
      ".csv" ->
        case CsvParser.process(file_path) do
          {:ok, metrics} ->
            # Combinar métricas con información del archivo
            Map.merge(metrics, %{
              type: :csv,
              status: :success,
              file_name: Path.basename(file_path),
              processed_by: inspect(self())  # Para ver qué worker lo procesó
            })
          {:error, reason} ->
            %{
              type: :csv,
              status: :error,
              file_name: Path.basename(file_path),
              error: reason,
              processed_by: inspect(self())
            }
        end

      ".json" ->
        case JsonParser.process(file_path) do
          {:ok, metrics} ->
            Map.merge(metrics, %{
              type: :json,
              status: :success,
              file_name: Path.basename(file_path),
              processed_by: inspect(self())
            })
          {:error, reason} ->
            %{
              type: :json,
              status: :error,
              file_name: Path.basename(file_path),
              error: reason,
              processed_by: inspect(self())
            }
        end

      ".log" ->
        case LogParser.process(file_path) do
          {:ok, metrics} ->
            Map.merge(metrics, %{
              type: :log,
              status: :success,
              file_name: Path.basename(file_path),
              processed_by: inspect(self())
            })
          {:error, reason} ->
            %{
              type: :log,
              status: :error,
              file_name: Path.basename(file_path),
              error: reason,
              processed_by: inspect(self())
            }
        end

      _ ->
        %{
          type: :unknown,
          status: :error,
          file_name: Path.basename(file_path),
          error: "Unsupported file type",
          processed_by: inspect(self())
        }
    end
  end
end
