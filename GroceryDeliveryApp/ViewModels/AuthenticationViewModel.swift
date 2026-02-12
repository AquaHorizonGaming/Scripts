import Foundation

class AuthenticationViewModel: ObservableObject {
    @Published var user: User?
    @Published var isAuthenticated = false

    func login(email: String, password: String) async {
        do {
            let user = try await APIService.shared.login(email: email, password: password)
            DispatchQueue.main.async {
                self.user = user
                self.isAuthenticated = true
            }
        } catch {
            print("Login error: \(error)")
        }
    }

    func signup(name: String, email: String, password: String) async {
        do {
            let user = try await APIService.shared.createAccount(name: name, email: email, password: password)
            DispatchQueue.main.async {
                self.user = user
                self.isAuthenticated = true
            }
        } catch {
            print("Signup error: \(error)")
        }
    }
}
