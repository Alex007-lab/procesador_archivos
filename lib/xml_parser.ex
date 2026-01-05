# File: lib/csv_parser.ex
# Purpose: Simple CSV parser for sales data

# Define módulo para parsear archivos XML
defmodule XmlParser do
  # Documentación del módulo que aparecerá en documentación generada
  @moduledoc """
  XML parser for sales data.
  Format: date,product,category,price,quantity,discount
  """

  # Función principal para procesar archivos CSV
  # Toma una ruta de archivo y retorna tupla {:ok, metrics} o {:error, reason}
  def process(file_path) do
    # Verifica si el archivo existe usando File.exists?/1
    if File.exists?(file_path) do
      # Bloque try para capturar errores durante el procesamiento
      try do
        # Lee todo el archivo y lo divide por líneas
        # File.read!/1 lee el contenido completo (¡lanza excepción si falla!)
        # String.split/2 divide el string por el separador "\n" (salto de línea)
        lines = File.read!(file_path) |> String.split("\n")

        # Separa encabezado (primera línea) de datos usando pattern matching
        # La variable _header contiene la primera línea pero no la usamos (por eso el _)
        # data_lines contiene el resto de las líneas (tail de la lista)
        [_header | data_lines] = lines

        # Procesa líneas de datos usando pipeline de operaciones
        valid_records =
          data_lines
          # Filtra líneas vacías usando Enum.filter/2
          # &(&1 != "") es una función anónima que verifica si el elemento no es string vacío
          |> Enum.filter(&(&1 != ""))
          # Parsea cada línea llamando a la función privada parse_line/1
          # Enum.map/2 aplica parse_line a cada elemento de la lista
          |> Enum.map(&parse_line/1)
          # Filtra solo registros válidos usando valid_record?/1
          |> Enum.filter(&valid_record?/1)

        # Calcula métricas (mínimo 3 requeridas) y las organiza en un mapa
        metrics = %{
          # Ventas totales: llama a calculate_total/1 con los registros válidos
          total_sales: calculate_total(valid_records),
          # Productos únicos: cuenta productos distintos
          unique_products: count_unique(valid_records),
          # Registros válidos: usa length/1 para contar elementos de la lista
          valid_records: length(valid_records),
          # Nombre del archivo: extrae solo el nombre sin la ruta
          file_name: Path.basename(file_path)
        }

        # Retorna tupla de éxito con métricas
        {:ok, metrics}

        # Manejo de errores durante el parsing usando rescue
      rescue
        # Captura cualquier error y retorna tupla de error con descripción
        error -> {:error, "CSV parsing error: #{inspect(error)}"}
      end
    else
      # Si el archivo no existe, retorna tupla de error
      {:error, "File not found: #{file_path}"}
    end
  end

  # Parsea una línea individual del CSV
  # Es privada (defp) porque solo se usa dentro del módulo
  # Formato esperado: date,product,category,price,quantity,discount
  defp parse_line(line) do
    # Divide la línea por comas usando String.split/2
    case String.split(line, ",") do
      # Pattern matching: si tiene exactamente 6 campos, extrae cada uno
      [date, product, category, price_str, quantity_str, discount_str] ->
        # Crea mapa con los datos parseados
        %{
          # Fecha como string (no se parsea a fecha real)
          date: date,
          # Producto como string
          product: product,
          # Categoría como string
          category: category,
          # Precio: convierte string a número usando parse_float/1
          price: parse_float(price_str),
          # Cantidad: convierte string a entero usando parse_int/1
          quantity: parse_int(quantity_str),
          # Descuento: convierte string a número (porcentaje)
          discount: parse_float(discount_str)
        }

      # Si no tiene 6 campos (cualquier otro caso), retorna nil
      _ ->
        nil
    end
  end

  # Verifica si un registro es válido
  # Primera cláusula: si el registro es nil, retorna false
  defp valid_record?(nil), do: false

  # Segunda cláusula: cuando el registro no es nil
  defp valid_record?(record) do
    # Un registro es válido si cumple todas estas condiciones:
    # 1. El precio es número positivo (is_number/1 verifica tipo)
    # 2. La cantidad es número positivo
    # 3. El descuento está entre 0 y 100% (inclusive)
    # Usamos operadores lógicos "and" para combinar condiciones
    is_number(record.price) and record.price > 0 and
      is_number(record.quantity) and record.quantity > 0 and
      is_number(record.discount) and record.discount >= 0 and
      record.discount <= 100
  end

  # Convierte string a número decimal (float)
  defp parse_float(string) do
    # Float.parse/1 intenta convertir string a float
    # Retorna tupla {número, resto} o :error si falla
    case Float.parse(string) do
      # Si se puede parsear, retorna solo el número (ignoramos el resto)
      {number, _} -> number
      # Si no se puede parsear, retorna átomo :error
      :error -> :error
    end
  end

  # Convierte string a número entero
  defp parse_int(string) do
    # Integer.parse/1 intenta convertir string a entero
    case Integer.parse(string) do
      # Éxito: retorna el número entero
      {number, _} -> number
      # Error: retorna átomo :error
      :error -> :error
    end
  end

  # Calcula el total de ventas
  # Fórmula: (precio * cantidad) - descuento
  defp calculate_total(records) do
    # Enum.reduce/3 acumula valores empezando desde 0.0
    Enum.reduce(records, 0.0, fn record, total ->
      # Calcula venta bruta: precio * cantidad
      sale = record.price * record.quantity
      # Calcula monto del descuento: venta * (porcentaje/100)
      discount_amount = sale * (record.discount / 100)
      # Suma venta neta (bruta - descuento) al total acumulado
      total + (sale - discount_amount)
    end)
    # Redondea el resultado final a 2 decimales
    |> Float.round(2)
  end

  # Cuenta productos únicos en los registros
  defp count_unique(records) do
    records
    # Enum.map/2: extrae solo el campo .product de cada registro
    # & &1.product es shorthand para fn(record) -> record.product end
    |> Enum.map(& &1.product)
    # Enum.uniq/1: elimina valores duplicados de la lista
    |> Enum.uniq()
    # length/1: cuenta cuántos elementos únicos quedaron
    |> length()
  end
end
