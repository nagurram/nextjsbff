using Duende.IdentityServer.Models;

namespace identityserver
{
    public static class Config
    {
        private static readonly string WebAppOrigin =
            Environment.GetEnvironmentVariable("WEBAPP_ORIGIN") ?? "https://localhost:3000";

        private static readonly string InteractiveClientSecret =
            Environment.GetEnvironmentVariable("IDENTITY_SERVER_CLIENT_SECRET")
            ?? "49C1A7E1-0C79-4A89-A3D6-A37998FB86B0";

        public static IEnumerable<IdentityResource> IdentityResources =>
            new IdentityResource[]
            {
                new IdentityResources.OpenId(),
                new IdentityResources.Profile(),
            };

        public static IEnumerable<ApiScope> ApiScopes =>
            new ApiScope[]
            {
                new ApiScope("scope1"),
                new ApiScope("scope2"),
            };

        public static IEnumerable<Client> Clients =>
            new Client[]
            {
                // m2m client credentials flow client
                new Client
                {
                    ClientId = "m2m.client",
                    ClientName = "Client Credentials Client",

                    AllowedGrantTypes = GrantTypes.ClientCredentials,
                    ClientSecrets = { new Secret("511536EF-F270-4058-80CA-1C89C192F69A".Sha256()) },

                    AllowedScopes = { "scope1" }
                },

                // interactive client using code flow + pkce
                new Client
                {
                    ClientId = "interactive",
                    ClientSecrets = { new Secret(InteractiveClientSecret.Sha256()) },

                    AllowedGrantTypes = GrantTypes.Code,

                    RedirectUris = { $"{WebAppOrigin}/api/auth/callback/identity-server4" },
                    FrontChannelLogoutUri = $"{WebAppOrigin}/signout-oidc",
                    PostLogoutRedirectUris = { $"{WebAppOrigin}/" },

                    AllowOfflineAccess = true,
                    AllowedScopes = { "openid", "profile", "scope2" }
                },
            };
    }
}
