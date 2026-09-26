const API_BASE = 'http://127.0.0.1:8000/api';

const state = {
  books: [],
  users: [],
  categories: [],
  authors: [],
  activeLoans: [],
  availableCopies: [],
  overdueLoans: []
};

document.addEventListener('DOMContentLoaded', () => {
  bindTabs();
  bindGlobalModalControls();
  bindBookForm();
  bindUserForm();
  bindLoanForm();
  bindTableActions();
  loadAllData();
});

function bindTabs() {
  document.querySelectorAll('.tab').forEach((button) => {
    button.addEventListener('click', () => {
      const tab = button.dataset.tab;
      document.querySelectorAll('.tab').forEach((tabButton) => {
        tabButton.classList.toggle('active', tabButton === button);
      });

      document.querySelectorAll('.view').forEach((section) => {
        section.classList.toggle('active', section.id === `${tab}-section`);
      });
    });
  });
}

function bindGlobalModalControls() {
  document.getElementById('new-book-btn').addEventListener('click', () => openBookModal());
  document.getElementById('new-user-btn').addEventListener('click', () => openUserModal());

  document.querySelectorAll('[data-close]').forEach((button) => {
    button.addEventListener('click', () => closeModal(button.dataset.close));
  });

  document.querySelectorAll('.modal').forEach((modal) => {
    modal.addEventListener('click', (event) => {
      if (event.target === modal) {
        closeModal(modal.id);
      }
    });
  });
}

function bindBookForm() {
  document.getElementById('book-form').addEventListener('submit', async (event) => {
    event.preventDefault();

    const form = event.currentTarget;
    const bookId = form.elements.id.value;

    const payload = {
      titulo: form.elements.titulo.value.trim(),
      isbn: form.elements.isbn.value.trim(),
      anio_publicacion: Number(form.elements.anio_publicacion.value),
      categoria_id: Number(form.elements.categoria_id.value),
      autor_id: Number(form.elements.autor_id.value),
      editorial: form.elements.editorial.value.trim() || null,
      descripcion: form.elements.descripcion.value.trim() || null
    };

    if (!payload.titulo || !payload.isbn || !payload.categoria_id || !payload.autor_id) {
      showMessage('Completa los campos requeridos del libro.', 'error');
      return;
    }

    try {
      if (bookId) {
        await apiRequest(`/books/${bookId}`, {
          method: 'PUT',
          body: JSON.stringify(payload)
        });
        showMessage('Libro actualizado correctamente.', 'success');
      } else {
        const createPayload = {
          ...payload,
          cantidad_ejemplares: Number(form.elements.cantidad_ejemplares.value || 1)
        };

        await apiRequest('/books', {
          method: 'POST',
          body: JSON.stringify(createPayload)
        });
        showMessage('Libro creado correctamente.', 'success');
      }

      form.reset();
      closeModal('book-modal');
      await loadBooks();
      await loadLoanData();
    } catch (error) {
      showMessage(error.message, 'error');
    }
  });
}

function bindUserForm() {
  document.getElementById('user-form').addEventListener('submit', async (event) => {
    event.preventDefault();

    const form = event.currentTarget;
    const userId = form.elements.id.value;

    const payload = {
      nombre: form.elements.nombre.value.trim(),
      email: form.elements.email.value.trim(),
      telefono: form.elements.telefono.value.trim() || null,
      max_prestamos: Number(form.elements.max_prestamos.value),
      activo: form.elements.activo.checked
    };

    if (!payload.nombre || !payload.email) {
      showMessage('Completa nombre y correo del usuario.', 'error');
      return;
    }

    try {
      if (userId) {
        await apiRequest(`/users/${userId}`, {
          method: 'PUT',
          body: JSON.stringify(payload)
        });
        showMessage('Usuario actualizado correctamente.', 'success');
      } else {
        await apiRequest('/users', {
          method: 'POST',
          body: JSON.stringify(payload)
        });
        showMessage('Usuario creado correctamente.', 'success');
      }

      form.reset();
      closeModal('user-modal');
      await loadUsers();
      await loadLoanSelectors();
    } catch (error) {
      showMessage(error.message, 'error');
    }
  });
}

