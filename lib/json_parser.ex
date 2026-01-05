defmodule JsonParser do
  # Documentación del módulo
  @moduledoc """
  JSON parser for user data using Jason library.
  """

  # Función principal para procesar archivos JSON
  def process(file_path) do
    # Verifica si el archivo existe
    if File.exists?(file_path) do
      try do
        # Lee todo el contenido del archivo
        content = File.read!(file_path)
        # Decodifica JSON a estructura de datos Elixir usando Jason
        # Jason.decode!/1 lanza excepción si el JSON es inválido
        data = Jason.decode!(content)

        # Obtiene lista de usuarios del mapa decodificado
        # Map.get/3 obtiene valor de la clave "usuarios" o retorna [] si no existe
        users = Map.get(data, "usuarios", [])
        # Obtiene lista de sesiones (similar a usuarios)
        sessions = Map.get(data, "sesiones", [])

        # Crea mapa de métricas
        metrics = %{
          # Total de usuarios: longitud de la lista
          total_users: length(users),
          # Usuarios activos: llama a función privada count_active/1
          active_users: count_active(users),
          # Total de sesiones: longitud de la lista
          total_sessions: length(sessions),
          # Nombre del archivo
          file_name: Path.basename(file_path)
        }

        # Retorna tupla de éxito
        {:ok, metrics}
      rescue
        # Captura error específico de decodificación JSON
        Jason.DecodeError -> {:error, "Invalid JSON format"}
        # Captura cualquier otro error
        error -> {:error, "JSON parsing error: #{inspect(error)}"}
      end
    else
      # Archivo no encontrado
      {:error, "File not found: #{file_path}"}
    end
  end

  # Función privada para contar usuarios activos
  defp count_active(users) do
    # Enum.count/2 cuenta elementos que cumplen la condición
    # & &1["activo"] es función anónima que verifica campo "activo" en cada usuario
    Enum.count(users, & &1["activo"])
  end
end
