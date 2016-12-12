/**
 * Copyright © 2014-2016 Cask Data, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License.
 */


(function (factory) {
    'use strict';

    // Support three module loading scenarios
    if (typeof require === 'function' && typeof exports === 'object' && typeof module === 'object') {
        // [1] CommonJS/Node.js
        var target = module['exports'] || exports; // module.exports is for Node.js
        factory(target, require);
    } else if (typeof define === 'function' && define['amd']) {
        // [2] AMD anonymous module
        define(['exports', 'CDAPAuth.Manager'], factory);
    } else {
        // [3] No module loader (plain <script> tag) - put directly in global namespace
        factory(window);
    }
}(function (target, require) {
    'use strict';

    // Given a promise, returns a callback which propogates the error to the given promise.
    var propogateError = function (promise) {
        return function(err) {
            promise.reject(err);
        }
    };
    var moduleConstructor = function () {
        var connectionInfo = {
                host: 'localhost',
                port: 11015,
                ssl: false,
                user: '',
                pass: ''
            },
            tokenInfo = {
                value: '',
                type: '',
                expirationDate: 0
            },
            httpConnection = null,
            authUrls = null,
            authEnabled = null,
            helpers = null,
            Promise = null,
            AUTH_HEADER_NAME = 'Authorization',
            AUTH_TYPE = 'Basic',
            TOKEN_EXPIRATION_TIMEOUT = 5000;

        if ('undefined' !== typeof window) {
            Promise = CDAPAuth.Promise;
            helpers = CDAPAuthHelpers.Browser;
            httpConnection = new XMLHttpRequest();
        } else {
            Promise = require('./promise');
            helpers = require('./helper-node');
            httpConnection = require('http');
        }

        var getAuthHeaders = helpers.getAuthHeaders,
            pingUrl = [ connectionInfo.ssl ? 'https' : 'http',
                        '://', connectionInfo.host,
                        ':', connectionInfo.port, '/ping'
                        ].join(''),
            fetchAuthUrl = helpers.fetchAuthUrl,
            getAuthUrl = function () {
                if (!authUrls) {
                    return '';
                }

                return authUrls[Math.floor(Math.random() * authUrls.length)];
            },
            isAuthEnabledImpl = function () {
                var retPromise = new Promise();
                if (null === authEnabled) {
                    if (!authUrls) {
                        var urlsPromise = fetchAuthUrl(httpConnection, pingUrl);
                        urlsPromise.then(function (urls) {
                            authUrls = urls || [];
                            authEnabled = !!authUrls.length;
                            retPromise.resolve(authEnabled);
                        }, propogateError(retPromise));
                    }
                } else {
                    retPromise.resolve(authEnabled);
                }

                return retPromise;
            },
            fetchToken = helpers.fetchTokenInfo,
            getTokenImpl = function () {
                var retPromise = new Promise(),
                    authEnabledPromise = isAuthEnabledImpl();

                authEnabledPromise.then(function (isAuthEnabled) {
                    var resolveWithToken = function (token) {
                        retPromise.resolve({
                            token: tokenInfo.value,
                            type: tokenInfo.type
                        });
                    };

                    if (isAuthEnabled) {
                        if ((TOKEN_EXPIRATION_TIMEOUT >= (tokenInfo.expirationDate - Date.now()))) {
                            var authHeaders = getAuthHeaders(AUTH_HEADER_NAME, AUTH_TYPE, connectionInfo),
                                tokenInfoPromise = fetchToken(getAuthUrl, httpConnection, authHeaders,
                                AUTH_HEADER_NAME);
                            tokenInfoPromise.then(function (token) {
                                tokenInfo = token;
                            }).then(resolveWithToken, resolveWithToken);
                        }
                    }
                }, propogateError(retPromise));

                return retPromise;
            },
            /**
             * @param {Object} properties {
             *   @param {string} username,
             *   @param {password} password
             * }
             */
            configureImpl = function (properties) {
                if (!properties.username || !properties.password) {
                    throw new Error('"username" and "password" are required');
                }

                if (connectionInfo.user && connectionInfo.pass) {
                    throw new Error('Client is already configured!');
                }

                connectionInfo.user = properties.username;
                connectionInfo.pass = properties.password;
            },
            setConnectionInfoImpl = function (host, port, ssl) {
                connectionInfo.host = host;
                connectionInfo.port = port;
                connectionInfo.ssl = ssl;
            },
            invalidateTokenImpl = function () {
                tokenInfo.value = '';
                tokenInfo.type = '';
                tokenInfo.expirationDate = 0;
            },
            getRequiredCredentialsImpl = function () {
                return [
                    {
                        name: 'username',
                        description: 'Username for basic authentication.',
                        secret: false
                    },
                    {
                        name: 'password',
                        description: 'Password for basic authentication.',
                        secret: true
                    }
                ];
            };

        return {
            isAuthEnabled: isAuthEnabledImpl,
            getToken: getTokenImpl,
            configure: configureImpl,
            setConnectionInfo: setConnectionInfoImpl,
            invalidateToken: invalidateTokenImpl,
            getRequiredCredentials: getRequiredCredentialsImpl
        };
    };

    if (('undefined' !== typeof module) && module.exports) {
        module.exports = moduleConstructor;
    } else {
        target['CDAPAuth'] = target['CDAPAuth'] || {};
        target['CDAPAuth']['Manager'] = target['CDAPAuth']['Manager'] || moduleConstructor;
    }
}));