function bindLoanForm() {
  document.getElementById('loan-form').addEventListener('submit', async (event) => {
    event.preventDefault();

    const form = event.currentTarget;
    const payload = {
      usuario_id: Number(form.elements.usuario_id.value),
      ejemplar_id: Number(form.elements.ejemplar_id.value),
      dias_prestamo: Number(form.elements.dias_prestamo.value)
    };

    if (!payload.usuario_id || !payload.ejemplar_id) {
      showMessage('Selecciona un usuario y un ejemplar disponibles.', 'error');
      return;
    }

    try {
      const response = await apiRequest('/loans', {
        method: 'POST',
        body: JSON.stringify(payload)
      });

      showMessage(response.mensaje || 'Préstamo registrado correctamente.', 'success');
      form.reset();
      form.elements.dias_prestamo.value = 14;
      await loadLoanData();
      await loadBooks();
    } catch (error) {
      showMessage(error.message, 'error');
    }
  });
}

function bindTableActions() {
  // Books actions
  document.getElementById('books-table-body').addEventListener('click', async (event) => {
    const button = event.target.closest('button');
    if (!button) return;

    const bookId = Number(button.dataset.id);
    const book = state.books.find((item) => item.LibroID === bookId);

    if (button.dataset.action === 'edit-book') {
      openBookModal(book);
    }

    if (button.dataset.action === 'delete-book') {
      if (!confirm(`¿Deseas eliminar el libro #${bookId} (${book ? book.Titulo : ''})?`)) return;

      try {
        const response = await apiRequest(`/books/${bookId}`, { method: 'DELETE' });
        showMessage(response.mensaje || 'Libro eliminado.', 'success');
        await loadBooks();
        await loadLoanData();
      } catch (error) {
        showMessage(error.message, 'error');
      }
    }
  });

  // Users actions
  document.getElementById('users-table-body').addEventListener('click', async (event) => {
    const button = event.target.closest('button');
    if (!button) return;

    const userId = Number(button.dataset.id);
    if (button.dataset.action === 'edit-user') {
      const user = state.users.find((item) => item.UsuarioID === userId);
      openUserModal(user);
    }

    if (button.dataset.action === 'delete-user') {
      if (!confirm(`¿Deseas desactivar al usuario #${userId}?`)) return;

      try {
        const response = await apiRequest(`/users/${userId}`, { method: 'DELETE' });
        showMessage(response.mensaje || 'Usuario desactivado.', 'success');
        await loadUsers();
        await loadLoanSelectors();
      } catch (error) {
        showMessage(error.message, 'error');
      }
    }
  });

  // Active loans actions
  document.getElementById('active-loans-table-body').addEventListener('click', async (event) => {
    const button = event.target.closest('button');
    if (!button) return;
    const loanId = Number(button.dataset.id);
    await handleLoanReturn(loanId);
  });

  // Overdue loans actions
  document.getElementById('overdue-table-body').addEventListener('click', async (event) => {
    const button = event.target.closest('button');
    if (!button) return;
    const loanId = Number(button.dataset.id);
    await handleLoanReturn(loanId);
  });
}

async function handleLoanReturn(loanId) {
  if (!loanId) return;
  try {
    const response = await apiRequest(`/loans/${loanId}/return`, { method: 'PUT' });
    const multa = Number(response.Multa || 0);
    if (multa > 0) {
      showMessage(`Devolución registrada. ¡Multa generada: $${multa.toLocaleString('es-CO')}! (${response.DiasRetraso || 0} días de retraso)`, 'warning');
    } else {
      showMessage(response.mensaje || 'Devolución registrada correctamente sin multa.', 'success');
    }
    await loadLoanData();
    await loadBooks();
  } catch (error) {
    showMessage(error.message, 'error');
  }
}

