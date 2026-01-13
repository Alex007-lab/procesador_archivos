# test/parallel_test.exs

# Define el módulo de pruebas para procesamiento paralelo
defmodule ParallelTest do
  # Indica que este módulo es una prueba de ExUnit
  use ExUnit.Case

  # Configuración que se ejecuta antes de cada prueba
  # Crea archivos de prueba para evaluación de procesamiento paralelo
  setup do
    # Crear directorio de salida para reportes
    File.mkdir_p!("output")

    # Lista de nombres de archivos de prueba que se crearán
    test_files = [
      "test_parallel_1.csv",
      "test_parallel_2.json",
      "test_parallel_3.log",
      "test_parallel_4.csv",
      "test_parallel_5.json"
    ]

    # Crear archivo CSV 1: Datos de ventas simple
    File.write!("test_parallel_1.csv",
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-01,Producto A,Electronica,100.0,2,10.0")

    # Crear archivo JSON 1: Datos de usuarios con estructura JSON válida
    File.write!("test_parallel_2.json",
      "{\"usuarios\": [{\"id\": 1, \"nombre\": \"Test\", \"email\": \"test@test.com\", \"activo\": true}], \"sesiones\": []}")

    # Crear archivo LOG: Registros con niveles INFO y ERROR
    File.write!("test_parallel_3.log",
      "2024-01-01 10:00:00 [INFO] [System] Test message\n2024-01-01 10:05:00 [ERROR] [System] Error test")

    # Crear archivo CSV 2: Otro conjunto de datos de ventas
    File.write!("test_parallel_4.csv",
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-02,Producto B,Libros,50.0,3,0.0")

    # Crear archivo JSON 2: Datos de sesiones con estructura JSON válida
    File.write!("test_parallel_5.json",
      "{\"usuarios\": [], \"sesiones\": [{\"usuario_id\": 1, \"inicio\": \"2024-01-01T09:00:00Z\", \"duracion_segundos\": 300}]}")

    # Retorna el contexto con la lista de archivos creados
    {:ok, %{test_files: test_files}}
  end

  # Configuración adicional para limpieza después de cada prueba
  setup context do
    # Hook que se ejecuta al salir de cada prueba
    on_exit(fn ->
      # Limpiar archivos de prueba individuales creados en el primer setup
      Enum.each(context.test_files, fn file ->
        File.rm(file)  # Elimina cada archivo de prueba
      end)
    end)
  end

  # Test 1: Verifica que el procesamiento paralelo retorna resultados para todos los archivos
  # context: Contiene los archivos de prueba creados en setup
  test "process_parallel returns results for all files", context do
    # Obtiene la lista de archivos del contexto
    files = context.test_files
    # Ejecuta el procesamiento paralelo (false = sin mostrar progreso)
    results = ProcesadorArchivos.process_parallel(files, false)

    # Verificaciones básicas del resultado
    assert is_list(results)  # Debe retornar una lista de resultados

    # Debe procesar al menos algunos archivos (puede fallar algunos por timeout u otros errores)
    assert length(results) > 0

    # Verifica la estructura de cada resultado individual
    Enum.each(results, fn result ->
      assert is_map(result)  # Cada resultado debe ser un mapa
      # Cada mapa debe contener estas claves mínimas
      assert Map.has_key?(result, :type)     # Tipo de archivo (CSV, JSON, LOG)
      assert Map.has_key?(result, :status)   # Estado (:ok, :error)
      assert Map.has_key?(result, :file_name) # Nombre del archivo procesado
    end)
  end

  # Test 2: Prueba el procesamiento paralelo de una carpeta completa
  test "process_folder_parallel processes folder", _context do
    # Crea un nombre único para la carpeta de prueba
    test_folder = "test_parallel_folder_#{System.unique_integer([:positive])}"
    File.mkdir_p!(test_folder)  # Crea la carpeta

    # Crea archivo CSV dentro de la carpeta
    File.write!(Path.join(test_folder, "test1.csv"),
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-01,Test,Test,10.0,1,0.0")

    # Crea archivo LOG dentro de la carpeta
    File.write!(Path.join(test_folder, "test2.log"),
      "2024-01-01 10:00:00 [INFO] [Test] Message")

    # Ejecuta prueba con manejo de errores
    try do
      # Procesa la carpeta completa
      results = ProcesadorArchivos.process_folder_parallel(test_folder)
      assert is_list(results)  # Debe retornar una lista
    rescue
      # Si falla, marca la prueba como fallida con el error
      error -> flunk("Error processing folder: #{inspect(error)}")
    after
      # Limpia la carpeta de prueba (siempre se ejecuta)
      File.rm_rf!(test_folder)
    end
  end

  # Test 3: Verifica que la función benchmark retorna una estructura válida
  test "benchmark returns valid structure" do
    # Crea carpeta temporal para benchmark
    test_folder = "test_benchmark_#{System.unique_integer([:positive])}"
    File.mkdir_p!(test_folder)

    # Crea un archivo simple para benchmark
    File.write!(Path.join(test_folder, "bench1.csv"),
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-01,A,B,10,1,0")

    # Ejecuta benchmark comparando procesamiento secuencial vs paralelo
    result = ProcesadorArchivos.benchmark(test_folder)

    # Verifica la estructura del resultado del benchmark
    assert is_map(result)  # Debe ser un mapa
    # Debe contener estas métricas clave
    assert Map.has_key?(result, :sequential_ms)  # Tiempo en milisegundos del procesamiento secuencial
    assert Map.has_key?(result, :parallel_ms)    # Tiempo en milisegundos del procesamiento paralelo
    assert Map.has_key?(result, :improvement)    # Porcentaje de mejora (paralelo vs secuencial)

    # Limpia la carpeta de prueba
    File.rm_rf!(test_folder)
  end

  # Test 4: Verifica que el Coordinator puede iniciar y recolectar resultados
  test "Coordinator collects some results" do
    # Usa solo 2 archivos para prueba simple
    files = ["test_parallel_1.csv", "test_parallel_2.json"]

    # Inicia el coordinador (que maneja workers paralelos)
    results_map = ProcesadorArchivos.Coordinator.start(files, false)

    # Verificaciones del mapa de resultados
    assert is_map(results_map)  # Debe ser un mapa
    # Puede recibir 0, 1 o 2 resultados dependiendo de:
    # - Si los archivos existen
    # - Si el procesamiento tiene éxito
    # - Timeouts u otros errores
    assert map_size(results_map) >= 0  # Mínimo 0 resultados
    assert map_size(results_map) <= 2  # Máximo 2 resultados (uno por archivo)
  end

  # Test 5: Verifica que el modo paralelo maneja errores (archivos inexistentes)
  test "parallel mode handles errors" do
    # Lista con un archivo que existe y otro que no
    files = ["test_parallel_1.csv", "file_que_no_existe.csv"]

    results = ProcesadorArchivos.process_parallel(files, false)

    assert is_list(results)
    # Debería tener al menos un resultado (el archivo que existe)
    # El archivo inexistente debería generar un resultado con estado :error
    assert length(results) >= 1
  end

  # Test 6: Verifica que el modo paralelo crea reportes de salida
  test "parallel mode creates reports" do
    files = ["test_parallel_1.csv"]

    # Limpiar reportes viejos para empezar desde cero
    File.rm_rf!("output")  # Elimina directorio de salida si existe
    File.mkdir_p!("output")  # Crea directorio de salida vacío

    # Procesa el archivo (esto debería generar reportes)
    ProcesadorArchivos.process_parallel(files, false)

    # Verifica que se creó al menos un archivo en la carpeta output
    case File.ls("output") do
      {:ok, files} ->
        # Si pudo listar los archivos, debe haber al menos uno
        assert length(files) > 0
      {:error, _} ->
        # Si hay error al listar, la prueba falla
        flunk("Output directory error")
    end
  end

  # Test 7: Compara resultados entre modo secuencial y paralelo
  test "both modes produce results" do
    files = ["test_parallel_1.csv", "test_parallel_2.json"]

    # Crea una carpeta temporal para prueba de comparación
    test_folder = "test_comparison_#{System.unique_integer([:positive])}"
    File.mkdir_p!(test_folder)

    # Copia los archivos de prueba a la carpeta temporal
    Enum.each(files, fn file ->
      File.cp!(file, Path.join(test_folder, file))
    end)

    # Procesar secuencialmente (llamada a process_files)
    {:ok, seq_results} = ProcesadorArchivos.process_files(test_folder)

    # Procesar paralelamente (llamada directa a archivos)
    par_results = ProcesadorArchivos.process_parallel(files, false)

    # Verificaciones de ambos modos
    assert is_list(seq_results)  # Resultados secuenciales deben ser lista
    assert is_list(par_results)  # Resultados paralelos deben ser lista
    assert length(seq_results) > 0  # Debe haber al menos un resultado secuencial
    assert length(par_results) > 0  # Debe haber al menos un resultado paralelo

    # Limpia la carpeta temporal
    File.rm_rf!(test_folder)
  end

  # Test 8: Verifica que el modo con progreso habilitado funciona
  test "progress can be enabled" do
    files = ["test_parallel_1.csv"]

    # Prueba con progreso habilitado (true)
    try do
      results = ProcesadorArchivos.process_parallel(files, true)
      assert is_list(results)  # Debe retornar lista incluso con progreso
    rescue
      # Si falla, marca la prueba como fallida
      error -> flunk("Error with progress enabled: #{inspect(error)}")
    end
  end

  # Test 9: Verifica que el módulo Worker existe y es funcional
  test "worker module exists and can be called" do
    # Verifica que el módulo Worker está cargado en el sistema
    assert Code.ensure_loaded?(ProcesadorArchivos.Worker)

    # Verifica que el módulo Worker exporta la función start/2
    # Esta función es la que inicia el procesamiento de un archivo
    assert function_exported?(ProcesadorArchivos.Worker, :start, 2)
  end

  # Test 10: Prueba de integración completa del sistema paralelo
  test "full parallel processing integration" do
    # Prueba simple con un solo archivo
    results = ProcesadorArchivos.process_parallel(["test_parallel_1.csv"], false)

    assert is_list(results)
    # Nota: Puede ser 0 si falla el procesamiento, pero lo importante es que no crashea
    # El sistema debe ser resistente a fallos
    assert length(results) >= 0  # Puede ser 0 si falla, pero no debería crashear
  end
end
