import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var viewModel: AuthenticationViewModel
    @State private var isLogin = true
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if !isLogin {
                    TextField("Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button(isLogin ? "Login" : "Sign Up") {
                    Task {
                        if isLogin {
                            await viewModel.login(email: email, password: password)
                        } else {
                            await viewModel.signup(name: name, email: email, password: password)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                Button(isLogin ? "Create an account" : "Have an account? Login") {
                    isLogin.toggle()
                }
                Spacer()
            }
            .padding()
            .navigationTitle(isLogin ? "Login" : "Sign Up")
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .environmentObject(AuthenticationViewModel())
    }
}