async function loadAllData() {
  try {
    await Promise.all([
      loadCategoriesAndAuthors(),
      loadBooks(),
      loadUsers(),
      loadLoanData()
    ]);
  } catch (error) {
    showMessage(error.message, 'error');
  }
}

async function loadCategoriesAndAuthors() {
  try {
    const [categories, authors] = await Promise.all([
      apiRequest('/categories'),
      apiRequest('/authors')
    ]);
    state.categories = categories;
    state.authors = authors;

    const catSelect = document.getElementById('book-categoria');
    const autSelect = document.getElementById('book-autor');

    if (catSelect) {
      catSelect.innerHTML = '<option value="">Seleccione una categoría</option>' +
        categories.map((c) => `<option value="${c.CategoriaID}">${escapeHtml(c.Nombre)}</option>`).join('');
    }

    if (autSelect) {
      autSelect.innerHTML = '<option value="">Seleccione un autor</option>' +
        authors.map((a) => `<option value="${a.AutorID}">${escapeHtml(a.NombreCompleto || `${a.Nombre} ${a.Apellido}`)}</option>`).join('');
    }
  } catch (error) {
    console.error('Error al cargar catálogos:', error);
  }
}

async function loadBooks() {
  state.books = await apiRequest('/books');
  renderBooksTable();
}

async function loadUsers() {
  state.users = await apiRequest('/users');
  renderUsersTable();
}

async function loadLoanData() {
  const [available, overdue, active] = await Promise.all([
    apiRequest('/loans/available'),
    apiRequest('/loans/overdue'),
    apiRequest('/loans/active')
  ]);

  state.availableCopies = available;
  state.overdueLoans = overdue;
  state.activeLoans = active;

  renderActiveLoansTable();
  renderOverdueTable();
  renderAvailableCopiesTable();
  await loadLoanSelectors();
}

async function loadLoanSelectors() {
  const users = await apiRequest('/users');
  const copies = await apiRequest('/loans/available');

  const userSelect = document.getElementById('loan-user-select');
  const copySelect = document.getElementById('loan-copy-select');

  userSelect.innerHTML = '<option value="">Seleccione un usuario</option>' +
    users.filter((user) => Number(user.Activo) === 1)
      .map((user) => `<option value="${user.UsuarioID}">${escapeHtml(user.Nombre)} (${escapeHtml(user.Email)})</option>`)
      .join('');

  copySelect.innerHTML = '<option value="">Seleccione un ejemplar</option>' +
    copies.map((copy) => `<option value="${copy.EjemplarID}">${escapeHtml(copy.CodigoInventario)} - ${escapeHtml(copy.Titulo)}</option>`).join('');
}

function renderBooksTable() {
  const tbody = document.getElementById('books-table-body');

  if (!state.books.length) {
    tbody.innerHTML = '<tr><td colspan="8" class="empty-state">No hay libros registrados.</td></tr>';
    return;
  }

  tbody.innerHTML = state.books.map((book) => `
    <tr>
      <td>${book.LibroID}</td>
      <td><strong>${escapeHtml(book.Titulo || '—')}</strong></td>
      <td><code>${escapeHtml(book.ISBN || '—')}</code></td>
      <td>${escapeHtml(book.Autor || '—')}</td>
      <td>${escapeHtml(book.Categoria || '—')}</td>
      <td>${Number(book.TotalEjemplares ?? 0)}</td>
      <td>
        <span class="badge ${Number(book.EjemplaresDisponibles) > 0 ? 'active' : 'inactive'}">
          ${Number(book.EjemplaresDisponibles ?? 0)} disponibles
        </span>
      </td>
      <td>
        <div class="cell-actions">
          <button class="action-btn" data-action="edit-book" data-id="${book.LibroID}" type="button">Editar</button>
          <button class="danger-btn" data-action="delete-book" data-id="${book.LibroID}" type="button">Eliminar</button>
        </div>
      </td>
    </tr>
  `).join('');
}

