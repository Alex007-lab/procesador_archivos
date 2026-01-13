# test/error_handling_test.exs

# Define el módulo de pruebas para el manejo de errores
defmodule ErrorHandlingTest do
  # Indica que este módulo es una prueba de ExUnit
  use ExUnit.Case

  # Configuración que se ejecuta antes de cada prueba
  # Crea archivos de prueba con diferentes tipos de errores
  setup do
    # Crear directorio temporal para pruebas
    # Genera un nombre de directorio único con número aleatorio para evitar colisiones
    test_dir = "test_error_dir_#{:rand.uniform(10000)}"
    # Crea el directorio y todos los directorios padres necesarios
    File.mkdir_p!(test_dir)

    # Crear archivo CSV con errores
    # Contenido CSV con datos válidos e inválidos para probar el manejo de errores
    csv_content = """
    fecha,producto,categoria,precio_unitario,cantidad,descuento
    2024-01-01,Producto A,Electronica,100.0,2,10.0  # Línea válida
    2024-01-02,Producto B,Libros,INVALIDO,3,0.0     # Precio inválido (no numérico)
    2024-01-03,Producto C,Ropa,50.0,,5.0            # Cantidad vacía
    2024-01-04,Producto D,Juguetes,75.0,abc,20.0    # Cantidad no numérica
    2024-01-05,Producto E,Cocina,120.0,1,150.0      # Descuento mayor que precio
    """

    # Escribe el archivo CSV en el directorio temporal
    File.write!(Path.join(test_dir, "test_errors.csv"), csv_content)

    # Crear archivo JSON malformado
    # JSON inválido (falta comillas en la clave y cierre incorrecto)
    json_content = "{malformed json: [1,2,3}"
    File.write!(Path.join(test_dir, "test_bad.json"), json_content)

    # Crear archivo LOG con lineas invalidas
    # Mezcla de líneas válidas e inválidas para probar procesamiento parcial
    log_content = """
    2024-01-01 10:00:00 [INFO] [System] Mensaje valido     # Línea con formato correcto
    Esta linea no sigue el formato                         # Línea sin formato esperado
    2024-01-01 10:05:00 [ERROR] [System] Otro mensaje valido # Línea con formato correcto
    """

    File.write!(Path.join(test_dir, "test_mixed.log"), log_content)

    # Retorna el contexto que estará disponible en todas las pruebas
    # El mapa contiene el directorio de prueba para limpieza posterior
    {:ok, %{test_dir: test_dir}}
  end

  # Prueba: Verifica que el procesamiento con manejo de errores detecta errores en CSV
  test "procesar_con_manejo_errores detecta errores en CSV" do
    # Llama a la función que se está probando con un archivo CSV corrupto
    result = ProcesadorArchivos.procesar_con_manejo_errores("data/error/ventas_corrupto.csv")

    # Verificaciones de la estructura del resultado
    assert is_map(result)  # Asegura que el resultado es un mapa
    assert result.estado == :parcial  # Indica que se procesaron algunas líneas pero hubo errores
    assert result.lineas_procesadas > 0  # Debe haber procesado al menos una línea
    assert result.lineas_con_error > 0  # Debe haber encontrado errores
    assert is_list(result.errores)  # Los errores deben estar en una lista

    # Extrae solo los mensajes de error para verificaciones más específicas
    errores_texto = Enum.map(result.errores, fn {_, msg} -> msg end)

    # Verifica que se detectaron tipos específicos de errores
    assert Enum.any?(errores_texto, &String.contains?(&1, "Precio invalido"))
    assert Enum.any?(errores_texto, &String.contains?(&1, "Cantidad vacia"))
    assert Enum.any?(errores_texto, &String.contains?(&1, "Cantidad no numerica"))
  end

  # Prueba: Verifica el manejo de archivos que no existen
  test "procesar_con_manejo_errores maneja archivos inexistentes" do
    # Intenta procesar un archivo que no existe
    result = ProcesadorArchivos.procesar_con_manejo_errores("archivo_que_no_existe.csv")

    # Verificaciones del resultado esperado
    assert result.estado == :error  # Debe indicar estado de error
    # El mensaje de error debe contener texto sobre archivo no encontrado
    assert String.contains?(result.error, "no encontrado") or
           String.contains?(result.error, "no existe")
  end

  # Prueba: Verifica que los reintentos funcionan correctamente
  test "process_with_retry funciona con reintentos" do
    # Configuración de prueba con pocos reintentos y timeout corto
    config = %{retries: 2, timeout: 100}

    # Procesa un archivo que debería fallar por timeout (100ms es muy poco tiempo)
    result = ProcesadorArchivos.process_with_retry("data/valid/ventas_enero.csv", config)

    # Verificaciones del resultado
    assert is_map(result)  # Resultado debe ser un mapa
    assert result.status == :error  # Debe indicar error
    assert result.type == :timeout  # Tipo de error debe ser timeout
    assert result.attempts == 2  # Debe haber hecho 2 intentos (inicial + 1 reintento)
  end

  # Prueba: Verifica que el procesamiento con configuración genera reportes con errores
  # context: Contiene el directorio de prueba creado en el setup
  test "process_files_with_config genera reporte con errores", context do
    # Configuración con timeout normal y un reintento
    config = %{timeout: 5000, retries: 1}

    # Procesa todos los archivos del directorio de prueba
    result = ProcesadorArchivos.process_files_with_config(context.test_dir, config)

    # Verifica que el resultado es una tupla {:ok, results}
    assert {:ok, results} = result
    assert is_list(results)  # Results debe ser una lista
    assert length(results) == 3  # Debe contener resultados para los 3 archivos creados

    # Cuenta cuántos resultados tienen estado de error
    errors = Enum.count(results, &(&1[:status] == :error))
    assert errors > 0  # Debe haber al menos un error
  end

  # Prueba: Verifica que el procesamiento paralelo maneja timeouts correctamente
  test "process_parallel_with_config maneja timeouts" do
    # Configuración extrema: timeout de 1ms para forzar errores
    config = %{
      timeout: 1,       # 1ms - prácticamente garantiza timeout
      retries: 0,       # Sin reintentos
      max_workers: 1,   # Solo un worker para pruebas controladas
      verbose: false    # Sin salida detallada
    }

    # Procesa archivos en paralelo con configuración restrictiva
    results = ProcesadorArchivos.process_parallel_with_config("data/valid", config)

    # Verificaciones
    assert is_list(results)  # Resultado debe ser lista
    # Al menos un resultado debe tener estado de error por timeout
    assert Enum.any?(results, &(&1[:status] == :error))
  end

  # Prueba: Verifica que el módulo CLI existe y tiene la función principal
  test "CLI funciona con opciones basicas" do
    # Verifica que el módulo CLI está cargado
    assert Code.ensure_loaded?(ProcesadorArchivos.CLI)
    # Verifica que el módulo CLI exporta la función main/1
    assert function_exported?(ProcesadorArchivos.CLI, :main, 1)
  end

  # Hook de limpieza que se ejecuta después de cada prueba
  setup context do
    # Registra una función para ejecutar al salir de la prueba
    on_exit(fn ->
      # Limpiar directorio de prueba
      # Verifica si el contexto tiene la clave test_dir
      if Map.has_key?(context, :test_dir) do
        # Elimina recursivamente el directorio y todo su contenido
        File.rm_rf!(context.test_dir)
      end
    end)
  end
end
