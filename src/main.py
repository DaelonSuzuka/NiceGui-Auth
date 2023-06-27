from nicegui import ui, app

# import auth


@ui.page('/')
def index():
    ui.label('hi')
    # ui.button('login').props('href="/auth/login')


ui.run(title='AuthTest', dark=True)
