# File: test/procesador_archivos_test.exs - VERSIÓN COMPLETA CORREGIDA

defmodule ProcesadorArchivosTest do
  # Habilita funcionalidad de pruebas ExUnit
  use ExUnit.Case

  # Configuración que se ejecuta antes de cada prueba
  setup do
    # Crea directorio output si no existe (mkdir_p! crea recursivamente)
    File.mkdir_p!("output")
    # Retorna :ok para indicar éxito
    :ok
  end

  # Prueba: process_files con carpeta existente debe retornar éxito
  test "process_files con carpeta existente devuelve éxito" do
    # Crea directorio de prueba
    test_dir = "datos_prueba"
    File.mkdir_p!(test_dir)

    # Crea contenido CSV de prueba con encabezado y una línea de datos
    csv_content =
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-01,Producto A,Categoria A,100.0,2,10.0"

    # Escribe archivo de prueba
    File.write!(Path.join(test_dir, "ventas.csv"), csv_content)

    # Ejecuta función bajo prueba
    result = ProcesadorArchivos.process_files(test_dir)
    # Verifica que retorna {:ok, _} (tupla de éxito)
    assert {:ok, _} = result

    # Limpieza: elimina directorio de prueba recursivamente
    # File.rm_rf!(test_dir)
  end

  # Prueba: process_files con carpeta inexistente debe retornar error
  test "process_files con carpeta inexistente devuelve error" do
    # Crea nombre de carpeta que seguro no existe (con número aleatorio)
    result =
      ProcesadorArchivos.process_files(
        "carpeta_que_no_existe_#{:rand.uniform(10000)}"
      )

    # Verifica que retorna {:error, _} (tupla de error)
    assert {:error, _} = result
  end

  # Prueba: CsvParser.process debe extraer al menos 3 métricas
  test "CsvParser.process extrae métricas mínimas" do
    test_file = "test_ventas.csv"
    # Crea contenido CSV de prueba multi-línea usando heredoc (""")
    content = """
    fecha,producto,categoria,precio_unitario,cantidad,descuento
    2024-01-01,Producto A,Electronica,100.0,2,10.0
    2024-01-02,Producto B,Libros,50.0,3,0.0
    """

    File.write!(test_file, content)

    # Ejecuta parser CSV
    result = CsvParser.process(test_file)
    # Verifica éxito y extrae métricas
    assert {:ok, metrics} = result
    # Verifica tipos de datos de cada métrica
    assert is_number(metrics.total_sales)
    assert is_integer(metrics.unique_products)
    assert is_integer(metrics.valid_records)

    # Limpieza: elimina archivo de prueba
    File.rm!(test_file)
  end

  # Prueba similar para JsonParser
  test "JsonParser.process extrae métricas mínimas" do
    test_file = "test_usuarios.json"
    # Crea JSON de prueba con estructura esperada
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

    result = JsonParser.process(test_file)
    assert {:ok, metrics} = result
    assert is_integer(metrics.total_users)
    assert is_integer(metrics.active_users)
    assert is_integer(metrics.total_sessions)

    File.rm!(test_file)
  end

  # Prueba similar para LogParser
  test "LogParser.process extrae métricas mínimas" do
    test_file = "test_sistema.log"
    # Crea log de prueba con diferentes niveles
    content = """
    2024-01-01 10:00:00 [INFO] [System] Sistema iniciado
    2024-01-01 10:05:00 [ERROR] [System] Error de base de datos
    2024-01-01 10:10:00 [WARN] [System] Uso alto de memoria
    """

    File.write!(test_file, content)

    result = LogParser.process(test_file)
    assert {:ok, metrics} = result
    assert is_integer(metrics.total_lines)
    assert is_integer(metrics.error)
    assert is_integer(metrics.warn)

    File.rm!(test_file)
  end

  # Prueba que todos los parsers retornan error para archivos inexistentes
  test "parsers devuelven error para archivos inexistentes" do
    # Genera nombres aleatorios para asegurar que no existen
    assert {:error, _} =
             CsvParser.process("no_existe_#{:rand.uniform(10000)}.csv")

    assert {:error, _} =
             JsonParser.process("no_existe_#{:rand.uniform(10000)}.json")

    assert {:error, _} =
             LogParser.process("no_existe_#{:rand.uniform(10000)}.log")
  end

  # Prueba: se debe crear archivo de reporte después de procesar
  # TEST 7 CORREGIDO - Usando File.ls (sin !) que devuelve tupla
  test "se crea archivo de reporte después de procesar" do
    test_dir = "test_reporte"
    File.mkdir_p!(test_dir)

    # Crea archivo CSV simple de prueba
    csv_content =
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n2024-01-01,Producto X,Cat X,50.0,1,0.0"

    File.write!(Path.join(test_dir, "test.csv"), csv_content)

    # Ejecuta procesador (creará reporte)
    ProcesadorArchivos.process_files(test_dir)

    # CORRECCIÓN: Usar File.ls (no File.ls!) que devuelve {:ok, files} o {:error, reason}
    report_files =
      case File.ls("output") do
        # Si éxito, obtiene lista de archivos
        {:ok, files} -> files
        # Si error, retorna lista vacía
        {:error, _} -> []
      end
      # Filtra solo archivos que empiezan con "report_"
      |> Enum.filter(fn file -> String.starts_with?(file, "report_") end)

    # Verifica que se creó al menos un reporte
    assert length(report_files) > 0

    # Limpieza
    # File.rm_rf!(test_dir)
    # Elimina archivos de reporte creados
    # Enum.each(report_files, &File.rm!("output/#{&1}"))
  end

  # Prueba: CsvParser debe manejar archivo CSV vacío (solo encabezado)
  test "CsvParser maneja archivo CSV vacío" do
    test_file = "test_vacio.csv"
    # Archivo con solo encabezado (línea de datos vacía)
    File.write!(
      test_file,
      "fecha,producto,categoria,precio_unitario,cantidad,descuento\n"
    )

    result = CsvParser.process(test_file)
    assert {:ok, metrics} = result
    # Con solo encabezado, ventas totales deben ser 0
    assert metrics.total_sales == 0.0
    assert metrics.unique_products == 0

    File.rm!(test_file)
  end

  # Prueba: JsonParser debe retornar error para JSON inválido
  test "JsonParser devuelve error para JSON inválido" do
    test_file = "test_malo.json"
    # JSON con sintaxis inválida
    File.write!(test_file, "{json invalido}")

    result = JsonParser.process(test_file)
    # Debe retornar tupla de error
    assert {:error, _} = result

    File.rm!(test_file)
  end

  # Prueba de integración completa con un archivo CSV
  test "flujo completo con un archivo CSV" do
    test_dir = "test_integracion"
    File.mkdir_p!(test_dir)

    # Crea CSV con datos de ejemplo
    csv_content = """
    fecha,producto,categoria,precio_unitario,cantidad,descuento
    2024-01-01,Manzana,Frutas,10.0,5,0.0
    2024-01-02,Pera,Frutas,8.0,3,10.0
    """

    File.write!(Path.join(test_dir, "ventas.csv"), csv_content)

    # Ejecuta procesador completo
    result = ProcesadorArchivos.process_files(test_dir)
    assert {:ok, results} = result
    # Verifica estructura de retorno
    assert is_list(results)
    # Solo un archivo procesado
    assert length(results) == 1

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
