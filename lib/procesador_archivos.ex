defmodule ProcesadorArchivos do
  # Documentación del módulo principal
  @moduledoc """
  Main module for file processing.
  Supports both sequential (Delivery 1) and parallel (Delivery 2) modes.
  """

  # ============================================================================
  # FUNCIONES DE LA ENTREGA 1 (PROCESAMIENTO SECUENCIAL)
  # ============================================================================

  # Función principal pública para procesar archivos en modo secuencial
  # Tiene valor por defecto para folder: "data/valid"
  def process_files(folder \\ "data/valid") do
    # Crea separador visual de 50 signos "="
    separator = String.duplicate("=", 50)
    # Imprime encabezado con separadores
    IO.puts(separator)
    IO.puts("FILE PROCESSOR - SEQUENTIAL MODE")
    IO.puts(separator)

    # Captura tiempo inicial en milisegundos
    # :os.system_time/1 obtiene tiempo del sistema con precisión
    start_time = :os.system_time(:millisecond)

    # Verifica si la carpeta existe usando File.dir?/1
    if File.dir?(folder) do
      IO.puts("Processing folder: #{folder}")
      # Llama a función privada para procesar la carpeta
      process_folder(folder, start_time)
    else
      IO.puts("ERROR: Folder '#{folder}' not found")
      {:error, "Folder not found"}
    end
  end

  # Función privada para procesar carpeta en modo secuencial
  defp process_folder(folder, start_time) do
    # Lista archivos en la carpeta
    # File.ls/1 retorna {:ok, lista_archivos} o {:error, razón}
    case File.ls(folder) do
      {:ok, files} ->
        IO.puts("Found #{length(files)} files")

        # Procesa cada archivo secuencialmente usando Enum.map/2
        # Para cada nombre de archivo, llama a process_file/1
        results =
          Enum.map(files, fn file_name ->
            # Construye ruta completa uniendo carpeta y nombre
            file_path = Path.join(folder, file_name)
            process_file(file_path)
          end)

        # Calcula tiempo total de procesamiento
        end_time = :os.system_time(:millisecond)
        total_time = end_time - start_time

        # Crea reporte con resultados
        create_report(results, total_time, folder, :sequential)
        {:ok, results}

      {:error, reason} ->
        IO.puts("ERROR reading folder: #{reason}")
        {:error, reason}
    end
  end

  # Procesa un archivo individual basado en su extensión
  defp process_file(file_path) do
    # Extrae solo el nombre del archivo sin la ruta
    file_name = Path.basename(file_path)
    IO.puts("Processing: #{file_name}")

    # Obtiene extensión del archivo usando Path.extname/1
    case Path.extname(file_path) do
      # Si es .csv, llama al parser CSV
      ".csv" ->
        process_csv(file_path)

      # Si es .json, llama al parser JSON
      ".json" ->
        process_json(file_path)

      # Si es .log, llama al parser LOG
      ".log" ->
        process_log(file_path)

      # Para cualquier otra extensión, retorna error
      _ ->
        IO.puts("  ERROR: Unsupported file type")

        %{
          type: :unknown,
          file_name: file_name,
          status: :error,
          error: "Unsupported file type"
        }
    end
  end

  # Procesa archivo CSV usando CsvParser
  def process_csv(file_path) do
    # Llama a CsvParser.process/1 que retorna {:ok, metrics} o {:error, reason}
    case CsvParser.process(file_path) do
      {:ok, metrics} ->
        IO.puts("  OK: CSV processed - #{metrics.valid_records} valid records")
        # Combina métricas con información adicional
        Map.merge(metrics, %{type: :csv, status: :success})

      {:error, reason} ->
        IO.puts("  ERROR: #{reason}")
        # Retorna estructura de error estandarizada
        %{
          type: :csv,
          file_name: Path.basename(file_path),
          status: :error,
          error: reason
        }
    end
  end

  # Procesa archivo JSON usando JsonParser (similar a CSV)
  defp process_json(file_path) do
    case JsonParser.process(file_path) do
      {:ok, metrics} ->
        IO.puts(
          "  OK: JSON processed - #{metrics.total_users} users, #{metrics.active_users} active"
        )

        Map.merge(metrics, %{type: :json, status: :success})

      {:error, reason} ->
        IO.puts("  ERROR: #{reason}")

        %{
          type: :json,
          file_name: Path.basename(file_path),
          status: :error,
          error: reason
        }
    end
  end

  # Procesa archivo LOG usando LogParser (similar a los anteriores)
  defp process_log(file_path) do
    case LogParser.process(file_path) do
      {:ok, metrics} ->
        IO.puts("  OK: LOG processed - #{metrics.total_lines} lines, #{metrics.error} errors")

        Map.merge(metrics, %{type: :log, status: :success})

      {:error, reason} ->
        IO.puts("  ERROR: #{reason}")

        %{
          type: :log,
          file_name: Path.basename(file_path),
          status: :error,
          error: reason
        }
    end
  end

  # ============================================================================
  # FUNCIONES NUEVAS PARA ENTREGA 2 (PROCESAMIENTO PARALELO)
  # ============================================================================

  # Función principal para procesamiento paralelo de archivos
  # Esta función usa los módulos Worker y Coordinator que ya creaste
  # @param files [List] Lista de rutas de archivos a procesar
  # @param show_progress [Boolean] Si muestra progreso en pantalla (default: true)
  # @return [List] Lista de resultados de todos los archivos procesados
  def process_parallel(files, show_progress \\ true) do
    # Mostramos un encabezado para indicar que estamos en modo paralelo
    separator = String.duplicate("=", 50)
    IO.puts(separator)
    IO.puts("FILE PROCESSOR - PARALLEL MODE")
    IO.puts(separator)

    start_time = :os.system_time(:millisecond)

    # Mostramos información sobre lo que vamos a procesar
    IO.puts("Starting parallel processing of #{length(files)} files...")
    IO.puts("Each file will be processed by a separate worker process.")

    # Iniciamos el coordinador que manejará todos los workers
    # Le pasamos la lista de archivos y si debe mostrar progreso
    # El coordinador retorna un mapa con los resultados
    results_map = ProcesadorArchivos.Coordinator.start(files, show_progress)

    # Calculamos cuánto tiempo tardó todo el procesamiento
    end_time = :os.system_time(:millisecond)
    total_time = end_time - start_time

    # Convertimos el mapa de resultados a una lista para ser compatible con el resto del código
    # Map.values toma todos los valores del mapa y los pone en una lista
    results_list = Map.values(results_map)

    # Mostramos un resumen del procesamiento
    IO.puts("\n#{separator}")
    IO.puts("PARALLEL PROCESSING COMPLETED")
    IO.puts("Total time: #{total_time} milliseconds")
    IO.puts("Files processed: #{length(results_list)}")
    IO.puts(separator)

    # Contamos cuántos archivos se procesaron exitosamente y cuántos con error
    successes =
      Enum.count(results_list, fn r ->
        r[:status] == :success || r.status == :success
      end)

    errors = length(results_list) - successes
    IO.puts("Successful: #{successes}, Errors: #{errors}")
    IO.puts(separator)

    # Creamos un reporte igual que en el modo secuencial, pero indicando que es paralelo
    # Le pasamos :parallel como último parámetro para que el reporte muestre el modo correcto
    create_report(results_list, total_time, "parallel processing", :parallel)

    # Devolvemos la lista de resultados para que el usuario los pueda usar si quiere
    results_list
  end

  # Función para procesar una carpeta completa en paralelo
  # Es similar a process_files pero usa el modo paralelo
  # @param folder [String] Ruta de la carpeta a procesar (default: "data/valid")
  # @return [List] Lista de resultados o {:error, reason} si hay error
  def process_folder_parallel(folder \\ "data/valid") do
    # Primero verificamos que la carpeta existe
    if File.dir?(folder) do
      # Obtenemos la lista de archivos en la carpeta
      case File.ls(folder) do
        {:ok, files} ->
          IO.puts("Found #{length(files)} files in #{folder}")

          # Convertimos los nombres de archivo a rutas completas
          # Path.join une el nombre de la carpeta con el nombre del archivo
          full_paths =
            Enum.map(files, fn file_name ->
              Path.join(folder, file_name)
            end)

          # Procesamos todos los archivos en paralelo
          process_parallel(full_paths)

        {:error, reason} ->
          IO.puts("ERROR reading folder: #{reason}")
          {:error, reason}
      end
    else
      IO.puts("ERROR: Folder '#{folder}' not found")
      {:error, "Folder not found"}
    end
  end

  # Función para comparar el rendimiento entre modo secuencial y paralelo
  # Esta es una función muy útil para ver cuánto más rápido es el modo paralelo
  # @param folder [String] Carpeta con archivos para hacer la comparación
  # @return [Map] Mapa con tiempos de ejecución y factor de mejora
  def benchmark(folder \\ "data/valid") do
    separator = String.duplicate("=", 50)
    IO.puts("\n#{separator}")
    IO.puts("BENCHMARK: SEQUENTIAL vs PARALLEL")
    IO.puts(separator)

    # Primero verificamos que la carpeta existe
    if File.dir?(folder) do
      # Obtenemos la lista de archivos en la carpeta
      case File.ls(folder) do
        {:ok, files} ->
          # Creamos las rutas completas a los archivos
          full_paths =
            Enum.map(files, fn file_name ->
              Path.join(folder, file_name)
            end)

          IO.puts("Testing with #{length(files)} files from #{folder}")

          # ============ MODO SECUENCIAL ============
          IO.puts("\n1. Running SEQUENTIAL mode...")

          # Medimos el tiempo del modo secuencial
          # :timer.tc mide el tiempo que tarda en ejecutarse una función
          # Devuelve una tupla {tiempo_en_microsegundos, resultado}
          {seq_time_microseconds, _seq_results} =
            :timer.tc(fn ->
              # Usamos Enum.map para procesar secuencialmente (como en Entrega 1)
              # &process_file/1 es una función anónima que llama a process_file con cada archivo
              Enum.map(full_paths, &process_file/1)
            end)

          # Convertimos de microsegundos a milisegundos (dividiendo entre 1000)
          seq_time_ms = div(seq_time_microseconds, 1000)
          IO.puts("   Sequential time: #{seq_time_ms} ms")

          # ============ MODO PARALELO ============
          IO.puts("\n2. Running PARALLEL mode...")

          # Medimos el tiempo del modo paralelo
          {par_time_microseconds, _par_results} =
            :timer.tc(fn ->
              # Usamos nuestra nueva función de procesamiento paralelo
              # Pasamos false para no mostrar progreso durante el benchmark
              process_parallel(full_paths, false)
            end)

          # Convertimos a milisegundos
          par_time_ms = div(par_time_microseconds, 1000)
          IO.puts("   Parallel time: #{par_time_ms} ms")

          # ============ CÁLCULO DE MEJORA ============
          # Calculamos cuántas veces más rápido es el modo paralelo
          improvement =
            if par_time_ms > 0 do
              # Dividimos el tiempo secuencial entre el tiempo paralelo
              # Ejemplo: si secuencial tarda 1000 ms y paralelo 250 ms, 1000/250 = 4x más rápido
              Float.round(seq_time_ms / par_time_ms, 2)
            else
              # Para evitar división por cero si el tiempo paralelo fuera 0 (muy improbable)
              0.0
            end

          # También calculamos el porcentaje de mejora
          percent_faster =
            if seq_time_ms > 0 do
              Float.round((1 - par_time_ms / seq_time_ms) * 100, 1)
            else
              0.0
            end

          # ============ MOSTRAR RESULTADOS ============
          IO.puts("\n#{separator}")
          IO.puts("RESULTS:")
          IO.puts("  Sequential: #{seq_time_ms} ms")
          IO.puts("  Parallel:   #{par_time_ms} ms")
          IO.puts("  Parallel is #{improvement}x faster!")
          IO.puts("  That's #{percent_faster}% faster!")
          IO.puts(separator)

          # Devolvemos los resultados en un mapa para que puedan ser usados
          %{
            sequential_ms: seq_time_ms,
            parallel_ms: par_time_ms,
            improvement: improvement,
            percent_faster: percent_faster,
            files_count: length(files)
          }

        {:error, reason} ->
          IO.puts("ERROR reading folder: #{reason}")
          {:error, reason}
      end
    else
      IO.puts("ERROR: Folder '#{folder}' not found")
      {:error, "Folder not found"}
    end
  end

  # ============================================================================
  # FUNCIONES DE REPORTE (MODIFICADAS PARA SOPORTAR AMBOS MODOS)
  # ============================================================================

  # Crea archivo de reporte con resultados del procesamiento
  # Ahora acepta un parámetro adicional para indicar si es modo paralelo
  # @param results [List] Lista de resultados del procesamiento
  # @param total_time [Integer] Tiempo total en milisegundos
  # @param folder [String] Ruta de la carpeta procesada
  # @param mode [Atom] :sequential o :parallel (default: :sequential)
  # @private
  defp create_report(results, total_time, folder, mode) do
    timestamp =
      DateTime.utc_now() |> DateTime.to_string() |> String.replace(":", "-")

    mode_str = if mode == :parallel, do: "parallel", else: "sequential"
    report_file = "output/report_#{mode_str}_#{timestamp}.txt"

    File.mkdir_p!("output")
    report_content = generate_report_content(results, total_time, folder, mode)
    File.write!(report_file, report_content)

    separator = String.duplicate("=", 50)
    IO.puts("\n#{separator}")
    IO.puts("Report saved to: #{report_file}")
    IO.puts(separator)
  end

  # Genera contenido textual del reporte
  # Ahora incluye información sobre el modo de procesamiento
  # @param results [List] Lista de resultados
  # @param total_time [Integer] Tiempo total en ms
  # @param folder [String] Carpeta procesada
  # @param mode [Atom] Modo de procesamiento (:sequential o :parallel)
  # @return [String] Contenido completo del reporte
  # @private
  defp generate_report_content(results, total_time, folder, mode) do
    # Cuenta archivos exitosos (status: :success)
    successes = Enum.count(results, &(&1[:status] == :success))
    # Cuenta archivos con error (status: :error)
    errors = Enum.count(results, &(&1[:status] == :error))

    # Filtra resultados por tipo de archivo
    csv_results = Enum.filter(results, &(&1[:type] == :csv))
    json_results = Enum.filter(results, &(&1[:type] == :json))
    log_results = Enum.filter(results, &(&1[:type] == :log))

    # Calcula tasa de éxito como porcentaje
    success_rate =
      if length(results) > 0 do
        # Fórmula: (éxitos / total) * 100
        Float.round(successes / length(results) * 100, 1)
      else
        0.0
      end

    # Determina el texto del modo de procesamiento
    mode_text =
      if mode == :parallel do
        "Paralelo (usando #{length(results)} procesos workers)"
      else
        "Secuencial"
      end

    # Construye líneas del reporte como lista de strings
    lines = [
      "================================================================================\n" <>
        "                    REPORTE DE PROCESAMIENTO DE ARCHIVOS\n" <>
        "================================================================================\n",
      "Fecha de generación: #{DateTime.utc_now()}",
      "Directorio procesado: #{folder}",
      "Modo de procesamiento: #{mode_text}\n",
      "--------------------------------------------------------------------------------\n" <>
        "RESUMEN EJECUTIVO\n" <>
        "--------------------------------------------------------------------------------",
      "Total de archivos procesados: #{length(results)}",
      "  - Archivos CSV: #{length(csv_results)}",
      "  - Archivos JSON: #{length(json_results)}",
      "  - Archivos LOG: #{length(log_results)}",
      "",
      "Tiempo total de procesamiento: #{total_time} ms",
      "Archivos exitosos: #{successes}",
      "Archivos con errores: #{errors}",
      "Tasa de éxito: #{success_rate}%",
      ""
    ]

    # Agrega sección de métricas para cada tipo de archivo
    lines = lines ++ generate_metrics_section("CSV", csv_results)
    lines = lines ++ generate_metrics_section("JSON", json_results)
    lines = lines ++ generate_metrics_section("LOG", log_results)

    # Si hay errores, agrega sección de detalles de errores
    error_details =
      if errors > 0 do
        error_lines = [
          "\n--------------------------------------------------------------------------------\n" <>
            "ERRORES DETECTADOS\n" <>
            "--------------------------------------------------------------------------------"
        ]

        # Genera lista de descripciones de errores
        details =
          Enum.map(results, fn result ->
            if result[:status] == :error do
              "✗ #{result[:file_name]}: #{result[:error]}"
            end
          end)
          # Filtra nils (resultados exitosos)
          |> Enum.filter(& &1)

        error_lines ++ details
      else
        # Si no hay errores, lista vacía
        []
      end

    # Combina todas las secciones del reporte
    all_lines =
      lines ++
        error_details ++
        [
          "\n================================================================================\n" <>
            "                           FIN DEL REPORTE\n" <>
            "================================================================================"
        ]

    # Une todas las líneas con saltos de línea
    Enum.join(all_lines, "\n")
  end

  # Genera sección de métricas para un tipo específico de archivo
  # @param type [String] Tipo de archivo ("CSV", "JSON", "LOG")
  # @param results [List] Lista de resultados de ese tipo
  # @return [List] Lista de strings con las métricas formateadas
  # @private
  defp generate_metrics_section(type, results) do
    # Si no hay resultados de este tipo, retorna lista vacía
    if Enum.empty?(results) do
      []
    else
      # Encabezado de sección
      section = [
        "\n--------------------------------------------------------------------------------\n" <>
          "MÉTRICAS DE ARCHIVOS #{String.upcase(type)}\n" <>
          "--------------------------------------------------------------------------------"
      ]

      # Genera métricas para cada resultado individual
      metrics =
        Enum.map(results, fn result ->
          case result[:status] do
            :success ->
              # Llama a función específica según el tipo
              generate_success_metrics(type, result)

            :error ->
              # Formato para errores
              "\n[#{result.file_name}]" <>
                "\n  • ERROR: #{result.error}"

            _ ->
              # Estado desconocido (no debería ocurrir)
              "\n[#{result.file_name}]" <>
                "\n  • Estado desconocido"
          end
        end)

      # Combina encabezado con métricas
      section ++ metrics
    end
  end

  # Genera formato específico para métricas exitosas de CSV
  # @param "CSV" [String] Tipo de archivo (siempre "CSV" para esta función)
  # @param result [Map] Resultado del procesamiento CSV
  # @return [String] String formateado con las métricas
  # @private
  defp generate_success_metrics("CSV", result) do
    # Formatea número con 2 decimales usando función de Erlang
    "\n[#{result.file_name}]" <>
      "\n  • Registros válidos: #{result.valid_records}" <>
      "\n  • Productos únicos: #{result.unique_products}" <>
      "\n  • Ventas totales: $#{:erlang.float_to_binary(result.total_sales, decimals: 2)}"
  end

  # Genera formato específico para métricas exitosas de JSON
  # @param "JSON" [String] Tipo de archivo (siempre "JSON" para esta función)
  # @param result [Map] Resultado del procesamiento JSON
  # @return [String] String formateado con las métricas
  # @private
  defp generate_success_metrics("JSON", result) do
    "\n[#{result.file_name}]" <>
      "\n  - Usuarios totales: #{result.total_users}" <>
      "\n  - Usuarios activos: #{result.active_users}" <>
      "\n  -  Sesiones totales: #{result.total_sessions}"
  end

  # Genera formato específico para métricas exitosas de LOG
  # @param "LOG" [String] Tipo de archivo (siempre "LOG" para esta función)
  # @param result [Map] Resultado del procesamiento LOG
  # @return [String] String formateado con las métricas
  # @private
  defp generate_success_metrics("LOG", result) do
    "\n[#{result.file_name}]" <>
      "\n  - Líneas totales: #{result.total_lines}" <>
      "\n  - Distribución: DEBUG(#{result.debug}), INFO(#{result.info}), WARN(#{result.warn}), ERROR(#{result.error}), FATAL(#{result.fatal})"
  end
end
