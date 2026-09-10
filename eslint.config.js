const js = require('@eslint/js');
const globals = require('globals');

module.exports = [
  {
    ignores: ['static/assets/elm.js'],
  },
  js.configs.recommended,
  {
    files: ['static/assets/**/*.js'],
    languageOptions: {
      globals: globals.browser,
    },
  },
  {
    files: ['*.js'],
    languageOptions: {
      sourceType: 'commonjs',
      globals: globals.node,
    },
  },
];
