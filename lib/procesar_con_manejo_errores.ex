# lib/procesar_con_manejo_errores.ex - VERSIÓN FINAL CORREGIDA

# Define el módulo especializado en procesamiento con manejo robusto de errores
# Este módulo está diseñado específicamente para manejar archivos corruptos o mal formados
defmodule ProcesadorArchivos.ProcesarConManejoErrores do
  @moduledoc """
  Modulo para procesamiento con manejo detallado de errores.
  Especialmente para archivos corruptos.
  """

  # Función pública principal que actúa como punto de entrada
  # file_path: Ruta del archivo a procesar
  # _config: Configuración opcional (usamos _ para indicar que no se usa aún)
  def procesar(file_path, _config \\ %{}) do
    # Determina el tipo de archivo basado en su extensión
    case Path.extname(file_path) do
      ".csv" -> procesar_csv_con_errores(file_path)   # Procesa archivos CSV
      ".json" -> procesar_json_con_errores(file_path) # Procesa archivos JSON
      ".log" -> procesar_log_con_errores(file_path)   # Procesa archivos LOG
      _ -> {:error, "Formato no soportado"}           # Formato desconocido
    end
  end

  # ============ SECCIÓN CSV ============
  # Función privada para procesar archivos CSV con manejo detallado de errores
  defp procesar_csv_con_errores(file_path) do
    # Primero verifica que el archivo existe
    if File.exists?(file_path) do
      try do
        # Lee todo el contenido del archivo (¡puede lanzar excepción!)
        content = File.read!(file_path)
        # Divide por líneas (\n es carácter de nueva línea)
        lines = String.split(content, "\n")

        # Verifica que tenga al menos 2 líneas (encabezado + al menos 1 dato)
        if length(lines) < 2 do
          {:error, "Archivo vacio o sin datos"}
        else
          # Pattern matching: separa encabezado de datos
          # _header: ignora la primera línea (encabezado)
          # data_lines: lista con el resto de líneas (datos)
          [_header | data_lines] = lines

          # Procesa líneas de datos recursivamente
          # 2: número de línea inicial (la primera línea de datos)
          # 0: contador de líneas procesadas exitosamente
          # []: lista acumuladora de errores (vacía al inicio)
          {procesadas, errores} = procesar_lineas_csv(data_lines, 2, 0, [])

          # Retorna mapa con resultados estructurados
          %{
            estado: if(length(errores) > 0, do: :parcial, else: :completo),
            lineas_procesadas: procesadas,
            lineas_con_error: length(errores),
            errores: Enum.reverse(errores),  # Reverse para mantener orden original
            total_lineas: length(data_lines),
            archivo: Path.basename(file_path)  # Solo el nombre, no la ruta completa
          }
        end
      rescue
        # Manejo de excepciones durante la lectura/procesamiento
        error ->
          {:error, "Error procesando CSV: #{inspect(error)}"}
      end
    else
      # Archivo no existe
      {:error, "Archivo no encontrado"}
    end
  end

  # Función recursiva para procesar líneas CSV - CASO BASE
  # Cuando no quedan líneas por procesar
  defp procesar_lineas_csv([], _, procesadas, errores), do: {procesadas, errores}

  # Función recursiva para procesar líneas CSV - CASO RECURSIVO
  # Procesa línea actual y llama recursivamente para el resto
  defp procesar_lineas_csv([line | rest], num_linea, procesadas, errores) do
    # Condicional para manejar diferentes casos de línea
    cond do
      # Caso 1: Línea vacía (solo espacios/tabs)
      String.trim(line) == "" ->
        # Ignora línea vacía, continúa con siguiente
        procesar_lineas_csv(rest, num_linea + 1, procesadas, errores)

      # Caso 2: Línea con contenido
      true ->
        # Valida la línea actual
        case validar_linea_csv(line) do
          # Línea válida
          :ok ->
            procesar_lineas_csv(rest, num_linea + 1, procesadas + 1, errores)

          # Línea con error
          {:error, mensaje} ->
            # Construye tupla de error: {número_linea, mensaje_error}
            nuevo_error = {num_linea, mensaje}
            # Agrega error a la lista (al inicio por eficiencia)
            procesar_lineas_csv(rest, num_linea + 1, procesadas, [nuevo_error | errores])
        end
    end
  end

  # Valida una línea individual de CSV
  defp validar_linea_csv(line) do
    # Divide la línea por comas para obtener campos
    campos = String.split(line, ",")

    # Verifica que tenga exactamente 6 campos (formato esperado)
    if length(campos) != 6 do
      {:error, "Linea incompleta (#{length(campos)} campos en lugar de 6)"}
    else
      # Pattern matching para extraer campos específicos
      # _ prefijo indica que no nos interesa ese valor
      [_fecha, _producto, _categoria, precio_str, cantidad_str, descuento_str] = campos

      # Inicializa lista de errores vacía
      errores = []
      # Valida cada campo, acumulando errores
      errores = validar_precio(precio_str, errores)
      errores = validar_cantidad(cantidad_str, errores)
      errores = validar_descuento(descuento_str, errores)

      # Si no hay errores, retorna :ok, de lo contrario retorna mensaje de error
      if Enum.empty?(errores) do
        :ok
      else
        {:error, Enum.join(errores, ", ")}  # Une múltiples errores con coma
      end
    end
  end

  # Funciones que devuelven la lista de errores actualizada
  # Valida campo precio: debe ser número flotante positivo
  defp validar_precio(precio_str, errores) do
    case safe_parse_float(precio_str) do
      # Precio válido y positivo
      {:ok, precio} when precio > 0 ->
        errores  # No agrega error

      # Precio válido pero no positivo (0 o negativo)
      {:ok, _} ->
        ["Precio debe ser positivo" | errores]  # Agrega error al inicio

      # Precio no es un número válido
      {:error, _} ->
        ["Precio invalido: '#{precio_str}'" | errores]
    end
  end

  # Valida campo cantidad: debe ser entero positivo
  defp validar_cantidad(cantidad_str, errores) do
    case safe_parse_int(cantidad_str) do
      # Cantidad válida y positiva
      {:ok, cantidad} when cantidad > 0 ->
        errores

      # Cantidad válida pero no positiva (0 o negativo)
      {:ok, _} ->
        ["Cantidad debe ser positiva" | errores]

      # Cantidad no es un número válido
      {:error, _} ->
        # Distingue entre vacío y valor inválido
        if String.trim(cantidad_str) == "" do
          ["Cantidad vacia" | errores]
        else
          ["Cantidad invalida: '#{cantidad_str}'" | errores]
        end
    end
  end

  # Valida campo descuento: debe ser porcentaje entre 0 y 100
  defp validar_descuento(descuento_str, errores) do
    case safe_parse_float(descuento_str) do
      # Descuento válido y en rango permitido (0-100)
      {:ok, descuento} when descuento >= 0 and descuento <= 100 ->
        errores

      # Descuento negativo
      {:ok, descuento} when descuento < 0 ->
        ["Descuento negativo" | errores]

      # Descuento mayor a 100%
      {:ok, descuento} when descuento > 100 ->
        ["Descuento mayor a 100%" | errores]

      # Descuento no es un número válido
      {:error, _} ->
        ["Descuento invalido: '#{descuento_str}'" | errores]
    end
  end

  # Funciones SEGURAS de parsing (no lanzan excepciones)
  # Parsea string a float de manera segura
  defp safe_parse_float(str) do
    try do
      # Float.parse retorna {valor, resto} o :error
      case Float.parse(String.trim(str)) do
        # String parseado completamente
        {num, ""} -> {:ok, num}
        # String parseado parcialmente (aceptamos esto)
        {num, _rest} -> {:ok, num}
        # No es un número float
        :error -> {:error, :not_a_number}
      end
    rescue
      # Cualquier excepción durante el parseo
      _ -> {:error, :parse_error}
    end
  end

  # Parsea string a entero de manera segura
  defp safe_parse_int(str) do
    try do
      # Integer.parse retorna {valor, resto} o :error
      case Integer.parse(String.trim(str)) do
        # String parseado completamente
        {num, ""} -> {:ok, num}
        # String parseado parcialmente (aceptamos esto)
        {num, _rest} -> {:ok, num}
        # No es un número entero
        :error -> {:error, :not_a_number}
      end
    rescue
      # Cualquier excepción durante el parseo
      _ -> {:error, :parse_error}
    end
  end

  # ============ SECCIÓN JSON ============
  # Función privada para procesar archivos JSON con manejo de errores
  defp procesar_json_con_errores(file_path) do
    if File.exists?(file_path) do
      try do
        # Lee y parsea JSON en un solo paso
        content = File.read!(file_path)
        Jason.decode!(content)  # ¡Puede lanzar Jason.DecodeError!

        # Si llegamos aquí, el JSON es válido
        %{
          estado: :completo,
          archivo: Path.basename(file_path),
          mensaje: "JSON valido"
        }
      rescue
        # Error específico de decodificación JSON
        _error in Jason.DecodeError ->
          %{
            estado: :error,
            archivo: Path.basename(file_path),
            error: "JSON malformado",
            detalles: "Error de decodificacion"
          }
        # Cualquier otro error
        error ->
          %{
            estado: :error,
            archivo: Path.basename(file_path),
            error: "Error procesando JSON",
            detalles: inspect(error)
          }
      end
    else
      {:error, "Archivo no encontrado"}
    end
  end

  # ============ SECCIÓN LOG ============
  # Función privada para procesar archivos LOG con manejo de errores
  defp procesar_log_con_errores(file_path) do
    if File.exists?(file_path) do
      try do
        # Lee y divide líneas, eliminando líneas vacías (trim: true)
        lines = File.read!(file_path) |> String.split("\n", trim: true)

        # Separa líneas válidas de inválidas
        {validas, invalidas} = Enum.split_with(lines, &es_linea_log_valida?/1)

        # Procesa líneas inválidas para crear tuplas de error
        errores = Enum.with_index(invalidas, 1)
                  |> Enum.map(fn {linea, idx} ->
                       # Limita mensaje a 30 caracteres para evitar líneas muy largas
                       {idx, "Formato invalido: #{String.slice(linea, 0..30)}..."}
                     end)

        %{
          estado: if(length(invalidas) > 0, do: :parcial, else: :completo),
          lineas_procesadas: length(validas),
          lineas_con_error: length(invalidas),
          errores: errores,
          archivo: Path.basename(file_path)
        }
      rescue
        # Manejo de errores generales
        error ->
          {:error, "Error procesando LOG: #{inspect(error)}"}
      end
    else
      {:error, "Archivo no encontrado"}
    end
  end

  # Determina si una línea de log tiene formato válido
  defp es_linea_log_valida?(line) do
    # Patrón de expresión regular más simple y tolerante
    # Busca: fecha hora [NIVEL] ... (case-insensitive)
    Regex.match?(~r/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2} \[(DEBUG|INFO|WARN|ERROR|FATAL)\]/i, line)
  end
end
