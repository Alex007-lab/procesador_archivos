# 📁 Procesador de Archivos

> Herramienta versátil desarrollada en **Elixir** para procesar múltiples tipos de archivos (CSV, JSON, LOG), extraer métricas relevantes y generar reportes detallados.

![Elixir](https://img.shields.io/badge/Elixir-1.19+-purple.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

---

## 📑 Tabla de Contenidos

- [Descripción](#descripción)
- [Características principales](#características-principales)
- [Requisitos previos](#requisitos-previos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Ejemplos de uso](#ejemplos-de-uso)
- [Ejecución de tests](#ejecución-de-tests)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Métricas extraídas](#métricas-extraídas)
- [Roadmap](#roadmap)

---

## 📖 Descripción

**Procesador de Archivos** es una aplicación completamente funcional que permite procesar y analizar archivos de múltiples formatos:

| Formato | Descripción |
|---------|-------------|
| **CSV** | Datos de ventas, inventarios y reportes tabulares |
| **JSON** | Información de usuarios, configuraciones estructuradas |
| **LOG** | Registros de eventos y trazas del sistema |

El sistema es capaz de:
- ✅ Consolidar métricas clave de cada archivo
- ✅ Generar reportes legibles en texto plano
- ✅ Procesar de forma secuencial o paralela
- ✅ Manejar errores y archivos corruptos de forma elegante
- ✅ Realizar benchmarking de rendimiento

---

## ⚡ Características principales

### Procesamiento
- 📊 Análisis de archivos CSV, JSON y LOG
- ⚙️ Procesamiento secuencial y paralelo configurable
- 🔄 Reintentos automáticos con configuración de timeout
- ❌ Manejo robusto de errores y archivos corruptos

### Reportes
- 📄 Generación de reportes en texto plano
- 📈 Extracción de métricas clave y estadísticas
- 🎯 Salida personalizable y formateada
- ⏱️ Benchmarking de rendimiento con Benchee

### Desarrollo
- ✨ Suite completa de tests automatizados
- 🔨 Ejecución como script (`escript`)
- 🚀 Compilación optimizada para producción
- 📦 Todas las dependencias especificadas en `mix.exs`

---

## 📋 Requisitos previos

- **Elixir**: 1.19 o superior
- **Erlang/OTP**: Compatible con la versión de Elixir utilizada
- **Git**: Para clonar el repositorio (opcional)

### Dependencias principales
- `jason` - Procesamiento de JSON
- `nimble_csv` - Análisis de CSV
- `benchee` - Benchmarking de rendimiento

---

## 🚀 Instalación

### 1. Clonar el repositorio

```bash
git clone <url-del-repositorio>
cd procesador_archivos
```

### 2. Instalar dependencias

```bash
mix deps.get
```

### 3. Compilar el proyecto

```bash
mix compile
```

---

## 💻 Uso

### Procesamiento secuencial

```bash
mix run -e "ProcesadorArchivos.procesar_secuencial('ruta/del/archivo.csv')"
```

### Procesamiento paralelo

```bash
mix run -e "ProcesadorArchivos.procesar_paralelo(['archivo1.csv', 'archivo2.json', 'archivo3.log'])"
```

### Generar reporte

```bash
mix run -e "ProcesadorArchivos.generar_reporte(['datos/archivo.csv'])"
```

---

## 📚 Ejemplos de uso

### Ejemplo 1: Procesar un archivo CSV

```elixir
iex> ProcesadorArchivos.procesar_archivos(['data/valid/ventas_enero.csv'])
```

### Ejemplo 2: Procesamiento paralelo con configuración

```elixir
iex> opciones = [timeout: 5000, reintentos: 3]
iex> ProcesadorArchivos.procesar_paralelo(['data/valid/usuarios.json', 'data/valid/sesiones.json'], opciones)
```

### Ejemplo 3: Manejo de errores

```elixir
iex> ProcesadorArchivos.procesar_archivos(['data/error/usuarios_malformado.json'])
# Genera un reporte con detalles del error
```

---

## 🧪 Ejecución de tests

### Ejecutar todos los tests

```bash
mix test
```

### Ejecutar tests con cobertura

```bash
mix test --cover
```

### Ejecutar un archivo de test específico

```bash
mix test test/procesador_archivos_test.exs
```

### Tests disponibles

- `procesador_archivos_test.exs` - Tests funcionales principales
- `error_handling_test.ex` - Tests de manejo de errores
- `parallel_test.exs` - Tests de procesamiento paralelo

---

## 📦 Estructura del proyecto

```
procesador_archivos/
├── lib/                      # Código fuente
│   ├── procesador_archivos.ex        # Módulo principal
│   ├── cli.ex                        # Interfaz de línea de comandos
│   ├── csv_parser.ex                 # Parseador CSV
│   ├── json_parser.ex                # Parseador JSON
│   ├── log_parser.ex                 # Parseador LOG
│   ├── coordinador.ex                # Orquestador de procesamiento
│   ├── worker.ex                     # Workers para procesamiento paralelo
│   └── procesar_con_manejo_errores.ex # Manejo de errores
├── test/                     # Tests
│   ├── procesador_archivos_test.exs
│   ├── error_handling_test.ex
│   ├── parallel_test.exs
│   └── test_helper.exs
├── data/                     # Datos de prueba
│   ├── valid/                # Archivos válidos
│   └── error/                # Archivos con errores
├── output/                   # Reportes generados
├── mix.exs                   # Configuración del proyecto
└── README.md                 # Este archivo
```

---

## 📊 Métricas extraídas

### Archivos CSV (Ventas)
- Total de ventas
- Promedio de ventas
- Máximo y mínimo de venta
- Cantidad de registros
- Errores detectados

### Archivos JSON (Usuarios)
- Total de usuarios
- Distribución por estado
- Edad promedio
- Usuarios activos/inactivos

### Archivos LOG
- Total de eventos
- Distribución por nivel (INFO, WARNING, ERROR)
- Eventos por hora
- Resumen de errores

---

## 🛣️ Roadmap

- [x] Procesamiento de CSV, JSON y LOG
- [x] Manejo de errores y archivos corruptos
- [x] Procesamiento paralelo
- [x] Generación de reportes
- [ ] Soporte para bases de datos
- [ ] API REST
- [ ] Dashboard web
- [ ] Exportación a múltiples formatos (PDF, Excel)

---

## 📧 Contacto

Para preguntas o sugerencias, por favor abre un issue en el repositorio.

**Última actualización**: 14 de enero de 2026
