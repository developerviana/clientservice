export const environment = {
  production: false,
  api: {
    baseUrl: 'http://localhost:8181/rest',
    timeout: 30000
  },
  totvs: {
    // basicAuthToken deve ser definido em tempo de execução, não no código fonte
    basicAuthToken: '',
    company: '99',
    branch: '01'
  }
};
