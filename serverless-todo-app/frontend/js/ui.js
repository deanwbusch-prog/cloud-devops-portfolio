(async function () {
  const el = (id) => document.getElementById(id);
  const authMsg = el('auth-msg');
  const authSection = el('auth-section');
  const appSection = el('app-section');
  const userEmail = el('user-email');
  const btnLogout = el('btn-logout');

  // Auth flows
  el('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    authMsg.textContent = '';
    try {
      const email = el('login-email').value.trim();
      const password = el('login-password').value;
      await Auth.login(email, password);
      userEmail.textContent = email;
      await refreshTasks();
      authSection.classList.add('hidden');
      appSection.classList.remove('hidden');
      btnLogout.classList.remove('hidden');
    } catch (err) {
      authMsg.textContent = err.message || String(err);
    }
  });

  el('signup-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    authMsg.textContent = '';
    try {
      const email = el('signup-email').value.trim();
      const password = el('signup-password').value;
      await Auth.signup(email, password);
      authMsg.textContent = 'Sign-up successful. Check your email for a confirmation code.';
      el('confirm-form').classList.remove('hidden');
      el('confirm-form').dataset.email = email;
    } catch (err) {
      authMsg.textContent = err.message || String(err);
    }
  });

  el('confirm-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    authMsg.textContent = '';
    try {
      const email = e.currentTarget.dataset.email;
      const code = el('confirm-code').value.trim();
      await Auth.confirm(email, code);
      authMsg.textContent = 'Account confirmed. You can now log in.';
    } catch (err) {
      authMsg.textContent = err.message || String(err);
    }
  });

  btnLogout.addEventListener('click', () => {
    Auth.logout();
    userEmail.textContent = '';
    appSection.classList.add('hidden');
    btnLogout.classList.add('hidden');
    authSection.classList.remove('hidden');
  });

  // Task UI
  el('add-task').addEventListener('click', async () => {
    const input = el('task-input');
    const text = input.value.trim();
    if (!text) return;
    try {
      const created = await Api.createTask(text);
      input.value = '';
      await refreshTasks();
    } catch (err) {
      alert(err.message || String(err));
    }
  });

  async function refreshTasks() {
    try {
      const tasks = await Api.listTasks();
      renderTasks(tasks);
    } catch (err) {
      console.warn(err);
    }
  }

  function renderTasks(tasks) {
    const list = el('task-list');
    list.innerHTML = '';
    tasks.forEach(t => {
      const li = document.createElement('li');
      li.className = 'task' + (t.completed ? ' completed' : '');
      li.innerHTML = `
        <div class="left">
          <input type="checkbox" ${t.completed ? 'checked' : ''} data-id="${t.taskId}"/>
          <span class="title">${escapeHtml(t.taskDescription)}</span>
        </div>
        <div class="actions">
          <button data-act="edit" data-id="${t.taskId}">Edit</button>
          <button data-act="del" data-id="${t.taskId}">Delete</button>
        </div>
      `;
      list.appendChild(li);
    });

    list.querySelectorAll('input[type=checkbox]').forEach(cb => {
      cb.addEventListener('change', async (e) => {
        const id = e.target.getAttribute('data-id');
        const completed = e.target.checked;
        try {
          await Api.updateTask(id, { completed });
          await refreshTasks();
        } catch (err) { alert(err.message || String(err)); }
      });
    });

    list.querySelectorAll('button[data-act=edit]').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const id = e.target.getAttribute('data-id');
        const titleEl = e.target.closest('.task').querySelector('.title');
        const current = titleEl.textContent;
        const next = prompt('Edit task', current);
        if (next && next.trim() && next !== current) {
          try {
            await Api.updateTask(id, { taskDescription: next.trim() });
            await refreshTasks();
          } catch (err) { alert(err.message || String(err)); }
        }
      });
    });

    list.querySelectorAll('button[data-act=del]').forEach(btn => {
      btn.addEventListener('click', async (e) => {
        const id = e.target.getAttribute('data-id');
        if (confirm('Delete this task?')) {
          try {
            await Api.deleteTask(id);
            await refreshTasks();
          } catch (err) { alert(err.message || String(err)); }
        }
      });
    });
  }

  function escapeHtml(s) {
    return s.replace(/[&<>"']/g, c => ({
      '&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'
    }[c]));
  }

  // Auto-login if session exists
  const cu = Auth.currentUser();
  if (cu) {
    cu.getSession(async (err, session) => {
      if (!err && session && session.isValid()) {
        userEmail.textContent = cu.getUsername();
        authSection.classList.add('hidden');
        appSection.classList.remove('hidden');
        document.getElementById('btn-logout').classList.remove('hidden');
        await refreshTasks();
      }
    });
  }
})();
