# Sistema de Gestión de Biblioteca Comunitaria/Universitaria
 
Sistema para digitalizar el préstamo, devolución y control de libros en bibliotecas pequeñas (de barrio, colegios, semilleros universitarios), reemplazando el uso de Excel o cuadernos físicos, reduciendo la pérdida de libros y generando datos para decisiones de compra y gestión de colección.
 
---
 
## Participantes

| @gregorio125-dev |
| @CristianMarulandalo | 
| @neiverfernandez4 | 

---
 
## Descripción y alcance del problema
 
Muchas bibliotecas pequeñas de barrio, colegios o semilleros universitarios siguen gestionando sus préstamos en hojas de Excel o cuadernos físicos esto genera varios problemas:
 
- **Pérdida de libros**, porque no hay un control centralizado ni trazabilidad de quién tiene qué libro y desde cuándo.
- **Ausencia de datos confiables** para tomar decisiones, como qué categorías de libros comprar o qué autores tienen más demanda.
- **Cálculo manual y propenso a errores** de multas por retraso en devoluciones.
- **Falta de un espacio estructurado** para que los usuarios dejen reseñas, calificaciones o comentarios sobre los libros que leen.
El proyecto busca resolver esto mediante un sistema que combine una **base de datos relacional** (catálogo, usuarios, préstamos, multas), una **base de datos NoSQL** (reseñas y comentarios con estructura variable) y una capa de **analítica** (Data Mart) para generar reportes de uso y tendencias de lectura.
 
**Alcance:** aplicación de backend (con posibilidad de frontend) que permita registrar préstamos, devoluciones y renovaciones, calcular multas automáticamente, buscar libros, y generar reportes sobre el comportamiento de los usuarios y la colección.
 
---
 
## Posibles usuarios del sistema
 
- **Bibliotecario(a):** gestiona el catálogo, registra préstamos/devoluciones, revisa multas y morosos, genera reportes.
- **Estudiante / usuario:** busca libros, solicita préstamos, deja reseñas y calificaciones, consulta su historial y multas.
- **Administrador:** gestiona usuarios y permisos, supervisa reglas de negocio (límites de préstamo, políticas de multas), accede a analítica y reportes ejecutivos.
---
 
## Lista preliminar de entidades
 
**Modelo relacional (SQL):**
- `Libro` (título, autor, categoría, ISBN, ejemplares disponibles)
- `Usuario` (nombre, tipo de usuario, estado)
- `Prestamo` (libro, usuario, fecha de préstamo, fecha esperada de devolución, fecha real de devolución)
- `Multa` (préstamo asociado, monto, estado de pago)
- `Categoria` / `Autor` (si se normalizan como entidades separadas)
**Modelo NoSQL (MongoDB):**
- `Reseña` (libro_id, usuario_id, calificación, comentario, etiquetas, fecha) — estructura flexible, ya que no todas las reseñas tienen los mismos campos (algunas con etiquetas, otras sin calificación numérica, etc.)
**Data Mart / analítica:**
- Hechos de préstamos (libro, fecha, categoría, usuario) para construir reportes agregados.
---
 
##  Reglas de negocio
 
1. Un usuario **no puede tener más de N libros prestados** simultáneamente (N configurable, ej. 3).
2. **No se puede prestar un libro que ya está prestado** (sin ejemplares disponibles) hasta que sea devuelto.
3. La **multa aumenta de forma automática según los días de retraso**, calculada mediante un trigger en la base de datos al momento de registrar la devolución.
4. Un usuario con **multas pendientes de pago no puede solicitar nuevos préstamos** hasta regularizar su situación.
---
 
## ¿Por qué es un proyecto suficientemente complejo?
 
- Combina **dos modelos de datos distintos** (relacional para catálogo/préstamos/multas, NoSQL para reseñas con estructura variable), lo que exige diseñar la integración entre ambos.
- Requiere **lógica de negocio no trivial**, como triggers para cálculo automático de multas y validaciones de disponibilidad antes de cada préstamo.
- Involucra **múltiples roles de usuario** con distintos permisos y flujos (bibliotecario, usuario, administrador).
- Necesita una **capa analítica** (Data Mart simple + Power BI) para generar reportes de libros más prestados por categoría/mes, usuarios morosos y tendencias de lectura, lo cual implica modelar hechos y dimensiones además del modelo transaccional.
- Contempla **casos de error costosos** (prestar un libro inexistente o ya prestado, no registrar una devolución) que deben prevenirse con restricciones e integridad de datos.
---
 
## Uso de IA
 
Se permite el apoyo de inteligencia artificial durante el desarrollo del proyecto, bajo la siguiente política:
 
- La IA puede usarse para: generar ideas de diseño, resolver dudas puntuales de sintaxis, ayudar a redactar documentación, y apoyar en la revisión de código.
- **No se permite** generar código completo sin comprensión por parte del equipo: cada integrante debe poder explicar el código que aporta al repositorio.
- Todo uso relevante de IA (prompts significativos, generación de fragmentos de código o de estructuras de base de datos) debe **documentarse** en este README o en un archivo `USO_IA.md`, indicando la herramienta usada y el propósito.
- Los mensajes de commit y el diseño final de las reglas de negocio deben reflejar decisiones propias del equipo, no una copia directa de una respuesta de IA.
---
 
## 🔀 Flujo de trabajo del repositorio
 
- Avances periódicos: **1 o 2 commits por integrante por semana**, con mensajes descriptivos.
- La rama `main` está **protegida**: todo cambio se integra mediante **pull requests** con al menos una aprobación antes del merge.
- El alcance del proyecto puede ajustarse sobre la marcha a medida que se avanza en las unidades del curso (relacional, NoSQL, Data Warehouse/Data Mart).
