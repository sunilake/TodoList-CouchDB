/**
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 **/

import Foundation

import Kitura
import HeliumLogger
import LoggerAPI
import TodoListWeb
import CloudFoundryEnv
import TodoListAPI
import TodoListWeb
import TodoList

HeliumLogger.use()

let configFile = "cloud_config.json"
let databaseServiceName = "TodoListCloudantDatabase"
let databaseName = "TodoList"

extension TodoList {
    public convenience init(withService: Service) {
        
        let host: String
        let username: String?
        let password: String?
        let port: UInt16
        
        if let credentials = withService.credentials {
            host = credentials["host"].stringValue
            username = credentials["username"].stringValue
            password = credentials["password"].stringValue
            port = UInt16(credentials["port"].stringValue)!
        } else {
            host = "127.0.0.1"
            username = nil
            password = nil
            port = UInt16(5984)
        }
        
        self.init(database: databaseName, host: host, port: port, username: username, password: password)
    }
}

let todos: TodoList


do {
    if let service = try getConfiguration(configFile: configFile,
                                          serviceName: databaseServiceName) {
        let database = "TodoList"
        todos = TodoList(withService: service)
  

        todos.createDatabase()

        let controller = TodoListController(backend: todos)

        let port = try CloudFoundryEnv.getAppEnv().port
        Log.verbose("Assigned port is \(port)")

        Kitura.addHTTPServer(onPort: port, with: controller.router)
        Kitura.run()
    }

} catch CloudFoundryEnvError.InvalidValue {
    Log.error("Oops... something went wrong. Server did not start!")
}
