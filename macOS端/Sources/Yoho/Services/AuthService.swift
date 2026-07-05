import Foundation
import Supabase

@MainActor
final class AuthService {
    private let client: SupabaseClient

    init() {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("Missing SUPABASE_URL or SUPABASE_ANON_KEY in Info.plist")
        }
        client = SupabaseClient(supabaseURL: URL(string: url)!, supabaseKey: key)
    }

    var isLoggedIn: Bool {
        client.auth.currentSession != nil
    }

    /// 邮箱注册（platform 由数据库默认值 'mac' 自动填入）
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    /// 邮箱登录
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    /// 退出登录
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
