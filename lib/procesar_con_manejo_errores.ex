defmodule ProcesadorArchivos.ProcesarConManejoErrores do
  @moduledoc """
  Módulo para procesar archivos con manejo de errores.
  """

  @doc """
  Procesa un archivo dado su ruta, manejando errores durante el procesamiento.

  ## Parámetros
    - file_path: Ruta del archivo a procesar.

  ## Retorna
    - {:ok, metrics} si el procesamiento es exitoso.
    - {:error, reason} si ocurre un error durante el procesamiento.
  """
  def procesar(file_path) do
    try do
      # Aquí iría la lógica real de procesamiento del archivo
      # Por simplicidad, simulamos un procesamiento exitoso
      metrics = %{
        total_sales: 1000,
        unique_products: 50,
        valid_records: 200,
        file_name: Path.basename(file_path)
      }

      {:ok, metrics}
    rescue
      error ->
        {:error, "Error al procesar el archivo #{file_path}: #{inspect(error)}"}
    end
  end
end
