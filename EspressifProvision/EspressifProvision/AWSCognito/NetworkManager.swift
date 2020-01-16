//
//  APIClient.swift
//  EspressifProvision
//
//  Created by Vikas Chandra on 01/07/19.
//  Copyright © 2019 Espressif. All rights reserved.
//

import Alamofire
import Foundation

class NetworkManager {
    /// A singleton class that manages Network call of the entire application
    static let shared = NetworkManager()

    private init() {}

    func getUserId(completionHandler: @escaping (String?, Error?) -> Void) {
        if let userID = User.shared.userID {
            completionHandler(userID, nil)
        } else {
            User.shared.getAccessToken(completionHandler: { idToken in
                if idToken != nil {
                    User.shared.idToken = idToken
                    let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                    Alamofire.request(Constants.getUserId, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                        if let json = response.result.value as? [String: String] {
                            print("JSON: \(json)")
                            if let userid = json[Constants.userID] {
                                User.shared.userID = userid
                                UserDefaults.standard.set(userid, forKey: Constants.userIDKey)
                                completionHandler(userid, nil)
                                return
                            }
                        }
                        completionHandler(nil, NetworkError.keyNotPresent)
                    }
                } else {
                    completionHandler(nil, NetworkError.emptyToken)
                }
            })
        }
    }

    func addDeviceToUser(parameter: [String: String], completionHandler: @escaping (String?, Error?) -> Void) {
        User.shared.getAccessToken(completionHandler: { idToken in
            if idToken != nil {
                let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                Alamofire.request(Constants.addDevice, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                    if let error = response.result.error {
                        print("Add device error \(error)")
                        completionHandler(nil, error)
                        return
                    }
                    print("Add device successfull)")
                    if let json = response.result.value as? [String: String] {
                        print("JSON: \(json)")
                        if let requestId = json[Constants.requestID] {
                            completionHandler(requestId, nil)
                            return
                        }
                    }
                    completionHandler(nil, NetworkError.keyNotPresent)
                }
            } else {
                completionHandler(nil, NetworkError.emptyToken)
            }
        })
    }

    func getNodeList(completionHandler: @escaping ([Node]?, Error?) -> Void) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        let url = Constants.getNodes
                        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
//                            if let path = Bundle.main.path(forResource: "DeviceDetails", ofType: "json") {
//                                do {
//                                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
//                                    let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
//                                    if let jsonResult = jsonResult as? [String: Any] {
//                                        // do stuff
//                                        print("valid json")
//                                        completionHandler(JSONParser.parseNodeData(data: jsonResult, nodeID: "00-11-22-33-44-55"), nil)
//                                        return
//                                    }
//                                } catch {
//                                    // handle error
//                                }
//                            }
                            print(response)
                            if let json = response.result.value as? [String: Any], let tempArray = json["nodes"] as? [String] {
                                var nodeList: [Node] = []
                                let serviceGroup = DispatchGroup()
                                for item in tempArray {
                                    serviceGroup.enter()
                                    self.getNodeConfig(nodeID: item, headers: headers, completionHandler: { node, _ in
                                        if let newNode = node {
                                            if newNode.devices?.count == 1 {
                                                nodeList.insert(newNode, at: 0)
                                            } else {
                                                nodeList.append(newNode)
                                            }
                                        }
                                        serviceGroup.leave()
                                    })
                                }
                                serviceGroup.notify(queue: .main) {
                                    completionHandler(nodeList, nil)
                                }
                            } else {
                                completionHandler(nil, NetworkError.keyNotPresent)
                            }
                        }
                    } else {
                        completionHandler(nil, NetworkError.emptyToken)
                    }
                })
            } else {
                completionHandler(nil, CustomError.userIDNotPresent)
            }
        }
    }

    func getNodeConfig(nodeID: String, headers: HTTPHeaders, completionHandler: @escaping (Node?, Error?) -> Void) {
        let url = Constants.getNodeConfig + "?nodeid=" + nodeID
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            print(response)
            if let json = response.result.value as? [String: Any] {
                completionHandler(JSONParser.parseNodeData(data: json, nodeID: nodeID), nil)
            } else {
                completionHandler(nil, NetworkError.keyNotPresent)
            }
        }
    }

    func deviceAssociationStatus(deviceID: String, requestID: String, completionHandler: @escaping (Bool) -> Void) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let url = Constants.checkStatus + "?node_id=" + deviceID
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        Alamofire.request(url + "&request_id=" + requestID + "&user_request=true", method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            if let json = response.result.value as? [String: String], let status = json["request_status"] as? String {
                                print(json)
                                if status == "confirmed" {
                                    completionHandler(true)
                                    return
                                }
                            }
                            completionHandler(false)
                        }
                    } else {
                        completionHandler(false)
                    }
                })
            } else {
                completionHandler(false)
            }
        }
    }

    func updateThingShadow(nodeID: String, parameter: [String: Any]) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let url = Constants.updateThingsShadow + "?nodeid=" + nodeID
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        Alamofire.request(url, method: .put, parameters: parameter, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            print(parameter)
                            print(response.result.value)
                        }
                    } else {}
                })
            }
        }
    }

    func getDeviceThingShadow(nodeID: String, completionHandler: @escaping ([String: Any]?) -> Void) {
        NetworkManager.shared.getUserId { userID, _ in
            if userID != nil {
                User.shared.getAccessToken(completionHandler: { idToken in
                    if idToken != nil {
                        let url = Constants.getDeviceShadow + "?nodeid=" + nodeID
                        let headers: HTTPHeaders = ["Content-Type": "application/json", "Authorization": idToken!]
                        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
                            if let json = response.result.value as? [String: Any] {
                                completionHandler(json)
                            }
                            print(response.result.value)
                            completionHandler(nil)
                        }
                    } else {
                        completionHandler(nil)
                    }
                })
            } else {
                completionHandler(nil)
            }
        }
    }

    func getIdToken(githubToken: String!, completionHandler _: @escaping (Bool) -> Void) {
        let requestData = "grant_type=authorization_code&client_id=" + Constants.clientID + "&code=" + githubToken + "&client_secret="
        let headers: HTTPHeaders = ["content-type": "application/x-www-form-urlencoded"]
    }
}
