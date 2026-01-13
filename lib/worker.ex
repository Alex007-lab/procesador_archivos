# Define el módulo Worker para procesamiento paralelo de archivos
defmodule ProcesadorArchivos.Worker do
  @moduledoc """
  Worker process for parallel file processing.

  Este módulo implementa un proceso worker que puede ejecutarse en paralelo
  para procesar archivos individuales. Cada worker corre en su propio proceso
  y comunica los resultados al coordinador principal.
  """

  # Función pública para iniciar un worker
  # file_path: Ruta del archivo a procesar
  # coordinator_pid: PID del proceso coordinador que recibirá los resultados
  def start(file_path, coordinator_pid) do
    # Crear un nuevo proceso (spawning) usando spawn/1
    # spawn/1: Crea un nuevo proceso que ejecuta la función anónima
    spawn(fn ->
      # Mostrar información del worker (para depuración)
      # inspect(self()): Obtiene y convierte el PID a string legible
      IO.puts("Worker #{inspect(self())} started for #{Path.basename(file_path)}")

      # Procesar el archivo llamando a la función privada
      result = process_file(file_path)

      # Enviar resultado al coordinador usando send/2
      # send/2: Envía un mensaje asíncrono al proceso con PID coordinator_pid
      # El mensaje es una tupla con 4 elementos:
      #   :result - Identificador del tipo de mensaje
      #   self() - PID del worker que envía el resultado (para identificación)
      #   file_path - Ruta original del archivo procesado
      #   result - Resultado del procesamiento (mapa con métricas)
      send(coordinator_pid, {:result, self(), file_path, result})

      # Esperar confirmación (acknowledgement) del coordinador
      # receive: Bloquea el proceso hasta recibir un mensaje que coincida con el patrón
      receive do
        # Patrón: recibe mensaje {:ack, ^coordinator_pid}
        # ^coordinator_pid: Verifica que el PID sea exactamente el mismo coordinador
        # (sin ^ sería pattern matching que asigna el valor a una variable)
        {:ack, ^coordinator_pid} ->
          # Confirmación recibida, worker puede terminar normalmente
          IO.puts("Worker #{inspect(self())} finished")
          :ok  # Valor de retorno de la función anónima
      after
        # Bloque after: Timeout si no se recibe mensaje en el tiempo especificado
        5000 -> # Timeout de 5 segundos (5000 milisegundos)
          # Si pasa 5 segundos sin recibir confirmación, el worker timeout
          IO.puts("Worker #{inspect(self())} timeout")
          # La función termina sin valor de retorno específico (retorna :timeout implícitamente)
      end
    end)
    # spawn/1 retorna inmediatamente el PID del nuevo proceso worker
    # Mientras el worker ejecuta la función anónima en segundo plano
  end

  # Función privada que procesa un archivo individual
  # Decide qué parser usar basado en la extensión del archivo
  defp process_file(file_path) do
    # Usa pattern matching en la extensión del archivo
    case Path.extname(file_path) do
      # Caso 1: Archivo CSV
      ".csv" ->
        # Llama al parser CSV que debe retornar {:ok, metrics} o {:error, reason}
        case CsvParser.process(file_path) do
          # Éxito: se procesó correctamente
          {:ok, metrics} ->
            # Combinar métricas específicas del parser con metadatos del worker
            # Map.merge/2: Combina dos mapas (las métricas del parser + metadatos)
            Map.merge(metrics, %{
              type: :csv,                     # Tipo de archivo como átomo
              status: :success,               # Estado del procesamiento
              file_name: Path.basename(file_path),  # Solo nombre, sin ruta completa
              processed_by: inspect(self())   # PID del worker para trazabilidad
            })

          # Error: falló el procesamiento
          {:error, reason} ->
            # Retorna mapa de error con estructura consistente
            %{
              type: :csv,
              status: :error,
              file_name: Path.basename(file_path),
              error: reason,                  # Razón del error del parser
              processed_by: inspect(self())
            }
        end

      # Caso 2: Archivo JSON (estructura similar a CSV)
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

      # Caso 3: Archivo LOG (estructura similar)
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

      # Caso 4: Extensión no soportada
      _ ->
        # Retorna error para tipo de archivo desconocido
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
