# mix.exs - ARCHIVO COMPLETAMENTE COMENTADO

defmodule ProcesadorArchivos.MixProject do
  # Usa Mix.Project para definir un proyecto de Mix
  use Mix.Project

  # Función principal del proyecto que define la configuración
  def project do
    [
      # Nombre de la aplicación
      app: :procesador_archivos,
      # Versión de la aplicación (actualizada para Entrega 3)
      version: "0.3.0",
      # Versión de Elixir requerida
      elixir: "~> 1.19",
      # Si se inicia en modo permanente en producción
      start_permanent: Mix.env() == :prod,
      # Dependencias del proyecto
      deps: deps(),
      # CONFIGURACIÓN PARA CREAR EJECUTABLE (ESCRIPT)
      # Esto es lo que permite crear ./procesador_archivos
      escript: [main_module: ProcesadorArchivos.CLI, name: "procesador_archivos"]
    ]
  end

  # Configuración de la aplicación (qué se ejecuta al iniciar)
  def application do
    [
      # Aplicaciones extra que se inician automáticamente
      extra_applications: [:logger]
    ]
  end

  # Lista de dependencias del proyecto
  defp deps do
    [
      # Biblioteca para parsear JSON (requerida desde Entrega 1)
      {:jason, "~> 1.4"}
    ]
  end
end
