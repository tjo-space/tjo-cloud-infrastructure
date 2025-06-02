from pgadmin.utils import env

MASTER_PASSWORD_REQUIRED = True
MFA_ENABLED = False

AUTHENTICATION_SOURCES = ["oauth2"]
OAUTH2_AUTO_CREATE_USER = True
OAUTH2_CONFIG = [
    {
        "OAUTH2_NAME": "id.tjo.cloud",
        "OAUTH2_DISPLAY_NAME": "id.tjo.cloud",
        "OAUTH2_CLIENT_ID": env("TJO_OAUTH2_CLIENT_ID"),
        "OAUTH2_CLIENT_SECRET": env("TJO_OAUTH2_CLIENT_SECRET"),
        "OAUTH2_TOKEN_URL": "https://id.tjo.cloud/application/o/token/",
        "OAUTH2_AUTHORIZATION_URL": "https://id.tjo.cloud/application/o/authorize/",
        "OAUTH2_API_BASE_URL": "https://id.tjo.cloud/",
        "OAUTH2_USERINFO_ENDPOINT": "https://id.tjo.cloud/application/o/userinfo/",
        "OAUTH2_SERVER_METADATA_URL": "https://id.tjo.cloud/application/o/postgresqltjocloud/.well-known/openid-configuration",
        "OAUTH2_SCOPE": "openid email profile",
        "OAUTH2_ICON": "",
        "OAUTH2_BUTTON_COLOR": "#7959c9",
    }
]