function renderUsersTable() {
  const tbody = document.getElementById('users-table-body');

  if (!state.users.length) {
    tbody.innerHTML = '<tr><td colspan="8" class="empty-state">No hay usuarios registrados.</td></tr>';
    return;
  }

  tbody.innerHTML = state.users.map((user) => `
    <tr>
      <td>${user.UsuarioID}</td>
      <td><strong>${escapeHtml(user.Nombre || '—')}</strong></td>
      <td>${escapeHtml(user.Email || '—')}</td>
      <td>${escapeHtml(user.Telefono || '—')}</td>
      <td>${Number(user.MaxPrestamos ?? 0)} libros</td>
      <td>
        <span class="badge ${Number(user.Activo) === 1 ? 'active' : 'inactive'}">
          ${Number(user.Activo) === 1 ? 'Activo' : 'Inactivo'}
        </span>
      </td>
      <td>${formatDate(user.FechaRegistro)}</td>
      <td>
        <div class="cell-actions">
          <button class="action-btn" data-action="edit-user" data-id="${user.UsuarioID}" type="button">Editar</button>
          <button class="danger-btn" data-action="delete-user" data-id="${user.UsuarioID}" type="button">Desactivar</button>
        </div>
      </td>
    </tr>
  `).join('');
}

function renderActiveLoansTable() {
  const tbody = document.getElementById('active-loans-table-body');
  const countBadge = document.getElementById('active-loans-count');
  if (countBadge) {
    countBadge.textContent = `${state.activeLoans.length} activo${state.activeLoans.length === 1 ? '' : 's'}`;
  }

  if (!state.activeLoans.length) {
    tbody.innerHTML = '<tr><td colspan="8" class="empty-state">No hay préstamos activos en este momento.</td></tr>';
    return;
  }

  tbody.innerHTML = state.activeLoans.map((loan) => {
    const dias = Number(loan.DiasParaVencer ?? 0);
    const diasLabel = dias < 0
      ? `<span class="badge danger">${Math.abs(dias)} días vencido</span>`
      : `<span class="badge active">${dias} días restantes</span>`;

    return `
      <tr>
        <td>${loan.PrestamoID}</td>
        <td><strong>${escapeHtml(loan.Usuario || '—')}</strong></td>
        <td>${escapeHtml(loan.Titulo || '—')}</td>
        <td><code>${escapeHtml(loan.CodigoInventario || '—')}</code></td>
        <td>${formatDate(loan.FechaPrestamo)}</td>
        <td>${formatDate(loan.FechaVencimiento)}</td>
        <td>${diasLabel}</td>
        <td>
          <button class="primary-btn" data-id="${loan.PrestamoID}" type="button">Marcar devuelto</button>
        </td>
      </tr>
    `;
  }).join('');
}

function renderOverdueTable() {
  const tbody = document.getElementById('overdue-table-body');

  if (!state.overdueLoans.length) {
    tbody.innerHTML = '<tr><td colspan="6" class="empty-state">No hay préstamos vencidos.</td></tr>';
    return;
  }

  tbody.innerHTML = state.overdueLoans.map((loan) => `
    <tr>
      <td>${loan.PrestamoID}</td>
      <td><strong>${escapeHtml(loan.Usuario || '—')}</strong></td>
      <td>${escapeHtml(loan.Titulo || '—')}</td>
      <td>${formatDate(loan.FechaVencimiento)}</td>
      <td><span class="badge danger">${Number(loan.DiasRetraso ?? 0)} días</span></td>
      <td>
        <button class="primary-btn" data-id="${loan.PrestamoID}" type="button">Marcar devuelto</button>
      </td>
    </tr>
  `).join('');
}

function renderAvailableCopiesTable() {
  const tbody = document.getElementById('available-table-body');

  if (!state.availableCopies.length) {
    tbody.innerHTML = '<tr><td colspan="3" class="empty-state">No hay ejemplares disponibles.</td></tr>';
    return;
  }

  tbody.innerHTML = state.availableCopies.map((copy) => `
    <tr>
      <td>${copy.EjemplarID}</td>
      <td><code>${escapeHtml(copy.CodigoInventario || '—')}</code></td>
      <td>${escapeHtml(copy.Titulo || '—')}</td>
    </tr>
  `).join('');
}

