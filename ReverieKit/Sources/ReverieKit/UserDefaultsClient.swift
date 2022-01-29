import ComposableArchitecture
import SharedModels

public struct UserDefaultsClient {
  public var boolForKey: (String) -> Bool
  public var dataForKey: (String) -> Data?
  public var doubleForKey: (String) -> Double
  public var remove: (String) -> Effect<Never, Never>
  public var setUser: (User) -> Effect<User, Error>
  public var setBool: (Bool, String) -> Effect<Never, Never>
  public var setData: (Data?, String) -> Effect<Never, Never>
  public var setDouble: (Double, String) -> Effect<Never, Never>

  public var user: User? {
    let decoder = JSONDecoder()
    guard let data = dataForKey(userKey) else { return nil }
    return try? decoder.decode(User.self, from: data)
  }

  public func setUser(_ user: User) -> Effect<Never, Never> {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(user) else { return .none }
    return setData(data, userKey)
  }

  public var recentUsernames: [String] {
    let decoder = JSONDecoder()
    guard let data = dataForKey(recentUsernamesKey) else { return [] }
    return (try? decoder.decode([String].self, from: data)) ?? []
  }

  public func setRecentUsernames(_ usernames: [String]) -> Effect<Never, Never> {
    let encoder = JSONEncoder()
    guard let data = try? encoder.encode(usernames) else { return .none }
    return setData(data, recentUsernamesKey)
  }
}

public let userKey = "user"
let recentUsernamesKey = "recentUsernames"
let lastTimelineRefreshTimeKey = "lastTimelineRefreshTimeKey"

public extension UserDefaultsClient {
  static func live(
    userDefaults: UserDefaults = .init(suiteName: "group.reverie")!
  ) -> Self {
    Self(
      boolForKey: userDefaults.bool(forKey:),
      dataForKey: { userDefaults.object(forKey: $0) as? Data },
      doubleForKey: userDefaults.double(forKey:),
      remove: { key in
        .fireAndForget {
          userDefaults.removeObject(forKey: key)
        }
      },
      setUser: { user in
        .result {
          let result = Result<User, Error> {
            let data = try JSONEncoder().encode(user)
            userDefaults.set(data, forKey: userKey)
            return user
          }
          return result
        }
      },
      setBool: { value, key in
        .fireAndForget {
          userDefaults.set(value, forKey: key)
        }
      },
      setData: { data, key in
        .fireAndForget {
          userDefaults.set(data, forKey: key)
        }
      },
      setDouble: { value, key in
        .fireAndForget {
          userDefaults.set(value, forKey: key)
        }
      }
    )
  }
}
