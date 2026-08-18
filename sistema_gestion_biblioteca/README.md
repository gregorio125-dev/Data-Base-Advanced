# Sistema de Gestión de Biblioteca

Proyecto académico — Primera parte: **SQL Server + FastAPI**

## Alcance

Esta versión se concentra exclusivamente en la primera unidad del proyecto:

- SQL Server 2025 Developer Edition como motor relacional.
- SQL Server Management Studio (SSMS) para administración y ejecución de scripts.
- Python + FastAPI como backend.
- Modelo relacional para libros, ejemplares, usuarios, categorías, autores, préstamos y multas.
- CRUD básico de libros y usuarios.
- Registro y devolución de préstamos.
- Reglas de negocio mediante restricciones, función, procedimiento almacenado, vista, CTE y trigger.
- Sin frontend.
- Sin MongoDB.
- Sin Power BI.

La metodología entregada para el proyecto establece como primera unidad el modelo relacional, inserciones y programación de SQL Server; además pide que el backend pueda leer/escribir y que las reglas de negocio funcionen desde la aplicación. Ver el documento base del proyecto. 

## Estructura

```text
sistema_gestion_biblioteca/
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── database.py
│   │   ├── schemas.py
│   │   └── routers/
│   │       ├── books.py
│   │       ├── users.py
│   │       └── loans.py
│   ├── requirements.txt
│   └── .env.example
├── database/
│   ├── 00_create_database.sql
│   ├── 01_schema/
│   │   └── 01_tables.sql
│   ├── 02_programmability/
│   │   ├── 01_function_calculate_fine.sql
│   │   ├── 02_procedure_register_loan.sql
│   │   ├── 03_trigger_return_fine.sql
│   │   └── 04_views.sql
│   ├── 03_seed/
│   │   └── 01_seed.sql
│   └── 04_queries_demo/
│       └── 01_demo_queries.sql
├── .gitignore
└── requirements.txt
```

## 1. Crear la base de datos

Abrir SSMS y ejecutar:

`database/00_create_database.sql`

Después ejecutar, en orden:

1. `database/01_schema/01_tables.sql`
2. `database/02_programmability/01_function_calculate_fine.sql`
3. `database/02_programmability/02_procedure_register_loan.sql`
4. `database/02_programmability/03_trigger_return_fine.sql`
5. `database/02_programmability/04_views.sql`
6. `database/03_seed/01_seed.sql`
7. `database/04_queries_demo/01_demo_queries.sql`

## 2. Configurar Python

Recomendado: Python 3.11+.

En una terminal ubicada en `backend/`:

```bash
python -m venv .venv
```

Windows:

```bash
.venv\Scripts\activate
```

Instalar dependencias:

```bash
pip install -r requirements.txt
```

Copiar `.env.example` como `.env` y ajustar:

```env
DB_SERVER=localhost
DB_PORT=1433
DB_NAME=BibliotecaDB
DB_USER=sa
DB_PASSWORD=TuPassword
DB_DRIVER=ODBC Driver 18 for SQL Server
DB_TRUST_SERVER_CERTIFICATE=yes
```

Si SQL Server usa autenticación de Windows, se puede cambiar la conexión en `backend/app/database.py`.

## 3. Ejecutar FastAPI

Desde `backend/`:

```bash
uvicorn app.main:app --reload
```

API:

```text
http://127.0.0.1:8000
```

Documentación interactiva:

```text
http://127.0.0.1:8000/docs
```

## 4. Flujo que se puede demostrar

### Libros
- `GET /api/books`
- `GET /api/books/{id}`
- `POST /api/books`
- `PUT /api/books/{id}`
- `DELETE /api/books/{id}`

### Usuarios
- `GET /api/users`
- `GET /api/users/{id}`
- `POST /api/users`
- `PUT /api/users/{id}`
- `DELETE /api/users/{id}`

### Préstamos
- `POST /api/loans`
- `GET /api/loans/overdue`
- `GET /api/loans/available`
- `PUT /api/loans/{id}/return`

## Reglas implementadas

1. Un usuario no puede superar el límite de préstamos activos configurado en `Usuario.MaxPrestamos`.
2. Un ejemplar no puede prestarse si ya tiene un préstamo activo.
3. Una devolución tardía genera automáticamente una multa mediante trigger.
4. El valor de la multa se calcula mediante la función `dbo.fn_CalcularMulta`.
5. El procedimiento `dbo.sp_RegistrarPrestamo` concentra la validación y creación del préstamo.
6. Las claves foráneas, `CHECK` y `UNIQUE` protegen la integridad del modelo.

## Nota académica

La metodología original plantea para la Unidad 1: modelo relacional, inserciones, subconsultas/CTE, vistas, funciones, procedimientos, triggers y endpoints de préstamo/devolución/disponibilidad. Este proyecto implementa esa primera parte y deja fuera deliberadamente MongoDB y Power BI.

## Política de IA

Si este repositorio se entrega como trabajo académico, documentar en el README final qué partes fueron generadas o asistidas por IA, qué fue validado manualmente y qué decisiones tomó el equipo.
