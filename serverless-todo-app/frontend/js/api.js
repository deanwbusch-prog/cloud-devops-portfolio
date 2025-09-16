(function () {
  const base = window.APP_CONFIG.apiBaseUrl;

  async function request(path, opts = {}) {
    const token = await window.Auth.getJwt();
    if (!token) throw new Error('Not authenticated');
    const res = await fetch(base + path, {
      method: opts.method || 'GET',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
      },
      body: opts.body ? JSON.stringify(opts.body) : undefined,
    });
    if (res.status === 204) return null;
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(data.error || `HTTP ${res.status}`);
    return data;
  }

  function listTasks() {
    return request('/tasks');
  }

  function createTask(taskDescription) {
    return request('/tasks', { method: 'POST', body: { taskDescription } });
  }

  function updateTask(taskId, updates) {
    return request(`/tasks/${encodeURIComponent(taskId)}`, { method: 'PUT', body: updates });
  }

  function deleteTask(taskId) {
    return request(`/tasks/${encodeURIComponent(taskId)}`, { method: 'DELETE' });
  }

  window.Api = { listTasks, createTask, updateTask, deleteTask };
})();
