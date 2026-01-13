# lib/cli.ex - VERSIÓN 100% FUNCIONAL

# Define el módulo CLI (Command Line Interface) para el procesador de archivos
# Este módulo maneja la interacción desde la línea de comandos
defmodule ProcesadorArchivos.CLI do
  @moduledoc """
  Interfaz de línea de comandos para el procesador.

  Este módulo proporciona una interfaz de consola para ejecutar el procesador
  de archivos con diferentes opciones y modos de operación.
  """

  # Función principal que se llama al ejecutar el programa desde la línea de comandos
  # args: Lista de argumentos pasados al programa (ej: ["data/", "--mode", "parallel"])

  def main(args) do
    # Delega el procesamiento a la función privada process_args
    process_args(args)
  end

  # Función privada que procesa los argumentos de línea de comandos
  # Maneja el parsing de opciones y decide qué acción tomar
  defp process_args(args) do
    # Parseamos argumentos de forma SIMPLE usando OptionParser
    # OptionParser es una biblioteca estándar de Elixir para parsear argumentos CLI
    case OptionParser.parse(args,
      # switches: Define las opciones válidas con sus tipos
      switches: [
        help: :boolean,      # --help (booleano, no necesita valor)
        mode: :string,       # --mode MODE (necesita un valor string)
        timeout: :integer,   # --timeout MS (necesita un valor entero)
        retries: :integer,   # --retries N (necesita un valor entero)
        output: :string      # --output DIR (necesita un valor string)
      ],
      # aliases: Define versiones cortas de las opciones
      aliases: [
        h: :help,      # -h equivale a --help
        m: :mode,      # -m equivale a --mode
        t: :timeout,   # -t equivale a --timeout
        r: :retries,   # -r equivale a --retries
        o: :output     # -o equivale a --output
      ]
    ) do
      # Caso 1: El usuario pidió ayuda (--help o -h)
      # Pattern matching para detectar opción help: true
      {[help: true], _, _} ->
        show_help()          # Muestra mensaje de ayuda

      # Caso 2: No se proporcionaron archivos/directorios
      # Pattern matching: lista vacía en la segunda posición significa sin archivos
      {_, [], _} ->
        IO.puts("Error: Necesitas especificar un archivo o directorio")
        show_help()          # Muestra ayuda para guiar al usuario

      # Caso 3: Se proporcionaron archivos - ¡ESTA ES LA CLAVE!
      # Pattern matching: opts = opciones, files = lista de archivos
      {opts, files, _} when is_list(files) and length(files) > 0 ->
        # IMPORTANTE: opts es una LISTA (puede estar vacía)
        # Ejemplo: opts podría ser [mode: "parallel", timeout: 5000] o []

        # Convertimos a mapa ANTES de usar Map.get porque OptionParser retorna lista
        opts_map =
          case opts do
            [] -> %{}  # Si está vacía, creamos mapa vacío
            _ -> Enum.into(opts, %{})  # Convierte lista de tuplas a mapa
          end

        # AHORA SÍ podemos usar Map.get con el mapa
        # Configuración por defecto si no se especifican opciones
        config = %{
          mode: Map.get(opts_map, :mode, "parallel"),      # Modo por defecto: parallel
          timeout: Map.get(opts_map, :timeout, 5000),      # Timeout por defecto: 5000ms
          retries: Map.get(opts_map, :retries, 3),         # Reintentos por defecto: 3
          output_dir: Map.get(opts_map, :output, "output") # Salida por defecto: "output"
        }

        # Procesa los archivos con la configuración obtenida
        # hd(files) toma el primer archivo/directorio (solo procesa uno)
        process_files(files, config)

      # Caso 4: Error en el parsing (no debería pasar con OptionParser)
      # Fallback para cualquier otro caso no manejado
      _ ->
        IO.puts("Error en opciones")
        show_help()
    end
  end

  # Función que inicia el procesamiento de archivos
  # files: Lista de rutas (solo usa la primera)
  # config: Mapa con configuración (modo, timeout, etc.)
  defp process_files(files, config) do
    # Encabezado visual para la ejecución
    IO.puts("==========================================")
    IO.puts("Procesador de Archivos - Entrega 3")
    IO.puts("==========================================")
    IO.puts("Configuración: #{inspect(config)}")  # Muestra configuración
    IO.puts("")  # Línea en blanco

    # Toma el primer elemento de la lista de archivos
    # NOTA: Solo procesa un archivo/directorio a la vez
    path = hd(files)

    # Decide si es directorio o archivo individual
    if File.dir?(path) do
      process_directory(path, config)      # Es un directorio
    else
      process_single_file(path, config)    # Es un archivo individual
    end
  end

  # Procesa un directorio completo
  defp process_directory(dir, config) do
    IO.puts("Procesando directorio: #{dir}")
    IO.puts("Modo: #{config.mode}")

    # Verifica que el directorio existe
    unless File.dir?(dir) do
      IO.puts("Error: Directorio no existe")
      System.halt(1)  # Error si no existe
    end

    # Intenta listar los archivos del directorio
    case File.ls(dir) do
      {:ok, archivos} ->
        IO.puts("Encontrados #{length(archivos)} archivos")

        # Selecciona el modo de procesamiento basado en la configuración
        case config.mode do
          "sequential" ->
            # Modo secuencial: procesa archivos uno por uno
            ProcesadorArchivos.process_files_with_config(dir, config)

          "parallel" ->
            # Modo paralelo: procesa archivos concurrentemente
            ProcesadorArchivos.process_parallel_with_config(dir, config)

          "benchmark" ->
            # Modo benchmark: compara rendimiento secuencial vs paralelo
            ProcesadorArchivos.benchmark_with_config(dir, config)

          _ ->
            # Modo desconocido: usa paralelo por defecto
            IO.puts("Modo desconocido, usando paralelo")
            ProcesadorArchivos.process_parallel_with_config(dir, config)
        end

      {:error, razon} ->
        # Error al leer el directorio
        IO.puts("Error leyendo directorio: #{razon}")
        System.halt(1)
    end
  end

  # Procesa un archivo individual
  defp process_single_file(file, config) do
    IO.puts("Procesando archivo: #{file}")

    # Verifica que el archivo existe
    unless File.exists?(file) do
      IO.puts("Error: Archivo no existe")
      System.halt(1)
    end

    # Procesa el archivo con manejo de errores
    # Esta función debe retornar un mapa con resultados o {:error, mensaje}
    resultado = ProcesadorArchivos.procesar_con_manejo_errores(file, config)

    # Muestra los resultados
    IO.puts("")
    IO.puts("RESULTADO:")
    IO.puts("==========")

    # Pattern matching para diferentes formatos de resultado
    case resultado do
      # Caso: Resultado es un mapa con clave :estado
      %{estado: estado} ->
        IO.puts("Estado: #{estado}")

        # Muestra líneas procesadas si existen en el mapa
        if Map.has_key?(resultado, :lineas_procesadas) do
          IO.puts("Líneas procesadas: #{resultado.lineas_procesadas}")
        end

        # Muestra líneas con error si existen
        if Map.has_key?(resultado, :lineas_con_error) do
          IO.puts("Líneas con error: #{resultado.lineas_con_error}")
        end

        # Muestra errores detallados si existen
        if Map.has_key?(resultado, :errores) and length(resultado.errores) > 0 do
          IO.puts("Errores encontrados:")
          # Itera sobre la lista de errores
          Enum.each(resultado.errores, fn {linea, error} ->
            IO.puts("  Línea #{linea}: #{error}")
          end)
        end
    end
  end

  # Muestra el mensaje de ayuda con instrucciones de uso
  defp show_help do
    IO.puts("""
    USO: ./procesador_archivos [OPCIONES] ARCHIVO|DIRECTORIO

    Opciones:
      -h, --help      Muestra esta ayuda
      -m, --mode      Modo: sequential, parallel, benchmark (default: parallel)
      -t, --timeout   Timeout en milisegundos (default: 5000)
      -r, --retries   Reintentos (default: 3)
      -o, --output    Directorio de salida (default: output)

    Ejemplos:
      ./procesador_archivos data/valid
      ./procesador_archivos --mode sequential data/valid
      ./procesador_archivos data/error/ventas_corrupto.csv
    """)
  end
end
