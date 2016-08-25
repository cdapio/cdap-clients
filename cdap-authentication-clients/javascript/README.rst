=========================================
CDAP Authentication Client for JavaScript
=========================================

Authentication client JavaScript API for the Cask Data Application Platform (CDAP).


Installation
============

Web browser
-----------
Copy ``<project_root>/dist/browser/cdap-auth-client.min.js`` to the project that depends
on it.

NodeJS
------
1. Copy ``<project_root>/dist/nodejs/cdap-auth-client`` to the ``node_modules`` directory
   of your project.
#. ``cd <project_root>/node_modules/cdap-auth-client``
#. ``npm install``

The last command will install all dependencies for ``cdap-auth-client``.


Usage
=====

To use the Authentication client JavaScript API, include these script tags in your
``index.html``:

Web browser
-----------

::

  <script type="text/javascript" src="cdap-auth-client.min.js"></script>


Node.JS
-------

::

  var CDAPAuthManager = require('cdap-auth-client');


Supported actions
=================

.. list-table::
   :widths: 60 40
   :header-rows: 1

   * - Method
     - Description
     
   * - ``isAuthEnabled()``
     - Checks if authentication is enabled from the server side.
       Returns a Promise object. Resolves with a true/false value as the only possible event.
       
   * - ``getToken()``
     - Authenticates and returns token info. Returns a Promise object. Resolves with a
       true/false value as the only possible event. Resolves with an object ``{ token: '',
       type: '' }`` where ``token`` is the token value and ``type`` is the token type;
       currently only ``Bearer`` is supported for ``token type``.

   * - ``configure(config)``
     - Sets up username and password for authentication manager where
       ``config`` is a JSON string: ``{ username: '', password: '' }``

   * - ``setConnectionInfo(hostname, port, ssl)``
     - Sets up connection data


Example
=======

Create a ``CDAPAuthManager`` instance, specifying the *username* and *password* fields. 
Optional configurations that can be set (and their default values):

- host: ``localhost`` (DNS name or IP address of the CDAP gateway server)
- port: ``11015`` (Port number the CDAP gateway server listens on)
- ssl: ``false`` (use HTTP protocol instead)

::

    var manager = new CDAPAuthManager();

    manager.configure({
        username: 'username',
        password: 'password'
    });
    manager.setConnectionInfo('localhost', 11015, false);

    var tokenPromise = manager.getToken();
    tokenPromise.then(function (token) {
        console.log(token);
    });
