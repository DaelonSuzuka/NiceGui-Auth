from nicegui import app
from fastapi import Request
from fastapi.responses import RedirectResponse
from fastapi_sso.sso.base import OpenID
from fastapi_sso.sso.microsoft import MicrosoftSSO
from starlette.datastructures import URL
import os


# os.environ["OAUTHLIB_INSECURE_TRANSPORT"] = "1"


class CustomMicrosoftSSO(MicrosoftSSO):
    @classmethod
    async def openid_from_response(cls, response: dict) -> OpenID:
        return OpenID(
            id=response["id"],
            email=response["mail"],
            display_name=response["displayName"],
            provider=cls.provider
        )


sso = CustomMicrosoftSSO(
    redirect_uri="http://localhost:5000/auth/callback",
)


class AuthRedirectMiddleware:
    def __init__(self, app):
        self.app = app

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        
        if app.storage.user.get('authenticated', False):
            await self.app(scope, receive, send)
            return

        url = URL(scope=scope)
        if url.path.startswith('/api'):
            await self.app(scope, receive, send)
            return

        if url.path not in ['auth/login', '/auth/login', 'auth/callback', '/auth/callback']:
            response = RedirectResponse('/auth/login', status_code=303)
            await response(scope, receive, send)
            return

        await self.app(scope, receive, send)


app.add_middleware(AuthRedirectMiddleware)


@app.get("/auth/login")
async def auth_init(request: Request):
    return await sso.get_login_redirect()


@app.get("/auth/logout")
async def auth_logout():
    pass


@app.get("/auth/callback")
async def auth_callback(request: Request):
    user = await sso.verify_and_process(request)
    app.storage.user['id'] = user.id
    app.storage.user['display_name'] = user.display_name
    app.storage.user['email'] = user.email
    app.storage.user['authenticated'] = True

    return RedirectResponse('/')
