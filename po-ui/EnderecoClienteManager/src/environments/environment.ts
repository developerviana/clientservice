export const environment = {
  production: false,
  api: {
    baseUrl: 'http://localhost:8181/rest',
    timeout: 30000
  },
  totvs: {
    basicAuthToken: btoa('admin:msadm'),
    company: '99',
    branch: '01'
  }
};
