Procesador de Archivos
Proyecto en Elixir para procesar archivos CSV, JSON y LOG, extraer métricas y generar reportes en texto plano.

 Resumen
Propósito: Procesar archivos de ventas (CSV), usuarios (JSON) y logs de uso (LOG), consolidar métricas y escribir reportes legibles.

Lenguaje: Elixir (>= 1.19)

Requisitos
Elixir 1.19 o superior

Erlang/OTP compatible con la versión de Elixir

Dependencias definidas en mix.exs (por ejemplo: jason)

Instalación
Instala las dependencias:

bash
mix deps.get
Verifica que todo funcione ejecutando los tests:

bash
mix test
Uso
Lista Completa de Comandos para Probar el Proyecto Manualmente
Procesamiento de archivos
bash
# Procesar archivos en la carpeta por defecto (`data/valid/`)
mix run -e "ProcesadorArchivos.process_files()"

# Procesar archivos desde una carpeta específica
mix run -e "ProcesadorArchivos.process_files(\"data/error\")"

# Procesamiento secuencial explícito
mix run -e "ProcesadorArchivos.process_files(\"data/valid\")"

# Procesamiento paralelo
mix run -e "ProcesadorArchivos.process_folder_parallel(\"data/valid\")"

# Benchmark de rendimiento
mix run -e "ProcesadorArchivos.benchmark(\"data/valid\")"
Ejecutar tests
bash
# Ejecutar todos los tests
mix test

# Ejecutar tests con cobertura
mix test --cover

# Ejecutar tests específicos por nombre
mix test --only "test_name"

# Ejecutar tests en modo detallado
mix test --trace
Limpieza y mantenimiento
bash
# Limpiar reportes generados
rm -rf output/*

# Limpiar archivos compilados
mix clean

# 1. Limpiar proyecto
mix clean

# 2. Obtener dependencias
mix deps.get

# 3. Compilar proyecto
mix compile

# 4. Crear ejecutable
mix escript.build

# Dentro de IEx, puedes probar funciones directamente:

# 17. Probar ayuda
./procesador_archivos --help
./procesador_archivos -h

# 18. Probar sin opciones (default: parallel)
./procesador_archivos data/valid

# 19. Probar todos los modos
./procesador_archivos --mode sequential data/valid
./procesador_archivos --mode parallel data/valid
./procesador_archivos --mode benchmark data/valid

# 20. Probar archivos individuales
./procesador_archivos data/valid/ventas_enero.csv
./procesador_archivos data/valid/usuarios.json
./procesador_archivos data/valid/sistema.log

# 21. Probar archivos corruptos (Entrega 3)
./procesador_archivos data/error/ventas_corrupto.csv
./procesador_archivos data/error/usuarios_malformado.json

# 22. Probar con timeout personalizado
./procesador_archivos --timeout 10000 data/valid
./procesador_archivos --timeout 500 data/valid
./procesador_archivos --timeout 1 data/valid  # Forzar timeout

# 23. Probar con reintentos
./procesador_archivos --retries 1 data/valid
./procesador_archivos --retries 5 data/valid
./procesador_archivos --retries 10 data/valid

# 24. Probar directorio de salida personalizado
./procesador_archivos --output mis_reportes data/valid
ls -la mis_reportes/

# 25. Probar combinaciones de opciones
./procesador_archivos --mode sequential --timeout 5000 --retries 3 data/valid
./procesador_archivos --mode parallel --timeout 10000 --retries 5 --output reportes_especiales data/valid

# 5. Ejecutar TODAS las pruebas
mix test

# 6. Ejecutar pruebas específicas
mix test test/procesador_archivos_test.exs
mix test test/parallel_test.exs

# 7. Si tienes test de errores (Entrega 3)
mix test test/error_handling_test.exs

# 8. Ejecutar pruebas con más detalles
    mix test --trace


# Abrir documentación generada
Estructura del proyecto
text
lib/
├── procesador_archivos.ex   # Módulo principal
├── csv_parser.ex            # Parser de archivos CSV (ventas)
├── json_parser.ex           # Parser de archivos JSON (usuarios)
└── log_parser.ex            # Parser de archivos LOG (estadísticas por nivel)
test/
└── procesador_archivos_test.exs   # Suite de pruebas
Métricas extraídas
Tipo	Métricas principales
CSV	total_sales, unique_products, valid_records
JSON	total_users, active_users, total_sessions
LOG	total_lines, conteos por nivel: DEBUG, INFO, WARN, ERROR, FATAL
Desarrollo
Ejecutar test:
bash
mix test 
Limpiar reportes generados:
bash
rm -rf output/*
Próximos pasos sugeridos
Mejorar LogParser para soportar más formatos de log.

Implementar procesamiento concurrente para grandes volúmenes de datos.

Configurar CI/CD que ejecute mix test automáticamente.

Añadir validación de esquemas en JSON y CSV.

Autor: Bryan Alexander Gómez Miranda