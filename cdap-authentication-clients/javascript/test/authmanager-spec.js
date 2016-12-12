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


var CDAPAuthManager = require('../src/authmanager'),
    expect = require('expect.js'),
    nock = require('nock');

describe('CDAP Auth manager tests', function () {
    describe('Checking Auth Manager functionality', function () {
        it('Constructor creates correct object', function () {
            var authManager = new CDAPAuthManager();

            expect(authManager).to.be.an('object');
            expect(authManager).to.have.property('isAuthEnabled');
            expect(authManager).to.have.property('getToken');
            expect(authManager).to.have.property('configure');
            expect(authManager).to.have.property('setConnectionInfo');
            expect(authManager).to.have.property('getRequiredCredentials');
            expect(authManager).to.have.property('invalidateToken');
        });

        it('"configure" method could not be called without "username" or "password" field', function () {
            var authManager = new CDAPAuthManager();
            expect(function () {
                authManager.configure({});
            }).to.throwException(function (e) {
                    expect(e).to.be.an(Error);
                });
        });

        it('Authentication is disabled on server side.', function () {
            var host = 'localhost',
                port = 11015,

                mock = nock('http://' + host + ':' + port)
                    .get('/ping')
                    .reply(200),

                authManager = new CDAPAuthManager(),
                promise = null,
                authEnabled = true,
                checker = function () {
                    expect(authEnabled).not.to.be.ok();
                };

            authManager.setConnectionInfo(host, port, false);
            promise = authManager.isAuthEnabled();
            promise.then(function (isEnabled) {
                authEnabled = isEnabled;
            });

            promise.then(checker, checker);
        });

        it('Authentication is enabled on server side.', function () {
            var host = 'localhost',
                port = 11015,
                jsonResp = {
                    auth_uri: ["/some/url", "/some/url1", "/some/url2"]
                },
                mock = nock('http://' + host + ':' + port)
                    .get('/ping')
                    .reply(401, JSON.stringify(jsonResp)),

                authManager = new CDAPAuthManager(),
                promise = null,
                authEnabled = false,
                checker = function () {
                    expect(authEnabled).to.be.ok();
                };

            authManager.setConnectionInfo(host, port, false);
            promise = authManager.isAuthEnabled();

            promise.then(function (isEnabled) {
                authEnabled = isEnabled;
            });

            promise.then(checker, checker);
        });

        it('"getToken" returns valid object', function () {
            var username = 'username',
                password = 'password',
                host = 'localhost',
                port = 11015,
                jsonResp1 = {
                    auth_uri: ["/token/url"]
                },
                jsonResp2 = {
                    "access_token": "2YotnFZFEjr1zCsicMWpAA",
                    "token_type": "Bearer",
                    "expires_in": 3600
                },
                mockAuth = nock('http://' + host + ':' + port).
                    get('/ping')
                    .reply(401, JSON.stringify(jsonResp1)),
                mockToken = nock('http://' + host + ':' + port).
                    get('/token/url')
                    .reply(200, JSON.stringify(jsonResp2));

            var authManager = new CDAPAuthManager(),
                authToken = null,
                checker = function () {
                    expect(authToken).to.have.property('token');
                    expect(authToken).to.have.property('type');
                };

            authManager.setConnectionInfo('localhost', 11015, false);
            authManager.configure({username: username, password: password});

            var tokenPromise = authManager.getToken();
            tokenPromise.then(function (token) {
                authToken = token;
            }).then(checker, checker);
        });

        it('"getToken" returns valid token data', function () {
            var username = 'username',
                password = 'password',
                host = 'localhost',
                port = 11015,
                jsonResp1 = {
                    auth_uri: ['http://' + host + ':' + port + '/token/url']
                },
                jsonResp2 = {
                    access_token: "2YotnFZFEjr1zCsicMWpAA",
                    token_type: "Bearer",
                    expires_in: 3600
                },
                mockAuth = nock('http://' + host + ':' + port).
                    get('/ping')
                    .reply(401, JSON.stringify(jsonResp1)),
                mockToken = nock('http://' + host + ':' + port, {
                    reqheaders: {
                        'authorization': 'Basic ' + new Buffer(username + ':' + password).toString('base64')
                    }
                }).
                    get('/token/url')
                    .reply(200, JSON.stringify(jsonResp2));

            var authManager = new CDAPAuthManager(),
                authToken = null,
                checker = function () {
                    expect(authToken.token).to.be(jsonResp2.access_token);
                    expect(authToken.type).to.be(jsonResp2.token_type);
                };

            authManager.setConnectionInfo(host, port, false);
            authManager.configure({username: username, password: password});

            var authTokenPromise = authManager.getToken();
            authTokenPromise.then(function (token) {
                authToken = token;
            }).then(checker, checker);
        });
    });
});