function openBookModal(book = null) {
  const form = document.getElementById('book-form');
  const modal = document.getElementById('book-modal');
  const quantityGroup = document.getElementById('book-quantity-group');
  const title = document.getElementById('book-modal-title');

  form.reset();
  form.elements.id.value = book ? book.LibroID : '';
  title.textContent = book ? 'Editar libro' : 'Nuevo libro';
  quantityGroup.style.display = book ? 'none' : 'block';

  if (book) {
    form.elements.titulo.value = book.Titulo || '';
    form.elements.isbn.value = book.ISBN || '';
    form.elements.anio_publicacion.value = book.AnioPublicacion || '';
    form.elements.categoria_id.value = book.CategoriaID || '';
    form.elements.autor_id.value = book.AutorID || '';
    form.elements.editorial.value = book.Editorial || '';
    form.elements.descripcion.value = book.Descripcion || '';
  }

  modal.classList.remove('hidden');
  modal.setAttribute('aria-hidden', 'false');
}

function openUserModal(user = null) {
  const form = document.getElementById('user-form');
  const modal = document.getElementById('user-modal');
  const title = document.getElementById('user-modal-title');

  form.reset();
  form.elements.id.value = user ? user.UsuarioID : '';
  title.textContent = user ? 'Editar usuario' : 'Nuevo usuario';

  if (user) {
    form.elements.nombre.value = user.Nombre || '';
    form.elements.email.value = user.Email || '';
    form.elements.telefono.value = user.Telefono || '';
    form.elements.max_prestamos.value = user.MaxPrestamos || 3;
    form.elements.activo.checked = Number(user.Activo) === 1;
  }

  modal.classList.remove('hidden');
  modal.setAttribute('aria-hidden', 'false');
}

function closeModal(modalId) {
  const modal = document.getElementById(modalId);
  if (!modal) return;
  modal.classList.add('hidden');
  modal.setAttribute('aria-hidden', 'true');
}

async function apiRequest(endpoint, options = {}) {
  const response = await fetch(`${API_BASE}${endpoint}`, {
    headers: {
      'Content-Type': 'application/json',
      ...(options.headers || {})
    },
    ...options
  });

  const text = await response.text();
  let payload = null;

  if (text) {
    try {
      payload = JSON.parse(text);
    } catch (error) {
      payload = text;
    }
  }

  if (!response.ok) {
    const message = extractErrorMessage(payload);
    throw new Error(message || `Error ${response.status}`);
  }

  return payload;
}

function extractErrorMessage(payload) {
  if (!payload) return 'Ha ocurrido un error.';

  if (typeof payload === 'string') return payload;

  if (Array.isArray(payload.detail)) {
    return payload.detail.map((item) => item.msg || item.error || 'Error').join(' · ');
  }

  if (payload.detail) {
    return typeof payload.detail === 'string' ? payload.detail : JSON.stringify(payload.detail);
  }

  if (payload.message) return payload.message;

  return 'Ha ocurrido un error en la solicitud.';
}

function showMessage(message, type = 'success') {
  const toast = document.getElementById('toast');
  toast.textContent = message;
  toast.className = `toast ${type}`;

  clearTimeout(showMessage.timeoutId);
  showMessage.timeoutId = setTimeout(() => {
    toast.classList.add('hidden');
  }, 4000);
}

function formatDate(value) {
  if (!value) return '—';
  // Handle ISO date strings (e.g. "2026-09-25")
  if (typeof value === 'string' && value.includes('-')) {
    const parts = value.split('T')[0].split('-');
    if (parts.length === 3) {
      return `${parts[2]}/${parts[1]}/${parts[0]}`;
    }
  }
  const date = new Date(value);
  if (Number.isNaN(date)) return String(value);
  return date.toLocaleDateString('es-ES');
}

function escapeHtml(value) {
  return String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
