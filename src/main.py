from nicegui import ui, app
from fastapi_sso.sso.github import GithubSSO
import os


os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"
CLIENT_ID = os.environ["CLIENT_ID"]
CLIENT_SECRET = os.environ["CLIENT_SECRET"]


sso = GithubSSO(
    client_id=CLIENT_ID,
    client_secret=CLIENT_SECRET,
    redirect_uri="http://localhost:5000/auth/callback",
    allow_insecure_http=True,
)


@app.get("/auth/login")
async def auth_init():
    """Initialize auth and redirect"""
    return await sso.get_login_redirect()


@app.get("/auth/callback")
async def auth_callback(request: Request):
    """Verify login"""
    user = await sso.verify_and_process(request)
    return user


@ui.page('/')
def index():
    ui.label('hi')


exclude = 'aggrid, audio, chart, colors, interactive_image, joystick, keyboard, log, markdown, mermaid, plotly, scene, video'

ui.run(title='AuthTest', port=8081, dark=True, exclude=exclude)
