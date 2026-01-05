# File: lib/log_parser.ex
# Purpose: Simple log file parser - COMPLETE SIMPLIFIED VERSION

defmodule LogParser do
  # Documentación del módulo
  @moduledoc """
  Log file parser for system logs.
  Format: YYYY-MM-DD HH:MM:SS [LEVEL] [COMPONENT] message
  Levels: DEBUG, INFO, WARN, ERROR, FATAL
  """

  # Función principal para procesar archivos de log
  def process(file_path) do
    if File.exists?(file_path) do
      try do
        # Lee archivo y divide por líneas, eliminando líneas vacías
        # trim: true elimina strings vacíos del resultado
        lines = File.read!(file_path) |> String.split("\n", trim: true)

        # Inicializa contadores para todos los niveles de log
        # Mapa con claves atómicas y valores inicializados a 0
        stats = %{debug: 0, info: 0, warn: 0, error: 0, fatal: 0}

        # Procesa cada línea acumulando estadísticas
        # Enum.reduce/3 itera sobre líneas actualizando stats
        stats =
          Enum.reduce(lines, stats, fn line, acc ->
            # Para cada línea, llama a parse_log_line/2
            parse_log_line(line, acc)
          end)

        # Calcula métricas finales
        metrics = %{
          # Total de líneas en el archivo
          total_lines: length(lines),
          # Extrae cada contador del mapa stats
          debug: stats.debug,
          info: stats.info,
          warn: stats.warn,
          error: stats.error,
          fatal: stats.fatal,
          # Nombre del archivo
          file_name: Path.basename(file_path)
        }

        {:ok, metrics}
      rescue
        # Captura cualquier error durante el procesamiento
        error -> {:error, "Log parsing error: #{inspect(error)}"}
      end
    else
      {:error, "File not found: #{file_path}"}
    end
  end

  # Parsea una línea individual de log
  defp parse_log_line(line, stats) do
    # Busca patrón de nivel de log como [ERROR], [WARN], etc.
    # Regex.run/2 busca coincidencia con expresión regular
    # ~r/\[(\w+)\]/ busca texto entre corchetes con letras/números
    case Regex.run(~r/\[(\w+)\]/, line) do
      # Si encuentra patrón: [coincidencia_completa, nivel_capturado]
      [_, level] ->
        # Actualiza contadores basado en el nivel
        # String.upcase/1 convierte a mayúsculas para estandarizar
        update_stats(stats, String.upcase(level))

      # Si no encuentra patrón, retorna stats sin cambios
      nil ->
        stats
    end
  end

  # Actualiza contadores para cada nivel de log
  # Cada cláusula maneja un nivel específico
  defp update_stats(stats, "DEBUG"), do: %{stats | debug: stats.debug + 1}
  defp update_stats(stats, "INFO"), do: %{stats | info: stats.info + 1}
  defp update_stats(stats, "WARN"), do: %{stats | warn: stats.warn + 1}
  defp update_stats(stats, "ERROR"), do: %{stats | error: stats.error + 1}
  defp update_stats(stats, "FATAL"), do: %{stats | fatal: stats.fatal + 1}

  # Para cualquier otro nivel (no debería ocurrir), retorna stats sin cambios
  defp update_stats(stats, _), do: stats
end
