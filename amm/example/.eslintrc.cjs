/* eslint-env node */
module.exports = {
  extends: ['./eslint-config-base.json', 'plugin:react/recommended', 'plugin:react-hooks/recommended'],
  parserOptions: {
    ecmaFeatures: {
      jsx: true,
    },
    tsconfigRootDir: __dirname,
    project: ['./tsconfig.json', './tsconfig.node.json'],
  },
  plugins: ['react'],
  rules: {
    'react/prop-types': 'off',
    'react/react-in-jsx-scope': 'off',
    'jsx-a11y/anchor-is-valid': 'off',
    'react/display-name': 'off',
  },
  ignorePatterns: ['**/*.js'],
  settings: {
    react: {
      version: 'detect',
    },
  },
}
