# Procesador de Archivos

Proyecto en Elixir para procesar archivos CSV, JSON y LOG, extraer métricas y generar reportes en texto plano.

## 📋 Resumen

**Propósito:** Procesar archivos de ventas (CSV), usuarios (JSON) y logs de uso (LOG), consolidar métricas y escribir reportes legibles.

**Lenguaje:** Elixir (>= 1.19)

## 🛠️ Requisitos

- Elixir 1.19 o superior
- Erlang/OTP compatible con la versión de Elixir
- Dependencias definidas en `mix.exs` (por ejemplo: `jason`)

## Instalación

1. Instala las dependencias:

```bash
mix deps.get
```

2. Verifica que todo funcione ejecutando los tests:

```bash
mix test
```

## Uso

### Procesar archivos en la carpeta por defecto (`data/valid/`):

```bash
mix run -e "ProcesadorArchivos.process_files()" 
```

### Procesar archivos desde la carpeta de error

```bash
mix run -e "ProcesadorArchivos.process_files(\"data/error\")"

```

Los reportes se generan automáticamente en la carpeta `output/` con el prefijo `report_`.

## Estructura del proyecto

```
lib/
├── procesador_archivos.ex   # Módulo principal
├── csv_parser.ex            # Parser de archivos CSV (ventas)
├── json_parser.ex           # Parser de archivos JSON (usuarios)
└── log_parser.ex            # Parser de archivos LOG (estadísticas por nivel)
test/
└── procesador_archivos_test.exs   # Suite de pruebas
```

## Métricas extraídas

| Tipo  | Métricas principales                                                                 |
|-------|--------------------------------------------------------------------------------------|
| CSV   | `total_sales`, `unique_products`, `valid_records`                                    |
| JSON  | `total_users`, `active_users`, `total_sessions`                                      |
| LOG   | `total_lines`, conteos por nivel: DEBUG, INFO, WARN, ERROR, FATAL                   |

## Desarrollo

### Ejecutar test:

```bash
mix test 
```

### Limpiar reportes generados:

```bash
rm -rf output/*
```

## Próximos pasos sugeridos

- Mejorar `LogParser` para soportar más formatos de log.
- Implementar procesamiento concurrente para grandes volúmenes de datos.
- Configurar CI/CD que ejecute `mix test` automáticamente.
- Añadir validación de esquemas en JSON y CSV.

# Procesamiento secuencial
mix run -e "ProcesadorArchivos.process_files(\"data/valid\")"

# Procesamiento paralelo  
mix run -e "ProcesadorArchivos.process_folder_parallel(\"data/valid\")"

# Benchmark
mix run -e "ProcesadorArchivos.benchmark(\"data/valid\")"

**Autor:** Bryan Alexander Gómez Miranda 