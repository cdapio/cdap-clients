===================================
CDAP Authentication Client for Ruby
===================================

The CDAP Authentication Client for Ruby API is for fetching the access token from the
authentication server when writing external Ruby applications.


Supported Actions
=================

- Fetch an access token from the authentication server with credentials supported by the
  active authentication mechanism;
- Check if authentication is enabled in the gateway server; and
- Invalidate any cached access tokens. 

Current implementation supports three authentication mechanisms:

- Basic Authentication
- LDAP
- JASPI


Usage
=====

To use the CDAP Authentication Client Ruby API, include this gem in your Gemfile::

  gem 'cdap-authentication-client'

If you use the gem outside Rails, you should require gem files in your application files::

  require 'cdap-authentication-client'


Examples
========
Create a ``CDAP::AuthenticationClient`` instance::

  authentication_client = CDAP::AuthenticationClient.new

Set the connection parameters (authentication server host, authentication server host
port, SSL mode)::

  authentication_client.set_connection_info('localhost', 11015, true)

Create the configuration file::

  # config/auth.yml
  security.auth.client.username: 'admin'
  security.auth.client.password: 'secret'
  security.auth.client.ssl_cert_check: true

Load the configuration from the file::

  config = YAML.load_file('spec/auth.yml')

Setting the configuration in Ruby::

  config = { 'security.auth.client.username' => 'admin', 'security.auth.client.password' => 'secret', 'security.auth.client.ssl_cert_check' => true }

Configure the authentication client::

  authentication_client.configure(config)

Check if authentication is enabled in the gateway server::

  is_enabled = authentication_client.is_auth_enabled

Retrieve the access token from the authentication server::

  token = authentication_client.get_access_token


Testing
=======
To run RSpec tests, run the ``rake rspec`` command in your shell.

The following gems are required to run the tests:

- simplecov
- simplecov-rcov
- webmock
- vcr
- httparty
- bundle
