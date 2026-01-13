# File: test/procesador_archivos_test.exs - VERSIÓN COMPLETA CORREGIDA

# Define el módulo de pruebas para el procesador de archivos
defmodule ProcesadorArchivosTest do
  # Habilita funcionalidad de pruebas ExUnit
  # Esto importa todas las macros y funciones de ExUnit.Case
  use ExUnit.Case

  # Configuración que se ejecuta antes de cada prueba
  # El bloque setup se ejecuta antes de CADA prueba individual
  setup do
    # Crea directorio output si no existe (mkdir_p! crea recursivamente)
    # Este directorio se usará para almacenar reportes generados
    File.mkdir_p!("output")
    # Retorna :ok para indicar éxito en la configuración
    # Este valor estará disponible como contexto en las pruebas
    :ok
  end

  # Prueba 1: Verifica que process_files procesa correctamente una carpeta existente
  # Descripción: Prueba el caso de éxito del procesador principal
  test "process_files con carpeta existente devuelve éxito" do
    # Crea directorio de prueba temporal
    test_dir = "datos_prueba"
    File.mkdir_p!(test_dir)  # Crea el directorio si no existe

    # Crea contenido CSV de prueba con encabezado y una línea de datos
    # Formato: encabezado + línea de datos con todos los campos necesarios
    csv_content =
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-01,Producto A,Categoria A,100.0,2,10.0"

    # Escribe archivo de prueba dentro del directorio temporal
    # Path.join: concatena directorio y nombre de archivo correctamente
    File.write!(Path.join(test_dir, "ventas.csv"), csv_content)

    # Ejecuta función bajo prueba - el núcleo del sistema
    result = ProcesadorArchivos.process_files(test_dir)
    # Verifica que retorna {:ok, _} (tupla de éxito)
    # Pattern matching que asegura el formato correcto de retorno
    assert {:ok, _} = result

    # Limpieza: elimina directorio de prueba recursivamente
    # Comentado para depuración, normalmente se descomentaría
    # File.rm_rf!(test_dir)
  end

  # Prueba 2: Verifica el manejo de errores cuando la carpeta no existe
  # Descripción: Prueba la robustez del sistema ante rutas inválidas
  test "process_files con carpeta inexistente devuelve error" do
    # Crea nombre de carpeta que seguro no existe (con número aleatorio)
    # :rand.uniform(10000) genera número aleatorio para evitar colisiones
    result =
      ProcesadorArchivos.process_files(
        "carpeta_que_no_existe_#{:rand.uniform(10000)}"
      )

    # Verifica que retorna {:error, _} (tupla de error)
    # Pattern matching para validar el formato de error esperado
    assert {:error, _} = result
  end

  # Prueba 3: Verifica que CsvParser.process extrae métricas mínimas
  # Descripción: Prueba unitaria del parser CSV
  test "CsvParser.process extrae métricas mínimas" do
    # Nombre del archivo de prueba temporal
    test_file = "test_ventas.csv"

    # Crea contenido CSV de prueba multi-línea usando heredoc (""")
    # Heredoc permite strings multi-línea sin escapar saltos de línea
    content = """
    fecha,producto,categoria,precio_unitario,cantidad,descuento
    2024-01-01,Producto A,Electronica,100.0,2,10.0
    2024-01-02,Producto B,Libros,50.0,3,0.0
    """

    # Escribe el contenido en el archivo temporal
    File.write!(test_file, content)

    # Ejecuta parser CSV con el archivo de prueba
    result = CsvParser.process(test_file)

    # Verifica éxito y extrae métricas usando pattern matching
    assert {:ok, metrics} = result

    # Verifica tipos de datos de cada métrica esperada
    # total_sales: debería ser un número (float o integer)
    assert is_number(metrics.total_sales)
    # unique_products: debería ser un entero
    assert is_integer(metrics.unique_products)
    # valid_records: debería ser un entero (conteo de registros válidos)
    assert is_integer(metrics.valid_records)

    # Limpieza: elimina archivo de prueba
    File.rm!(test_file)
  end

  # Prueba 4: Verifica que JsonParser.process extrae métricas mínimas
  # Descripción: Prueba unitaria del parser JSON
  test "JsonParser.process extrae métricas mínimas" do
    test_file = "test_usuarios.json"

    # Crea JSON de prueba con estructura esperada
    # Incluye usuarios activos/inactivos y sesiones
    content = """
    {
      "timestamp": "2024-01-01T10:00:00Z",
      "usuarios": [
        {"id": 1, "nombre": "Ana", "email": "ana@test.com", "activo": true},
        {"id": 2, "nombre": "Juan", "email": "juan@test.com", "activo": false}
      ],
      "sesiones": [
        {"usuario_id": 1, "inicio": "2024-01-01T09:00:00Z", "duracion_segundos": 300, "paginas_visitadas": 5}
      ]
    }
    """

    File.write!(test_file, content)

    # Ejecuta parser JSON
    result = JsonParser.process(test_file)
    assert {:ok, metrics} = result

    # Verifica las métricas específicas del parser JSON
    assert is_integer(metrics.total_users)       # Total de usuarios
    assert is_integer(metrics.active_users)      # Usuarios activos
    assert is_integer(metrics.total_sessions)    # Total de sesiones

    File.rm!(test_file)
  end

  # Prueba 5: Verifica que LogParser.process extrae métricas mínimas
  # Descripción: Prueba unitaria del parser de logs
  test "LogParser.process extrae métricas mínimas" do
    test_file = "test_sistema.log"

    # Crea log de prueba con diferentes niveles (INFO, ERROR, WARN)
    # Formato esperado: timestamp [LEVEL] [Module] Message
    content = """
    2024-01-01 10:00:00 [INFO] [System] Sistema iniciado
    2024-01-01 10:05:00 [ERROR] [System] Error de base de datos
    2024-01-01 10:10:00 [WARN] [System] Uso alto de memoria
    """

    File.write!(test_file, content)

    result = LogParser.process(test_file)
    assert {:ok, metrics} = result

    # Verifica métricas específicas del parser de logs
    assert is_integer(metrics.total_lines)  # Total de líneas en el log
    assert is_integer(metrics.error)        # Conteo de líneas ERROR
    assert is_integer(metrics.warn)         # Conteo de líneas WARN

    File.rm!(test_file)
  end

  # Prueba 6: Verifica que todos los parsers retornan error para archivos inexistentes
  # Descripción: Prueba consistencia en el manejo de archivos faltantes
  test "parsers devuelven error para archivos inexistentes" do
    # Genera nombres aleatorios para asegurar que no existen
    # Se prueba cada parser individualmente

    # Prueba CsvParser
    assert {:error, _} =
             CsvParser.process("no_existe_#{:rand.uniform(10000)}.csv")

    # Prueba JsonParser
    assert {:error, _} =
             JsonParser.process("no_existe_#{:rand.uniform(10000)}.json")

    # Prueba LogParser
    assert {:error, _} =
             LogParser.process("no_existe_#{:rand.uniform(10000)}.log")
  end

  # Prueba 7: Verifica que se crean archivos de reporte después de procesar
  # Descripción: Prueba la generación de reportes como salida del sistema
  # NOTA: Esta es la versión corregida mencionada en el comentario
  test "se crea archivo de reporte después de procesar" do
    # Crea directorio temporal para la prueba
    test_dir = "test_reporte"
    File.mkdir_p!(test_dir)

    # Crea archivo CSV simple de prueba
    csv_content =
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-01,Producto X,Cat X,50.0,1,0.0"

    File.write!(Path.join(test_dir, "test.csv"), csv_content)

    # Ejecuta procesador - esto debería crear reportes en "output/"
    ProcesadorArchivos.process_files(test_dir)

    # CORRECCIÓN: Usar File.ls (no File.ls!) que devuelve {:ok, files} o {:error, reason}
    # File.ls! lanzaría excepción si hay error, File.ls retorna tupla
    report_files =
      case File.ls("output") do
        # Si éxito, obtiene lista de archivos
        {:ok, files} -> files
        # Si error (ej. directorio no existe), retorna lista vacía
        {:error, _} -> []
      end
      # Filtra solo archivos que empiezan con "report_"
      # Los reportes deben seguir este patrón de nombres
      |> Enum.filter(fn file -> String.starts_with?(file, "report_") end)

    # Verifica que se creó al menos un reporte
    # Si length es 0, la prueba falla
    assert length(report_files) > 0

    # Limpieza (comentada para depuración)
    # File.rm_rf!(test_dir)
    # Enum.each(report_files, &File.rm!("output/#{&1}"))
  end

  # Prueba 8: Verifica que CsvParser maneja archivo CSV vacío (solo encabezado)
  # Descripción: Prueba caso límite - archivo sin datos
  test "CsvParser maneja archivo CSV vacío" do
    test_file = "test_vacio.csv"

    # Archivo con solo encabezado (línea de datos vacía)
    # El \n final es importante para CSV válido
    File.write!(
      test_file,
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n"
    )

    result = CsvParser.process(test_file)
    assert {:ok, metrics} = result

    # Con solo encabezado, las métricas deben ser 0
    assert metrics.total_sales == 0.0          # Sin ventas
    assert metrics.unique_products == 0        # Sin productos únicos

    File.rm!(test_file)
  end

  # Prueba 9: Verifica que JsonParser retorna error para JSON inválido
  # Descripción: Prueba manejo de errores de sintaxis JSON
  test "JsonParser devuelve error para JSON inválido" do
    test_file = "test_malo.json"

    # JSON con sintaxis inválida - falta comillas, formato incorrecto
    File.write!(test_file, "{json invalido}")

    result = JsonParser.process(test_file)
    # Debe retornar tupla de error, no crashear
    assert {:error, _} = result

    File.rm!(test_file)
  end

  # Prueba 10: Prueba de integración completa con un archivo CSV
  # Descripción: Prueba end-to-end del flujo completo del sistema
  test "flujo completo con un archivo CSV" do
    # Crea directorio temporal para integración
    test_dir = "test_integracion"
    File.mkdir_p!(test_dir)

    # Crea CSV con datos de ejemplo (dos registros)
    csv_content = """
    fecha,producto,categoria,precio_unitario,cantidad,descuento
    2024-01-01,Manzana,Frutas,10.0,5,0.0
    2024-01-02,Pera,Frutas,8.0,3,10.0
    """

    File.write!(Path.join(test_dir, "ventas.csv"), csv_content)

    # Ejecuta procesador completo
    result = ProcesadorArchivos.process_files(test_dir)

    # Verifica estructura de retorno
    assert {:ok, results} = result
    assert is_list(results)          # Debe ser lista de resultados
    assert length(results) == 1      # Solo un archivo procesado

    # Limpieza (comentada)
    # File.rm_rf!(test_dir)

    # Limpiar reportes en output creados durante la prueba
    # case File.ls("output") do
    #  {:ok, files} ->
    #    files
    #    |> Enum.filter(fn file -> String.starts_with?(file, "report_") end)
    #    |> Enum.each(fn file -> File.rm!("output/#{file}") end)
    #  _ -> :ok  # Si hay error al listar, no hacer nada
    # end
  end
end
