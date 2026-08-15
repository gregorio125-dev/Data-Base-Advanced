# Modelo relacional

## Entidades principales

- **Categoria** 1:N **Libro**
- **Autor** 1:N **Libro**
- **Libro** 1:N **Ejemplar**
- **Usuario** 1:N **Prestamo**
- **Ejemplar** 1:N **Prestamo** (histórico)
- **Prestamo** 1:0..1 **Multa**
- **Libro** N:M **Autor** mediante **LibroAutor**

## Flujo principal

```text
Usuario
   |
   | solicita
   v
Prestamo -----> Ejemplar -----> Libro -----> Categoria
   |                 |
   |                 +---------> Autor
   |
   +---- si devolución tardía ----> Multa
```

La relación `LibroAutor` permite ampliar el modelo a libros con múltiples autores sin romper la estructura principal.
